from collections.abc import Generator
from typing import Any

from sqlalchemy import Engine, create_engine, event
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import Settings, get_settings


class Base(DeclarativeBase):
    pass


def build_engine(settings: Settings | None = None) -> Engine:
    cfg = settings or get_settings()
    connect_args: dict[str, Any] = {}
    engine_kwargs: dict[str, Any] = {
        'echo': False,
        'future': True,
    }
    if cfg.is_sqlite:
        connect_args['check_same_thread'] = False
        connect_args['timeout'] = 10
    else:
        engine_kwargs['pool_pre_ping'] = True
        engine_kwargs['pool_size'] = 10
        engine_kwargs['max_overflow'] = 20

    engine = create_engine(cfg.database_url, connect_args=connect_args, **engine_kwargs)

    if cfg.is_sqlite:
        is_memory = ':memory:' in cfg.database_url or 'mode=memory' in cfg.database_url
        enable_wal = not is_memory and cfg.app_env.lower() != 'test'

        @event.listens_for(engine, 'connect')
        def _set_sqlite_pragmas(dbapi_conn: Any, _record: Any) -> None:
            cursor = dbapi_conn.cursor()
            cursor.execute('PRAGMA foreign_keys=ON')
            cursor.execute('PRAGMA busy_timeout=5000')
            if enable_wal:
                cursor.execute('PRAGMA journal_mode=WAL')
            cursor.close()

    return engine


def create_session_factory(engine: Engine) -> sessionmaker[Session]:
    return sessionmaker(
        bind=engine,
        autoflush=False,
        autocommit=False,
        expire_on_commit=False,
    )


def db_session_dependency(
    session_factory: sessionmaker[Session],
) -> Generator[Session, None, None]:
    session = session_factory()
    try:
        yield session
    finally:
        session.close()
