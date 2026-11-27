"""Profile Showcase & Opt-in Weekly Subject Leaderboard service (T085)."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import (
    AlarmSession,
    ConsentEvent,
    DailyReport,
    SubjectMemory,
    User,
    UserCommunityProfile,
    XpLedger,
)
from app.services.commitment_group_service import CommitmentGroupService
from app.services.eduskills_adapter import normalize_subject_code
from app.services.progression import (
    STREAK_XP_REASONS,
    build_streak_snapshot,
    progress_level,
    resolve_zone,
)

LEADERBOARD_OPT_IN_SCOPE = 'weekly_leaderboard_opt_in'

_SUBJECT_LABELS_VI: dict[str, str] = {
    'TOAN': 'Toán',
    'NGU_VAN': 'Ngữ văn',
    'TIENG_ANH': 'Tiếng Anh',
    'VAT_LY': 'Vật lý',
    'HOA_HOC': 'Hóa học',
    'SINH_HOC': 'Sinh học',
    'LICH_SU': 'Lịch sử',
    'DIA_LY': 'Địa lý',
    'GDCD': 'GDCD',
    'TIN_HOC': 'Tin học',
    'CONG_NGHE': 'Công nghệ',
}


def subject_label_vi(subject_code: str) -> str:
    norm = normalize_subject_code(subject_code)
    return _SUBJECT_LABELS_VI.get(norm, norm)


def compute_season_rank(xp: int) -> dict[str, Any]:
    clean_xp = max(0, int(xp))
    if clean_xp >= 1500:
        return {
            'seasonCode': '2026-S4',
            'tier': 'cao_thu',
            'labelVi': 'Học Bá · Cao thủ',
            'frameColor': '#8C3B68',
            'minXp': 1500,
            'nextMinXp': None,
        }
    if clean_xp >= 700:
        return {
            'seasonCode': '2026-S4',
            'tier': 'bach_kim',
            'labelVi': 'Bạch Kim · Tinh anh',
            'frameColor': '#126F73',
            'minXp': 700,
            'nextMinXp': 1500,
        }
    if clean_xp >= 300:
        return {
            'seasonCode': '2026-S4',
            'tier': 'vang',
            'labelVi': 'Vàng · Bình minh',
            'frameColor': '#D9932B',
            'minXp': 300,
            'nextMinXp': 700,
        }
    if clean_xp >= 100:
        return {
            'seasonCode': '2026-S4',
            'tier': 'bac',
            'labelVi': 'Bạc · Kiên trì',
            'frameColor': '#6E7F91',
            'minXp': 100,
            'nextMinXp': 300,
        }
    return {
        'seasonCode': '2026-S4',
        'tier': 'dong',
        'labelVi': 'Đồng · Khởi hành',
        'frameColor': '#A67C52',
        'minXp': 0,
        'nextMinXp': 100,
    }


def _aware_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _early_bird_days_last_7(
    db: Session,
    *,
    user: User,
    now_utc: datetime,
) -> int:
    zone = resolve_zone(user.time_zone)
    today_local = now_utc.astimezone(zone).date()
    window_dates = {(today_local - timedelta(days=i)).isoformat() for i in range(7)}

    completed_dates = set(
        db.scalars(
            select(AlarmSession.local_date).where(
                AlarmSession.user_id == user.id,
                AlarmSession.state == 'completed',
                AlarmSession.local_date.in_(window_dates),
            )
        ).all()
    )
    report_morning_dates = set(
        db.scalars(
            select(DailyReport.local_date).where(
                DailyReport.user_id == user.id,
                DailyReport.challenge_completed.is_(True),
                DailyReport.local_date.in_(window_dates),
            )
        ).all()
    )
    return min(7, len(completed_dates | report_morning_dates))


def _equipped_title_vi(
    *,
    early_bird_days: int,
    streak: int,
    top_subject: dict[str, Any] | None,
) -> str:
    if early_bird_days >= 5:
        return 'Chiến thần Bình minh tuần'
    if streak >= 7:
        return 'Bền bỉ chuỗi tuần'
    if (
        top_subject is not None
        and top_subject.get('attemptsCount', 0) >= 3
        and top_subject.get('accuracyPct', 0) >= 80
    ):
        return f"Học bá {top_subject['subjectNameVi']}"
    if early_bird_days >= 2:
        return 'Dậy sớm chủ động'
    return 'Bạn đồng hành MindClock'


def _top_subject_from_memories(
    user: User,
    memories: list[SubjectMemory],
) -> dict[str, Any]:
    if memories:
        best = sorted(
            memories,
            key=lambda m: (
                -int(m.correct_count or 0),
                -int(m.mastery_score or 0),
                -int(m.attempts_count or 0),
                m.subject_code,
            ),
        )[0]
        attempts = int(best.attempts_count or 0)
        correct = int(best.correct_count or 0)
        accuracy = round((correct * 100) / attempts) if attempts > 0 else 0
        return {
            'subjectCode': best.subject_code,
            'subjectNameVi': subject_label_vi(best.subject_code),
            'masteryScore': int(best.mastery_score or 50),
            'attemptsCount': attempts,
            'correctCount': correct,
            'accuracyPct': accuracy,
            'currentWeek': int(best.current_week or 12),
            'currentChapter': best.current_chapter or '',
        }

    raw_subjects = list(user.selected_subjects_json or [])
    fallback_code = normalize_subject_code(raw_subjects[0] if raw_subjects else 'TOAN')
    return {
        'subjectCode': fallback_code,
        'subjectNameVi': subject_label_vi(fallback_code),
        'masteryScore': 50,
        'attemptsCount': 0,
        'correctCount': 0,
        'accuracyPct': 0,
        'currentWeek': 12,
        'currentChapter': '',
    }


def is_user_opted_in_leaderboard(db: Session, user_id: str) -> bool:
    latest = db.scalar(
        select(ConsentEvent)
        .where(
            ConsentEvent.user_id == user_id,
            ConsentEvent.scope == LEADERBOARD_OPT_IN_SCOPE,
        )
        .order_by(ConsentEvent.occurred_at.desc())
        .limit(1)
    )
    return bool(latest.granted) if latest is not None else False


def build_profile_showcase(db: Session, user: User) -> dict[str, Any]:
    now_utc = datetime.now(timezone.utc)
    meta = db.get(UserCommunityProfile, user.id)
    avatar_id = (meta.avatar_id if meta else None) or 'avatar_sunrise'

    total_xp = int(
        db.scalar(
            select(func.coalesce(func.sum(XpLedger.delta), 0)).where(
                XpLedger.user_id == user.id
            )
        )
        or 0
    )
    xp_rows = db.execute(
        select(XpLedger.created_at, XpLedger.reason, XpLedger.delta).where(
            XpLedger.user_id == user.id,
            XpLedger.reason.in_(tuple(STREAK_XP_REASONS)),
            XpLedger.delta > 0,
        )
    ).all()
    report_dates = list(
        db.scalars(select(DailyReport.local_date).where(DailyReport.user_id == user.id))
    )
    streak_data = build_streak_snapshot(
        xp_events=[(row[0], row[1], int(row[2] or 0)) for row in xp_rows],
        report_dates=report_dates,
        time_zone=user.time_zone,
        now=now_utc,
    )
    streak = int(streak_data['streak'])
    best_streak = int(streak_data['bestStreak'])

    memories = list(
        db.scalars(select(SubjectMemory).where(SubjectMemory.user_id == user.id))
    )
    top_subject = _top_subject_from_memories(user, memories)
    early_bird_days = _early_bird_days_last_7(db, user=user, now_utc=now_utc)
    season_rank = compute_season_rank(total_xp)
    equipped_title = _equipped_title_vi(
        early_bird_days=early_bird_days,
        streak=streak,
        top_subject=top_subject,
    )
    groups_hub = CommitmentGroupService(db).hub(user.id)
    groups = list(groups_hub.get('groups') or [])

    stamps = [
        {
            'id': 'streak',
            'titleVi': 'Chuỗi bền bỉ',
            'valueVi': f'{streak} ngày',
            'subtitleVi': f'Kỷ lục {best_streak} ngày',
            'kind': 'flame',
        },
        {
            'id': 'early_bird',
            'titleVi': 'Dậy sớm tuần',
            'valueVi': f'{early_bird_days}/7 ngày',
            'subtitleVi': 'Hoàn thành thử thách sáng',
            'kind': 'sunrise',
        },
        {
            'id': 'top_subject',
            'titleVi': 'Sở trường',
            'valueVi': top_subject['subjectNameVi'],
            'subtitleVi': f"{top_subject['masteryScore']}% · Tuần {top_subject['currentWeek']}",
            'kind': 'book',
        },
    ]

    return {
        'userId': user.id,
        'alias': user.alias,
        'avatarId': avatar_id,
        'gradeLevel': user.grade_band,
        'selectedSubjects': list(user.selected_subjects_json or []),
        'goalLabel': user.goal_label,
        'xp': total_xp,
        'streak': streak,
        'bestStreak': best_streak,
        **progress_level(total_xp),
        'seasonRank': season_rank,
        'equippedTitleVi': equipped_title,
        'earlyBirdDaysThisWeek': early_bird_days,
        'topSubject': top_subject,
        'stamps': stamps,
        'groups': groups,
        'leaderboardOptIn': is_user_opted_in_leaderboard(db, user.id),
    }


def build_weekly_subject_leaderboard(
    db: Session,
    *,
    viewer: User,
    subject_code: str,
    limit: int = 20,
) -> dict[str, Any]:
    norm_subject = normalize_subject_code(subject_code)
    now_utc = datetime.now(timezone.utc)
    week_ago = now_utc - timedelta(days=7)

    # Lấy consent mới nhất theo từng user đối với LEADERBOARD_OPT_IN_SCOPE.
    consent_rows = list(
        db.scalars(
            select(ConsentEvent)
            .where(ConsentEvent.scope == LEADERBOARD_OPT_IN_SCOPE)
            .order_by(ConsentEvent.occurred_at.desc())
        )
    )
    opt_in_by_user: dict[str, bool] = {}
    for row in consent_rows:
        if row.user_id not in opt_in_by_user:
            opt_in_by_user[row.user_id] = bool(row.granted)

    opted_in_ids = [uid for uid, granted in opt_in_by_user.items() if granted]
    viewer_opted_in = opt_in_by_user.get(viewer.id, False)

    if not opted_in_ids:
        return {
            'subjectCode': norm_subject,
            'subjectNameVi': subject_label_vi(norm_subject),
            'weekWindowVi': '7 ngày gần nhất',
            'currentUserOptedIn': viewer_opted_in,
            'entries': [],
        }

    users = {
        u.id: u
        for u in db.scalars(select(User).where(User.id.in_(opted_in_ids))).all()
    }
    metas = {
        m.user_id: m
        for m in db.scalars(
            select(UserCommunityProfile).where(
                UserCommunityProfile.user_id.in_(opted_in_ids)
            )
        ).all()
    }
    subject_memories = {
        m.user_id: m
        for m in db.scalars(
            select(SubjectMemory).where(
                SubjectMemory.user_id.in_(opted_in_ids),
                SubjectMemory.subject_code == norm_subject,
            )
        ).all()
    }

    total_xp_rows = db.execute(
        select(XpLedger.user_id, func.coalesce(func.sum(XpLedger.delta), 0))
        .where(XpLedger.user_id.in_(opted_in_ids))
        .group_by(XpLedger.user_id)
    ).all()
    total_xp_map = {uid: int(total or 0) for uid, total in total_xp_rows}

    weekly_xp_rows = db.execute(
        select(XpLedger.user_id, XpLedger.delta, XpLedger.created_at).where(
            XpLedger.user_id.in_(opted_in_ids)
        )
    ).all()
    weekly_xp_map: dict[str, int] = {}
    for uid, delta, created_at in weekly_xp_rows:
        if created_at is not None and _aware_utc(created_at) >= week_ago:
            weekly_xp_map[uid] = weekly_xp_map.get(uid, 0) + int(delta or 0)

    ranked_rows: list[dict[str, Any]] = []
    for uid in opted_in_ids:
        u = users.get(uid)
        if u is None:
            continue
        selected = [normalize_subject_code(s) for s in (u.selected_subjects_json or [])]
        mem = subject_memories.get(uid)
        if mem is None and norm_subject not in selected:
            continue

        attempts = int(mem.attempts_count or 0) if mem else 0
        correct = int(mem.correct_count or 0) if mem else 0
        mastery = int(mem.mastery_score or 50) if mem else 50
        accuracy = round((correct * 100) / attempts) if attempts > 0 else 0
        weekly_xp = weekly_xp_map.get(uid, 0)
        early_days = _early_bird_days_last_7(db, user=u, now_utc=now_utc)
        weekly_score = weekly_xp + (correct * 15) + (mastery // 2) + (early_days * 5)
        season_rank = compute_season_rank(total_xp_map.get(uid, 0))
        meta = metas.get(uid)
        avatar_id = (meta.avatar_id if meta else None) or 'avatar_sunrise'
        title_vi = _equipped_title_vi(
            early_bird_days=early_days,
            streak=early_days,
            top_subject={
                'subjectNameVi': subject_label_vi(norm_subject),
                'attemptsCount': attempts,
                'accuracyPct': accuracy,
            },
        )
        ranked_rows.append({
            'userId': u.id,
            'alias': u.alias,
            'avatarId': avatar_id,
            'gradeLevel': u.grade_band,
            'seasonRank': season_rank,
            'equippedTitleVi': title_vi,
            'subjectCode': norm_subject,
            'subjectNameVi': subject_label_vi(norm_subject),
            'weeklyScore': weekly_score,
            'accuracyPct': accuracy,
            'attemptsCount': attempts,
            'earlyBirdDaysThisWeek': early_days,
            'isCurrentUser': u.id == viewer.id,
        })

    ranked_rows.sort(
        key=lambda item: (
            -int(item['weeklyScore']),
            -int(item['accuracyPct']),
            -int(item['earlyBirdDaysThisWeek']),
            str(item['alias']).lower(),
        )
    )
    limited = ranked_rows[: max(1, min(limit, 50))]
    for idx, entry in enumerate(limited, start=1):
        entry['rank'] = idx

    return {
        'subjectCode': norm_subject,
        'subjectNameVi': subject_label_vi(norm_subject),
        'weekWindowVi': '7 ngày gần nhất',
        'currentUserOptedIn': viewer_opted_in,
        'entries': limited,
    }
