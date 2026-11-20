from fastapi.testclient import TestClient
from app.main import create_app
from tests.test_community_rooms_and_friends import _settings, _h


def test_host_settings_authorization_validation_and_members(tmp_path):
    with TestClient(create_app(_settings(tmp_path))) as client:
        for user in ['host', 'a', 'b']:
            client.get('/v1/me', headers=_h(user))
        room = client.post('/v1/study-rooms', headers=_h('host'),
            json={'title': 'Nhóm ôn', 'maxMembers': 4}).json()
        rid = room['roomId']
        route = f'/v1/study-rooms/{rid}/settings'
        assert client.patch(route, json={'maxMembers': 3}).status_code == 401
        assert client.patch(route, headers=_h('a'), json={'maxMembers': 3}).status_code == 403
        for invalid in [{}, {'maxMembers': 1}, {'maxMembers': 9}, {'title': '  '},
            {'title': None}, {'visibility': 'private'}, {'ownerId': 'a'}, {'aiCompanionEnabled': None}]:
            assert client.patch(route, headers=_h('host'), json=invalid).status_code == 422
        for user in ['a', 'b']:
            assert client.post(f'/v1/study-rooms/{rid}/join', headers=_h(user), json={}).status_code == 200
        conflict = client.patch(route, headers=_h('host'), json={'maxMembers': 2, 'title': 'Không lưu'})
        assert conflict.status_code == 409
        updated = client.patch(route, headers=_h('host'), json={
            'maxMembers': 3, 'title': '  Nhóm mới  ', 'visibility': 'invite_only', 'aiCompanionEnabled': False})
        assert updated.status_code == 200
        body = updated.json()
        assert body['title'] == 'Nhóm mới'
        assert body['maxMembers'] == 3
        assert body['aiCompanionEnabled'] is False
        assert len(body['members']) == 3
        # Existing members retain access after visibility changes.
        assert client.get(f'/v1/study-rooms/{rid}', headers=_h('a')).status_code == 200
        assert client.get('/v1/study-rooms/public', headers=_h('b')).json()['rooms'] == []
        assert client.patch(route, headers=_h('host'), json={'maxMembers': 3}).status_code == 200
        client.post(f'/v1/study-rooms/{rid}/leave', headers=_h('host'), json={})
        assert client.patch(route, headers=_h('host'), json={'title': 'Đã đóng'}).status_code == 404
        assert client.get(f'/v1/study-rooms/{rid}', headers=_h('a')).status_code == 404
