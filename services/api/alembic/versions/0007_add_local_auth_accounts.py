"""Add PostgreSQL-backed local auth accounts for backend email/password auth (T076).

Revision ID: 0007_local_auth_accounts
Revises: 0006_primary_commitment_pet
Create Date: 2026-11-21
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0007_local_auth_accounts'
down_revision: Union[str, None] = '0006_primary_commitment_pet'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'local_auth_accounts',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('email', sa.String(length=254), nullable=False),
        sa.Column('password_hash', sa.String(length=256), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        'ix_local_auth_accounts_user_id',
        'local_auth_accounts',
        ['user_id'],
        unique=True,
    )
    op.create_index(
        'ix_local_auth_accounts_email',
        'local_auth_accounts',
        ['email'],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index('ix_local_auth_accounts_email', table_name='local_auth_accounts')
    op.drop_index('ix_local_auth_accounts_user_id', table_name='local_auth_accounts')
    op.drop_table('local_auth_accounts')
