"""Add the server-selected primary commitment pet (T075).

Revision ID: 0006_primary_commitment_pet
Revises: 0005_commitment_groups_pet
Create Date: 2026-11-21
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0006_primary_commitment_pet'
down_revision: Union[str, None] = '0005_commitment_groups_pet'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'commitment_group_members',
        sa.Column('is_primary', sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.execute(sa.text("""
        UPDATE commitment_group_members
        SET is_primary = true
        WHERE id IN (
            SELECT id FROM (
                SELECT id,
                       ROW_NUMBER() OVER (
                           PARTITION BY user_id ORDER BY joined_at ASC, id ASC
                       ) AS row_no
                FROM commitment_group_members
                WHERE status = 'active'
            ) ranked
            WHERE row_no = 1
        )
    """))
    if op.get_bind().dialect.name == 'postgresql':
        op.create_index(
            'uq_commitment_primary_per_user',
            'commitment_group_members',
            ['user_id'],
            unique=True,
            postgresql_where=sa.text("status = 'active' AND is_primary = true"),
        )


def downgrade() -> None:
    if op.get_bind().dialect.name == 'postgresql':
        op.drop_index('uq_commitment_primary_per_user', table_name='commitment_group_members')
    op.drop_column('commitment_group_members', 'is_primary')
