"""Initial MindClock schema (docs/28 & docs/45)

Revision ID: 0001_initial_schema
Revises:
Create Date: 2026-11-14
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('auth_subject', sa.String(length=128), nullable=False),
        sa.Column('alias', sa.String(length=80), nullable=False),
        sa.Column('grade_band', sa.String(length=40), nullable=False),
        sa.Column('selected_subjects_json', sa.JSON(), nullable=False),
        sa.Column('goal_label', sa.String(length=120), nullable=False),
        sa.Column('locale', sa.String(length=16), nullable=False),
        sa.Column('time_zone', sa.String(length=64), nullable=False),
        sa.Column('consent_version', sa.String(length=32), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_users_auth_subject', 'users', ['auth_subject'], unique=True)
    op.create_index('ix_users_grade_band', 'users', ['grade_band'], unique=False)

    op.create_table(
        'alarms',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('local_time', sa.String(length=8), nullable=False),
        sa.Column('time_zone', sa.String(length=64), nullable=False),
        sa.Column('weekdays_json', sa.JSON(), nullable=False),
        sa.Column('enabled', sa.Boolean(), nullable=False),
        sa.Column('challenge_mode', sa.String(length=24), nullable=False),
        sa.Column('snooze_minutes', sa.Integer(), nullable=True),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_alarms_user_id', 'alarms', ['user_id'])

    op.create_table(
        'timetable_slots',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('weekday', sa.Integer(), nullable=False),
        sa.Column('subject_code', sa.String(length=32), nullable=False),
        sa.Column('topic_id', sa.String(length=64), nullable=False),
        sa.Column('position', sa.Integer(), nullable=False),
        sa.UniqueConstraint('user_id', 'weekday', 'position', name='uq_timetable_slot'),
    )
    op.create_index('ix_timetable_slots_user_id', 'timetable_slots', ['user_id'])

    op.create_table(
        'questions',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('subject_code', sa.String(length=32), nullable=False),
        sa.Column('grade_band', sa.String(length=40), nullable=False),
        sa.Column('topic_id', sa.String(length=64), nullable=False),
        sa.Column('difficulty', sa.Integer(), nullable=False),
        sa.Column('prompt', sa.Text(), nullable=False),
        sa.Column('answer_spec_json', sa.JSON(), nullable=False),
        sa.Column('reasoning_prompt_vi', sa.Text(), nullable=False),
        sa.Column('rubric_json', sa.JSON(), nullable=False),
        sa.Column('rubric_revision', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=24), nullable=False),
        sa.Column('source_type', sa.String(length=32), nullable=False),
        sa.Column('target_user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=True),
        sa.Column('model_version', sa.String(length=64), nullable=True),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('approved_by', sa.String(length=64), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        'ix_questions_bank_lookup',
        'questions',
        ['status', 'grade_band', 'subject_code', 'topic_id', 'difficulty'],
    )
    op.create_index('ix_questions_target_user_id', 'questions', ['target_user_id'])

    op.create_table(
        'alarm_sessions',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('alarm_id', sa.String(length=64), nullable=False),
        sa.Column('local_session_id', sa.String(length=64), nullable=False),
        sa.Column('question_id', sa.String(length=64), nullable=False),
        sa.Column('question_revision', sa.Integer(), nullable=False),
        sa.Column('local_date', sa.String(length=16), nullable=False),
        sa.Column('time_zone', sa.String(length=64), nullable=False),
        sa.Column('state', sa.String(length=32), nullable=False),
        sa.Column('version', sa.Integer(), nullable=False),
        sa.Column('wrong_attempts', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('user_id', 'local_session_id', name='uq_alarm_session_local'),
    )
    op.create_index('ix_alarm_sessions_user_id', 'alarm_sessions', ['user_id'])

    op.create_table(
        'attempts',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('session_id', sa.String(length=64), sa.ForeignKey('alarm_sessions.id', ondelete='CASCADE'), nullable=False),
        sa.Column('client_attempt_id', sa.String(length=64), nullable=False),
        sa.Column('kind', sa.String(length=16), nullable=False),
        sa.Column('grade_status', sa.String(length=16), nullable=False),
        sa.Column('feedback_json', sa.JSON(), nullable=False),
        sa.Column('rubric_revision', sa.Integer(), nullable=False),
        sa.Column('model_version', sa.String(length=64), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('session_id', 'client_attempt_id', name='uq_attempt_client'),
    )
    op.create_index('ix_attempts_session_id', 'attempts', ['session_id'])

    op.create_table(
        'study_sessions',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('client_session_id', sa.String(length=64), nullable=False),
        sa.Column('task_title', sa.String(length=160), nullable=False),
        sa.Column('subject_code', sa.String(length=32), nullable=True),
        sa.Column('grade_band', sa.String(length=40), nullable=True),
        sa.Column('target_minutes', sa.Integer(), nullable=False),
        sa.Column('focus_level', sa.String(length=24), nullable=False),
        sa.Column('state', sa.String(length=24), nullable=False),
        sa.Column('elapsed_wall_seconds', sa.Integer(), nullable=False),
        sa.Column('in_app_focus_seconds', sa.Integer(), nullable=False),
        sa.Column('notes_done', sa.Text(), nullable=False),
        sa.Column('notes_stuck', sa.Text(), nullable=False),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('ended_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('user_id', 'client_session_id', name='uq_study_client_session'),
    )
    op.create_index('ix_study_sessions_user_id', 'study_sessions', ['user_id'])

    op.create_table(
        'xp_ledger',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('source_type', sa.String(length=32), nullable=False),
        sa.Column('source_id', sa.String(length=64), nullable=False),
        sa.Column('reason', sa.String(length=48), nullable=False),
        sa.Column('delta', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('user_id', 'source_type', 'source_id', 'reason', name='uq_xp_ledger_idempotent'),
    )
    op.create_index('ix_xp_ledger_user_id', 'xp_ledger', ['user_id'])

    op.create_table(
        'topic_progress',
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), primary_key=True),
        sa.Column('topic_id', sa.String(length=64), primary_key=True),
        sa.Column('subject_code', sa.String(length=32), nullable=False),
        sa.Column('attempts', sa.Integer(), nullable=False),
        sa.Column('correct', sa.Integer(), nullable=False),
        sa.Column('next_review_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        'idempotency_records',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('route', sa.String(length=120), nullable=False),
        sa.Column('key', sa.String(length=120), nullable=False),
        sa.Column('payload_hash', sa.String(length=64), nullable=False),
        sa.Column('response_json', sa.JSON(), nullable=False),
        sa.Column('status_code', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('user_id', 'route', 'key', name='uq_idempotency_user_route_key'),
    )
    op.create_index('ix_idempotency_records_user_id', 'idempotency_records', ['user_id'])

    op.create_table(
        'consent_events',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('scope', sa.String(length=48), nullable=False),
        sa.Column('version', sa.String(length=32), nullable=False),
        sa.Column('granted', sa.Boolean(), nullable=False),
        sa.Column('occurred_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_consent_events_user_id', 'consent_events', ['user_id'])
    op.create_index('ix_consent_events_scope', 'consent_events', ['scope'])


def downgrade() -> None:
    op.drop_table('consent_events')
    op.drop_table('idempotency_records')
    op.drop_table('topic_progress')
    op.drop_table('xp_ledger')
    op.drop_table('study_sessions')
    op.drop_table('attempts')
    op.drop_table('alarm_sessions')
    op.drop_table('questions')
    op.drop_table('timetable_slots')
    op.drop_table('alarms')
    op.drop_table('users')
