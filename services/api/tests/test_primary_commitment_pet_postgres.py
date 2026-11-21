from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.models import CommitmentGroupMember
from app.main import create_app
from app.services.commitment_group_service import CommitmentGroupService
from tests.test_progression_postgres import isolated_pg  # noqa: F401


def test_competing_primary_selection_keeps_one_row(isolated_pg):
    cfg = Config('alembic.ini')
    cfg.attributes['sqlalchemy.url'] = isolated_pg
    command.upgrade(cfg, 'head')
    app = create_app(Settings(
        _env_file=None,
        app_env='test',
        database_url=isolated_pg,
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    ))
    headers = {'Authorization': 'Bearer dev:primary_pg'}
    with TestClient(app) as client:
        user_id = client.get('/v1/me', headers=headers).json()['id']
        group_ids = [
            client.post('/v1/commitment-groups', headers=headers,
                        json={'name': f'Nhóm {index}'}).json()['groupId']
            for index in range(2)
        ]

    barrier = Barrier(2)
    engine = create_engine(isolated_pg)

    def select_primary(group_id: str) -> None:
        with Session(engine) as db:
            barrier.wait(timeout=10)
            CommitmentGroupService(db).set_primary(user_id, group_id)

    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(select_primary, group_ids))
        with Session(engine) as db:
            count = db.scalar(select(func.count()).select_from(
                CommitmentGroupMember
            ).where(
                CommitmentGroupMember.user_id == user_id,
                CommitmentGroupMember.status == 'active',
                CommitmentGroupMember.is_primary.is_(True),
            ))
            assert count == 1
    finally:
        engine.dispose()
