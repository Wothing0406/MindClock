"""Add daily_reports table for daily check-in report streak tracking (T077).

Revision ID: 0008_add_daily_reports
Revises: 0007_local_auth_accounts
Create Date: 2026-11-27
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0008_add_daily_reports'
down_revision: Union[str, None] = '0007_local_auth_accounts'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'daily_reports',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('local_date', sa.String(length=10), nullable=False),
        sa.Column('study_minutes', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('tasks_completed', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('challenge_completed', sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column('feeling', sa.String(length=24), nullable=False, server_default='steady'),
        sa.Column('reflection_note', sa.Text(), nullable=False, server_default=''),
        sa.Column('xp_awarded', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'local_date', name='uq_daily_report_user_date'),
    )
    op.create_index('ix_daily_reports_user_id', 'daily_reports', ['user_id'], unique=False)
    op.create_index('ix_daily_reports_local_date', 'daily_reports', ['local_date'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_daily_reports_local_date', table_name='daily_reports')
    op.drop_index('ix_daily_reports_user_id', table_name='daily_reports')
    op.drop_table('daily_reports')
