from pathlib import Path

from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings
from app.main import create_app


def _settings(tmp_path: Path) -> Settings:
    db_file = tmp_path / 'commitment_t074.db'
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('AQ.TEST_FAKE_KEY'),
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def _friend(client: TestClient, sender: str, receiver: str) -> tuple[str, str]:
    sender_id = client.get('/v1/me', headers=_h(sender)).json()['id']
    receiver_id = client.get('/v1/me', headers=_h(receiver)).json()['id']
    req = client.post(
        '/v1/friends/request', headers=_h(sender),
        json={'receiverUserId': receiver_id},
    ).json()
    assert client.post(
        f"/v1/friends/requests/{req['requestId']}/respond",
        headers=_h(receiver), json={'decision': 'accept'},
    ).status_code == 200
    return sender_id, receiver_id


def test_create_invite_accept_kick_and_private_hub(tmp_path: Path) -> None:
    with TestClient(create_app(_settings(tmp_path))) as client:
        owner_id, member_id = _friend(client, 'owner', 'member')
        group = client.post(
            '/v1/commitment-groups', headers=_h('owner'),
            json={'name': 'Cùng học 12A', 'petName': 'Mầm Xanh'},
        )
        assert group.status_code == 201
        data = group.json()
        assert data['members'][0]['userId'] == owner_id
        assert data['pet']['stage'] == 1
        assert data['pet']['currentStreakDays'] == 0

        idem_headers = {**_h('owner'), 'Idempotency-Key': 'create-idem-1'}
        first_idem = client.post(
            '/v1/commitment-groups', headers=idem_headers,
            json={'name': 'Nhóm idempotent'},
        )
        second_idem = client.post(
            '/v1/commitment-groups', headers=idem_headers,
            json={'name': 'Nhóm idempotent'},
        )
        assert first_idem.status_code == second_idem.status_code == 201
        assert first_idem.json()['groupId'] == second_idem.json()['groupId']

        invited = client.post(
            f"/v1/commitment-groups/{data['groupId']}/invites",
            headers=_h('owner'), json={'recipientUserId': member_id},
        )
        assert invited.status_code == 201
        hub = client.get('/v1/commitment-groups/me', headers=_h('member')).json()
        assert hub['group'] is None
        assert hub['incomingInvites'][0]['groupName'] == 'Cùng học 12A'

        accepted = client.post(
            f"/v1/commitment-group-invites/{invited.json()['inviteId']}/respond",
            headers=_h('member'), json={'decision': 'accept'},
        )
        assert accepted.status_code == 200
        assert len(accepted.json()['members']) == 2
        assert client.post(
            '/v1/commitment-groups', headers=_h('member'),
            json={'name': 'Nhóm thứ hai'},
        ).status_code == 201
        assert client.post(
            '/v1/commitment-groups', headers=_h('member'),
            json={'name': 'Nhóm thứ ba'},
        ).status_code == 201
        assert client.post(
            '/v1/commitment-groups', headers=_h('member'),
            json={'name': 'Nhóm thứ tư'},
        ).status_code == 409

        denied = client.delete(
            f"/v1/commitment-groups/{data['groupId']}/members/{owner_id}",
            headers=_h('member'),
        )
        assert denied.status_code == 403
        kicked = client.delete(
            f"/v1/commitment-groups/{data['groupId']}/members/{member_id}",
            headers=_h('owner'),
        )
        assert kicked.status_code == 200
        assert len(kicked.json()['members']) == 1
        member_hub = client.get('/v1/commitment-groups/me', headers=_h('member')).json()
        assert len(member_hub['groups']) == 2


def test_join_request_needs_owner_approval_and_capacity(tmp_path: Path) -> None:
    with TestClient(create_app(_settings(tmp_path))) as client:
        group = client.post(
            '/v1/commitment-groups', headers=_h('host'), json={'name': 'Nhóm kín'},
        ).json()
        client.get('/v1/me', headers=_h('candidate'))
        requested = client.post(
            '/v1/commitment-group-join-requests', headers=_h('candidate'),
            json={'groupCode': group['groupCode']},
        )
        assert requested.status_code == 201
        refreshed = client.get('/v1/commitment-groups/me', headers=_h('host')).json()['group']
        assert refreshed['pendingRequests'][0]['alias'].startswith('Học sinh')
        outsider = client.post(
            f"/v1/commitment-groups/{group['groupId']}/join-requests/{requested.json()['requestId']}/respond",
            headers=_h('candidate'), json={'decision': 'accept'},
        )
        assert outsider.status_code == 403
        approved = client.post(
            f"/v1/commitment-groups/{group['groupId']}/join-requests/{requested.json()['requestId']}/respond",
            headers=_h('host'), json={'decision': 'accept'},
        )
        assert approved.status_code == 200
        assert len(approved.json()['members']) == 2


def test_valid_study_session_records_one_daily_care(tmp_path: Path) -> None:
    with TestClient(create_app(_settings(tmp_path))) as client:
        group = client.post(
            '/v1/commitment-groups', headers=_h('learner'),
            json={'name': 'Nhóm đều đặn'},
        ).json()
        started = client.post(
            '/v1/study/sessions', headers=_h('learner'),
            json={
                'clientSessionId': 'care-session-1',
                'taskTitle': 'Ôn Toán',
                'targetMinutes': 25,
            },
        ).json()
        finish = client.post(
            f"/v1/study/sessions/{started['sessionId']}/finish",
            headers=_h('learner'),
            json={
                'clientSessionId': 'care-session-1',
                'finalStatus': 'completed',
                'elapsedWallSeconds': 600,
                'inAppFocusSeconds': 600,
            },
        )
        assert finish.status_code == 200
        assert finish.json()['groupCare'][0]['recorded'] is True
        retry = client.post(
            f"/v1/study/sessions/{started['sessionId']}/finish",
            headers=_h('learner'),
            json={
                'clientSessionId': 'care-session-1',
                'finalStatus': 'completed',
                'elapsedWallSeconds': 600,
                'inAppFocusSeconds': 600,
            },
        )
        assert retry.status_code == 200
        assert retry.json()['groupCare'][0]['recorded'] is False
        alarm = client.post(
            '/v1/sessions', headers=_h('learner'),
            json={
                'alarmId': 'alarm-care-1',
                'localSessionId': 'morning-care-1',
                'localDate': '2026-11-21',
                'timeZone': 'Asia/Ho_Chi_Minh',
                'questionId': 'math9-linear-001',
            },
        ).json()
        answered = client.post(
            f"/v1/sessions/{alarm['sessionId']}/answers",
            headers={**_h('learner'), 'Idempotency-Key': 'morning-care-answer-1'},
            json={'answerValue': '8', 'reasoningText': 'Tính theo phương trình đã cho.'},
        )
        assert answered.status_code == 200
        assert answered.json()['result'] == 'correct'
        assert answered.json()['groupCare'][0]['recorded'] is True
        pet = client.get('/v1/commitment-groups/me', headers=_h('learner')).json()['group']['pet']
        assert pet['totalCareDays'] == 1
        assert pet['todayCareCount'] == 1
        assert pet['currentStreakDays'] == 1
        assert pet['stage'] == 1
        assert pet['totalXp'] == 30
        assert group['groupId']


def test_short_or_abandoned_session_does_not_feed_pet(tmp_path: Path) -> None:
    with TestClient(create_app(_settings(tmp_path))) as client:
        client.post('/v1/commitment-groups', headers=_h('short'), json={'name': 'Nhóm thử'})
        started = client.post(
            '/v1/study/sessions', headers=_h('short'),
            json={'clientSessionId': 'short-1', 'taskTitle': 'Đọc nhanh'},
        ).json()
        finish = client.post(
            f"/v1/study/sessions/{started['sessionId']}/finish",
            headers=_h('short'),
            json={'finalStatus': 'completed', 'elapsedWallSeconds': 120, 'inAppFocusSeconds': 120},
        ).json()
        assert finish['xpStatus'] == 'below_minimum_duration'
        assert finish['groupCare'] is None
        pet = client.get('/v1/commitment-groups/me', headers=_h('short')).json()['group']['pet']
        assert pet['totalCareDays'] == 0


def test_group_streak_requires_all_active_members_and_accumulates_days(tmp_path: Path) -> None:
    from datetime import datetime, timedelta, timezone
    from zoneinfo import ZoneInfo
    from sqlalchemy import create_engine
    from sqlalchemy.orm import Session
    from app.db.models import CommitmentPetCare
    from app.services.commitment_group_service import CommitmentGroupService

    cfg = _settings(tmp_path)
    with TestClient(create_app(cfg)) as client:
        owner_id, member_id = _friend(client, 'streak_a', 'streak_b')
        group = client.post(
            '/v1/commitment-groups',
            headers=_h('streak_a'),
            json={'name': 'Nhóm 100 Ngày', 'petName': 'Mầm Xanh'},
        ).json()
        group_id = group['groupId']

        invite = client.post(
            f'/v1/commitment-groups/{group_id}/invites',
            headers=_h('streak_a'),
            json={'recipientUserId': member_id},
        ).json()
        assert client.post(
            f"/v1/commitment-group-invites/{invite['inviteId']}/respond",
            headers=_h('streak_b'),
            json={'decision': 'accept'},
        ).status_code == 200

        # Chỉ thành viên A nộp báo cáo ngày -> mới 1/2 người, CHƯA thành 1 chuỗi nhóm
        client.post(
            '/v1/progress/daily-report',
            headers=_h('streak_a'),
            json={'tasksCompleted': 2, 'feeling': 'focused', 'reflectionNote': 'A xong'},
        )
        pet_partial = client.get('/v1/commitment-groups/me', headers=_h('streak_a')).json()['group']['pet']
        assert pet_partial['todayCareCount'] == 1
        assert pet_partial['memberCount'] == 2
        assert pet_partial['allMembersDoneToday'] is False
        assert pet_partial['currentStreakDays'] == 0

        # Thành viên B cũng hoàn thành cùng ngày -> cả nhóm 2/2 xong -> lên Chuỗi 1
        client.post(
            '/v1/progress/daily-report',
            headers=_h('streak_b'),
            json={'tasksCompleted': 3, 'feeling': 'steady', 'reflectionNote': 'B xong'},
        )
        pet_day1 = client.get('/v1/commitment-groups/me', headers=_h('streak_a')).json()['group']['pet']
        assert pet_day1['todayCareCount'] == 2
        assert pet_day1['allMembersDoneToday'] is True
        assert pet_day1['currentStreakDays'] == 1
        assert pet_day1['streakMilestoneLabelVi'] == 'Chuỗi 1'

        # Mô phỏng thêm 2 ngày liền kề trước đó đều có cả A và B hoàn thành -> cộng dồn Chuỗi 3
        today_vn = datetime.now(timezone.utc).astimezone(ZoneInfo('Asia/Ho_Chi_Minh')).date()
        engine = create_engine(cfg.database_url)
        try:
            with Session(engine) as db:
                for back in (1, 2):
                    d_str = (today_vn - timedelta(days=back)).isoformat()
                    for uid in (owner_id, member_id):
                        db.add(CommitmentPetCare(
                            group_id=group_id,
                            user_id=uid,
                            local_date=d_str,
                            care_kind='daily_report',
                            source_type='daily_report',
                            source_id=f'rep_{d_str}_{uid}',
                            xp_delta=10,
                        ))
                db.commit()
        finally:
            engine.dispose()

        pet_day3 = client.get('/v1/commitment-groups/me', headers=_h('streak_b')).json()['group']['pet']
        assert pet_day3['currentStreakDays'] == 3
        assert pet_day3['bestStreakDays'] == 3
        assert pet_day3['totalCareDays'] == 3
        assert pet_day3['streakMilestoneLabelVi'] == 'Chuỗi 3'
        assert CommitmentGroupService._best_streak([
            (today_vn - timedelta(days=i)).isoformat() for i in range(100)
        ]) == 100
