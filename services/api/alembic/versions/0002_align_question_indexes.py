"""Align questions single-column indexes with SQLAlchemy models (B01c)

Revision ID: 0002_align_question_indexes
Revises: 0001_initial_schema
Create Date: 2026-11-16
"""
from typing import Sequence, Union

from alembic import op

revision: str = '0002_align_question_indexes'
down_revision: Union[str, None] = '0001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index('ix_questions_subject_code', 'questions', ['subject_code'], unique=False)
    op.create_index('ix_questions_grade_band', 'questions', ['grade_band'], unique=False)
    op.create_index('ix_questions_topic_id', 'questions', ['topic_id'], unique=False)
    op.create_index('ix_questions_status', 'questions', ['status'], unique=False)
    op.create_index('ix_questions_source_type', 'questions', ['source_type'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_questions_source_type', table_name='questions')
    op.drop_index('ix_questions_status', table_name='questions')
    op.drop_index('ix_questions_topic_id', table_name='questions')
    op.drop_index('ix_questions_grade_band', table_name='questions')
    op.drop_index('ix_questions_subject_code', table_name='questions')
