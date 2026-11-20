from datetime import datetime, timedelta, timezone

from app.services.progression import progress_level, review_streak


def test_level_boundaries():
    assert [progress_level(x)['level'] for x in [0, 99, 100, 399, 400]] == [1, 1, 2, 2, 3]
    assert progress_level(400)['xpToNextLevel'] == 500


def test_review_days_deduplicate_and_expire():
    now = datetime(2026, 11, 20, 12, tzinfo=timezone.utc)
    assert review_streak([now, now, now - timedelta(days=1)], 'Asia/Ho_Chi_Minh', now) == 2
    assert review_streak([now - timedelta(days=1)], 'Asia/Ho_Chi_Minh', now) == 1
    assert review_streak([now - timedelta(days=2)], 'Asia/Ho_Chi_Minh', now) == 0
    assert review_streak([now + timedelta(days=1)], 'Asia/Ho_Chi_Minh', now) == 0


def test_timezone_and_sqlite_naive_utc():
    now = datetime(2026, 11, 20, 18, tzinfo=timezone.utc)
    # Local Nov 21 01:00; two UTC timestamps are on consecutive local dates.
    events = [datetime(2026, 11, 20, 17, 30), datetime(2026, 11, 20, 10)]
    assert review_streak(events, 'Asia/Ho_Chi_Minh', now) == 2


def test_history_and_summary_owner_scope(tmp_path):
    from fastapi.testclient import TestClient
    from sqlalchemy.orm import Session
    from app.db.models import XpLedger
    from app.main import create_app
    from app.config import Settings
    def _make_settings(path, mock_mode=True):
        return Settings(app_env='test', database_url=f'sqlite+pysqlite:///{(path / "progress.db").as_posix()}',
            gemini_mock_mode=mock_mode, local_dev_bearer_uid_fallback=True)
    def _headers(uid):
        return {'Authorization': f'Bearer dev:{uid}'}

    app = create_app(_make_settings(tmp_path, mock_mode=True))
    with TestClient(app) as client:
        a = client.get('/v1/me', headers=_headers('progress_a')).json()['id']
        client.get('/v1/me', headers=_headers('progress_b'))
        from sqlalchemy import create_engine
        engine = create_engine(_make_settings(tmp_path).database_url)
        with Session(engine) as db:
            for index in range(2):
                db.add(XpLedger(user_id=a, source_type='alarm_session', source_id=f's{index}',
                    reason='challenge_correct', delta=50))
            db.commit()
        engine.dispose()
        assert client.get('/v1/progress/xp-history').status_code == 401
        first = client.get('/v1/progress/xp-history?limit=1', headers=_headers('progress_a')).json()
        second = client.get('/v1/progress/xp-history?limit=1&offset=1', headers=_headers('progress_a')).json()
        assert first['nextOffset'] == 1
        assert second['nextOffset'] is None
        assert first['items'][0]['id'] != second['items'][0]['id']
        assert client.get('/v1/progress/xp-history', headers=_headers('progress_b')).json()['items'] == []
        summary = client.get('/v1/progress/summary', headers=_headers('progress_a')).json()
        assert summary['xp'] == 100
        assert summary['level'] == 2
        assert summary['streak'] == 1
        assert client.get('/v1/progress/summary', headers=_headers('progress_b')).json()['xp'] == 0
