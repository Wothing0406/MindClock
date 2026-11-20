"""Opt-in PostgreSQL contract in a disposable database, never the app database."""
import os
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.models import XpLedger
from app.main import create_app


@pytest.fixture
def isolated_pg():
    admin_url = os.environ.get('MINDCLOCK_TEST_POSTGRES_ADMIN_URL')
    if not admin_url:
        pytest.skip('Set MINDCLOCK_TEST_POSTGRES_ADMIN_URL for disposable PostgreSQL test')
    import psycopg
    from psycopg import sql
    url = make_url(admin_url).set(drivername='postgresql')
    name = 'mindclock_test_progress_' + uuid.uuid4().hex
    admin = psycopg.connect(url.render_as_string(hide_password=False), autocommit=True)
    try:
        admin.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(name)))
        yield url.set(drivername='postgresql+psycopg', database=name).render_as_string(hide_password=False)
    finally:
        # Only the randomly named database created by this fixture can be dropped.
        admin.execute(sql.SQL('DROP DATABASE IF EXISTS {} WITH (FORCE)').format(sql.Identifier(name)))
        admin.close()


def test_postgres_progress_history_and_unique_ledger(isolated_pg):
    from alembic import command
    from alembic.config import Config
    cfg = Config('alembic.ini')
    # Explicit override avoids cached app settings selecting a development DB.
    cfg.attributes['sqlalchemy.url'] = isolated_pg
    command.upgrade(cfg, 'head')
    settings = Settings(_env_file=None, app_env='test', database_url=isolated_pg,
        gemini_mock_mode=True, local_dev_bearer_uid_fallback=True)
    app = create_app(settings)
    headers = lambda user: {'Authorization': f'Bearer dev:{user}'}
    with TestClient(app) as first, TestClient(app) as second:
        a = first.get('/v1/me', headers=headers('pg_a')).json()['id']
        second.get('/v1/me', headers=headers('pg_b'))
        now = datetime.now(timezone.utc)
        engine = create_engine(isolated_pg)
        try:
            with Session(engine) as db:
                for index in range(3):
                    db.add(XpLedger(user_id=a, source_type='alarm_session',
                        source_id=f's{index}', reason='challenge_correct', delta=50,
                        created_at=now - timedelta(days=index)))
                db.commit()
                db.add(XpLedger(user_id=a, source_type='alarm_session', source_id='s0',
                    reason='challenge_correct', delta=50))
                with pytest.raises(IntegrityError):
                    db.commit()
                db.rollback()
            summary = first.get('/v1/progress/summary', headers=headers('pg_a')).json()
            assert summary['xp'] == 150
            assert summary['level'] == 2
            assert summary['streak'] == 3
            # A second independent client sees the same authoritative state.
            assert second.get('/v1/progress/summary', headers=headers('pg_a')).json() == summary
            assert second.get('/v1/progress/summary', headers=headers('pg_b')).json()['xp'] == 0
            history = first.get('/v1/progress/xp-history?limit=2', headers=headers('pg_a')).json()
            assert len(history['items']) == 2
            assert history['nextOffset'] == 2
            assert len(second.get('/v1/progress/xp-history?offset=2', headers=headers('pg_a')).json()['items']) == 1
            assert second.get('/v1/progress/xp-history', headers=headers('pg_b')).json()['items'] == []
            assert first.get('/v1/progress/xp-history?limit=101', headers=headers('pg_a')).status_code == 422
        finally:
            engine.dispose()
