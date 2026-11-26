from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.models import LocalAuthAccount, User
from app.main import create_app
from tests.test_progression_postgres import isolated_pg  # noqa: F401


def test_local_auth_register_login_refresh_and_delete_isolation(tmp_path) -> None:
    db_file = tmp_path / 'local_auth.db'
    settings = Settings(
        _env_file=None,
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=False,
        local_auth_enabled=True,
        local_auth_jwt_secret='test-local-auth-secret-32-bytes-key!',
    )
    app = create_app(settings)

    with TestClient(app) as client:
        # 1. Weak password blocked (422)
        bad_pw = client.post(
            '/v1/auth/register',
            json={
                'email': 'studentA@mindclock.vn',
                'password': 'password1',
                'alias': 'Hoc Sinh A',
            },
        )
        assert bad_pw.status_code == 422
        assert bad_pw.json()['error']['code'] == 'WEAK_PASSWORD'

        # 2. Register succeeds -> returns real HS256 JWT
        reg = client.post(
            '/v1/auth/register',
            json={
                'email': 'studentA@mindclock.vn',
                'password': 'MindClock@2026',
                'alias': 'Hoc Sinh A',
            },
        )
        assert reg.status_code == 200
        body = reg.json()
        assert body['uid'].startswith('loc_')
        assert body['email'] == 'studenta@mindclock.vn'
        assert body['alias'] == 'Hoc Sinh A'
        assert body['idToken']
        assert body['refreshToken']

        # 3. Duplicate email rejected (409)
        dup = client.post(
            '/v1/auth/register',
            json={
                'email': 'StudentA@mindclock.vn',
                'password': 'MindClock@2026',
            },
        )
        assert dup.status_code == 409
        assert dup.json()['error']['code'] == 'EMAIL_EXISTS'

        # 4. Wrong password rejected (401)
        wrong = client.post(
            '/v1/auth/login',
            json={
                'email': 'studenta@mindclock.vn',
                'password': 'WrongPassword@1',
            },
        )
        assert wrong.status_code == 401
        assert wrong.json()['error']['code'] == 'INVALID_LOGIN_CREDENTIALS'

        # 5. Authenticated /v1/me works strictly via HS256 JWT (dev fallback is False!)
        me = client.get(
            '/v1/me',
            headers={'Authorization': f"Bearer {body['idToken']}"},
        )
        assert me.status_code == 200
        assert me.json()['alias'] == 'Hoc Sinh A'

        # 6. Refresh token works
        refreshed = client.post(
            '/v1/auth/refresh',
            json={'refreshToken': body['refreshToken']},
        )
        assert refreshed.status_code == 200
        new_token = refreshed.json()['idToken']
        assert new_token

        # 7. DELETE /v1/me deletes user + local_auth_accounts cleanly & blocks old refresh
        deleted = client.delete(
            '/v1/me',
            headers={'Authorization': f'Bearer {new_token}'},
        )
        assert deleted.status_code == 202

        post_delete_refresh = client.post(
            '/v1/auth/refresh',
            json={'refreshToken': refreshed.json()['refreshToken']},
        )
        assert post_delete_refresh.status_code == 401

        # 8. Deleted email can register cleanly again with brand new uid
        re_reg = client.post(
            '/v1/auth/register',
            json={
                'email': 'studenta@mindclock.vn',
                'password': 'MindClock@2026',
                'alias': 'Hoc Sinh A2',
            },
        )
        assert re_reg.status_code == 200
        assert re_reg.json()['uid'] != body['uid']


def test_local_auth_works_on_live_postgresql_with_alembic_0007(isolated_pg) -> None:
    from alembic import command
    from alembic.config import Config

    cfg = Config('alembic.ini')
    cfg.attributes['sqlalchemy.url'] = isolated_pg
    command.upgrade(cfg, 'head')

    settings = Settings(
        _env_file=None,
        app_env='test',
        database_url=isolated_pg,
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=False,
        local_auth_enabled=True,
        local_auth_jwt_secret='pg-local-auth-test-secret-32bytes!',
    )
    app = create_app(settings)
    with TestClient(app) as client:
        r = client.post(
            '/v1/auth/register',
            json={
                'email': 'pgstudent@mindclock.vn',
                'password': 'StrongPass@99',
                'alias': 'PG Minh',
            },
        )
        assert r.status_code == 200
        tok = r.json()['idToken']

        login = client.post(
            '/v1/auth/login',
            json={'email': 'pgstudent@mindclock.vn', 'password': 'StrongPass@99'},
        )
        assert login.status_code == 200

        grp = client.post(
            '/v1/commitment-groups',
            headers={'Authorization': f'Bearer {tok}'},
            json={'name': 'Nhom PG 12A', 'petName': 'Mầm Xanh'},
        )
        assert grp.status_code == 201
        assert grp.json()['name'] == 'Nhom PG 12A'

        # Verify local_auth_accounts row exists in PostgreSQL
        from app.db.base import build_engine

        eng = build_engine(settings)
        try:
            with Session(eng) as s:
                acc = s.scalar(
                    select(LocalAuthAccount).where(
                        LocalAuthAccount.email == 'pgstudent@mindclock.vn'
                    )
                )
                assert acc is not None
                u = s.get(User, acc.user_id)
                assert u is not None
        finally:
            eng.dispose()
