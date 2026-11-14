from datetime import datetime, timezone
import uuid

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    JSON,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def new_uuid() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = 'users'

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    auth_subject: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    alias: Mapped[str] = mapped_column(String(80), default='Học sinh MindClock')
    grade_band: Mapped[str] = mapped_column(String(40), default='Lớp 9', index=True)
    selected_subjects_json: Mapped[list[str]] = mapped_column(
        JSON, default=lambda: ['TOAN', 'NGU_VAN', 'TIENG_ANH']
    )
    goal_label: Mapped[str] = mapped_column(String(120), default='Ôn tập hằng ngày')
    locale: Mapped[str] = mapped_column(String(16), default='vi-VN')
    time_zone: Mapped[str] = mapped_column(String(64), default='Asia/Ho_Chi_Minh')
    consent_version: Mapped[str] = mapped_column(String(32), default='2026-11')
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class Alarm(Base):
    __tablename__ = 'alarms'

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), index=True
    )
    local_time: Mapped[str] = mapped_column(String(8))
    time_zone: Mapped[str] = mapped_column(String(64), default='Asia/Ho_Chi_Minh')
    weekdays_json: Mapped[list[int]] = mapped_column(JSON, default=list)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    challenge_mode: Mapped[str] = mapped_column(String(24), default='short_review')
    snooze_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    revision: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class TimetableSlot(Base):
    __tablename__ = 'timetable_slots'
    __table_args__ = (
        UniqueConstraint('user_id', 'weekday', 'position', name='uq_timetable_slot'),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), index=True
    )
    weekday: Mapped[int] = mapped_column(Integer)
    subject_code: Mapped[str] = mapped_column(String(32))
    topic_id: Mapped[str] = mapped_column(String(64), default='')
    position: Mapped[int] = mapped_column(Integer, default=0)


class Question(Base):
    __tablename__ = 'questions'
    __table_args__ = (
        Index(
            'ix_questions_bank_lookup',
            'status',
            'grade_band',
            'subject_code',
            'topic_id',
            'difficulty',
        ),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_uuid)
    subject_code: Mapped[str] = mapped_column(String(32), index=True)
    grade_band: Mapped[str] = mapped_column(String(40), index=True)
    topic_id: Mapped[str] = mapped_column(String(64), index=True)
    difficulty: Mapped[int] = mapped_column(Integer, default=1)
    prompt: Mapped[str] = mapped_column(Text)
    answer_spec_json: Mapped[dict] = mapped_column(JSON, default=dict)
    reasoning_prompt_vi: Mapped[str] = mapped_column(
        Text, default='Viết ngắn gọn 1–2 bước bạn đã làm.'
    )
    rubric_json: Mapped[dict] = mapped_column(JSON, default=dict)
    rubric_revision: Mapped[int] = mapped_column(Integer, default=1)
    # `published` (ngân hàng đã duyệt cho XP) hoặc `draft` (câu cá nhân hóa do AI tạo, 0 XP)
    status: Mapped[str] = mapped_column(String(24), default='published', index=True)
    source_type: Mapped[str] = mapped_column(
        String(32), default='approved_bank', index=True
    )
    target_user_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), nullable=True, index=True
    )
    model_version: Mapped[str | None] = mapped_column(String(64), nullable=True)
    revision: Mapped[int] = mapped_column(Integer, default=1)
    approved_by: Mapped[str | None] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class AlarmSession(Base):
    __tablename__ = 'alarm_sessions'
    __table_args__ = (
        UniqueConstraint('user_id', 'local_session_id', name='uq_alarm_session_local'),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), index=True
    )
    alarm_id: Mapped[str] = mapped_column(String(64))
    local_session_id: Mapped[str] = mapped_column(String(64))
    question_id: Mapped[str] = mapped_column(String(64))
    question_revision: Mapped[int] = mapped_column(Integer, default=1)
    local_date: Mapped[str] = mapped_column(String(16))
    time_zone: Mapped[str] = mapped_column(String(64), default='Asia/Ho_Chi_Minh')
    state: Mapped[str] = mapped_column(String(32), default='active')
    version: Mapped[int] = mapped_column(Integer, default=1)
    wrong_attempts: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class Attempt(Base):
    __tablename__ = 'attempts'
    __table_args__ = (
        UniqueConstraint('session_id', 'client_attempt_id', name='uq_attempt_client'),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_uuid)
    session_id: Mapped[str] = mapped_column(
        String(64), ForeignKey('alarm_sessions.id', ondelete='CASCADE'), index=True
    )
    client_attempt_id: Mapped[str] = mapped_column(String(64))
    kind: Mapped[str] = mapped_column(String(16), default='text')
    grade_status: Mapped[str] = mapped_column(String(16))
    feedback_json: Mapped[dict] = mapped_column(JSON, default=dict)
    rubric_revision: Mapped[int] = mapped_column(Integer, default=1)
    model_version: Mapped[str] = mapped_column(String(64), default='deterministic-validator')
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class StudySession(Base):
    __tablename__ = 'study_sessions'
    __table_args__ = (
        UniqueConstraint('user_id', 'client_session_id', name='uq_study_client_session'),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), index=True
    )
    client_session_id: Mapped[str] = mapped_column(String(64))
    task_title: Mapped[str] = mapped_column(String(160))
    subject_code: Mapped[str | None] = mapped_column(String(32), nullable=True)
    grade_band: Mapped[str | None] = mapped_column(String(40), nullable=True)
    target_minutes: Mapped[int] = mapped_column(Integer, default=25)
    focus_level: Mapped[str] = mapped_column(String(24), default='standard')
    state: Mapped[str] = mapped_column(String(24), default='active')
    elapsed_wall_seconds: Mapped[int] = mapped_column(Integer, default=0)
    in_app_focus_seconds: Mapped[int] = mapped_column(Integer, default=0)
    notes_done: Mapped[str] = mapped_column(Text, default='')
    notes_stuck: Mapped[str] = mapped_column(Text, default='')
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class XpLedger(Base):
    __tablename__ = 'xp_ledger'
    __table_args__ = (
        UniqueConstraint(
            'user_id',
            'source_type',
            'source_id',
            'reason',
            name='uq_xp_ledger_idempotent',
        ),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), index=True
    )
    source_type: Mapped[str] = mapped_column(String(32))
    source_id: Mapped[str] = mapped_column(String(64))
    reason: Mapped[str] = mapped_column(String(48))
    delta: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class TopicProgress(Base):
    __tablename__ = 'topic_progress'

    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True
    )
    topic_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    subject_code: Mapped[str] = mapped_column(String(32), default='TOAN')
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    correct: Mapped[int] = mapped_column(Integer, default=0)
    next_review_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class IdempotencyRecord(Base):
    __tablename__ = 'idempotency_records'
    __table_args__ = (
        UniqueConstraint('user_id', 'route', 'key', name='uq_idempotency_user_route_key'),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), index=True
    )
    route: Mapped[str] = mapped_column(String(120))
    key: Mapped[str] = mapped_column(String(120))
    payload_hash: Mapped[str] = mapped_column(String(64))
    response_json: Mapped[dict] = mapped_column(JSON, default=dict)
    status_code: Mapped[int] = mapped_column(Integer, default=200)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class ConsentEvent(Base):
    __tablename__ = 'consent_events'

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey('users.id', ondelete='CASCADE'), index=True
    )
    scope: Mapped[str] = mapped_column(String(48), index=True)
    version: Mapped[str] = mapped_column(String(32), default='2026-11')
    granted: Mapped[bool] = mapped_column(Boolean, default=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
