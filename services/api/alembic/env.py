from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from app.config import get_settings
from app.db.base import Base
import app.db.models  # noqa: F401

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name, disable_existing_loggers=False)

target_metadata = Base.metadata
_DEFAULT_INI_URL = 'sqlite+pysqlite:///./mindclock_local.db'


def get_url() -> str:
    override_url = config.attributes.get('sqlalchemy.url')
    if isinstance(override_url, str) and override_url.strip():
        return override_url.strip()
    ini_url = config.get_main_option('sqlalchemy.url')
    if ini_url and ini_url.strip() and ini_url.strip() != _DEFAULT_INI_URL:
        return ini_url.strip()
    return get_settings().database_url


def run_migrations_offline() -> None:
    context.configure(
        url=get_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={'paramstyle': 'named'},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    section = config.get_section(config.config_ini_section, {})
    section['sqlalchemy.url'] = get_url()
    connectable = engine_from_config(
        section,
        prefix='sqlalchemy.',
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
