from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.config import Settings
from app.main import create_app
from app.services.commitment_group_service import CommitmentGroupService


def _settings(tmp_path: Path) -> Settings:
    db_file = tmp_path / 't084_busy_days.db'
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('AQ.TEST_FAKE_KEY'),
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_t084_group_busy_day_preserves_streak_and_enforces_monthly_quota(tmp_path: Path) -> None:
    cfg = _settings(tmp_path)
    app = create_app(cfg)
    with TestClient(app) as client:
        u1 = client.get('/v1/me', headers=_h('busy_a')).json()['id']
        u2 = client.get('/v1/me', headers=_h('busy_b')).json()['id']

        req = client.post(
            '/v1/friends/request',
            headers=_h('busy_a'),
            json={'receiverUserId': u2},
        )
        assert req.status_code == 201
        client.post(
            f"/v1/friends/requests/{req.json()['requestId']}/respond",
            headers=_h('busy_b'),
            json={'decision': 'accept'},
        )

        grp = client.post(
            '/v1/commitment-groups',
            headers=_h('busy_a'),
            json={'name': 'Nhom 2 ban', 'petName': 'Mam'},
        )
        assert grp.status_code == 201
        gid = grp.json()['groupId']

        inv = client.post(
            f'/v1/commitment-groups/{gid}/invites',
            headers=_h('busy_a'),
            json={'recipientUserId': u2},
        )
        client.post(
            f"/v1/commitment-group-invites/{inv.json()['inviteId']}/respond",
            headers=_h('busy_b'),
            json={'decision': 'accept'},
        )

        vn_now = datetime.now(timezone.utc).astimezone(ZoneInfo('Asia/Ho_Chi_Minh'))
        d_minus_2 = vn_now - timedelta(days=2)
        d_minus_1 = vn_now - timedelta(days=1)
        d_today = vn_now

        engine = create_engine(cfg.database_url)
        try:
            with Session(engine) as db:
                svc = CommitmentGroupService(db)
                svc.record_daily_report(u1, 'r_m2_a', at=d_minus_2)
                svc.record_daily_report(u2, 'r_m2_b', at=d_minus_2)
                svc.report_busy_today(u2, gid, reason='exam', local_date=d_minus_1.date().isoformat())
                svc.record_daily_report(u1, 'r_m1_a', at=d_minus_1)
                db.commit()

            hub_before = client.get('/v1/commitment-groups/me', headers=_h('busy_a')).json()
            assert hub_before['groups'][0]['pet']['currentStreakDays'] == 1
            assert hub_before['groups'][0]['pet']['streakMilestoneLabelVi'] == 'Chuỗi 1'

            with Session(engine) as db:
                svc = CommitmentGroupService(db)
                svc.record_daily_report(u1, 'r_0_a', at=d_today)
                svc.record_daily_report(u2, 'r_0_b', at=d_today)
                db.commit()

            hub_after = client.get('/v1/commitment-groups/me', headers=_h('busy_a')).json()
            assert hub_after['groups'][0]['pet']['currentStreakDays'] == 2
            assert hub_after['groups'][0]['pet']['streakMilestoneLabelVi'] == 'Chuỗi 2'
        finally:
            engine.dispose()

        today_str = d_today.date().isoformat()
        busy1 = client.post(
            f'/v1/commitment-groups/{gid}/busy-today',
            headers=_h('busy_b'),
            json={'reason': 'family', 'localDate': today_str},
        )
        assert busy1.status_code == 200
        assert busy1.json()['pet']['busyTodayByMe'] is True

        same_month_day = f'{today_str[:7]}-10'
        same_month_day2 = f'{today_str[:7]}-11'
        client.post(
            f'/v1/commitment-groups/{gid}/busy-today',
            headers=_h('busy_b'),
            json={'reason': 'sick', 'localDate': same_month_day},
        )
        busy_overflow = client.post(
            f'/v1/commitment-groups/{gid}/busy-today',
            headers=_h('busy_b'),
            json={'reason': 'exam', 'localDate': same_month_day2},
        )
        assert busy_overflow.status_code == 409
        assert busy_overflow.json()['error']['code'] == 'BUSY_QUOTA_EXCEEDED'
