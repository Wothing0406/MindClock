from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.config import Settings
from app.main import create_app
from app.services.commitment_group_service import (
    CommitmentGroupError,
    CommitmentGroupService,
)
from tests.test_progression_postgres import isolated_pg  # noqa: F401


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_competing_third_membership_is_atomic(isolated_pg):
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
    pending: list[tuple[str, str, str]] = []
    with TestClient(app) as client:
        candidate_id = client.get('/v1/me', headers=_h('candidate')).json()['id']
        for index in range(4):
            host = f'host_{index}'
            host_id = client.get('/v1/me', headers=_h(host)).json()['id']
            group = client.post(
                '/v1/commitment-groups', headers=_h(host),
                json={'name': f'Nhóm {index + 1}'},
            ).json()
            request = client.post(
                '/v1/commitment-group-join-requests', headers=_h('candidate'),
                json={'groupCode': group['groupCode']},
            ).json()
            if index < 2:
                assert client.post(
                    f"/v1/commitment-groups/{group['groupId']}/join-requests/{request['requestId']}/respond",
                    headers=_h(host), json={'decision': 'accept'},
                ).status_code == 200
            else:
                pending.append((host_id, group['groupId'], request['requestId']))

    barrier = Barrier(2)
    engine = create_engine(isolated_pg)

    def approve(item: tuple[str, str, str]) -> int:
        owner_id, group_id, request_id = item
        with Session(engine) as db:
            barrier.wait(timeout=10)
            try:
                CommitmentGroupService(db).respond_join_request(
                    owner_id, group_id, request_id, 'accept'
                )
                return 200
            except CommitmentGroupError as error:
                db.rollback()
                return error.status_code

    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(approve, pending))
        assert sorted(results) == [200, 409]
        with Session(engine) as db:
            assert len(CommitmentGroupService(db)._active_memberships(candidate_id)) == 3
    finally:
        engine.dispose()
