from __future__ import annotations

from collections.abc import Callable
from datetime import datetime, timedelta, timezone
import hashlib
import secrets
from typing import Any
from urllib.parse import parse_qs, urlparse

from sqlalchemy import and_, delete, func, or_, select
from sqlalchemy.orm import Session

from app.db.models import (
    FriendRequest,
    Friendship,
    StudyRoom,
    StudyRoomInvite,
    StudyRoomMember,
    User,
    UserBlock,
    UserCommunityProfile,
)
from app.services.eduskills_adapter import normalize_subject_code

VALID_STUDY_LEVELS = {'beginner', 'basic', 'exam_prep', 'challenge'}
OPEN_ROOM_STATUSES = ('waiting', 'active')
TERMINAL_ROOM_STATUSES = ('closed', 'expired', 'ended')
MEMBER_HEARTBEAT_TIMEOUT = timedelta(seconds=90)
EMPTY_ROOM_TTL = timedelta(seconds=120)
DEFAULT_ROOM_TTL_MINUTES = 240

LEVEL_LABEL_VI = {
    'beginner': 'Mới bắt đầu',
    'basic': 'Cơ bản',
    'exam_prep': 'Đang ôn thi',
    'challenge': 'Thử thách cao',
}


class CommunityServiceError(Exception):
    def __init__(self, status_code: int, code: str, message_vi: str) -> None:
        super().__init__(message_vi)
        self.status_code = status_code
        self.code = code
        self.message_vi = message_vi


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _iso(dt: datetime | None) -> str | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.isoformat().replace('+00:00', 'Z')


def _canonical_pair(uid_1: str, uid_2: str) -> tuple[str, str]:
    return (uid_1, uid_2) if uid_1 < uid_2 else (uid_2, uid_1)


def normalize_study_level(raw: str | None) -> str:
    clean = (raw or 'basic').strip().lower()
    return clean if clean in VALID_STUDY_LEVELS else 'basic'


def _ensure_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _extract_raw_invite_token(raw_input: str) -> str:
    clean = raw_input.strip()
    if clean.startswith('http://') or clean.startswith('https://'):
        parsed = urlparse(clean)
        qs = parse_qs(parsed.query)
        for key in ('invite', 'token'):
            if key in qs and qs[key]:
                return qs[key][0].strip()
    return clean


def _hash_invite_token(raw_token: str) -> str:
    extracted = _extract_raw_invite_token(raw_token)
    return hashlib.sha256(extracted.encode('utf-8')).hexdigest()


class CommunityService:
    """Xử lý hồ sơ công khai, kết bạn, chặn và vòng đời phòng học cộng đồng (T058/T094)."""

    def __init__(
        self,
        db: Session,
        *,
        now_provider: Callable[[], datetime] = _utc_now,
        member_heartbeat_timeout: timedelta = MEMBER_HEARTBEAT_TIMEOUT,
        empty_room_ttl: timedelta = EMPTY_ROOM_TTL,
    ) -> None:
        self._db = db
        self._now = now_provider
        self._member_heartbeat_timeout = member_heartbeat_timeout
        self._empty_room_ttl = empty_room_ttl

    def _revoke_open_invites(self, room_id: str, now: datetime) -> None:
        open_invites = list(
            self._db.scalars(
                select(StudyRoomInvite).where(
                    StudyRoomInvite.room_id == room_id,
                    StudyRoomInvite.revoked_at.is_(None),
                )
            )
        )
        for inv in open_invites:
            inv.revoked_at = now

    def _transition_room_closing_to_terminal(
        self,
        room: StudyRoom,
        *,
        terminal_status: str,
        now: datetime,
    ) -> None:
        room.status = 'closing'
        active_members = list(
            self._db.scalars(
                select(StudyRoomMember).where(
                    StudyRoomMember.room_id == room.id,
                    StudyRoomMember.left_at.is_(None),
                )
            )
        )
        for m in active_members:
            m.left_at = now
            m.mic_enabled = False
            m.cam_enabled = False
        self._revoke_open_invites(room.id, now)
        room.status = terminal_status
        room.closed_at = now
        room.updated_at = now

    def _reconcile_room_locked(
        self,
        room: StudyRoom,
        now: datetime,
    ) -> tuple[bool, bool]:
        """Kiểm tra TTL phòng & heartbeat thành viên dưới khóa row.

        Trả về `(terminated, host_transferred)`. Phòng còn thành viên hợp lệ và
        chưa quá `expires_at` tuyệt đối không bị đóng hay xóa.
        """
        if room.status not in OPEN_ROOM_STATUSES:
            return (False, False)

        exp = _ensure_utc(room.expires_at)
        if exp is not None and exp <= now:
            self._transition_room_closing_to_terminal(
                room, terminal_status='expired', now=now
            )
            return (True, False)

        active_members = list(
            self._db.scalars(
                select(StudyRoomMember)
                .where(
                    StudyRoomMember.room_id == room.id,
                    StudyRoomMember.left_at.is_(None),
                )
                .order_by(StudyRoomMember.joined_at.asc(), StudyRoomMember.id.asc())
            )
        )
        cutoff = now - self._member_heartbeat_timeout
        disconnected_any = False
        for m in active_members:
            hb = _ensure_utc(m.last_heartbeat_at) or _ensure_utc(m.joined_at)
            if hb is not None and hb <= cutoff:
                m.left_at = now
                m.mic_enabled = False
                m.cam_enabled = False
                m.status_note = 'Mất kết nối'
                disconnected_any = True

        if disconnected_any:
            self._db.flush()

        remaining = [m for m in active_members if m.left_at is None]
        if not remaining:
            last_hb = _ensure_utc(room.last_heartbeat_at) or _ensure_utc(room.created_at)
            if disconnected_any or (
                last_hb is not None and (last_hb + self._empty_room_ttl) <= now
            ):
                self._transition_room_closing_to_terminal(
                    room, terminal_status='expired', now=now
                )
                return (True, False)
            room.status = 'waiting'
            return (False, False)

        host_transferred = False
        remaining_ids = {m.user_id for m in remaining}
        if room.owner_id not in remaining_ids:
            new_host = remaining[0]
            new_host.role = 'host'
            room.owner_id = new_host.user_id
            host_transferred = True

        next_status = 'active' if len(remaining) >= 2 else 'waiting'
        if room.status != next_status:
            room.status = next_status
        return (False, host_transferred)

    def sweep_stale_rooms(self, *, now: datetime | None = None) -> dict[str, int]:
        effective_now = _ensure_utc(now) or self._now()
        rooms = list(
            self._db.scalars(
                select(StudyRoom)
                .where(StudyRoom.status.in_(OPEN_ROOM_STATUSES))
                .order_by(StudyRoom.id.asc())
                .with_for_update()
            )
        )
        terminated_count = 0
        transferred_count = 0
        for r in rooms:
            terminated, transferred = self._reconcile_room_locked(r, effective_now)
            if terminated:
                terminated_count += 1
            if transferred:
                transferred_count += 1
        if rooms:
            self._db.commit()
        return {
            'inspected': len(rooms),
            'closedOrExpired': terminated_count,
            'hostTransferred': transferred_count,
        }

    def _blocked_ids_for(self, user_id: str) -> set[str]:
        rows = self._db.execute(
            select(UserBlock.blocker_id, UserBlock.blocked_id).where(
                or_(UserBlock.blocker_id == user_id, UserBlock.blocked_id == user_id)
            )
        ).all()
        blocked: set[str] = set()
        for blocker_id, blocked_id in rows:
            blocked.add(blocked_id if blocker_id == user_id else blocker_id)
        return blocked

    def _is_blocked_pair(self, uid_a: str, uid_b: str) -> bool:
        existing = self._db.scalar(
            select(UserBlock.id).where(
                or_(
                    and_(UserBlock.blocker_id == uid_a, UserBlock.blocked_id == uid_b),
                    and_(UserBlock.blocker_id == uid_b, UserBlock.blocked_id == uid_a),
                )
            )
        )
        return existing is not None

    def _friend_ids_for(self, user_id: str) -> set[str]:
        rows = self._db.execute(
            select(Friendship.user_a_id, Friendship.user_b_id).where(
                or_(Friendship.user_a_id == user_id, Friendship.user_b_id == user_id)
            )
        ).all()
        return {b if a == user_id else a for a, b in rows}

    def _pending_requests_map(self, viewer_id: str, target_ids: list[str]) -> dict[str, tuple[str, str]]:
        if not target_ids:
            return {}
        rows = self._db.scalars(
            select(FriendRequest).where(
                FriendRequest.status == 'pending',
                or_(
                    and_(
                        FriendRequest.sender_id == viewer_id,
                        FriendRequest.receiver_id.in_(target_ids),
                    ),
                    and_(
                        FriendRequest.receiver_id == viewer_id,
                        FriendRequest.sender_id.in_(target_ids),
                    ),
                ),
            )
        ).all()
        mapping: dict[str, tuple[str, str]] = {}
        for req in rows:
            if req.sender_id == viewer_id:
                mapping[req.receiver_id] = ('outgoing_pending', req.id)
            else:
                mapping[req.sender_id] = ('incoming_pending', req.id)
        return mapping

    def _community_profiles_map(self, user_ids: list[str]) -> dict[str, UserCommunityProfile]:
        if not user_ids:
            return {}
        rows = self._db.scalars(
            select(UserCommunityProfile).where(UserCommunityProfile.user_id.in_(set(user_ids)))
        ).all()
        return {row.user_id: row for row in rows}

    def get_or_create_profile_meta(self, user_id: str) -> UserCommunityProfile:
        meta = self._db.get(UserCommunityProfile, user_id)
        if meta is None:
            meta = UserCommunityProfile(user_id=user_id, avatar_id='avatar_sunrise', study_level='basic')
            self._db.add(meta)
            self._db.flush()
        return meta

    def _to_public_profile(
        self,
        viewer_id: str,
        target: User,
        *,
        meta: UserCommunityProfile | None,
        friend_ids: set[str],
        pending_map: dict[str, tuple[str, str]],
    ) -> dict[str, Any]:
        if target.id == viewer_id:
            relation = 'self'
            req_id = None
        elif target.id in friend_ids:
            relation = 'friends'
            req_id = None
        elif target.id in pending_map:
            relation, req_id = pending_map[target.id]
        else:
            relation = 'none'
            req_id = None
        level = normalize_study_level(meta.study_level if meta else 'basic')
        avatar_id = (meta.avatar_id if meta else None) or 'avatar_sunrise'
        # Tuyệt đối không đưa email, auth_subject, alarms hay timetable chi tiết vào projection công khai.
        return {
            'userId': target.id,
            'alias': target.alias,
            'avatarId': avatar_id,
            'gradeLevel': target.grade_band,
            'selectedSubjects': list(target.selected_subjects_json or []),
            'goalLabel': target.goal_label,
            'studyLevel': level,
            'studyLevelLabelVi': LEVEL_LABEL_VI.get(level, 'Cơ bản'),
            'friendStatus': relation,
            'pendingRequestId': req_id,
        }

    def get_public_profile(self, viewer_id: str, target_user_id: str) -> dict[str, Any]:
        target = self._db.get(User, target_user_id)
        if target is None:
            raise CommunityServiceError(404, 'USER_NOT_FOUND', 'Không tìm thấy hồ sơ học sinh.')
        if viewer_id != target.id and self._is_blocked_pair(viewer_id, target.id):
            raise CommunityServiceError(403, 'USER_BLOCKED', 'Không thể xem hồ sơ người dùng này.')
        friend_ids = self._friend_ids_for(viewer_id)
        pending_map = self._pending_requests_map(viewer_id, [target.id])
        metas = self._community_profiles_map([target.id])
        return self._to_public_profile(
            viewer_id,
            target,
            meta=metas.get(target.id),
            friend_ids=friend_ids,
            pending_map=pending_map,
        )

    def search_users(
        self,
        viewer_id: str,
        *,
        query: str = '',
        grade_level: str | None = None,
        subject_code: str | None = None,
        limit: int = 20,
    ) -> list[dict[str, Any]]:
        blocked = self._blocked_ids_for(viewer_id)
        stmt = select(User).where(User.id != viewer_id)
        if blocked:
            stmt = stmt.where(~User.id.in_(blocked))
        clean_q = query.strip().lower()
        if clean_q:
            stmt = stmt.where(func.lower(User.alias).contains(clean_q))
        if grade_level and grade_level.strip():
            stmt = stmt.where(User.grade_band == grade_level.strip())
        candidates = list(self._db.scalars(stmt.order_by(User.updated_at.desc()).limit(60)))

        norm_subject = normalize_subject_code(subject_code) if subject_code and subject_code.strip() else None
        filtered: list[User] = []
        for u in candidates:
            subjects = {normalize_subject_code(s) for s in (u.selected_subjects_json or [])}
            if norm_subject and norm_subject not in subjects:
                continue
            filtered.append(u)
            if len(filtered) >= min(limit, 50):
                break

        uids = [u.id for u in filtered]
        friend_ids = self._friend_ids_for(viewer_id)
        pending_map = self._pending_requests_map(viewer_id, uids)
        metas = self._community_profiles_map(uids)
        return [
            self._to_public_profile(
                viewer_id,
                u,
                meta=metas.get(u.id),
                friend_ids=friend_ids,
                pending_map=pending_map,
            )
            for u in filtered
        ]

    def send_friend_request(
        self,
        sender_id: str,
        receiver_user_id: str,
        message_vi: str = '',
    ) -> dict[str, Any]:
        if sender_id == receiver_user_id:
            raise CommunityServiceError(400, 'SELF_FRIEND_INVALID', 'Không thể tự gửi lời mời cho chính mình.')
        receiver = self._db.get(User, receiver_user_id)
        if receiver is None:
            raise CommunityServiceError(404, 'USER_NOT_FOUND', 'Không tìm thấy học sinh để kết bạn.')
        if self._is_blocked_pair(sender_id, receiver_user_id):
            raise CommunityServiceError(403, 'USER_BLOCKED', 'Không thể kết bạn do có thiết lập chặn.')

        a, b = _canonical_pair(sender_id, receiver_user_id)
        already_friend = self._db.scalar(
            select(Friendship).where(Friendship.user_a_id == a, Friendship.user_b_id == b)
        )
        if already_friend is not None:
            return {
                'requestId': None,
                'status': 'accepted',
                'receiverUserId': receiver_user_id,
            }

        reverse = self._db.scalar(
            select(FriendRequest).where(
                FriendRequest.sender_id == receiver_user_id,
                FriendRequest.receiver_id == sender_id,
                FriendRequest.status == 'pending',
            )
        )
        if reverse is not None:
            return self.respond_friend_request(sender_id, reverse.id, 'accept')

        existing = self._db.scalar(
            select(FriendRequest).where(
                FriendRequest.sender_id == sender_id,
                FriendRequest.receiver_id == receiver_user_id,
            )
        )
        clean_msg = message_vi.strip()[:160] or 'Cùng ôn thi trên MindClock nhé!'
        if existing is not None:
            existing.status = 'pending'
            existing.message_vi = clean_msg
            existing.updated_at = _utc_now()
            req = existing
        else:
            req = FriendRequest(
                sender_id=sender_id,
                receiver_id=receiver_user_id,
                status='pending',
                message_vi=clean_msg,
            )
            self._db.add(req)
        self._db.commit()
        self._db.refresh(req)
        return {
            'requestId': req.id,
            'status': req.status,
            'senderUserId': req.sender_id,
            'receiverUserId': req.receiver_id,
            'messageVi': req.message_vi,
            'createdAt': _iso(req.created_at),
        }

    def list_friend_requests(self, user_id: str) -> dict[str, Any]:
        rows = list(
            self._db.scalars(
                select(FriendRequest)
                .where(
                    FriendRequest.status == 'pending',
                    or_(FriendRequest.sender_id == user_id, FriendRequest.receiver_id == user_id),
                )
                .order_by(FriendRequest.created_at.desc())
            )
        )
        other_ids = list({r.sender_id if r.receiver_id == user_id else r.receiver_id for r in rows})
        users = {
            u.id: u
            for u in self._db.scalars(select(User).where(User.id.in_(other_ids))).all()
        } if other_ids else {}
        friend_ids = self._friend_ids_for(user_id)
        metas = self._community_profiles_map(other_ids)

        incoming: list[dict[str, Any]] = []
        outgoing: list[dict[str, Any]] = []
        for req in rows:
            other_id = req.sender_id if req.receiver_id == user_id else req.receiver_id
            other = users.get(other_id)
            if other is None:
                continue
            item = {
                'requestId': req.id,
                'status': req.status,
                'messageVi': req.message_vi,
                'createdAt': _iso(req.created_at),
                'peer': self._to_public_profile(
                    user_id,
                    other,
                    meta=metas.get(other.id),
                    friend_ids=friend_ids,
                    pending_map={},
                ),
            }
            if req.receiver_id == user_id:
                incoming.append(item)
            else:
                outgoing.append(item)
        return {'incoming': incoming, 'outgoing': outgoing}

    def respond_friend_request(
        self,
        actor_id: str,
        request_id: str,
        decision: str,
    ) -> dict[str, Any]:
        req = self._db.scalar(select(FriendRequest).where(
            FriendRequest.id == request_id).with_for_update())
        if req is None:
            raise CommunityServiceError(404, 'REQUEST_NOT_FOUND', 'Không tìm thấy lời mời kết bạn.')

        if decision == 'cancel':
            if req.sender_id != actor_id:
                raise CommunityServiceError(403, 'FORBIDDEN', 'Bạn không phải người gửi lời mời này.')
            if req.status == 'cancelled':
                return {'requestId': req.id, 'status': req.status}
            if req.status != 'pending':
                raise CommunityServiceError(409, 'REQUEST_CLOSED', 'Lời mời đã được xử lý.')
            req.status = 'cancelled'
            self._db.commit()
            return {'requestId': req.id, 'status': 'cancelled'}

        if req.receiver_id != actor_id:
            raise CommunityServiceError(403, 'FORBIDDEN', 'Bạn không phải người nhận lời mời này.')

        if self._is_blocked_pair(req.sender_id, req.receiver_id):
            raise CommunityServiceError(403, 'USER_BLOCKED', 'Không thể xử lý lời mời do có thiết lập chặn.')
        if (req.status == 'accepted' and decision == 'accept') or (req.status == 'declined' and decision == 'decline'):
            return {'requestId': req.id, 'status': req.status}
        if req.status != 'pending':
            raise CommunityServiceError(409, 'REQUEST_CLOSED', 'Lời mời đã được xử lý.')

        if decision == 'decline':
            req.status = 'declined'
            self._db.commit()
            return {'requestId': req.id, 'status': 'declined'}

        req.status = 'accepted'
        a, b = _canonical_pair(req.sender_id, req.receiver_id)
        exists = self._db.scalar(
            select(Friendship).where(Friendship.user_a_id == a, Friendship.user_b_id == b)
        )
        if exists is None:
            self._db.add(Friendship(user_a_id=a, user_b_id=b))
        self._db.commit()
        return {'requestId': req.id, 'status': 'accepted'}

    def list_friends(self, user_id: str) -> list[dict[str, Any]]:
        blocked = self._blocked_ids_for(user_id)
        friend_ids = [fid for fid in self._friend_ids_for(user_id) if fid not in blocked]
        if not friend_ids:
            return []
        peers = list(
            self._db.scalars(select(User).where(User.id.in_(friend_ids)).order_by(User.alias.asc()))
        )
        friend_set = set(friend_ids)
        metas = self._community_profiles_map(friend_ids)
        return [
            self._to_public_profile(
                user_id,
                peer,
                meta=metas.get(peer.id),
                friend_ids=friend_set,
                pending_map={},
            )
            for peer in peers
        ]

    def block_user(self, blocker_id: str, blocked_user_id: str, reason: str = '') -> dict[str, Any]:
        if blocker_id == blocked_user_id:
            raise CommunityServiceError(400, 'SELF_BLOCK_INVALID', 'Không thể tự chặn chính mình.')
        target = self._db.get(User, blocked_user_id)
        if target is None:
            raise CommunityServiceError(404, 'USER_NOT_FOUND', 'Không tìm thấy người dùng.')
        existing = self._db.scalar(
            select(UserBlock).where(
                UserBlock.blocker_id == blocker_id,
                UserBlock.blocked_id == blocked_user_id,
            )
        )
        if existing is None:
            self._db.add(
                UserBlock(
                    blocker_id=blocker_id,
                    blocked_id=blocked_user_id,
                    reason=reason.strip()[:120],
                )
            )
        a, b = _canonical_pair(blocker_id, blocked_user_id)
        self._db.execute(
            delete(Friendship).where(Friendship.user_a_id == a, Friendship.user_b_id == b)
        )
        self._db.execute(
            delete(FriendRequest).where(
                or_(
                    and_(
                        FriendRequest.sender_id == blocker_id,
                        FriendRequest.receiver_id == blocked_user_id,
                    ),
                    and_(
                        FriendRequest.sender_id == blocked_user_id,
                        FriendRequest.receiver_id == blocker_id,
                    ),
                )
            )
        )
        self._db.commit()
        return {'blockedUserId': blocked_user_id, 'status': 'blocked'}

    def _serialize_room_summary(
        self,
        room: StudyRoom,
        *,
        owner: User | None,
        owner_meta: UserCommunityProfile | None,
        member_count: int,
        match_score: int | None = None,
        match_reason_vi: str | None = None,
    ) -> dict[str, Any]:
        level = normalize_study_level(room.target_level)
        data: dict[str, Any] = {
            'roomId': room.id,
            'roomCode': room.room_code,
            'ownerUserId': room.owner_id,
            'title': room.title,
            'subjectCode': room.subject_code,
            'gradeLevel': room.grade_band,
            'targetLevel': level,
            'targetLevelLabelVi': LEVEL_LABEL_VI.get(level, 'Cơ bản'),
            'visibility': room.visibility,
            'maxMembers': room.max_members,
            'memberCount': member_count,
            'aiCompanionEnabled': room.ai_companion_enabled,
            'status': room.status,
            'ownerAlias': owner.alias if owner else 'Trưởng nhóm MindClock',
            'ownerAvatarId': (owner_meta.avatar_id if owner_meta else None) or 'avatar_sunrise',
            'createdAt': _iso(room.created_at),
            'expiresAt': _iso(room.expires_at),
            'lastHeartbeatAt': _iso(room.last_heartbeat_at),
            'closedAt': _iso(room.closed_at),
        }
        if match_score is not None:
            data['matchScore'] = match_score
        if match_reason_vi is not None:
            data['matchReasonVi'] = match_reason_vi
        return data

    def _serialize_room_detail(self, viewer_id: str, room: StudyRoom) -> dict[str, Any]:
        members = list(
            self._db.scalars(
                select(StudyRoomMember)
                .where(StudyRoomMember.room_id == room.id, StudyRoomMember.left_at.is_(None))
                .order_by(StudyRoomMember.joined_at.asc())
            )
        )
        user_ids = list({m.user_id for m in members} | {room.owner_id})
        users = {
            u.id: u for u in self._db.scalars(select(User).where(User.id.in_(user_ids))).all()
        } if user_ids else {}
        metas = self._community_profiles_map(user_ids)
        owner = users.get(room.owner_id)
        summary = self._serialize_room_summary(
            room,
            owner=owner,
            owner_meta=metas.get(room.owner_id),
            member_count=len(members),
        )
        summary['members'] = [
            {
                'userId': m.user_id,
                'alias': users[m.user_id].alias if m.user_id in users else 'Thành viên',
                'avatarId': (
                    (metas[m.user_id].avatar_id if m.user_id in metas else None)
                    or 'avatar_sunrise'
                ),
                'gradeLevel': users[m.user_id].grade_band if m.user_id in users else room.grade_band,
                'role': m.role,
                'micEnabled': m.mic_enabled,
                'camEnabled': m.cam_enabled,
                'statusNote': m.status_note,
                'isSelf': m.user_id == viewer_id,
            }
            for m in members
        ]
        return summary

    def _active_member_counts(self, room_ids: list[str]) -> dict[str, int]:
        if not room_ids:
            return {}
        rows = self._db.execute(
            select(StudyRoomMember.room_id, func.count(StudyRoomMember.id))
            .where(StudyRoomMember.room_id.in_(room_ids), StudyRoomMember.left_at.is_(None))
            .group_by(StudyRoomMember.room_id)
        ).all()
        return {rid: int(cnt) for rid, cnt in rows}

    def list_public_rooms(
        self,
        viewer_id: str,
        *,
        grade_level: str | None = None,
        subject_code: str | None = None,
    ) -> list[dict[str, Any]]:
        self.sweep_stale_rooms()
        blocked = self._blocked_ids_for(viewer_id)
        stmt = select(StudyRoom).where(
            StudyRoom.status.in_(OPEN_ROOM_STATUSES),
            StudyRoom.visibility == 'public',
        )
        if blocked:
            stmt = stmt.where(~StudyRoom.owner_id.in_(blocked))
        if grade_level and grade_level.strip():
            stmt = stmt.where(StudyRoom.grade_band == grade_level.strip())
        if subject_code and subject_code.strip():
            stmt = stmt.where(StudyRoom.subject_code == normalize_subject_code(subject_code))
        rooms = list(self._db.scalars(stmt.order_by(StudyRoom.updated_at.desc()).limit(30)))
        if not rooms:
            return []
        room_ids = [r.id for r in rooms]
        owner_ids = list({r.owner_id for r in rooms})
        counts = self._active_member_counts(room_ids)
        owners = {
            u.id: u for u in self._db.scalars(select(User).where(User.id.in_(owner_ids))).all()
        }
        metas = self._community_profiles_map(owner_ids)
        return [
            self._serialize_room_summary(
                r,
                owner=owners.get(r.owner_id),
                owner_meta=metas.get(r.owner_id),
                member_count=counts.get(r.id, 0),
            )
            for r in rooms
        ]

    def create_room(
        self,
        owner: User,
        *,
        title: str,
        subject_code: str,
        grade_band: str,
        target_level: str,
        visibility: str,
        max_members: int,
        ai_companion_enabled: bool,
        ttl_minutes: int = DEFAULT_ROOM_TTL_MINUTES,
    ) -> dict[str, Any]:
        now = self._now()
        room_code = secrets.token_hex(3).upper()
        while self._db.scalar(select(StudyRoom.id).where(StudyRoom.room_code == room_code)) is not None:
            room_code = secrets.token_hex(3).upper()

        clamped_ttl = max(5, min(int(ttl_minutes), 720))
        room = StudyRoom(
            owner_id=owner.id,
            room_code=room_code,
            title=title.strip()[:80],
            subject_code=normalize_subject_code(subject_code),
            grade_band=grade_band.strip()[:40],
            target_level=normalize_study_level(target_level),
            visibility=visibility,
            max_members=max_members,
            ai_companion_enabled=ai_companion_enabled,
            status='waiting',
            created_at=now,
            updated_at=now,
            last_heartbeat_at=now,
            expires_at=now + timedelta(minutes=clamped_ttl),
        )
        self._db.add(room)
        self._db.flush()
        # Mic & Camera luôn tắt mặc định khi vào phòng (AGENTS.md §3).
        self._db.add(
            StudyRoomMember(
                room_id=room.id,
                user_id=owner.id,
                role='host',
                mic_enabled=False,
                cam_enabled=False,
                status_note='Trưởng phòng đang tập trung',
                joined_at=now,
                last_heartbeat_at=now,
            )
        )
        self._db.commit()
        self._db.refresh(room)
        return self._serialize_room_detail(owner.id, room)

    def join_room(
        self,
        user_id: str,
        room_id: str,
        *,
        room_code: str | None = None,
        invite_token: str | None = None,
        mic_enabled: bool = False,
        cam_enabled: bool = False,
        status_note: str = 'Đang tập trung',
    ) -> dict[str, Any]:
        if invite_token and invite_token.strip():
            return self.redeem_room_invite(
                user_id,
                invite_token,
                status_note=status_note,
            )
        now = self._now()
        room = self._db.scalar(select(StudyRoom).where(
            StudyRoom.id == room_id).with_for_update())
        if room is None:
            clean_code = (room_code or room_id).strip().upper()
            room = self._db.scalar(select(StudyRoom).where(
                StudyRoom.room_code == clean_code).with_for_update())
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES:
            self._db.commit()
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại hoặc đã kết thúc.')
        if self._is_blocked_pair(user_id, room.owner_id):
            raise CommunityServiceError(403, 'USER_BLOCKED', 'Bạn không thể tham gia phòng học này.')
        if room.visibility == 'invite_only' and room.owner_id != user_id:
            clean = (room_code or '').strip().upper()
            if clean != room.room_code:
                raise CommunityServiceError(403, 'ROOM_INVITE_REQUIRED', 'Phòng chỉ mời yêu cầu mã mời hợp lệ.')

        existing = self._db.scalar(
            select(StudyRoomMember).where(
                StudyRoomMember.room_id == room.id,
                StudyRoomMember.user_id == user_id,
            )
        )
        if existing is not None and existing.role == 'removed':
            raise CommunityServiceError(
                403,
                'ROOM_REMOVED_BY_HOST',
                'Bạn đã được chủ phòng mời ra khỏi phòng này.',
            )
        active_count = self._active_member_counts([room.id]).get(room.id, 0)
        is_joining_seat = existing is None or existing.left_at is not None
        if is_joining_seat and active_count >= room.max_members:
            raise CommunityServiceError(409, 'ROOM_FULL', 'Phòng học đã đủ số lượng thành viên.')

        if existing is None:
            self._db.add(
                StudyRoomMember(
                    room_id=room.id,
                    user_id=user_id,
                    role='host' if room.owner_id == user_id else 'member',
                    mic_enabled=bool(mic_enabled),
                    cam_enabled=bool(cam_enabled),
                    status_note=status_note.strip()[:80] or 'Đang tập trung',
                    joined_at=now,
                    last_heartbeat_at=now,
                )
            )
            next_count = active_count + 1
        else:
            existing.left_at = None
            existing.mic_enabled = bool(mic_enabled)
            existing.cam_enabled = bool(cam_enabled)
            existing.status_note = status_note.strip()[:80] or existing.status_note
            if is_joining_seat:
                existing.joined_at = now
                next_count = active_count + 1
            else:
                next_count = active_count
            existing.last_heartbeat_at = now
        room.last_heartbeat_at = now
        room.status = 'active' if next_count >= 2 else 'waiting'
        self._db.commit()
        return self._serialize_room_detail(user_id, room)

    def get_room_detail(self, user_id: str, room_id: str) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES:
            self._db.commit()
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại hoặc đã đóng.')
        if self._is_blocked_pair(user_id, room.owner_id):
            raise CommunityServiceError(403, 'USER_BLOCKED', 'Không có quyền xem phòng này.')
        member = self._db.scalar(
            select(StudyRoomMember).where(
                StudyRoomMember.room_id == room.id,
                StudyRoomMember.user_id == user_id,
                StudyRoomMember.left_at.is_(None),
            )
        )
        if room.visibility == 'invite_only' and member is None and room.owner_id != user_id:
            raise CommunityServiceError(403, 'ROOM_INVITE_REQUIRED', 'Chỉ thành viên phòng mới xem được.')
        if member is not None:
            member.last_heartbeat_at = now
            room.last_heartbeat_at = now
        self._db.commit()
        return self._serialize_room_detail(user_id, room)

    def heartbeat_room(
        self,
        user_id: str,
        room_id: str,
        *,
        status_note: str | None = None,
    ) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES:
            self._db.commit()
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học đã đóng hoặc hết hạn.')
        member = self._db.scalar(
            select(StudyRoomMember).where(
                StudyRoomMember.room_id == room.id,
                StudyRoomMember.user_id == user_id,
                StudyRoomMember.left_at.is_(None),
            )
        )
        if member is None:
            raise CommunityServiceError(403, 'NOT_ROOM_MEMBER', 'Bạn không còn là thành viên phòng này.')
        member.last_heartbeat_at = now
        if status_note is not None and status_note.strip():
            member.status_note = status_note.strip()[:80]
        room.last_heartbeat_at = now
        self._db.commit()
        return self._serialize_room_detail(user_id, room)

    def close_room(self, owner_id: str, room_id: str) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is None:
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại.')
        if room.owner_id != owner_id:
            raise CommunityServiceError(403, 'HOST_REQUIRED', 'Chỉ chủ phòng được kết thúc phòng.')
        if room.status in OPEN_ROOM_STATUSES:
            self._transition_room_closing_to_terminal(
                room, terminal_status='closed', now=now
            )
            self._db.commit()
        return {
            'roomId': room.id,
            'status': room.status,
            'closedAt': _iso(room.closed_at),
        }

    def create_room_invite(
        self,
        owner_id: str,
        room_id: str,
        *,
        ttl_minutes: int = 30,
        max_uses: int = 8,
    ) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES:
            self._db.commit()
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học đã đóng hoặc không tồn tại.')
        if room.owner_id != owner_id:
            raise CommunityServiceError(403, 'HOST_REQUIRED', 'Chỉ chủ phòng được tạo mã mời.')

        clamped_ttl = max(1, min(int(ttl_minutes), 240))
        clamped_uses = max(1, min(int(max_uses), 32))
        raw_token = secrets.token_urlsafe(24)
        token_hash = _hash_invite_token(raw_token)
        while self._db.scalar(
            select(StudyRoomInvite.id).where(StudyRoomInvite.token_hash == token_hash)
        ) is not None:
            raw_token = secrets.token_urlsafe(24)
            token_hash = _hash_invite_token(raw_token)

        inv = StudyRoomInvite(
            room_id=room.id,
            created_by_user_id=owner_id,
            token_hash=token_hash,
            expires_at=now + timedelta(minutes=clamped_ttl),
            max_uses=clamped_uses,
            use_count=0,
            created_at=now,
        )
        self._db.add(inv)
        room.last_heartbeat_at = now
        self._db.commit()
        self._db.refresh(inv)
        # Link/QR chỉ chứa opaque token ngẫu nhiên, tuyệt đối không chứa email/alias/TKB/giờ báo thức.
        invite_link = f'https://mindclock.app/study-rooms/join?invite={raw_token}'
        return {
            'inviteId': inv.id,
            'roomId': room.id,
            'inviteToken': raw_token,
            'inviteLink': invite_link,
            'qrPayload': invite_link,
            'expiresAt': _iso(inv.expires_at),
            'maxUses': inv.max_uses,
            'useCount': inv.use_count,
            'revoked': False,
        }

    def revoke_room_invite(
        self,
        owner_id: str,
        room_id: str,
        invite_id: str,
    ) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is None:
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại.')
        if room.owner_id != owner_id:
            raise CommunityServiceError(403, 'HOST_REQUIRED', 'Chỉ chủ phòng được thu hồi mã mời.')
        inv = self._db.scalar(
            select(StudyRoomInvite)
            .where(StudyRoomInvite.id == invite_id, StudyRoomInvite.room_id == room.id)
            .with_for_update()
        )
        if inv is None:
            raise CommunityServiceError(404, 'INVITE_NOT_FOUND', 'Không tìm thấy link mời.')
        if inv.revoked_at is None:
            inv.revoked_at = now
            self._db.commit()
        return {
            'inviteId': inv.id,
            'roomId': room.id,
            'revoked': True,
            'revokedAt': _iso(inv.revoked_at),
        }

    def redeem_room_invite(
        self,
        user_id: str,
        invite_token: str,
        *,
        status_note: str = 'Đang tập trung',
    ) -> dict[str, Any]:
        now = self._now()
        token_hash = _hash_invite_token(invite_token)
        inv_lookup = self._db.scalar(
            select(StudyRoomInvite).where(StudyRoomInvite.token_hash == token_hash)
        )
        if inv_lookup is None:
            raise CommunityServiceError(404, 'INVITE_NOT_FOUND', 'Link mời không hợp lệ.')
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == inv_lookup.room_id).with_for_update()
        )
        inv = self._db.scalar(
            select(StudyRoomInvite).where(StudyRoomInvite.id == inv_lookup.id).with_for_update()
        )
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES or inv is None:
            self._db.commit()
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học đã đóng hoặc hết hạn.')
        if inv.revoked_at is not None:
            raise CommunityServiceError(410, 'INVITE_REVOKED', 'Link mời này đã bị thu hồi.')
        if (_ensure_utc(inv.expires_at) or now) <= now:
            raise CommunityServiceError(410, 'INVITE_EXPIRED', 'Link mời đã hết hạn.')
        if self._is_blocked_pair(user_id, room.owner_id):
            raise CommunityServiceError(403, 'USER_BLOCKED', 'Bạn không thể tham gia phòng học này.')

        existing = self._db.scalar(
            select(StudyRoomMember).where(
                StudyRoomMember.room_id == room.id,
                StudyRoomMember.user_id == user_id,
            )
        )
        if existing is not None and existing.role == 'removed':
            raise CommunityServiceError(
                403, 'ROOM_REMOVED_BY_HOST', 'Bạn đã được chủ phòng mời ra khỏi phòng này.'
            )
        if existing is not None and existing.left_at is None:
            existing.last_heartbeat_at = now
            room.last_heartbeat_at = now
            self._db.commit()
            return self._serialize_room_detail(user_id, room)

        if inv.use_count >= inv.max_uses:
            raise CommunityServiceError(
                409, 'INVITE_MAX_USES_REACHED', 'Link mời đã đạt giới hạn lượt tham gia.'
            )
        active_count = self._active_member_counts([room.id]).get(room.id, 0)
        if active_count >= room.max_members:
            raise CommunityServiceError(409, 'ROOM_FULL', 'Phòng học đã đủ số lượng thành viên.')

        inv.use_count += 1
        if existing is None:
            self._db.add(
                StudyRoomMember(
                    room_id=room.id,
                    user_id=user_id,
                    role='host' if room.owner_id == user_id else 'member',
                    mic_enabled=False,
                    cam_enabled=False,
                    status_note=status_note.strip()[:80] or 'Đang tập trung',
                    joined_at=now,
                    last_heartbeat_at=now,
                )
            )
        else:
            existing.left_at = None
            existing.mic_enabled = False
            existing.cam_enabled = False
            existing.status_note = status_note.strip()[:80] or 'Đang tập trung'
            existing.joined_at = now
            existing.last_heartbeat_at = now
        next_count = active_count + 1
        room.last_heartbeat_at = now
        room.status = 'active' if next_count >= 2 else 'waiting'
        self._db.commit()
        return self._serialize_room_detail(user_id, room)

    def update_room_settings(
        self, user_id: str, room_id: str, *, title: str | None = None,
        max_members: int | None = None, visibility: str | None = None,
        ai_companion_enabled: bool | None = None,
    ) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(select(StudyRoom).where(
            StudyRoom.id == room_id).with_for_update())
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES:
            self._db.commit()
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học đã đóng hoặc không tồn tại.')
        if room.owner_id != user_id:
            raise CommunityServiceError(403, 'HOST_REQUIRED', 'Chỉ chủ phòng được sửa cài đặt.')
        if max_members is not None:
            count = self._active_member_counts([room.id]).get(room.id, 0)
            if max_members < count:
                raise CommunityServiceError(409, 'CAPACITY_BELOW_MEMBERS',
                    'Giới hạn mới thấp hơn số người đang trong phòng.')
            room.max_members = max_members
        if title is not None:
            room.title = title
        if visibility is not None:
            room.visibility = visibility
        if ai_companion_enabled is not None:
            room.ai_companion_enabled = ai_companion_enabled
        room.last_heartbeat_at = now
        self._db.commit()
        return self._serialize_room_detail(user_id, room)

    def update_room_media(
        self,
        user_id: str,
        room_id: str,
        *,
        mic_enabled: bool | None = None,
        cam_enabled: bool | None = None,
        ai_companion_enabled: bool | None = None,
        status_note: str | None = None,
    ) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES:
            self._db.commit()
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại.')
        member = self._db.scalar(
            select(StudyRoomMember).where(
                StudyRoomMember.room_id == room.id,
                StudyRoomMember.user_id == user_id,
                StudyRoomMember.left_at.is_(None),
            )
        )
        if member is None:
            raise CommunityServiceError(403, 'NOT_ROOM_MEMBER', 'Bạn chưa ở trong phòng học này.')
        if mic_enabled is not None:
            member.mic_enabled = mic_enabled
        if cam_enabled is not None:
            member.cam_enabled = cam_enabled
        if status_note is not None:
            member.status_note = status_note.strip()[:80] or member.status_note
        member.last_heartbeat_at = now
        room.last_heartbeat_at = now
        if ai_companion_enabled is not None and room.owner_id == user_id:
            room.ai_companion_enabled = ai_companion_enabled
        self._db.commit()
        return self._serialize_room_detail(user_id, room)

    def leave_room(
        self,
        user_id: str,
        room_id: str,
        *,
        transfer_host: bool = False,
    ) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(select(StudyRoom).where(
            StudyRoom.id == room_id).with_for_update())
        if room is None:
            raise CommunityServiceError(404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại.')
        member = self._db.scalar(
            select(StudyRoomMember).where(
                StudyRoomMember.room_id == room.id,
                StudyRoomMember.user_id == user_id,
            )
        )
        if member is not None and member.left_at is None:
            member.left_at = now
            member.mic_enabled = False
            member.cam_enabled = False
            self._db.flush()

        remaining = list(
            self._db.scalars(
                select(StudyRoomMember)
                .where(
                    StudyRoomMember.room_id == room.id,
                    StudyRoomMember.left_at.is_(None),
                )
                .order_by(StudyRoomMember.joined_at.asc(), StudyRoomMember.id.asc())
            )
        )
        new_host_id: str | None = None
        if room.owner_id == user_id:
            if transfer_host and remaining:
                new_host = remaining[0]
                new_host.role = 'host'
                room.owner_id = new_host.user_id
                new_host_id = new_host.user_id
                room.status = 'active' if len(remaining) >= 2 else 'waiting'
                room.last_heartbeat_at = now
            else:
                self._transition_room_closing_to_terminal(
                    room, terminal_status='closed', now=now
                )
        else:
            if not remaining:
                self._transition_room_closing_to_terminal(
                    room, terminal_status='closed', now=now
                )
            elif room.status in OPEN_ROOM_STATUSES:
                room.status = 'active' if len(remaining) >= 2 else 'waiting'
                room.last_heartbeat_at = now

        self._db.commit()
        result: dict[str, Any] = {
            'roomId': room.id,
            'left': True,
            'roomStatus': room.status,
        }
        if new_host_id is not None:
            result['newHostUserId'] = new_host_id
        return result

    def remove_room_member(
        self, owner_id: str, room_id: str, member_user_id: str
    ) -> dict[str, Any]:
        now = self._now()
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is not None:
            self._reconcile_room_locked(room, now)
        if room is None or room.status not in OPEN_ROOM_STATUSES:
            self._db.commit()
            raise CommunityServiceError(
                404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại hoặc đã đóng.'
            )
        if room.owner_id != owner_id:
            raise CommunityServiceError(
                403, 'HOST_REQUIRED', 'Chỉ chủ phòng được mời thành viên ra.'
            )
        if member_user_id == owner_id:
            raise CommunityServiceError(
                409, 'HOST_CANNOT_BE_REMOVED', 'Chủ phòng không thể tự mời mình ra.'
            )
        member = self._db.scalar(
            select(StudyRoomMember).where(
                StudyRoomMember.room_id == room.id,
                StudyRoomMember.user_id == member_user_id,
            )
        )
        if member is None or member.left_at is not None:
            raise CommunityServiceError(
                404, 'ROOM_MEMBER_NOT_FOUND', 'Thành viên không còn ở trong phòng.'
            )
        member.left_at = now
        member.mic_enabled = False
        member.cam_enabled = False
        # Giữ row làm dấu chặn tái tham gia; task moderation sau có thể thêm
        # thao tác cho phép quay lại thay vì xóa dấu này ngầm.
        member.role = 'removed'
        self._db.flush()
        remaining_count = self._active_member_counts([room.id]).get(room.id, 0)
        room.status = 'active' if remaining_count >= 2 else 'waiting'
        room.last_heartbeat_at = now
        self._db.commit()
        return self._serialize_room_detail(owner_id, room)

    def delete_room(self, owner_id: str, room_id: str) -> None:
        room = self._db.scalar(
            select(StudyRoom).where(StudyRoom.id == room_id).with_for_update()
        )
        if room is None:
            raise CommunityServiceError(
                404, 'ROOM_NOT_FOUND', 'Phòng học không tồn tại hoặc đã được xóa.'
            )
        if room.owner_id != owner_id:
            raise CommunityServiceError(
                403, 'HOST_REQUIRED', 'Chỉ chủ phòng được xóa phòng.'
            )
        self._db.delete(room)
        self._db.commit()

    def ai_match_rooms_and_peers(
        self,
        viewer: User,
        *,
        subject_code: str | None = None,
        grade_band: str | None = None,
        target_level: str | None = None,
    ) -> dict[str, Any]:
        viewer_meta = self._community_profiles_map([viewer.id]).get(viewer.id)
        want_grade = (grade_band or viewer.grade_band or 'Lớp 11').strip()
        want_level = normalize_study_level(
            target_level or (viewer_meta.study_level if viewer_meta else 'basic')
        )
        user_subjects = {normalize_subject_code(s) for s in (viewer.selected_subjects_json or [])}
        want_subject = (
            normalize_subject_code(subject_code)
            if subject_code and subject_code.strip()
            else (next(iter(user_subjects)) if user_subjects else 'TOAN')
        )
        self.sweep_stale_rooms()
        blocked = self._blocked_ids_for(viewer.id)

        rooms_stmt = select(StudyRoom).where(
            StudyRoom.status.in_(OPEN_ROOM_STATUSES),
            StudyRoom.visibility == 'public',
            StudyRoom.owner_id != viewer.id,
        )
        if blocked:
            rooms_stmt = rooms_stmt.where(~StudyRoom.owner_id.in_(blocked))
        rooms = list(self._db.scalars(rooms_stmt.limit(40)))
        counts = self._active_member_counts([r.id for r in rooms])
        owner_ids = list({r.owner_id for r in rooms})
        owners = {
            u.id: u
            for u in self._db.scalars(select(User).where(User.id.in_(owner_ids))).all()
        } if owner_ids else {}
        owner_metas = self._community_profiles_map(owner_ids)

        scored_rooms: list[tuple[int, dict[str, Any]]] = []
        for r in rooms:
            c = counts.get(r.id, 0)
            if c >= r.max_members:
                continue
            score = 0
            reasons: list[str] = []
            if r.grade_band == want_grade:
                score += 40
                reasons.append(f'Cùng {want_grade}')
            if r.subject_code == want_subject or r.subject_code in user_subjects:
                score += 35
                reasons.append(f'Đúng môn {r.subject_code}')
            if normalize_study_level(r.target_level) == want_level:
                score += 20
                reasons.append(f'Nhịp {LEVEL_LABEL_VI.get(want_level, want_level)}')
            if c > 0:
                score += 5
            if not reasons:
                reasons.append('Phòng công khai đang mở')
            scored_rooms.append(
                (
                    score,
                    self._serialize_room_summary(
                        r,
                        owner=owners.get(r.owner_id),
                        owner_meta=owner_metas.get(r.owner_id),
                        member_count=c,
                        match_score=score,
                        match_reason_vi=' · '.join(reasons),
                    ),
                )
            )
        scored_rooms.sort(key=lambda item: item[0], reverse=True)

        peers_stmt = select(User).where(User.id != viewer.id)
        if blocked:
            peers_stmt = peers_stmt.where(~User.id.in_(blocked))
        peers = list(self._db.scalars(peers_stmt.limit(50)))
        peer_ids = [p.id for p in peers]
        friend_ids = self._friend_ids_for(viewer.id)
        pending_map = self._pending_requests_map(viewer.id, peer_ids)
        peer_metas = self._community_profiles_map(peer_ids)

        scored_peers: list[tuple[int, dict[str, Any]]] = []
        for p in peers:
            p_meta = peer_metas.get(p.id)
            p_level = normalize_study_level(p_meta.study_level if p_meta else 'basic')
            p_subjects = {normalize_subject_code(s) for s in (p.selected_subjects_json or [])}
            overlap = sorted(p_subjects & (user_subjects | {want_subject}))
            score = 0
            reasons = []
            if p.grade_band == want_grade:
                score += 40
                reasons.append(f'Cùng {want_grade}')
            if overlap:
                score += 20 * min(len(overlap), 2)
                reasons.append(f'Chung môn {", ".join(overlap[:2])}')
            if p_level == want_level:
                score += 20
                reasons.append(f'Trình độ {LEVEL_LABEL_VI.get(want_level, want_level)}')
            prof = self._to_public_profile(
                viewer.id,
                p,
                meta=p_meta,
                friend_ids=friend_ids,
                pending_map=pending_map,
            )
            prof['matchScore'] = score
            prof['matchReasonVi'] = ' · '.join(reasons) if reasons else 'Bạn học cùng hệ THPT'
            scored_peers.append((score, prof))
        scored_peers.sort(key=lambda item: item[0], reverse=True)

        return {
            'criteria': {
                'gradeLevel': want_grade,
                'subjectCode': want_subject,
                'targetLevel': want_level,
            },
            'recommendedRooms': [r for _, r in scored_rooms[:8]],
            'recommendedPeers': [p for _, p in scored_peers[:8]],
        }
