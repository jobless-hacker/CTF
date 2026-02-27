"""create challenge_solves table

Revision ID: 55a5c1608623
Revises: 428e5fff16fd
Create Date: 2026-02-27 03:04:30.213013

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '55a5c1608623'
down_revision: Union[str, Sequence[str], None] = '428e5fff16fd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    bind = op.get_bind()
    is_postgresql = bind.dialect.name == "postgresql"

    op.create_table('challenge_solves',
    sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('challenge_id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('points_awarded', sa.Integer(), nullable=False),
    sa.Column('is_first_blood', sa.Boolean(), server_default=sa.text('false'), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.CheckConstraint('points_awarded > 0', name='ck_challenge_solves_points_awarded_positive'),
    sa.ForeignKeyConstraint(['challenge_id'], ['challenges.id'], name=op.f('fk_challenge_solves_challenge_id_challenges'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], name=op.f('fk_challenge_solves_user_id_users'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_challenge_solves')),
    sa.UniqueConstraint('user_id', 'challenge_id', name=op.f('uq_challenge_solves_user_id'))
    )
    op.create_index(op.f('ix_challenge_solves_user_id'), 'challenge_solves', ['user_id'], unique=False)
    op.create_index(op.f('ix_challenge_solves_challenge_id'), 'challenge_solves', ['challenge_id'], unique=False)
    op.create_index('ix_challenge_solves_challenge_id_created_at', 'challenge_solves', ['challenge_id', 'created_at'], unique=False)
    op.create_index('ix_challenge_solves_user_id_created_at', 'challenge_solves', ['user_id', 'created_at'], unique=False)
    if is_postgresql:
        op.create_index(
            'ux_challenge_solves_first_blood_challenge_id',
            'challenge_solves',
            ['challenge_id'],
            unique=True,
            postgresql_where=sa.text('is_first_blood = true'),
        )


def downgrade() -> None:
    """Downgrade schema."""
    bind = op.get_bind()
    is_postgresql = bind.dialect.name == "postgresql"

    if is_postgresql:
        op.drop_index('ux_challenge_solves_first_blood_challenge_id', table_name='challenge_solves')
    op.drop_index('ix_challenge_solves_user_id_created_at', table_name='challenge_solves')
    op.drop_index('ix_challenge_solves_challenge_id_created_at', table_name='challenge_solves')
    op.drop_index(op.f('ix_challenge_solves_user_id'), table_name='challenge_solves')
    op.drop_index(op.f('ix_challenge_solves_challenge_id'), table_name='challenge_solves')
    op.drop_table('challenge_solves')
