"""fix_sqlite_now

Revision ID: 516b9bce5e2c
Revises: 9dceb569e6b3
Create Date: 2026-03-01 13:59:34.532498

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '516b9bce5e2c'
down_revision: Union[str, Sequence[str], None] = '9dceb569e6b3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
