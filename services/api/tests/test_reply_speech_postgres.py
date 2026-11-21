from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from datetime import datetime, timezone
import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select, func
from sqlalchemy.orm import Session
from app.config import Settings
from app.db.models import IdempotencyRecord
from app.main import create_app
from app.services.gemini_service import GeminiServiceError
from app.services.speech_service import reserve_speech, SPEECH_ROUTE
from tests.test_progression_postgres import isolated_pg  # noqa: F401


def test_speech_last_quota_slot_is_atomic(isolated_pg):
    from alembic import command
    from alembic.config import Config
    cfg = Config('alembic.ini')
    cfg.attributes['sqlalchemy.url'] = isolated_pg
    command.upgrade(cfg, 'head')
    app = create_app(Settings(_env_file=None, app_env='test', database_url=isolated_pg,
        gemini_mock_mode=True, local_dev_bearer_uid_fallback=True))
    headers = {'Authorization': 'Bearer dev:voice_pg', 'Idempotency-Key': str(uuid.uuid4())}
    with TestClient(app) as client:
        uid = client.get('/v1/me', headers=headers).json()['id']
        sid = client.post('/v1/study/sessions', headers=headers,
            json={'clientSessionId': 'voice_pg_session', 'taskTitle': 'Ôn tập'}).json()['sessionId']
        engine = create_engine(isolated_pg)
        now = datetime.now(timezone.utc)
        with Session(engine) as db:
            for _ in range(4):
                db.add(IdempotencyRecord(user_id=uid, route=SPEECH_ROUTE, key=str(uuid.uuid4()),
                    payload_hash='speech-reservation-v1', response_json={'reserved': True}, created_at=now))
            db.commit()
        barrier = Barrier(2)
        def reserve(_):
            with Session(engine) as db:
                barrier.wait(timeout=10)
                try:
                    reserve_speech(db, user_id=uid, session_id=sid, key=str(uuid.uuid4()), consent=True, now=now)
                    return 200
                except GeminiServiceError as error:
                    db.rollback()
                    return error.status_code
        try:
            with ThreadPoolExecutor(max_workers=2) as pool:
                assert sorted(pool.map(reserve, range(2))) == [200, 429]
            with Session(engine) as db:
                assert db.scalar(select(func.count(IdempotencyRecord.id)).where(
                    IdempotencyRecord.route == SPEECH_ROUTE)) == 5
        finally:
            engine.dispose()
