from datetime import datetime, timedelta, timezone
from pathlib import Path

from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.models import DailyReport, XpLedger
from app.main import create_app


def _settings(tmp_path: Path) -> Settings:
    db_file = tmp_path / 'daily_report_t077.db'
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('AQ.TEST_FAKE_KEY'),
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_daily_report_creates_one_streak_day_idempotent_and_isolated(tmp_path: Path) -> None:
    cfg = _settings(tmp_path)
    with TestClient(create_app(cfg)) as client:
        # Tạo nhóm cam kết trước để kiểm tra đồng bộ Pet nhóm khi nộp báo cáo ngày.
        group = client.post(
            '/v1/commitment-groups',
            headers=_h('student_a'),
            json={'name': 'Nhóm Đỗ ĐH 12A', 'petName': 'Mầm Xanh'},
        )
        assert group.status_code == 201

        before = client.get('/v1/progress/summary', headers=_h('student_a')).json()
        assert before['streak'] == 0
        assert before['todayCompleted'] is False
        assert before['todayReportSubmitted'] is False
        assert len(before['recentDays']) == 14

        # Gửi payload sai / trường cấm bị chặn 422
        bad = client.post(
            '/v1/progress/daily-report',
            headers=_h('student_a'),
            json={'tasksCompleted': 3, 'feeling': 'focused', 'streak': 999},
        )
        assert bad.status_code == 422

        # Nộp báo cáo lần 1 -> 1 ngày streak + 5 XP + chăm Pet nhóm
        submit_1 = client.post(
            '/v1/progress/daily-report',
            headers={**_h('student_a'), 'Idempotency-Key': 'dr-idem-1'},
            json={
                'tasksCompleted': 4,
                'feeling': 'focused',
                'reflectionNote': 'Hoàn thành 2 đề Toán chương hàm số.',
            },
        )
        assert submit_1.status_code == 200
        body_1 = submit_1.json()
        assert body_1['alreadyReportedToday'] is False
        assert body_1['xpAwarded'] == 5
        assert body_1['streakAwardedToday'] is True
        assert body_1['report']['tasksCompleted'] == 4
        assert body_1['report']['feeling'] == 'focused'
        assert body_1['summary']['streak'] == 1
        assert body_1['summary']['bestStreak'] == 1
        assert body_1['summary']['totalActiveDays'] == 1
        assert body_1['summary']['todayCompleted'] is True
        assert body_1['summary']['todayReportSubmitted'] is True
        assert 'daily_report' in body_1['summary']['todaySources']
        assert body_1['summary']['xp'] == 5
        assert body_1['groupCare'][0]['recorded'] is True

        # Retry cùng Idempotency-Key trả lại đúng kết quả không cộng thêm
        replay = client.post(
            '/v1/progress/daily-report',
            headers={**_h('student_a'), 'Idempotency-Key': 'dr-idem-1'},
            json={
                'tasksCompleted': 4,
                'feeling': 'focused',
                'reflectionNote': 'Hoàn thành 2 đề Toán chương hàm số.',
            },
        )
        assert replay.status_code == 200
        assert replay.json()['xpAwarded'] == 5

        # Nộp lại lần 2 trong cùng ngày với key mới -> cập nhật ghi chú, 0 XP thêm, streak giữ nguyên = 1
        submit_2 = client.post(
            '/v1/progress/daily-report',
            headers={**_h('student_a'), 'Idempotency-Key': 'dr-idem-2'},
            json={
                'tasksCompleted': 5,
                'feeling': 'steady',
                'reflectionNote': 'Bổ sung thêm bài tập Lý.',
            },
        )
        assert submit_2.status_code == 200
        body_2 = submit_2.json()
        assert body_2['alreadyReportedToday'] is True
        assert body_2['xpAwarded'] == 0
        assert body_2['streakAwardedToday'] is False
        assert body_2['report']['tasksCompleted'] == 5
        assert body_2['report']['reflectionNote'] == 'Bổ sung thêm bài tập Lý.'
        assert body_2['summary']['streak'] == 1
        assert body_2['summary']['xp'] == 5

        # Pet nhóm nhận care từ báo cáo ngày (+10 EXP nhóm, streak 1 ngày)
        pet = client.get('/v1/commitment-groups/me', headers=_h('student_a')).json()['group']['pet']
        assert pet['currentStreakDays'] == 1
        assert pet['totalCareDays'] == 1
        assert pet['todayCareCount'] == 1
        assert pet['totalXp'] == 10

        # Kiểm tra lịch sử báo cáo ngày cô lập theo tài khoản (A/B)
        reports_a = client.get('/v1/progress/daily-reports', headers=_h('student_a')).json()['items']
        assert len(reports_a) == 1
        assert reports_a[0]['tasksCompleted'] == 5
        client.get('/v1/me', headers=_h('student_b'))
        reports_b = client.get('/v1/progress/daily-reports', headers=_h('student_b')).json()['items']
        assert reports_b == []


def test_morning_challenge_alone_feeds_group_pet_streak_and_multiday_sources(tmp_path: Path) -> None:
    cfg = _settings(tmp_path)
    with TestClient(create_app(cfg)) as client:
        client.post('/v1/commitment-groups', headers=_h('morning_only'), json={'name': 'Nhóm Dậy Sớm'})
        alarm = client.post(
            '/v1/sessions',
            headers=_h('morning_only'),
            json={
                'alarmId': 'alarm-1',
                'localSessionId': 'morning-only-1',
                'localDate': '2026-11-27',
                'timeZone': 'Asia/Ho_Chi_Minh',
                'questionId': 'math9-linear-001',
            },
        ).json()
        answered = client.post(
            f"/v1/sessions/{alarm['sessionId']}/answers",
            headers={**_h('morning_only'), 'Idempotency-Key': 'm-ans-1'},
            json={'answerValue': '8', 'reasoningText': 'Chia hai vế cho 2 rồi cộng 3.'},
        )
        assert answered.status_code == 200
        assert answered.json()['result'] == 'correct'

        # Sửa lỗi _pet_summary: chỉ riêng morning_challenge cũng tính currentStreakDays = 1
        pet = client.get('/v1/commitment-groups/me', headers=_h('morning_only')).json()['group']['pet']
        assert pet['currentStreakDays'] == 1
        assert pet['totalCareDays'] == 1
        assert pet['totalXp'] == 20

        # Kiểm tra chuỗi nhiều ngày kết hợp study_time_v0_1 + photo_challenge_correct + daily_report
        user_id = client.get('/v1/me', headers=_h('morning_only')).json()['id']
        now_utc = datetime.now(timezone.utc)
        engine = create_engine(cfg.database_url)
        try:
            with Session(engine) as db:
                db.add(XpLedger(
                    user_id=user_id,
                    source_type='study_session',
                    source_id='st_prev_1',
                    reason='study_time_v0_1',
                    delta=6,
                    created_at=now_utc - timedelta(days=1),
                ))
                db.add(XpLedger(
                    user_id=user_id,
                    source_type='alarm_session',
                    source_id='photo_prev_2',
                    reason='photo_challenge_correct',
                    delta=10,
                    created_at=now_utc - timedelta(days=2),
                ))
                # Cùng ngày hôm qua thêm 1 daily_report -> vẫn chỉ tính 1 ngày, tổng chuỗi = 3
                yesterday_vn = (now_utc - timedelta(days=1)).astimezone(timezone(timedelta(hours=7))).date().isoformat()
                db.add(DailyReport(
                    user_id=user_id,
                    local_date=yesterday_vn,
                    study_minutes=30,
                    tasks_completed=2,
                    challenge_completed=False,
                    feeling='steady',
                    reflection_note='Ôn đều.',
                    xp_awarded=5,
                    created_at=now_utc - timedelta(days=1),
                ))
                db.commit()
        finally:
            engine.dispose()

        summary = client.get('/v1/progress/summary', headers=_h('morning_only')).json()
        assert summary['streak'] == 3
        assert summary['bestStreak'] == 3
        assert summary['totalActiveDays'] == 3
        assert summary['todayCompleted'] is True
        assert 'challenge' in summary['todaySources']
