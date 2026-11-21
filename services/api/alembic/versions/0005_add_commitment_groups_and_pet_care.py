"""Add private commitment groups and server-authoritative pet care (T074).

Revision ID: 0005_commitment_groups_pet
Revises: 0004_add_community_study_rooms
Create Date: 2026-11-21
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0005_commitment_groups_pet'
down_revision: Union[str, None] = '0004_add_community_study_rooms'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'commitment_groups',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('owner_id', sa.String(36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('group_code', sa.String(12), nullable=False),
        sa.Column('name', sa.String(60), nullable=False),
        sa.Column('time_zone', sa.String(64), nullable=False),
        sa.Column('pet_key', sa.String(24), nullable=False),
        sa.Column('pet_name', sa.String(40), nullable=False),
        sa.Column('progression_version', sa.String(32), nullable=False),
        sa.Column('max_members', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(16), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_commitment_groups_owner_id', 'commitment_groups', ['owner_id'])
    op.create_index('ix_commitment_groups_group_code', 'commitment_groups', ['group_code'], unique=True)
    op.create_index('ix_commitment_groups_status', 'commitment_groups', ['status'])

    op.create_table(
        'commitment_group_members',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('group_id', sa.String(64), sa.ForeignKey('commitment_groups.id', ondelete='CASCADE'), nullable=False),
        sa.Column('user_id', sa.String(36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('role', sa.String(16), nullable=False),
        sa.Column('status', sa.String(16), nullable=False),
        sa.Column('joined_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('left_at', sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint('group_id', 'user_id', name='uq_commitment_group_member'),
    )
    op.create_index('ix_commitment_group_members_group_id', 'commitment_group_members', ['group_id'])
    op.create_index('ix_commitment_group_members_user_id', 'commitment_group_members', ['user_id'])
    op.create_index('ix_commitment_group_members_status', 'commitment_group_members', ['status'])

    op.create_table(
        'commitment_group_invites',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('group_id', sa.String(64), sa.ForeignKey('commitment_groups.id', ondelete='CASCADE'), nullable=False),
        sa.Column('inviter_id', sa.String(36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('recipient_id', sa.String(36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.String(16), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('responded_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    )
    for col in ('group_id', 'inviter_id', 'recipient_id', 'status'):
        op.create_index(f'ix_commitment_group_invites_{col}', 'commitment_group_invites', [col])

    op.create_table(
        'commitment_group_join_requests',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('group_id', sa.String(64), sa.ForeignKey('commitment_groups.id', ondelete='CASCADE'), nullable=False),
        sa.Column('user_id', sa.String(36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.String(16), nullable=False),
        sa.Column('responded_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('group_id', 'user_id', name='uq_commitment_join_request'),
    )
    for col in ('group_id', 'user_id', 'status'):
        op.create_index(f'ix_commitment_group_join_requests_{col}', 'commitment_group_join_requests', [col])

    op.create_table(
        'commitment_pet_care',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('group_id', sa.String(64), sa.ForeignKey('commitment_groups.id', ondelete='CASCADE'), nullable=False),
        sa.Column('user_id', sa.String(36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('local_date', sa.String(10), nullable=False),
        sa.Column('care_kind', sa.String(24), nullable=False),
        sa.Column('source_type', sa.String(32), nullable=False),
        sa.Column('source_id', sa.String(64), nullable=False),
        sa.Column('xp_delta', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('group_id', 'user_id', 'local_date', 'care_kind', name='uq_commitment_pet_daily_care'),
        sa.UniqueConstraint('group_id', 'source_type', 'source_id', name='uq_commitment_pet_source'),
    )
    op.create_index('ix_commitment_pet_care_group_id', 'commitment_pet_care', ['group_id'])
    op.create_index('ix_commitment_pet_care_user_id', 'commitment_pet_care', ['user_id'])
    op.create_index('ix_commitment_pet_care_local_date', 'commitment_pet_care', ['local_date'])


def downgrade() -> None:
    op.drop_table('commitment_pet_care')
    op.drop_table('commitment_group_join_requests')
    op.drop_table('commitment_group_invites')
    op.drop_table('commitment_group_members')
    op.drop_table('commitment_groups')
