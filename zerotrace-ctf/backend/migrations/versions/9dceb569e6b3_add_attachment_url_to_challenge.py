"""Add attachment_url to Challenge

Revision ID: 9dceb569e6b3
Revises: 1cadcc5b1f70
Create Date: 2026-03-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9dceb569e6b3'
down_revision: Union[str, Sequence[str], None] = '1cadcc5b1f70'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('challenges', sa.Column('attachment_url', sa.String(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('challenges', 'attachment_url')
