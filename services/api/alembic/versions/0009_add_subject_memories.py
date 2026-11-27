"""Add subject_memories table for per-subject weekly progress & mastery memory (T083).

Revision ID: 0009_add_subject_memories
Revises: 0008_add_daily_reports
Create Date: 2026-11-27
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0009_add_subject_memories'
down_revision: Union[str, None] = '0008_add_daily_reports'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'subject_memories',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('subject_code', sa.String(length=32), nullable=False),
        sa.Column('grade_level', sa.String(length=24), nullable=False, server_default='Lớp 11'),
        sa.Column('current_week', sa.Integer(), nullable=False, server_default='12'),
        sa.Column('current_chapter', sa.String(length=160), nullable=False, server_default=''),
        sa.Column('current_topic', sa.String(length=160), nullable=False, server_default=''),
        sa.Column('mastery_score', sa.Integer(), nullable=False, server_default='50'),
        sa.Column('attempts_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('correct_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('last_practiced_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'subject_code', name='uq_subject_memory_user_subject'),
    )
    op.create_index('ix_subject_memories_user_id', 'subject_memories', ['user_id'], unique=False)
    op.create_index('ix_subject_memories_subject_code', 'subject_memories', ['subject_code'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_subject_memories_subject_code', table_name='subject_memories')
    op.drop_index('ix_subject_memories_user_id', table_name='subject_memories')
    op.drop_table('subject_memories')
