from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
import secrets
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import delete, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.models import (
    CommitmentGroup,
    CommitmentGroupBusyDay,
    CommitmentGroupInvite,
    CommitmentGroupJoinRequest,
    CommitmentGroupMember,
    CommitmentPetCare,
    Friendship,
    User,
    UserCommunityProfile,
)


class CommitmentGroupError(Exception):
    def __init__(self, status_code: int, code: str, message_vi: str):
        super().__init__(message_vi)
        self.status_code = status_code
        self.code = code
        self.message_vi = message_vi


class CommitmentGroupService:
    MAX_MEMBERS = 4
    MAX_ACTIVE_GROUPS = 3
    INVITE_HOURS = 72
    MONTHLY_BUSY_QUOTA = 2

    def __init__(self, db: Session):
        self.db = db

    def create_group(self, user: User, *, name: str, pet_name: str) -> dict[str, Any]:
        existing_memberships = self._active_memberships(user.id)
        self._require_group_capacity(user.id)
        clean_name = ' '.join(name.split())
        clean_pet = ' '.join(pet_name.split())
        if len(clean_name) < 2 or not clean_pet:
            raise CommitmentGroupError(422, 'INVALID_GROUP_INPUT', 'Tên nhóm hoặc tên pet chưa hợp lệ.')
        group = CommitmentGroup(
            owner_id=user.id,
            group_code=self._new_code(),
            name=clean_name,
            time_zone=user.time_zone or 'Asia/Ho_Chi_Minh',
            pet_name=clean_pet,
            max_members=self.MAX_MEMBERS,
        )
        self.db.add(group)
        self.db.flush()
        self.db.add(CommitmentGroupMember(
            group_id=group.id,
            user_id=user.id,
            role='owner',
            is_primary=not existing_memberships,
        ))
        self.db.commit()
        return self.detail(user.id, group.id)

    def hub(self, user_id: str) -> dict[str, Any]:
        now = datetime.now(timezone.utc)
        invites = list(self.db.scalars(select(CommitmentGroupInvite).where(
            CommitmentGroupInvite.recipient_id == user_id,
            CommitmentGroupInvite.status == 'pending',
        ).order_by(CommitmentGroupInvite.created_at.desc())))
        incoming = []
        for invite in invites:
            if self._aware(invite.expires_at) <= now:
                invite.status = 'expired'
                continue
            group = self.db.get(CommitmentGroup, invite.group_id)
            inviter = self.db.get(User, invite.inviter_id)
            if group and group.status == 'active':
                incoming.append(self._invite_wire(invite, group, inviter))
        memberships = self._active_memberships(user_id)
        self.db.commit()
        return {
            'group': self.detail(user_id, memberships[0].group_id) if memberships else None,
            'groups': [self.detail(user_id, item.group_id) for item in memberships],
            'incomingInvites': incoming,
            'membershipLimit': self.MAX_ACTIVE_GROUPS,
        }

    def detail(self, user_id: str, group_id: str) -> dict[str, Any]:
        group = self._group(group_id)
        viewer = self._active_member(group_id, user_id)
        if viewer is None:
            raise CommitmentGroupError(403, 'GROUP_MEMBER_REQUIRED', 'Bạn không còn ở trong nhóm này.')
        memberships = list(self.db.scalars(select(CommitmentGroupMember).where(
            CommitmentGroupMember.group_id == group_id,
            CommitmentGroupMember.status == 'active',
        ).order_by(CommitmentGroupMember.joined_at.asc())))
        members = []
        for item in memberships:
            user = self.db.get(User, item.user_id)
            profile = self.db.get(UserCommunityProfile, item.user_id)
            members.append({
                'userId': item.user_id,
                'alias': user.alias if user else 'Học sinh MindClock',
                'avatarId': profile.avatar_id if profile else 'avatar_sunrise',
                'role': item.role,
                'isSelf': item.user_id == user_id,
            })
        pending_requests = []
        if viewer.role == 'owner':
            requests = list(self.db.scalars(select(CommitmentGroupJoinRequest).where(
                CommitmentGroupJoinRequest.group_id == group_id,
                CommitmentGroupJoinRequest.status == 'pending',
            ).order_by(CommitmentGroupJoinRequest.created_at.asc())))
            for request in requests:
                candidate = self.db.get(User, request.user_id)
                profile = self.db.get(UserCommunityProfile, request.user_id)
                pending_requests.append({
                    'requestId': request.id,
                    'userId': request.user_id,
                    'alias': candidate.alias if candidate else 'Học sinh MindClock',
                    'avatarId': profile.avatar_id if profile else 'avatar_sunrise',
                })
        return {
            'groupId': group.id,
            'groupCode': group.group_code,
            'name': group.name,
            'ownerId': group.owner_id,
            'isOwner': viewer.role == 'owner',
            'isPrimary': viewer.is_primary,
            'maxMembers': group.max_members,
            'members': members,
            'pendingRequests': pending_requests,
            'pet': self._pet_summary(group, viewer_user_id=viewer.user_id),
        }

    def invite(self, owner_id: str, group_id: str, recipient_id: str) -> dict[str, Any]:
        group = self._require_owner(owner_id, group_id)
        if recipient_id == owner_id or not self._are_friends(owner_id, recipient_id):
            raise CommitmentGroupError(403, 'FRIEND_REQUIRED', 'Chỉ có thể mời một người đã kết bạn hai chiều.')
        if self._active_member(group_id, recipient_id):
            raise CommitmentGroupError(409, 'ALREADY_IN_GROUP', 'Bạn này đã ở trong nhóm.')
        self._require_group_capacity(recipient_id)
        now = datetime.now(timezone.utc)
        existing = self.db.scalar(select(CommitmentGroupInvite).where(
            CommitmentGroupInvite.group_id == group_id,
            CommitmentGroupInvite.recipient_id == recipient_id,
            CommitmentGroupInvite.status == 'pending',
        ))
        if existing and self._aware(existing.expires_at) > now:
            raise CommitmentGroupError(409, 'INVITE_ALREADY_PENDING', 'Lời mời đang chờ phản hồi.')
        invite = CommitmentGroupInvite(
            group_id=group.id,
            inviter_id=owner_id,
            recipient_id=recipient_id,
            expires_at=now + timedelta(hours=self.INVITE_HOURS),
        )
        self.db.add(invite)
        self.db.commit()
        return {'inviteId': invite.id, 'status': invite.status, 'expiresAt': invite.expires_at.isoformat()}

    def respond_invite(self, user_id: str, invite_id: str, decision: str) -> dict[str, Any]:
        invite = self.db.get(CommitmentGroupInvite, invite_id)
        if invite is None or invite.recipient_id != user_id:
            raise CommitmentGroupError(404, 'INVITE_NOT_FOUND', 'Không tìm thấy lời mời.')
        now = datetime.now(timezone.utc)
        if invite.status != 'pending':
            raise CommitmentGroupError(409, 'INVITE_ALREADY_RESOLVED', 'Lời mời đã được xử lý.')
        if self._aware(invite.expires_at) <= now:
            invite.status = 'expired'
            self.db.commit()
            raise CommitmentGroupError(409, 'INVITE_EXPIRED', 'Lời mời đã hết hạn.')
        if decision == 'decline':
            invite.status = 'declined'
            invite.responded_at = now
            self.db.commit()
            return {'status': 'declined'}
        self._join_locked(user_id, invite.group_id)
        invite.status = 'accepted'
        invite.responded_at = now
        self.db.commit()
        return self.detail(user_id, invite.group_id)

    def request_join(self, user_id: str, group_code: str) -> dict[str, Any]:
        self._require_group_capacity(user_id)
        group = self.db.scalar(select(CommitmentGroup).where(
            CommitmentGroup.group_code == group_code.strip().upper(),
            CommitmentGroup.status == 'active',
        ))
        if group is None:
            raise CommitmentGroupError(404, 'GROUP_NOT_FOUND', 'Mã nhóm không tồn tại.')
        request = self.db.scalar(select(CommitmentGroupJoinRequest).where(
            CommitmentGroupJoinRequest.group_id == group.id,
            CommitmentGroupJoinRequest.user_id == user_id,
        ))
        if request and request.status == 'pending':
            raise CommitmentGroupError(409, 'JOIN_REQUEST_PENDING', 'Yêu cầu đang chờ trưởng nhóm duyệt.')
        if request:
            request.status = 'pending'
            request.responded_at = None
            request.created_at = datetime.now(timezone.utc)
        else:
            request = CommitmentGroupJoinRequest(group_id=group.id, user_id=user_id)
            self.db.add(request)
        self.db.commit()
        return {'requestId': request.id, 'status': request.status, 'groupName': group.name}

    def respond_join_request(self, owner_id: str, group_id: str, request_id: str, decision: str) -> dict[str, Any]:
        self._require_owner(owner_id, group_id)
        request = self.db.get(CommitmentGroupJoinRequest, request_id)
        if request is None or request.group_id != group_id or request.status != 'pending':
            raise CommitmentGroupError(404, 'JOIN_REQUEST_NOT_FOUND', 'Yêu cầu không còn hiệu lực.')
        request.responded_at = datetime.now(timezone.utc)
        if decision in ('decline', 'reject'):
            request.status = 'rejected'
        else:
            self._join_locked(request.user_id, group_id)
            request.status = 'accepted'
        self.db.commit()
        return self.detail(owner_id, group_id)

    def remove_member(self, owner_id: str, group_id: str, member_user_id: str) -> dict[str, Any]:
        self._require_owner(owner_id, group_id)
        member = self._active_member(group_id, member_user_id)
        if member is None or member.role == 'owner':
            raise CommitmentGroupError(409, 'MEMBER_NOT_REMOVABLE', 'Không thể xóa thành viên này.')
        member.status = 'removed'
        member.left_at = datetime.now(timezone.utc)
        member.is_primary = False
        self._ensure_primary(member_user_id)
        self.db.commit()
        return self.detail(owner_id, group_id)

    def leave(self, user_id: str, group_id: str) -> dict[str, Any]:
        member = self._active_member(group_id, user_id)
        if member is None:
            raise CommitmentGroupError(404, 'MEMBERSHIP_NOT_FOUND', 'Bạn không ở trong nhóm này.')
        if member.role == 'owner':
            raise CommitmentGroupError(409, 'OWNER_MUST_DELETE_GROUP', 'Trưởng nhóm cần xóa nhóm thay vì rời nhóm.')
        member.status = 'left'
        member.left_at = datetime.now(timezone.utc)
        member.is_primary = False
        self._ensure_primary(user_id)
        self.db.commit()
        return {'status': 'left'}

    def delete_group(self, owner_id: str, group_id: str) -> None:
        group = self._require_owner(owner_id, group_id)
        affected_users = [item.user_id for item in self._active_group_members(group_id)]
        self.db.delete(group)
        self.db.flush()
        for user_id in affected_users:
            self._ensure_primary(user_id)
        self.db.commit()

    def set_primary(self, user_id: str, group_id: str) -> dict[str, Any]:
        self.db.execute(select(User.id).where(User.id == user_id).with_for_update()).scalar_one()
        target = self._active_member(group_id, user_id)
        if target is None:
            raise CommitmentGroupError(403, 'GROUP_MEMBER_REQUIRED', 'Bạn không còn ở trong nhóm này.')
        memberships = self._active_memberships(user_id)
        for item in memberships:
            item.is_primary = False
        # Flush the demotion first. PostgreSQL checks the partial unique index
        # while each UPDATE batch is applied, so swapping True/False in one
        # executemany can momentarily look like two primary pets.
        self.db.flush()
        target.is_primary = True
        self.db.commit()
        return self.hub(user_id)

    def record_activity_care(
        self,
        user_id: str,
        source_id: str,
        *,
        source_type: str,
        care_kind: str,
        xp_delta: int,
        at: datetime | None = None,
    ) -> list[dict[str, Any]]:
        memberships = self._active_memberships(user_id)
        if not memberships:
            return []
        event_at = at or datetime.now(timezone.utc)
        results: list[dict[str, Any]] = []
        for member in memberships:
            group = self._group(member.group_id)
            try:
                local_date = event_at.astimezone(ZoneInfo(group.time_zone)).date().isoformat()
            except ZoneInfoNotFoundError:
                local_date = event_at.astimezone(ZoneInfo('Asia/Ho_Chi_Minh')).date().isoformat()
            existing = self.db.scalar(select(CommitmentPetCare).where(or_(
                (CommitmentPetCare.group_id == group.id) &
                (CommitmentPetCare.source_type == source_type) &
                (CommitmentPetCare.source_id == source_id),
                (CommitmentPetCare.group_id == group.id) &
                (CommitmentPetCare.user_id == user_id) &
                (CommitmentPetCare.local_date == local_date) &
                (CommitmentPetCare.care_kind == care_kind),
            )))
            if existing is None:
                self.db.add(CommitmentPetCare(
                    group_id=group.id, user_id=user_id, local_date=local_date,
                    source_type=source_type, source_id=source_id,
                    care_kind=care_kind, xp_delta=xp_delta,
                ))
                self.db.flush()
            results.append({'groupId': group.id, 'recorded': existing is None, 'localDate': local_date})
        return results

    def record_study_care(self, user_id: str, source_id: str, *, at: datetime | None = None) -> list[dict[str, Any]]:
        return self.record_activity_care(
            user_id, source_id, source_type='study_session', care_kind='study_care',
            xp_delta=10, at=at,
        )

    def record_morning_challenge(self, user_id: str, source_id: str, *, at: datetime | None = None) -> list[dict[str, Any]]:
        return self.record_activity_care(
            user_id, source_id, source_type='alarm_session',
            care_kind='morning_challenge', xp_delta=20, at=at,
        )

    def record_daily_report(self, user_id: str, source_id: str, *, at: datetime | None = None) -> list[dict[str, Any]]:
        return self.record_activity_care(
            user_id, source_id, source_type='daily_report',
            care_kind='daily_report', xp_delta=10, at=at,
        )

    def report_busy_today(
        self,
        user_id: str,
        group_id: str,
        *,
        reason: str = 'exam',
        local_date: str | None = None,
    ) -> dict[str, Any]:
        group = self._group(group_id)
        viewer = self._active_member(group_id, user_id)
        if viewer is None:
            raise CommitmentGroupError(403, 'FORBIDDEN_MEMBER', 'Bạn không phải thành viên nhóm này.')
        try:
            today = datetime.now(timezone.utc).astimezone(ZoneInfo(group.time_zone)).date()
        except ZoneInfoNotFoundError:
            today = datetime.now(timezone.utc).date()

        target_date = today.isoformat()
        if local_date and local_date.strip():
            try:
                target_date = date.fromisoformat(local_date.strip()).isoformat()
            except ValueError:
                pass
        month_key = target_date[:7]

        existing = self.db.scalar(
            select(CommitmentGroupBusyDay).where(
                CommitmentGroupBusyDay.group_id == group_id,
                CommitmentGroupBusyDay.user_id == user_id,
                CommitmentGroupBusyDay.local_date == target_date,
            )
        )
        if existing is None:
            used_this_month = self.db.scalar(
                select(func.count()).select_from(CommitmentGroupBusyDay).where(
                    CommitmentGroupBusyDay.group_id == group_id,
                    CommitmentGroupBusyDay.user_id == user_id,
                    CommitmentGroupBusyDay.month_key == month_key,
                )
            ) or 0
            if used_this_month >= self.MONTHLY_BUSY_QUOTA:
                raise CommitmentGroupError(
                    409,
                    'BUSY_QUOTA_EXCEEDED',
                    f'Bạn đã dùng hết {self.MONTHLY_BUSY_QUOTA}/{self.MONTHLY_BUSY_QUOTA} lượt xin bận trong tháng {month_key}.',
                )
            self.db.add(
                CommitmentGroupBusyDay(
                    group_id=group_id,
                    user_id=user_id,
                    local_date=target_date,
                    month_key=month_key,
                    reason=(reason.strip() or 'exam')[:64],
                )
            )
            self.db.flush()
        return self.detail(user_id, group_id)

    def _pet_summary(
        self,
        group: CommitmentGroup,
        *,
        viewer_user_id: str | None = None,
    ) -> dict[str, Any]:
        active_member_ids = {m.user_id for m in self._active_group_members(group.id)}
        rows = self.db.execute(
            select(CommitmentPetCare.local_date, CommitmentPetCare.user_id).where(
                CommitmentPetCare.group_id == group.id,
                CommitmentPetCare.care_kind.in_(('study_care', 'morning_challenge', 'daily_report')),
            )
        ).all()
        users_by_date: dict[str, set[str]] = {}
        for local_date, care_user_id in rows:
            users_by_date.setdefault(local_date, set()).add(care_user_id)

        busy_rows = self.db.execute(
            select(CommitmentGroupBusyDay.local_date, CommitmentGroupBusyDay.user_id).where(
                CommitmentGroupBusyDay.group_id == group.id,
            )
        ).all()
        busy_by_date: dict[str, set[str]] = {}
        for b_date, b_uid in busy_rows:
            busy_by_date.setdefault(b_date, set()).add(b_uid)

        # Ngày đủ 100% thành viên hoàn thành -> cộng +1 Chuỗi.
        completed_days_set = {
            local_date
            for local_date, uids in users_by_date.items()
            if active_member_ids and active_member_ids.issubset(uids)
        }
        # Ngày có bạn xin bận hợp lệ & mọi thành viên không bận còn lại đều hoàn thành -> bảo lưu nguyên Chuỗi N.
        preserved_days_set: set[str] = set()
        for b_date, b_uids in busy_by_date.items():
            if b_date in completed_days_set or not active_member_ids:
                continue
            active_busy = active_member_ids & b_uids
            non_busy = active_member_ids - active_busy
            if active_busy and non_busy and non_busy.issubset(users_by_date.get(b_date, set())):
                preserved_days_set.add(b_date)

        days = sorted(completed_days_set)
        try:
            today = datetime.now(timezone.utc).astimezone(ZoneInfo(group.time_zone)).date()
        except ZoneInfoNotFoundError:
            today = datetime.now(timezone.utc).date()
        today_iso = today.isoformat()
        month_key = today_iso[:7]
        member_count = len(active_member_ids)
        today_count = len(active_member_ids & users_by_date.get(today_iso, set()))
        busy_today_uids = active_member_ids & busy_by_date.get(today_iso, set())
        busy_count_today = len(busy_today_uids)
        all_done_today = member_count > 0 and today_count >= member_count
        streak_preserved_today = (
            today_iso in preserved_days_set
            or (busy_count_today > 0 and today_count + busy_count_today >= member_count)
        )
        streak = self._streak(days, today, preserved_days=preserved_days_set)
        best_streak = max(streak, self._best_streak(days))
        total = len(days)
        total_xp = self.db.scalar(select(func.coalesce(func.sum(CommitmentPetCare.xp_delta), 0)).where(
            CommitmentPetCare.group_id == group.id,
        )) or 0
        stage = 4 if total_xp >= 320 else 3 if total_xp >= 160 else 2 if total_xp >= 60 else 1
        milestone_label = (
            'Chuỗi 100+'
            if streak >= 100
            else (f'Chuỗi {streak}' if streak > 0 else 'Chưa mở chuỗi')
        )
        my_busy_used = 0
        busy_today_by_me = False
        if viewer_user_id:
            busy_today_by_me = viewer_user_id in busy_today_uids
            my_busy_used = int(
                self.db.scalar(
                    select(func.count()).select_from(CommitmentGroupBusyDay).where(
                        CommitmentGroupBusyDay.group_id == group.id,
                        CommitmentGroupBusyDay.user_id == viewer_user_id,
                        CommitmentGroupBusyDay.month_key == month_key,
                    )
                )
                or 0
            )
        return {
            'key': group.pet_key,
            'name': group.pet_name,
            'stage': stage,
            'stageLabelVi': ('Mầm non', 'Mầm khỏe', 'Mầm vươn', 'Mầm bền bỉ')[stage - 1],
            'totalCareDays': total,
            'currentStreakDays': streak,
            'bestStreakDays': best_streak,
            'todayCareCount': int(today_count),
            'memberCount': member_count,
            'allMembersDoneToday': all_done_today,
            'streakMilestoneLabelVi': milestone_label,
            'busyCountToday': busy_count_today,
            'streakPreservedToday': streak_preserved_today,
            'shieldsAvailable': min(2, best_streak // 7),
            'myBusyQuotaUsed': my_busy_used,
            'myBusyQuotaLimit': self.MONTHLY_BUSY_QUOTA,
            'busyTodayByMe': busy_today_by_me,
            'totalXp': int(total_xp),
            'nextStageXp': (60, 160, 320, 320)[stage - 1],
            'progressionVersion': group.progression_version,
        }

    @staticmethod
    def _best_streak(days: list[str]) -> int:
        parsed = {date.fromisoformat(value) for value in days}
        best = 0
        for day in parsed:
            if (day - timedelta(days=1)) not in parsed:
                run = 1
                cursor = day + timedelta(days=1)
                while cursor in parsed:
                    run += 1
                    cursor += timedelta(days=1)
                if run > best:
                    best = run
        return best

    @staticmethod
    def _streak(
        days: list[str],
        today: date,
        *,
        preserved_days: set[str] | None = None,
    ) -> int:
        parsed = {date.fromisoformat(value) for value in days}
        preserved = {date.fromisoformat(value) for value in (preserved_days or set())}
        cursor = today if (today in parsed or today in preserved) else today - timedelta(days=1)
        count = 0
        while cursor in parsed or cursor in preserved:
            if cursor in parsed:
                count += 1
            cursor -= timedelta(days=1)
        return count

    def _new_code(self) -> str:
        for _ in range(8):
            code = secrets.token_hex(3).upper()
            if self.db.scalar(select(CommitmentGroup.id).where(CommitmentGroup.group_code == code)) is None:
                return code
        raise CommitmentGroupError(503, 'GROUP_CODE_UNAVAILABLE', 'Chưa thể cấp mã nhóm. Hãy thử lại.')

    def _group(self, group_id: str) -> CommitmentGroup:
        group = self.db.get(CommitmentGroup, group_id)
        if group is None or group.status != 'active':
            raise CommitmentGroupError(404, 'GROUP_NOT_FOUND', 'Không tìm thấy nhóm cam kết.')
        return group

    def _require_owner(self, user_id: str, group_id: str) -> CommitmentGroup:
        group = self._group(group_id)
        if group.owner_id != user_id:
            raise CommitmentGroupError(403, 'GROUP_OWNER_REQUIRED', 'Chỉ trưởng nhóm được thực hiện thao tác này.')
        return group

    def _active_member(self, group_id: str, user_id: str) -> CommitmentGroupMember | None:
        return self.db.scalar(select(CommitmentGroupMember).where(
            CommitmentGroupMember.group_id == group_id,
            CommitmentGroupMember.user_id == user_id,
            CommitmentGroupMember.status == 'active',
        ))

    def _active_memberships(self, user_id: str) -> list[CommitmentGroupMember]:
        return list(self.db.scalars(select(CommitmentGroupMember).join(
            CommitmentGroup, CommitmentGroup.id == CommitmentGroupMember.group_id
        ).where(
            CommitmentGroupMember.user_id == user_id,
            CommitmentGroupMember.status == 'active',
            CommitmentGroup.status == 'active',
        ).order_by(CommitmentGroupMember.is_primary.desc(), CommitmentGroupMember.joined_at.asc())))

    def _active_group_members(self, group_id: str) -> list[CommitmentGroupMember]:
        return list(self.db.scalars(select(CommitmentGroupMember).where(
            CommitmentGroupMember.group_id == group_id,
            CommitmentGroupMember.status == 'active',
        )))

    def _ensure_primary(self, user_id: str) -> None:
        memberships = self._active_memberships(user_id)
        if memberships and not any(item.is_primary for item in memberships):
            memberships[0].is_primary = True

    def _require_group_capacity(self, user_id: str) -> None:
        # Locking the user serializes competing accepts/approvals on PostgreSQL.
        self.db.execute(select(User.id).where(User.id == user_id).with_for_update()).scalar_one()
        if len(self._active_memberships(user_id)) >= self.MAX_ACTIVE_GROUPS:
            raise CommitmentGroupError(409, 'ACTIVE_GROUP_LIMIT', 'Bạn đã tham gia đủ 3 nhóm cam kết đang hoạt động.')

    def _join_locked(self, user_id: str, group_id: str) -> None:
        self._require_group_capacity(user_id)
        group = self.db.execute(select(CommitmentGroup).where(
            CommitmentGroup.id == group_id,
            CommitmentGroup.status == 'active',
        ).with_for_update()).scalar_one_or_none()
        if group is None:
            raise CommitmentGroupError(404, 'GROUP_NOT_FOUND', 'Không tìm thấy nhóm cam kết.')
        count = self.db.scalar(select(func.count()).select_from(CommitmentGroupMember).where(
            CommitmentGroupMember.group_id == group_id,
            CommitmentGroupMember.status == 'active',
        )) or 0
        if count >= group.max_members:
            raise CommitmentGroupError(409, 'GROUP_FULL', 'Nhóm đã đủ thành viên.')
        old = self.db.scalar(select(CommitmentGroupMember).where(
            CommitmentGroupMember.group_id == group_id,
            CommitmentGroupMember.user_id == user_id,
        ))
        has_active_membership = bool(self._active_memberships(user_id))
        if old:
            old.status = 'active'
            old.role = 'member'
            old.left_at = None
            old.joined_at = datetime.now(timezone.utc)
            old.is_primary = not has_active_membership
        else:
            self.db.add(CommitmentGroupMember(
                group_id=group_id,
                user_id=user_id,
                is_primary=not has_active_membership,
            ))
        self.db.flush()

    def _are_friends(self, a: str, b: str) -> bool:
        low, high = sorted((a, b))
        return self.db.scalar(select(Friendship.id).where(
            Friendship.user_a_id == low,
            Friendship.user_b_id == high,
        )) is not None

    @staticmethod
    def _invite_wire(invite: CommitmentGroupInvite, group: CommitmentGroup, inviter: User | None) -> dict[str, Any]:
        return {
            'inviteId': invite.id,
            'groupId': group.id,
            'groupName': group.name,
            'inviterAlias': inviter.alias if inviter else 'Học sinh MindClock',
            'expiresAt': invite.expires_at.isoformat(),
        }

    @staticmethod
    def _aware(value: datetime) -> datetime:
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
