"""Add community profiles, friends, blocks, and public/invite study rooms (T058)

Revision ID: 0004_add_community_study_rooms
Revises: 0003_add_pvp_match_tables
Create Date: 2026-11-19
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0004_add_community_study_rooms'
down_revision: Union[str, None] = '0003_add_pvp_match_tables'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'user_community_profiles',
        sa.Column(
            'user_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            primary_key=True,
        ),
        sa.Column('avatar_id', sa.String(length=40), nullable=False),
        sa.Column('study_level', sa.String(length=24), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        'friend_requests',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'sender_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'receiver_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('message_vi', sa.String(length=160), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('sender_id', 'receiver_id', name='uq_friend_request_pair'),
    )
    op.create_index('ix_friend_requests_sender_id', 'friend_requests', ['sender_id'], unique=False)
    op.create_index('ix_friend_requests_receiver_id', 'friend_requests', ['receiver_id'], unique=False)
    op.create_index('ix_friend_requests_status', 'friend_requests', ['status'], unique=False)

    op.create_table(
        'friendships',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'user_a_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'user_b_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('user_a_id', 'user_b_id', name='uq_friendship_pair'),
    )
    op.create_index('ix_friendships_user_a_id', 'friendships', ['user_a_id'], unique=False)
    op.create_index('ix_friendships_user_b_id', 'friendships', ['user_b_id'], unique=False)

    op.create_table(
        'user_blocks',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'blocker_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'blocked_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('reason', sa.String(length=120), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('blocker_id', 'blocked_id', name='uq_user_block_pair'),
    )
    op.create_index('ix_user_blocks_blocker_id', 'user_blocks', ['blocker_id'], unique=False)
    op.create_index('ix_user_blocks_blocked_id', 'user_blocks', ['blocked_id'], unique=False)

    op.create_table(
        'study_rooms',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'owner_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('room_code', sa.String(length=12), nullable=False),
        sa.Column('title', sa.String(length=80), nullable=False),
        sa.Column('subject_code', sa.String(length=32), nullable=False),
        sa.Column('grade_band', sa.String(length=40), nullable=False),
        sa.Column('target_level', sa.String(length=24), nullable=False),
        sa.Column('visibility', sa.String(length=16), nullable=False),
        sa.Column('max_members', sa.Integer(), nullable=False),
        sa.Column('ai_companion_enabled', sa.Boolean(), nullable=False),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_study_rooms_owner_id', 'study_rooms', ['owner_id'], unique=False)
    op.create_index('ix_study_rooms_room_code', 'study_rooms', ['room_code'], unique=True)
    op.create_index('ix_study_rooms_subject_code', 'study_rooms', ['subject_code'], unique=False)
    op.create_index('ix_study_rooms_grade_band', 'study_rooms', ['grade_band'], unique=False)
    op.create_index('ix_study_rooms_visibility', 'study_rooms', ['visibility'], unique=False)
    op.create_index('ix_study_rooms_status', 'study_rooms', ['status'], unique=False)

    op.create_table(
        'study_room_members',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column(
            'room_id',
            sa.String(length=64),
            sa.ForeignKey('study_rooms.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'user_id',
            sa.String(length=36),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('role', sa.String(length=16), nullable=False),
        sa.Column('mic_enabled', sa.Boolean(), nullable=False),
        sa.Column('cam_enabled', sa.Boolean(), nullable=False),
        sa.Column('status_note', sa.String(length=80), nullable=False),
        sa.Column('joined_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('left_at', sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint('room_id', 'user_id', name='uq_study_room_member'),
    )
    op.create_index('ix_study_room_members_room_id', 'study_room_members', ['room_id'], unique=False)
    op.create_index('ix_study_room_members_user_id', 'study_room_members', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_table('study_room_members')
    op.drop_table('study_rooms')
    op.drop_table('user_blocks')
    op.drop_table('friendships')
    op.drop_table('friend_requests')
    op.drop_table('user_community_profiles')
