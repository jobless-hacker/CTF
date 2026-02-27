"""seed default roles

Revision ID: a2188e8b8677
Revises: e826212d0419
Create Date: 2026-02-27 01:48:37.590869

"""
import uuid
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'a2188e8b8677'
down_revision: Union[str, Sequence[str], None] = 'e826212d0419'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_roles_table = sa.table(
    "roles",
    sa.column("id", postgresql.UUID(as_uuid=True)),
    sa.column("name", sa.String(length=64)),
    sa.column("description", sa.String(length=255)),
    sa.column("created_at", sa.DateTime(timezone=True)),
    sa.column("updated_at", sa.DateTime(timezone=True)),
)

_seed_roles = (
    {
        "name": "admin",
        "description": "Administrator with elevated privileges",
    },
    {
        "name": "player",
        "description": "Default platform user role",
    },
)


def upgrade() -> None:
    """Upgrade schema."""
    bind = op.get_bind()
    role_names = [role["name"] for role in _seed_roles]

    existing_names = set(
        bind.execute(
            sa.select(_roles_table.c.name).where(_roles_table.c.name.in_(role_names))
        ).scalars()
    )

    for role in _seed_roles:
        if role["name"] in existing_names:
            continue

        bind.execute(
            _roles_table.insert().values(
                id=uuid.uuid4(),
                name=role["name"],
                description=role["description"],
                created_at=sa.func.now(),
                updated_at=sa.func.now(),
            )
        )


def downgrade() -> None:
    """Downgrade schema."""
    bind = op.get_bind()
    bind.execute(
        _roles_table.delete().where(
            _roles_table.c.name.in_([role["name"] for role in _seed_roles])
        )
    )
