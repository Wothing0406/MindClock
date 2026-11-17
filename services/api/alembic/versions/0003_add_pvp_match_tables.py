"""Add PvP 1v1 friendly matchmaking & combat tables (T038)

Revision ID: 0003_add_pvp_match_tables
Revises: 0002_align_question_indexes
Create Date: 2026-11-18
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0003_add_pvp_match_tables'
down_revision: Union[str, None] = '0002_align_question_indexes'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'match_queue',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'user_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('champion_id', sa.String(length=32), nullable=False),
        sa.Column('subject_code', sa.String(length=32), nullable=False),
        sa.Column('grade_band', sa.String(length=40), nullable=False),
        sa.Column('curriculum', sa.String(length=32), nullable=False),
        sa.Column('queued_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_match_queue_user_id', 'match_queue', ['user_id'], unique=True)
    op.create_index('ix_match_queue_subject_code', 'match_queue', ['subject_code'], unique=False)
    op.create_index('ix_match_queue_grade_band', 'match_queue', ['grade_band'], unique=False)

    op.create_table(
        'matches',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('mode', sa.String(length=24), nullable=False),
        sa.Column('subject_code', sa.String(length=32), nullable=False),
        sa.Column('grade_band', sa.String(length=40), nullable=False),
        sa.Column('curriculum', sa.String(length=32), nullable=False),
        sa.Column('status', sa.String(length=24), nullable=False),
        sa.Column('rule_version', sa.String(length=32), nullable=False),
        sa.Column('current_round', sa.Integer(), nullable=False),
        sa.Column('secret_round_no', sa.Integer(), nullable=False),
        sa.Column('winner_user_id', sa.String(length=36), nullable=True),
        sa.Column('finish_reason', sa.String(length=32), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_matches_mode', 'matches', ['mode'], unique=False)
    op.create_index('ix_matches_subject_code', 'matches', ['subject_code'], unique=False)
    op.create_index('ix_matches_grade_band', 'matches', ['grade_band'], unique=False)
    op.create_index('ix_matches_status', 'matches', ['status'], unique=False)

    op.create_table(
        'match_players',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'match_id',
            sa.String(length=64),
            sa.ForeignKey('matches.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'user_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('champion_id', sa.String(length=32), nullable=False),
        sa.Column('hp', sa.Integer(), nullable=False),
        sa.Column('armor', sa.Integer(), nullable=False),
        sa.Column('ward', sa.Integer(), nullable=False),
        sa.Column('qi', sa.Integer(), nullable=False),
        sa.Column('skill_1_used', sa.Boolean(), nullable=False),
        sa.Column('skill_2_used', sa.Boolean(), nullable=False),
        sa.Column('consecutive_correct', sa.Integer(), nullable=False),
        sa.Column('passive_triggers', sa.Integer(), nullable=False),
        sa.Column('passive_pending_ward', sa.Integer(), nullable=False),
        sa.Column('buff_next_basic', sa.Integer(), nullable=False),
        sa.Column('penalty_next_basic', sa.Integer(), nullable=False),
        sa.UniqueConstraint('match_id', 'user_id', name='uq_match_player'),
    )
    op.create_index('ix_match_players_match_id', 'match_players', ['match_id'], unique=False)
    op.create_index('ix_match_players_user_id', 'match_players', ['user_id'], unique=False)

    op.create_table(
        'match_rounds',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'match_id',
            sa.String(length=64),
            sa.ForeignKey('matches.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('round_no', sa.Integer(), nullable=False),
        sa.Column(
            'question_id',
            sa.String(length=64),
            sa.ForeignKey('questions.id', ondelete='RESTRICT'),
            nullable=False,
        ),
        sa.Column('question_revision', sa.Integer(), nullable=False),
        sa.Column('rubric_revision', sa.Integer(), nullable=False),
        sa.Column('prompt', sa.Text(), nullable=False),
        sa.Column('reasoning_prompt_vi', sa.Text(), nullable=False),
        sa.Column('rubric_json', sa.JSON(), nullable=False),
        sa.Column('deadline_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('state', sa.String(length=24), nullable=False),
        sa.UniqueConstraint('match_id', 'round_no', name='uq_match_round_no'),
    )
    op.create_index('ix_match_rounds_match_id', 'match_rounds', ['match_id'], unique=False)

    op.create_table(
        'round_submissions',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'match_id',
            sa.String(length=64),
            sa.ForeignKey('matches.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('round_no', sa.Integer(), nullable=False),
        sa.Column(
            'user_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('answer_text', sa.String(length=255), nullable=False),
        sa.Column('reasoning_text', sa.Text(), nullable=False),
        sa.Column('grade_status', sa.String(length=24), nullable=False),
        sa.Column('feedback_vi', sa.String(length=255), nullable=False),
        sa.Column('submitted_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('match_id', 'round_no', 'user_id', name='uq_round_submission'),
    )
    op.create_index('ix_round_submissions_match_id', 'round_submissions', ['match_id'], unique=False)
    op.create_index('ix_round_submissions_user_id', 'round_submissions', ['user_id'], unique=False)

    op.create_table(
        'round_actions',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'match_id',
            sa.String(length=64),
            sa.ForeignKey('matches.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('round_no', sa.Integer(), nullable=False),
        sa.Column(
            'user_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('action_type', sa.String(length=24), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('match_id', 'round_no', 'user_id', name='uq_round_action'),
    )
    op.create_index('ix_round_actions_match_id', 'round_actions', ['match_id'], unique=False)
    op.create_index('ix_round_actions_user_id', 'round_actions', ['user_id'], unique=False)

    op.create_table(
        'match_events',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'match_id',
            sa.String(length=64),
            sa.ForeignKey('matches.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('sequence', sa.Integer(), nullable=False),
        sa.Column('event_type', sa.String(length=48), nullable=False),
        sa.Column('payload_json', sa.JSON(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('match_id', 'sequence', name='uq_match_event_sequence'),
    )
    op.create_index('ix_match_events_match_id', 'match_events', ['match_id'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_match_events_match_id', table_name='match_events')
    op.drop_table('match_events')

    op.drop_index('ix_round_actions_user_id', table_name='round_actions')
    op.drop_index('ix_round_actions_match_id', table_name='round_actions')
    op.drop_table('round_actions')

    op.drop_index('ix_round_submissions_user_id', table_name='round_submissions')
    op.drop_index('ix_round_submissions_match_id', table_name='round_submissions')
    op.drop_table('round_submissions')

    op.drop_index('ix_match_rounds_match_id', table_name='match_rounds')
    op.drop_table('match_rounds')

    op.drop_index('ix_match_players_user_id', table_name='match_players')
    op.drop_index('ix_match_players_match_id', table_name='match_players')
    op.drop_table('match_players')

    op.drop_index('ix_matches_status', table_name='matches')
    op.drop_index('ix_matches_grade_band', table_name='matches')
    op.drop_index('ix_matches_subject_code', table_name='matches')
    op.drop_index('ix_matches_mode', table_name='matches')
    op.drop_table('matches')

    op.drop_index('ix_match_queue_grade_band', table_name='match_queue')
    op.drop_index('ix_match_queue_subject_code', table_name='match_queue')
    op.drop_index('ix_match_queue_user_id', table_name='match_queue')
    op.drop_table('match_queue')
