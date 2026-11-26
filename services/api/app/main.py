from contextlib import asynccontextmanager
from typing import Callable

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import inspect as sa_inspect
from sqlalchemy.orm import sessionmaker, Session

from app.auth.verify_token import build_auth_dependency
from app.config import Settings, get_settings
from app.db.base import Base, build_engine, create_session_factory, db_session_dependency
from app.db.seed import seed_approved_questions
from app.demo_ui import create_demo_router
try:
    from app.product_ui import create_product_router
except ImportError:  # pragma: no cover
    create_product_router = None
from app.routes.auth import create_auth_router
from app.routes.v1 import create_v1_router
from app.services.gemini_service import GeminiService


def create_app(
    settings: Settings | None = None,
    *,
    gemini_factory: Callable[[Settings], GeminiService] | None = None,
) -> FastAPI:
    cfg = settings or get_settings()
    engine = build_engine(cfg)
    session_factory: sessionmaker[Session] = create_session_factory(engine)

    def _get_db():
        yield from db_session_dependency(session_factory)

    def _get_settings_override() -> Settings:
        return cfg

    current_user_dep = build_auth_dependency(_get_db)

    @asynccontextmanager
    async def lifespan(_app: FastAPI):
        # Chỉ tự create_all khi DB chưa do Alembic quản lý (tránh tạo bảng vượt trước alembic_version trên PostgreSQL).
        if cfg.app_env.lower() in {'development', 'test', 'local'}:
            if not sa_inspect(engine).has_table('alembic_version'):
                Base.metadata.create_all(bind=engine)
            with session_factory() as db:
                seed_approved_questions(db)
        yield
        engine.dispose()

    app = FastAPI(
        title='MindClock API v1',
        version='0.1.0',
        lifespan=lifespan,
    )
    app.dependency_overrides[get_settings] = _get_settings_override

    app.add_middleware(
        CORSMiddleware,
        allow_origins=cfg.cors_origins_list or ['*'],
        allow_credentials=True,
        allow_methods=['*'],
        allow_headers=['*'],
    )

    @app.exception_handler(HTTPException)
    async def _mindclock_http_exception_handler(
        _request: Request, exc: HTTPException
    ) -> JSONResponse:
        if isinstance(exc.detail, dict) and 'error' in exc.detail:
            return JSONResponse(status_code=exc.status_code, content=exc.detail)
        return JSONResponse(status_code=exc.status_code, content={'detail': exc.detail})

    app.include_router(create_auth_router(get_db=_get_db))
    app.include_router(
        create_v1_router(
            get_db=_get_db,
            get_current_user=current_user_dep,
            gemini_factory=gemini_factory,
        )
    )
    if cfg.app_env.lower() in {'development', 'test', 'local'}:
        app.include_router(create_demo_router())
        if create_product_router is not None:
            app.include_router(create_product_router())
    return app


app = create_app()
