"""Read-only projections from authoritative reward events & daily reports (progress-v1 / streak-v2)."""
from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from math import isqrt
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

STREAK_XP_REASONS = frozenset({
    'challenge_correct',
    'photo_challenge_correct',
    'study_time_v0_1',
    'daily_report',
})
DAILY_REPORT_XP = 5

_WEEKDAY_VI = ('T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN')


def resolve_zone(time_zone: str | None) -> ZoneInfo | timezone:
    clean = (time_zone or 'Asia/Ho_Chi_Minh').strip() or 'Asia/Ho_Chi_Minh'
    try:
        return ZoneInfo(clean)
    except ZoneInfoNotFoundError:
        if clean == 'Asia/Ho_Chi_Minh':
            return timezone(timedelta(hours=7))
        return timezone.utc


def _aware_utc(value: datetime) -> datetime:
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def progress_level(xp: int) -> dict[str, Any]:
    xp = max(0, xp)
    level = 1 + isqrt(xp // 100)
    floor = 100 * (level - 1) ** 2
    ceiling = 100 * level ** 2
    return {
        'level': level,
        'levelStartXp': floor,
        'nextLevelXp': ceiling,
        'xpIntoLevel': xp - floor,
        'xpToNextLevel': ceiling - xp,
        'progressVersion': 'progress-v1',
    }


def review_streak(events: list[datetime], time_zone: str, now: datetime) -> int:
    zone = resolve_zone(time_zone)
    today = _aware_utc(now).astimezone(zone).date()
    days = {
        _aware_utc(event).astimezone(zone).date()
        for event in events if _aware_utc(event) <= _aware_utc(now)
    }
    cursor = today if today in days else today - timedelta(days=1)
    count = 0
    while cursor in days:
        count += 1
        cursor -= timedelta(days=1)
    return count


def _longest_consecutive_run(days: set[date]) -> int:
    if not days:
        return 0
    best = 0
    for day in days:
        if (day - timedelta(days=1)) not in days:
            run = 1
            cursor = day + timedelta(days=1)
            while cursor in days:
                run += 1
                cursor += timedelta(days=1)
            if run > best:
                best = run
    return best


def build_streak_snapshot(
    *,
    xp_events: list[tuple[datetime, str, int]],
    report_dates: list[str],
    time_zone: str | None,
    now: datetime,
    window_days: int = 14,
) -> dict[str, Any]:
    """Build daily streak state, 14-day activity strip, and source breakdown."""
    zone = resolve_zone(time_zone)
    now_utc = _aware_utc(now)
    today = now_utc.astimezone(zone).date()

    day_sources: dict[date, set[str]] = defaultdict(set)
    day_xp: dict[date, int] = defaultdict(int)

    for created_at, reason, delta in xp_events:
        if delta <= 0 or reason not in STREAK_XP_REASONS:
            continue
        event_utc = _aware_utc(created_at)
        if event_utc > now_utc:
            continue
        local_day = event_utc.astimezone(zone).date()
        if reason in {'challenge_correct', 'photo_challenge_correct'}:
            day_sources[local_day].add('challenge')
        elif reason == 'study_time_v0_1':
            day_sources[local_day].add('study')
        elif reason == 'daily_report':
            day_sources[local_day].add('daily_report')
        day_xp[local_day] += int(delta)

    parsed_report_dates: set[date] = set()
    for raw_date in report_dates:
        try:
            parsed = date.fromisoformat(raw_date)
        except ValueError:
            continue
        if parsed <= today:
            parsed_report_dates.add(parsed)
            day_sources[parsed].add('daily_report')

    active_days = {day for day, sources in day_sources.items() if sources}
    cursor = today if today in active_days else today - timedelta(days=1)
    current_streak = 0
    while cursor in active_days:
        current_streak += 1
        cursor -= timedelta(days=1)

    best_streak = _longest_consecutive_run(active_days)
    recent_days: list[dict[str, Any]] = []
    for offset in range(window_days - 1, -1, -1):
        d = today - timedelta(days=offset)
        sources = day_sources.get(d, set())
        recent_days.append({
            'date': d.isoformat(),
            'weekdayLabel': _WEEKDAY_VI[d.weekday()],
            'isToday': d == today,
            'completed': bool(sources),
            'hasDailyReport': 'daily_report' in sources or d in parsed_report_dates,
            'hasStudy': 'study' in sources,
            'hasChallenge': 'challenge' in sources,
            'xpEarned': day_xp.get(d, 0),
        })

    return {
        'streak': current_streak,
        'bestStreak': best_streak,
        'totalActiveDays': len(active_days),
        'todayCompleted': today in active_days,
        'todayReportSubmitted': today in parsed_report_dates,
        'todaySources': sorted(day_sources.get(today, set())),
        'recentDays': recent_days,
        'streakPolicyVersion': 'streak-v2',
    }
