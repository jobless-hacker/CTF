"""seed default tracks

Revision ID: 0780a7f8188d
Revises: aeafc4b9b9fd
Create Date: 2026-02-27 02:04:33.751731

"""
import uuid
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '0780a7f8188d'
down_revision: Union[str, Sequence[str], None] = 'aeafc4b9b9fd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_tracks_table = sa.table(
    "tracks",
    sa.column("id", postgresql.UUID(as_uuid=True)),
    sa.column("name", sa.String(length=100)),
    sa.column("slug", sa.String(length=64)),
    sa.column("description", sa.String(length=255)),
    sa.column("is_active", sa.Boolean()),
    sa.column("created_at", sa.DateTime(timezone=True)),
    sa.column("updated_at", sa.DateTime(timezone=True)),
)

_seed_tracks = (
    {
        "name": "Linux",
        "slug": "linux",
        "description": "Linux fundamentals and system exploitation",
    },
    {
        "name": "Networking",
        "slug": "networking",
        "description": "Packet analysis and protocol exploitation",
    },
    {
        "name": "Cryptography",
        "slug": "cryptography",
        "description": "Encryption, encoding, and cryptanalysis challenges",
    },
)


def upgrade() -> None:
    """Upgrade schema."""
    bind = op.get_bind()
    seed_slugs = [track["slug"] for track in _seed_tracks]

    existing_slugs = set(
        bind.execute(
            sa.select(_tracks_table.c.slug).where(_tracks_table.c.slug.in_(seed_slugs))
        ).scalars()
    )

    for track in _seed_tracks:
        if track["slug"] in existing_slugs:
            continue

        bind.execute(
            _tracks_table.insert().values(
                id=uuid.uuid4(),
                name=track["name"],
                slug=track["slug"],
                description=track["description"],
                is_active=True,
                created_at=sa.func.now(),
                updated_at=sa.func.now(),
            )
        )


def downgrade() -> None:
    """Downgrade schema."""
    bind = op.get_bind()
    bind.execute(
        _tracks_table.delete().where(
            _tracks_table.c.slug.in_([track["slug"] for track in _seed_tracks])
        )
    )
