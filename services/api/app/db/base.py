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
    else:
        engine_kwargs['pool_pre_ping'] = True
        engine_kwargs['pool_size'] = 10
        engine_kwargs['max_overflow'] = 20

    engine = create_engine(cfg.database_url, connect_args=connect_args, **engine_kwargs)

    if cfg.is_sqlite:
        @event.listens_for(engine, 'connect')
        def _set_sqlite_pragmas(dbapi_conn: Any, _record: Any) -> None:
            cursor = dbapi_conn.cursor()
            cursor.execute('PRAGMA foreign_keys=ON')
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
