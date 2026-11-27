from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from threading import Barrier
import time

from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.models import StudyRoom, StudyRoomInvite, StudyRoomMember, StudySession
from app.main import create_app
from app.services.community_service import CommunityService
from tests.test_progression_postgres import isolated_pg  # noqa: F401


def _upgrade_pg(url: str) -> None:
    cfg = Config('alembic.ini')
    cfg.attributes['sqlalchemy.url'] = url
    command.upgrade(cfg, 'head')


def _make_app(url: str):
    return create_app(
        Settings(
            _env_file=None,
            app_env='test',
            database_url=url,
            gemini_mock_mode=True,
            local_dev_bearer_uid_fallback=True,
        )
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_room_lifecycle_states_and_active_protection_on_postgres(isolated_pg: str) -> None:
    _upgrade_pg(isolated_pg)
    engine = create_engine(isolated_pg)
    try:
        with TestClient(_make_app(isolated_pg)) as client:
            host = client.get('/v1/me', headers=_h('lc_host')).json()
            peer = client.get('/v1/me', headers=_h('lc_peer')).json()

            created = client.post(
                '/v1/study-rooms',
                headers=_h('lc_host'),
                json={
                    'title': 'Phòng Toán 12 T094',
                    'subjectCode': 'TOAN',
                    'gradeLevel': 'Lớp 12',
                    'visibility': 'public',
                    'maxMembers': 4,
                    'ttlMinutes': 120,
                },
            )
            assert created.status_code == 201
            room = created.json()
            rid = room['roomId']
            assert room['ownerUserId'] == host['id']
            assert room['maxMembers'] == 4
            assert room['visibility'] == 'public'
            assert room['status'] == 'waiting'
            assert room['createdAt'] is not None
            assert room['expiresAt'] is not None
            assert room['lastHeartbeatAt'] is not None

            joined = client.post(
                f'/v1/study-rooms/{rid}/join',
                headers=_h('lc_peer'),
                json={'statusNote': 'Đang làm đề'},
            )
            assert joined.status_code == 200
            assert joined.json()['status'] == 'active'
            assert joined.json()['memberCount'] == 2

            # Phòng đang active hợp lệ không bị xóa hoặc đóng khi chạy sweep
            with Session(engine) as db:
                stats = CommunityService(db).sweep_stale_rooms()
                assert stats['closedOrExpired'] == 0

            hb = client.post(
                f'/v1/study-rooms/{rid}/heartbeat',
                headers=_h('lc_peer'),
                json={'statusNote': 'Vẫn tập trung'},
            )
            assert hb.status_code == 200
            assert hb.json()['status'] == 'active'
            assert any(
                m['userId'] == peer['id'] and m['statusNote'] == 'Vẫn tập trung'
                for m in hb.json()['members']
            )

            closed = client.post(f'/v1/study-rooms/{rid}/close', headers=_h('lc_host'))
            assert closed.status_code == 200
            assert closed.json()['status'] == 'closed'
            assert client.get(f'/v1/study-rooms/{rid}', headers=_h('lc_peer')).status_code == 404
    finally:
        engine.dispose()


def test_concurrent_members_leaving_and_host_transfer_vs_close_on_postgres(
    isolated_pg: str,
) -> None:
    _upgrade_pg(isolated_pg)
    engine = create_engine(isolated_pg)
    try:
        with TestClient(_make_app(isolated_pg)) as client:
            host_id = client.get('/v1/me', headers=_h('conc_host')).json()['id']
            member_ids = [
                client.get('/v1/me', headers=_h(u)).json()['id']
                for u in ('conc_m1', 'conc_m2', 'conc_m3')
            ]
            room = client.post(
                '/v1/study-rooms',
                headers=_h('conc_host'),
                json={'title': 'Đông người rời cùng lúc', 'maxMembers': 6},
            ).json()
            rid = room['roomId']
            for u in ('conc_m1', 'conc_m2', 'conc_m3'):
                assert (
                    client.post(
                        f'/v1/study-rooms/{rid}/join',
                        headers=_h(u),
                        json={'micEnabled': True, 'camEnabled': True},
                    ).status_code
                    == 200
                )

            barrier = Barrier(3)

            def leave_worker(uid: str) -> dict:
                with Session(engine) as db:
                    barrier.wait(timeout=10)
                    return CommunityService(db).leave_room(uid, rid)

            with ThreadPoolExecutor(max_workers=3) as pool:
                outcomes = list(pool.map(leave_worker, member_ids))
            assert all(item['left'] is True for item in outcomes)

            detail = client.get(f'/v1/study-rooms/{rid}', headers=_h('conc_host')).json()
            assert detail['status'] == 'waiting'
            assert [m['userId'] for m in detail['members']] == [host_id]

            with Session(engine) as db:
                left_rows = list(
                    db.scalars(
                        select(StudyRoomMember).where(
                            StudyRoomMember.room_id == rid,
                            StudyRoomMember.user_id.in_(member_ids),
                        )
                    )
                )
                assert len(left_rows) == 3
                assert all(
                    r.left_at is not None and not r.mic_enabled and not r.cam_enabled
                    for r in left_rows
                )

            # Cho m1 và m2 vào lại cách nhau 20ms để thứ tự joined_at rõ trên clock Windows -> m1 lên làm host mới
            assert client.post(f'/v1/study-rooms/{rid}/join', headers=_h('conc_m1'), json={}).status_code == 200
            time.sleep(0.02)
            assert client.post(f'/v1/study-rooms/{rid}/join', headers=_h('conc_m2'), json={}).status_code == 200
            transferred = client.post(
                f'/v1/study-rooms/{rid}/leave',
                headers=_h('conc_host'),
                json={'transferHost': True},
            )
            assert transferred.status_code == 200
            assert transferred.json()['newHostUserId'] == member_ids[0]
            assert transferred.json()['roomStatus'] == 'active'

            after_transfer = client.get(f'/v1/study-rooms/{rid}', headers=_h('conc_m1')).json()
            assert after_transfer['ownerUserId'] == member_ids[0]
            host_tile = next(m for m in after_transfer['members'] if m['userId'] == member_ids[0])
            assert host_tile['role'] == 'host'
    finally:
        engine.dispose()


def test_host_disconnect_transfers_host_and_all_heartbeat_expiry_cleans_up_on_postgres(
    isolated_pg: str,
) -> None:
    _upgrade_pg(isolated_pg)
    engine = create_engine(isolated_pg)
    t0 = datetime(2026, 11, 27, 14, 0, 0, tzinfo=timezone.utc)
    try:
        with TestClient(_make_app(isolated_pg)) as client:
            host_id = client.get('/v1/me', headers=_h('hb_host')).json()['id']
            m1_id = client.get('/v1/me', headers=_h('hb_m1')).json()['id']
            m2_id = client.get('/v1/me', headers=_h('hb_m2')).json()['id']

            # Tạo 1 phiên học cá nhân của host để chứng minh dọn phòng KHÔNG xóa lịch sử cá nhân
            ps = client.post(
                '/v1/study/sessions',
                headers={'Authorization': 'Bearer dev:hb_host', 'Idempotency-Key': 'hb-ps-1'},
                json={
                    'clientSessionId': 'local_hb_session_1',
                    'taskTitle': 'Tự học Toán 12',
                    'plannedDurationMinutes': 25,
                    'focusLevel': 'standard',
                    'roomMode': 'solo',
                    'cadence': 'interval',
                },
            )
            assert ps.status_code in (200, 201)

        with Session(engine) as db:
            from app.db.models import User

            host_user = db.get(User, host_id)
            assert host_user is not None
            svc_t0 = CommunityService(db, now_provider=lambda: t0)
            created = svc_t0.create_room(
                host_user,
                title='Phòng kiểm tra mất mạng',
                subject_code='TOAN',
                grade_band='Lớp 12',
                target_level='exam_prep',
                visibility='public',
                max_members=4,
                ai_companion_enabled=False,
                ttl_minutes=120,
            )
            rid = created['roomId']
            svc_t1 = CommunityService(db, now_provider=lambda: t0 + timedelta(seconds=5))
            svc_t1.join_room(m1_id, rid)
            svc_t2 = CommunityService(db, now_provider=lambda: t0 + timedelta(seconds=10))
            svc_t2.join_room(m2_id, rid)

            # T+60s: m1 và m2 gửi heartbeat; host mất mạng không gửi gì từ T+0s
            t_60 = t0 + timedelta(seconds=60)
            svc_60 = CommunityService(db, now_provider=lambda: t_60)
            svc_60.heartbeat_room(m1_id, rid)
            svc_60.heartbeat_room(m2_id, rid)

            # T+100s (>90s kể từ T+0s của host, nhưng chỉ 40s kể từ heartbeat của m1/m2):
            # Host tự động bị đánh dấu mất kết nối và quyền host chuyển sang m1!
            t_100 = t0 + timedelta(seconds=100)
            svc_100 = CommunityService(db, now_provider=lambda: t_100)
            sweep_1 = svc_100.sweep_stale_rooms()
            assert sweep_1['hostTransferred'] == 1
            assert sweep_1['closedOrExpired'] == 0

            detail_100 = svc_100.get_room_detail(m1_id, rid)
            assert detail_100['ownerUserId'] == m1_id
            assert detail_100['status'] == 'active'
            assert {m['userId'] for m in detail_100['members']} == {m1_id, m2_id}

            # T+250s (>90s sau lần chạm cuối của cả m1 và m2) -> phòng chuyển sang expired
            t_250 = t0 + timedelta(seconds=250)
            svc_250 = CommunityService(db, now_provider=lambda: t_250)
            sweep_2 = svc_250.sweep_stale_rooms()
            assert sweep_2['closedOrExpired'] == 1

            room_row = db.get(StudyRoom, rid)
            assert room_row is not None
            assert room_row.status == 'expired'
            assert room_row.closed_at is not None
            assert svc_250.list_public_rooms(m2_id) == []

            # Lịch sử phiên tự học cá nhân vẫn nguyên vẹn tuyệt đối
            personal_count = db.scalar(
                select(func.count()).select_from(StudySession).where(StudySession.user_id == host_id)
            )
            assert personal_count == 1
    finally:
        engine.dispose()


def test_room_full_and_invite_link_ttl_revoke_and_no_pii_on_postgres(
    isolated_pg: str,
) -> None:
    _upgrade_pg(isolated_pg)
    engine = create_engine(isolated_pg)
    try:
        with TestClient(_make_app(isolated_pg)) as client:
            host = client.patch(
                '/v1/me',
                headers=_h('inv_host'),
                json={
                    'alias': 'Minh Khoa Bí Mật',
                    'gradeLevel': 'Lớp 12',
                    'selectedSubjects': ['TOAN'],
                },
            ).json()
            client.put(
                '/v1/timetable',
                headers=_h('inv_host'),
                json={'slots': [{'weekday': 1, 'subjectCode': 'TOAN'}]},
            )
            client.post(
                '/v1/alarms',
                headers={'Authorization': 'Bearer dev:inv_host', 'Idempotency-Key': 'inv-alm-1'},
                json={'localTime': '05:15', 'weekdays': [1, 2], 'enabled': True},
            )
            for u in ('inv_m1', 'inv_m2'):
                client.get('/v1/me', headers=_h(u))

            room = client.post(
                '/v1/study-rooms',
                headers=_h('inv_host'),
                json={
                    'title': 'Nhóm kín 2 chỗ',
                    'subjectCode': 'TOAN',
                    'gradeLevel': 'Lớp 12',
                    'visibility': 'invite_only',
                    'maxMembers': 2,
                },
            ).json()
            rid = room['roomId']

            # Tạo link/QR mời -> kiểm tra không chứa bất kỳ PII nào và DB chỉ lưu hash
            inv_res = client.post(
                f'/v1/study-rooms/{rid}/invites',
                headers=_h('inv_host'),
                json={'ttlMinutes': 30, 'maxUses': 4},
            )
            assert inv_res.status_code == 201
            inv = inv_res.json()
            for pii_fragment in (
                host['id'],
                'Minh',
                'Khoa',
                'inv_host',
                '05:15',
                'TOAN',
                'tokenHash',
            ):
                assert pii_fragment not in inv['inviteLink']
                assert pii_fragment not in inv['qrPayload']

            with Session(engine) as db:
                stored_inv = db.get(StudyRoomInvite, inv['inviteId'])
                assert stored_inv is not None
                assert stored_inv.token_hash != inv['inviteToken']

            # m1 dùng nguyên URL QR để vào phòng -> thành công (2/2 đầy phòng)
            redeem_m1 = client.post(
                '/v1/study-rooms/invites/redeem',
                headers=_h('inv_m1'),
                json={'inviteToken': inv['qrPayload']},
            )
            assert redeem_m1.status_code == 200
            assert redeem_m1.json()['memberCount'] == 2
            assert redeem_m1.json()['status'] == 'active'

            # Phòng đã đủ 2/2 -> m2 dùng link bị từ chối 409 ROOM_FULL
            full_res = client.post(
                '/v1/study-rooms/invites/redeem',
                headers=_h('inv_m2'),
                json={'inviteToken': inv['inviteToken']},
            )
            assert full_res.status_code == 409
            assert full_res.json()['error']['code'] == 'ROOM_FULL'

            # Host thu hồi link -> m1 đã ở trong phòng KHÔNG bị đuổi, nhưng lượt mới bị 410 INVITE_REVOKED
            rev = client.post(
                f"/v1/study-rooms/{rid}/invites/{inv['inviteId']}/revoke",
                headers=_h('inv_host'),
            )
            assert rev.status_code == 200
            assert rev.json()['revoked'] is True
            assert client.get(f'/v1/study-rooms/{rid}', headers=_h('inv_m1')).status_code == 200

            client.post(f'/v1/study-rooms/{rid}/leave', headers=_h('inv_m1'), json={})
            revoked_join = client.post(
                '/v1/study-rooms/invites/redeem',
                headers=_h('inv_m2'),
                json={'inviteToken': inv['inviteToken']},
            )
            assert revoked_join.status_code == 410
            assert revoked_join.json()['error']['code'] == 'INVITE_REVOKED'

            # Tạo link mới nhưng chỉnh expires_at về quá khứ -> 410 INVITE_EXPIRED
            exp_inv = client.post(
                f'/v1/study-rooms/{rid}/invites',
                headers=_h('inv_host'),
                json={'ttlMinutes': 5, 'maxUses': 2},
            ).json()
            with Session(engine) as db:
                row = db.get(StudyRoomInvite, exp_inv['inviteId'])
                assert row is not None
                row.expires_at = datetime.now(timezone.utc) - timedelta(seconds=10)
                db.commit()

            expired_join = client.post(
                '/v1/study-rooms/invites/redeem',
                headers=_h('inv_m2'),
                json={'inviteToken': exp_inv['inviteToken']},
            )
            assert expired_join.status_code == 410
            assert expired_join.json()['error']['code'] == 'INVITE_EXPIRED'
    finally:
        engine.dispose()
