from fastapi.testclient import TestClient
from app.main import create_app
from tests.test_community_rooms_and_friends import _settings, _h


def test_cancelled_request_cannot_be_accepted_and_retries_are_safe(tmp_path):
    with TestClient(create_app(_settings(tmp_path))) as client:
        a = client.get('/v1/me', headers=_h('a')).json()['id']
        b = client.get('/v1/me', headers=_h('b')).json()['id']
        client.get('/v1/me', headers=_h('c'))
        request = client.post('/v1/friends/request', headers=_h('a'), json={'receiverUserId': b}).json()['requestId']
        route = f'/v1/friends/requests/{request}/respond'
        assert client.post(route, headers=_h('c'), json={'decision': 'accept'}).status_code == 403
        assert client.post(route, headers=_h('a'), json={'decision': 'cancel'}).status_code == 200
        assert client.post(route, headers=_h('b'), json={'decision': 'accept'}).status_code == 409
        assert client.get('/v1/friends', headers=_h('a')).json()['friends'] == []
        client.post('/v1/friends/request', headers=_h('a'), json={'receiverUserId': b})
        assert client.post(route, headers=_h('b'), json={'decision': 'accept'}).status_code == 200
        assert client.post(route, headers=_h('b'), json={'decision': 'accept'}).status_code == 200
        assert len(client.get('/v1/friends', headers=_h('a')).json()['friends']) == 1
        assert client.post(route, headers=_h('a'), json={'decision': 'cancel'}).status_code == 409


def test_capacity_validation_and_private_code(tmp_path):
    with TestClient(create_app(_settings(tmp_path))) as client:
        client.get('/v1/me', headers=_h('host'))
        client.get('/v1/me', headers=_h('guest'))
        for count in [1, 9]:
            assert client.post('/v1/study-rooms', headers=_h('host'),
                json={'title': 'Nhóm ôn', 'maxMembers': count}).status_code == 422
        room = client.post('/v1/study-rooms', headers=_h('host'), json={
            'title': 'Nhóm riêng', 'maxMembers': 2, 'visibility': 'invite_only'}).json()
        route = f'/v1/study-rooms/{room["roomId"]}/join'
        assert client.post(route, headers=_h('guest'), json={}).status_code == 403
        joined = client.post(f'/v1/study-rooms/{room["roomCode"]}/join',
            headers=_h('guest'), json={'roomCode': room['roomCode']})
        assert joined.status_code == 200
        assert len(joined.json()['members']) == 2
        assert all(not m['micEnabled'] and not m['camEnabled'] for m in joined.json()['members'])
