"""Add study room lifecycle timestamps and revocable invite tokens (T094).

Revision ID: 0011_room_lifecycle_invites
Revises: 0010_add_group_busy_days
Create Date: 2026-11-27
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0011_room_lifecycle_invites'
down_revision: Union[str, None] = '0010_add_group_busy_days'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'study_rooms',
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        'study_rooms',
        sa.Column('last_heartbeat_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        'study_rooms',
        sa.Column('closed_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        'ix_study_rooms_expires_at', 'study_rooms', ['expires_at'], unique=False
    )
    op.create_index(
        'ix_study_rooms_last_heartbeat_at',
        'study_rooms',
        ['last_heartbeat_at'],
        unique=False,
    )

    op.add_column(
        'study_room_members',
        sa.Column('last_heartbeat_at', sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        'study_room_invites',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('room_id', sa.String(length=64), nullable=False),
        sa.Column('created_by_user_id', sa.String(length=36), nullable=False),
        sa.Column('token_hash', sa.String(length=64), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('max_uses', sa.Integer(), nullable=False, server_default='8'),
        sa.Column('use_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('revoked_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['room_id'], ['study_rooms.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['created_by_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        'ix_study_room_invites_token_hash',
        'study_room_invites',
        ['token_hash'],
        unique=True,
    )
    op.create_index(
        'ix_study_room_invites_room_id', 'study_room_invites', ['room_id'], unique=False
    )
    op.create_index(
        'ix_study_room_invites_created_by_user_id',
        'study_room_invites',
        ['created_by_user_id'],
        unique=False,
    )
    op.create_index(
        'ix_study_room_invites_expires_at',
        'study_room_invites',
        ['expires_at'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index('ix_study_room_invites_expires_at', table_name='study_room_invites')
    op.drop_index(
        'ix_study_room_invites_created_by_user_id', table_name='study_room_invites'
    )
    op.drop_index('ix_study_room_invites_room_id', table_name='study_room_invites')
    op.drop_index('ix_study_room_invites_token_hash', table_name='study_room_invites')
    op.drop_table('study_room_invites')

    op.drop_column('study_room_members', 'last_heartbeat_at')

    op.drop_index('ix_study_rooms_last_heartbeat_at', table_name='study_rooms')
    op.drop_index('ix_study_rooms_expires_at', table_name='study_rooms')
    op.drop_column('study_rooms', 'closed_at')
    op.drop_column('study_rooms', 'last_heartbeat_at')
    op.drop_column('study_rooms', 'expires_at')
