"""Add commitment_group_busy_days table for group busy-day streak preservation (T084).

Revision ID: 0010_add_group_busy_days
Revises: 0009_add_subject_memories
Create Date: 2026-11-27
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0010_add_group_busy_days'
down_revision: Union[str, None] = '0009_add_subject_memories'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'commitment_group_busy_days',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('group_id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('local_date', sa.String(length=10), nullable=False),
        sa.Column('month_key', sa.String(length=7), nullable=False),
        sa.Column('reason', sa.String(length=64), nullable=False, server_default='busy'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['group_id'], ['commitment_groups.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('group_id', 'user_id', 'local_date', name='uq_group_busy_user_date'),
    )
    op.create_index('ix_commitment_group_busy_days_group_id', 'commitment_group_busy_days', ['group_id'], unique=False)
    op.create_index('ix_commitment_group_busy_days_user_id', 'commitment_group_busy_days', ['user_id'], unique=False)
    op.create_index('ix_commitment_group_busy_days_local_date', 'commitment_group_busy_days', ['local_date'], unique=False)
    op.create_index('ix_commitment_group_busy_days_month_key', 'commitment_group_busy_days', ['month_key'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_commitment_group_busy_days_month_key', table_name='commitment_group_busy_days')
    op.drop_index('ix_commitment_group_busy_days_local_date', table_name='commitment_group_busy_days')
    op.drop_index('ix_commitment_group_busy_days_user_id', table_name='commitment_group_busy_days')
    op.drop_index('ix_commitment_group_busy_days_group_id', table_name='commitment_group_busy_days')
    op.drop_table('commitment_group_busy_days')
