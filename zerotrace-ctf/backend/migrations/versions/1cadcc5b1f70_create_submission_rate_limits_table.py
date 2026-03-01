"""create submission_rate_limits table

Revision ID: 1cadcc5b1f70
Revises: 55a5c1608623
Create Date: 2026-02-27 03:58:24.972513

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '1cadcc5b1f70'
down_revision: Union[str, Sequence[str], None] = '55a5c1608623'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('submission_rate_limits',
    sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('challenge_id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('window_started_at', sa.DateTime(timezone=True), nullable=False),
    sa.Column('attempt_count', sa.Integer(), nullable=False),
    sa.Column('violation_count', sa.Integer(), server_default=sa.text('0'), nullable=False),
    sa.Column('lock_until', sa.DateTime(timezone=True), nullable=True),
    sa.Column('last_attempt_at', sa.DateTime(timezone=True), nullable=False),
    sa.Column('last_blocked_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
    sa.CheckConstraint('attempt_count >= 0', name='ck_submission_rate_limits_attempt_count_non_negative'),
    sa.CheckConstraint('violation_count >= 0', name='ck_submission_rate_limits_violation_count_non_negative'),
    sa.ForeignKeyConstraint(['challenge_id'], ['challenges.id'], name=op.f('fk_submission_rate_limits_challenge_id_challenges'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], name=op.f('fk_submission_rate_limits_user_id_users'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_submission_rate_limits')),
    sa.UniqueConstraint('user_id', 'challenge_id', name=op.f('uq_submission_rate_limits_user_id'))
    )
    op.create_index(op.f('ix_submission_rate_limits_last_attempt_at'), 'submission_rate_limits', ['last_attempt_at'], unique=False)
    op.create_index(op.f('ix_submission_rate_limits_lock_until'), 'submission_rate_limits', ['lock_until'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_submission_rate_limits_lock_until'), table_name='submission_rate_limits')
    op.drop_index(op.f('ix_submission_rate_limits_last_attempt_at'), table_name='submission_rate_limits')
    op.drop_table('submission_rate_limits')
