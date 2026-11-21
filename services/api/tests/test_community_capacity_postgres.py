from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

from fastapi.testclient import TestClient
from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.models import StudyRoom, StudyRoomMember
from app.main import create_app
from app.services.community_service import CommunityService, CommunityServiceError
from tests.test_progression_postgres import isolated_pg  # noqa: F401


def test_competing_last_seat_is_atomic(isolated_pg):
    from alembic import command
    from alembic.config import Config
    cfg = Config('alembic.ini')
    cfg.attributes['sqlalchemy.url'] = isolated_pg
    command.upgrade(cfg, 'head')
    app = create_app(Settings(_env_file=None, app_env='test', database_url=isolated_pg,
        gemini_mock_mode=True, local_dev_bearer_uid_fallback=True))
    headers = lambda user: {'Authorization': f'Bearer dev:{user}'}
    with TestClient(app) as client:
        ids = [client.get('/v1/me', headers=headers(user)).json()['id']
            for user in ['host', 'one', 'two']]
        room = client.post('/v1/study-rooms', headers=headers('host'),
            json={'title': 'Hai chỗ', 'maxMembers': 2}).json()
        barrier = Barrier(2)
        engine = create_engine(isolated_pg)
        def join(uid):
            with Session(engine) as db:
                barrier.wait(timeout=10)
                try:
                    detail = CommunityService(db).join_room(uid, room['roomId'])
                    return (200, uid, len(detail['members']))
                except CommunityServiceError as error:
                    db.rollback()
                    return (error.status_code, uid, error.code)
        try:
            with ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(join, ids[1:]))
            assert sorted(result[0] for result in results) == [200, 409]
            winner = next(result[1] for result in results if result[0] == 200)
            loser = next(result[1] for result in results if result[0] == 409)
            with Session(engine) as db:
                service = CommunityService(db)
                assert len(service.join_room(winner, room['roomId'])['members']) == 2
                assert db.scalar(select(func.count()).select_from(StudyRoomMember).where(
                    StudyRoomMember.room_id == room['roomId'], StudyRoomMember.left_at.is_(None))) == 2
                service.leave_room(winner, room['roomId'])
                assert len(service.join_room(loser, room['roomId'])['members']) == 2
                service.leave_room(ids[0], room['roomId'])
                try:
                    service.join_room(winner, room['roomId'])
                    assert False, 'Closed room must reject join'
                except CommunityServiceError as error:
                    assert error.code == 'ROOM_NOT_FOUND'
        finally:
            engine.dispose()


def test_shrink_capacity_and_join_share_one_lock(isolated_pg):
    from alembic import command
    from alembic.config import Config
    cfg = Config('alembic.ini')
    cfg.attributes['sqlalchemy.url'] = isolated_pg
    command.upgrade(cfg, 'head')
    app = create_app(Settings(_env_file=None, app_env='test', database_url=isolated_pg,
        gemini_mock_mode=True, local_dev_bearer_uid_fallback=True))
    headers = lambda user: {'Authorization': f'Bearer dev:{user}'}
    with TestClient(app) as client:
        ids = [client.get('/v1/me', headers=headers(user)).json()['id'] for user in ['host', 'one', 'two']]
        room = client.post('/v1/study-rooms', headers=headers('host'), json={'title': 'Nhóm ôn', 'maxMembers': 4}).json()
        rid = room['roomId']
        client.post(f'/v1/study-rooms/{rid}/join', headers=headers('one'), json={})
        barrier = Barrier(2)
        engine = create_engine(isolated_pg)
        def act(operation):
            with Session(engine) as db:
                barrier.wait(timeout=10)
                try:
                    service = CommunityService(db)
                    if operation == 'shrink':
                        service.update_room_settings(ids[0], rid, max_members=2)
                    else:
                        service.join_room(ids[2], rid)
                    return 200
                except CommunityServiceError as error:
                    db.rollback()
                    return error.status_code
        try:
            with ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(act, ['shrink', 'join']))
            assert sorted(results) == [200, 409]
            with Session(engine) as db:
                result = CommunityService(db).get_room_detail(ids[0], rid)
                assert len(result['members']) <= result['maxMembers']
        finally:
            engine.dispose()


def test_delete_room_cascades_members_on_postgres(isolated_pg):
    from alembic import command
    from alembic.config import Config
    cfg = Config('alembic.ini')
    cfg.attributes['sqlalchemy.url'] = isolated_pg
    command.upgrade(cfg, 'head')
    app = create_app(Settings(_env_file=None, app_env='test', database_url=isolated_pg,
        gemini_mock_mode=True, local_dev_bearer_uid_fallback=True))
    headers = lambda user: {'Authorization': f'Bearer dev:{user}'}
    engine = create_engine(isolated_pg)
    try:
        with TestClient(app) as client:
            host_id = client.get('/v1/me', headers=headers('cascade_host')).json()['id']
            client.get('/v1/me', headers=headers('cascade_member'))
            room = client.post('/v1/study-rooms', headers=headers('cascade_host'),
                json={'title': 'Xóa cascade', 'maxMembers': 2}).json()
            room_id = room['roomId']
            assert client.post(f'/v1/study-rooms/{room_id}/join',
                headers=headers('cascade_member'), json={}).status_code == 200
            assert client.delete(f'/v1/study-rooms/{room_id}',
                headers=headers('cascade_host')).status_code == 204
        with Session(engine) as db:
            assert db.scalar(select(func.count()).select_from(StudyRoom).where(
                StudyRoom.id == room_id)) == 0
            assert db.scalar(select(func.count()).select_from(StudyRoomMember).where(
                StudyRoomMember.room_id == room_id)) == 0
            assert host_id
    finally:
        engine.dispose()
