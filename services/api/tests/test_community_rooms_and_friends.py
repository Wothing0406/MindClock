from pathlib import Path

from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings
from app.main import create_app


def _settings(tmp_path: Path) -> Settings:
    db_file = tmp_path / 'community_t058.db'
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('AQ.TEST_FAKE_KEY'),
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_public_profile_search_friends_and_block_isolation(tmp_path: Path) -> None:
    with TestClient(create_app(_settings(tmp_path))) as client:
        assert client.get('/v1/study-rooms/public').status_code == 401

        # Thiết lập hồ sơ User A và User B
        a_me = client.patch(
            '/v1/me',
            headers=_h('alice_uid'),
            json={
                'alias': 'Minh Anh 11A',
                'avatarId': 'ca-chep',
                'studyLevel': 'exam_prep',
                'gradeLevel': 'Lớp 11',
                'selectedSubjects': ['TOAN', 'VAT_LY'],
                'goalLabel': 'Top 10 khối A',
            },
        ).json()
        b_me = client.patch(
            '/v1/me',
            headers=_h('bob_uid'),
            json={
                'alias': 'Quang Huy 11B',
                'avatarId': 'cu-meo',
                'studyLevel': 'exam_prep',
                'gradeLevel': 'Lớp 11',
                'selectedSubjects': ['TOAN', 'TIENG_ANH'],
                'goalLabel': 'Đạt 9+ Toán',
            },
        ).json()

        # User A tạo TKB & báo thức riêng -> đảm bảo profile công khai KHÔNG rò rỉ
        client.put(
            '/v1/timetable',
            headers=_h('alice_uid'),
            json={'slots': [{'weekday': 1, 'subjectCode': 'TOAN'}]},
        )
        client.post(
            '/v1/alarms',
            headers={'Authorization': 'Bearer dev:alice_uid', 'Idempotency-Key': 'alm-a-1'},
            json={'localTime': '05:30', 'weekdays': [1, 2], 'enabled': True},
        )

        # User B xem hồ sơ công khai của User A
        prof_res = client.get(f"/v1/profiles/{a_me['id']}", headers=_h('bob_uid'))
        assert prof_res.status_code == 200
        prof = prof_res.json()
        assert prof['alias'] == 'Minh Anh 11A'
        assert prof['avatarId'] == 'ca-chep'
        assert prof['gradeLevel'] == 'Lớp 11'
        assert prof['selectedSubjects'] == ['TOAN', 'VAT_LY']
        assert prof['friendStatus'] == 'none'
        assert 'authSubject' not in prof
        assert 'email' not in prof
        assert 'alarms' not in prof
        assert 'timetable' not in prof

        # Tìm bạn theo môn & biệt danh
        search = client.get(
            '/v1/users/search?q=Minh&subjectCode=TOAN',
            headers=_h('bob_uid'),
        )
        assert search.status_code == 200
        assert len(search.json()['users']) == 1
        assert search.json()['users'][0]['userId'] == a_me['id']

        # B gửi lời mời kết bạn -> A chấp nhận
        req_res = client.post(
            '/v1/friends/request',
            headers=_h('bob_uid'),
            json={'receiverUserId': a_me['id'], 'messageVi': 'Cùng luyện Toán 11 nhé'},
        )
        assert req_res.status_code == 201
        req_id = req_res.json()['requestId']

        inbox = client.get('/v1/friends/requests', headers=_h('alice_uid')).json()
        assert len(inbox['incoming']) == 1
        assert inbox['incoming'][0]['peer']['userId'] == b_me['id']

        acc = client.post(
            f'/v1/friends/requests/{req_id}/respond',
            headers=_h('alice_uid'),
            json={'decision': 'accept'},
        )
        assert acc.status_code == 200
        assert acc.json()['status'] == 'accepted'

        friends_a = client.get('/v1/friends', headers=_h('alice_uid')).json()['friends']
        assert len(friends_a) == 1
        assert friends_a[0]['userId'] == b_me['id']

        # A chặn B -> xóa kết bạn & chặn xem hồ sơ/kết bạn
        blk = client.post(
            '/v1/users/block',
            headers=_h('alice_uid'),
            json={'blockedUserId': b_me['id'], 'reason': 'spam'},
        )
        assert blk.status_code == 200
        assert client.get(f"/v1/profiles/{a_me['id']}", headers=_h('bob_uid')).status_code == 403
        assert client.get('/v1/friends', headers=_h('alice_uid')).json()['friends'] == []


def test_public_vs_invite_rooms_ai_match_and_delete_cleanup(tmp_path: Path) -> None:
    with TestClient(create_app(_settings(tmp_path))) as client:
        client.patch(
            '/v1/me',
            headers=_h('host_1'),
            json={
                'alias': 'Trưởng nhóm Toán 11',
                'avatarId': 'tho-so',
                'studyLevel': 'exam_prep',
                'gradeLevel': 'Lớp 11',
                'selectedSubjects': ['TOAN', 'VAT_LY'],
            },
        )
        client.patch(
            '/v1/me',
            headers=_h('student_2'),
            json={
                'alias': 'Bạn học mới',
                'avatarId': 'rua-xanh',
                'studyLevel': 'exam_prep',
                'gradeLevel': 'Lớp 11',
                'selectedSubjects': ['TOAN'],
            },
        )

        # Phòng công khai
        pub_room = client.post(
            '/v1/study-rooms',
            headers=_h('host_1'),
            json={
                'title': 'Cày đề Toán chương 3',
                'subjectCode': 'TOAN',
                'gradeLevel': 'Lớp 11',
                'targetLevel': 'exam_prep',
                'visibility': 'public',
                'maxMembers': 4,
                'aiCompanionEnabled': True,
            },
        )
        assert pub_room.status_code == 201
        pub_data = pub_room.json()
        assert pub_data['members'][0]['micEnabled'] is False
        assert pub_data['members'][0]['camEnabled'] is False

        # Phòng riêng tư Chỉ mời
        priv_room = client.post(
            '/v1/study-rooms',
            headers=_h('host_1'),
            json={
                'title': 'Nhóm kín 2 người',
                'subjectCode': 'VAT_LY',
                'gradeLevel': 'Lớp 11',
                'targetLevel': 'basic',
                'visibility': 'invite_only',
                'maxMembers': 2,
                'aiCompanionEnabled': False,
            },
        ).json()

        # Quét phòng công khai chỉ hiện phòng public
        listed = client.get('/v1/study-rooms/public', headers=_h('student_2')).json()['rooms']
        assert [r['roomId'] for r in listed] == [pub_data['roomId']]

        # Phòng riêng không cho join nếu thiếu roomCode
        bad_join = client.post(
            f"/v1/study-rooms/{priv_room['roomId']}/join",
            headers=_h('student_2'),
            json={},
        )
        assert bad_join.status_code == 403

        # AI ghép nhóm gợi ý phòng công khai khớp khối 11 + Toán + exam_prep
        ai_match = client.post(
            '/v1/study-rooms/ai-match',
            headers=_h('student_2'),
            json={'subjectCode': 'TOAN', 'gradeLevel': 'Lớp 11', 'targetLevel': 'exam_prep'},
        )
        assert ai_match.status_code == 200
        match_data = ai_match.json()
        assert len(match_data['recommendedRooms']) == 1
        assert match_data['recommendedRooms'][0]['roomId'] == pub_data['roomId']
        assert 'Lớp 11' in match_data['recommendedRooms'][0]['matchReasonVi']

        # Student 2 join phòng public (mic/cam mặc định tắt), bật cam -> rời phòng
        joined = client.post(
            f"/v1/study-rooms/{pub_data['roomId']}/join",
            headers=_h('student_2'),
            json={'statusNote': 'Đang giải câu tích phân'},
        )
        assert joined.status_code == 200
        assert len(joined.json()['members']) == 2
        self_member = [m for m in joined.json()['members'] if m['isSelf']][0]
        assert self_member['micEnabled'] is False
        assert self_member['camEnabled'] is False

        toggled = client.patch(
            f"/v1/study-rooms/{pub_data['roomId']}/media",
            headers=_h('student_2'),
            json={'camEnabled': True, 'micEnabled': False},
        )
        assert toggled.status_code == 200
        self_after = [m for m in toggled.json()['members'] if m['isSelf']][0]
        assert self_after['camEnabled'] is True

        # Host xóa tài khoản -> dọn sạch phòng học & không lỗi FK
        del_res = client.delete('/v1/me', headers=_h('host_1'))
        assert del_res.status_code == 202
        assert client.get('/v1/study-rooms/public', headers=_h('student_2')).json()['rooms'] == []
