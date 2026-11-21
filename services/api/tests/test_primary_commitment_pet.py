from pathlib import Path

from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


def _settings(tmp_path: Path) -> Settings:
    return Settings(
        _env_file=None,
        app_env='test',
        database_url=f"sqlite+pysqlite:///{(tmp_path / 'primary_pet.db').as_posix()}",
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_primary_pet_is_server_authoritative_and_falls_back_after_delete(tmp_path: Path) -> None:
    with TestClient(create_app(_settings(tmp_path))) as client:
        first = client.post(
            '/v1/commitment-groups', headers=_h('owner'),
            json={'name': 'Nhóm đầu'},
        ).json()
        second = client.post(
            '/v1/commitment-groups', headers=_h('owner'),
            json={'name': 'Nhóm chính'},
        ).json()
        assert first['isPrimary'] is True
        assert second['isPrimary'] is False

        selected = client.post(
            f"/v1/commitment-groups/{second['groupId']}/primary",
            headers=_h('owner'), json={},
        )
        assert selected.status_code == 200
        groups = selected.json()['groups']
        assert groups[0]['groupId'] == second['groupId']
        assert sum(1 for item in groups if item['isPrimary']) == 1

        assert client.post(
            f"/v1/commitment-groups/{second['groupId']}/primary",
            headers=_h('outsider'), json={},
        ).status_code == 403

        assert client.delete(
            f"/v1/commitment-groups/{second['groupId']}",
            headers=_h('owner'),
        ).status_code == 204
        fallback = client.get(
            '/v1/commitment-groups/me', headers=_h('owner')
        ).json()['groups']
        assert len(fallback) == 1
        assert fallback[0]['groupId'] == first['groupId']
        assert fallback[0]['isPrimary'] is True
