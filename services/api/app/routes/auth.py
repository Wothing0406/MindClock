from __future__ import annotations

import uuid
from typing import Any, Callable

from fastapi import APIRouter, Depends, HTTPException, status
from jwt.exceptions import ExpiredSignatureError, InvalidTokenError
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth.local_auth import (
    decode_local_auth_token,
    hash_password,
    is_strong_password,
    issue_auth_tokens,
    normalize_email,
    validate_email_format,
    verify_password,
)
from app.config import Settings, get_settings
from app.db.models import LocalAuthAccount, User
from app.schemas import AuthLoginRequest, AuthRefreshRequest, AuthRegisterRequest


def _auth_error(status_code: int, code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={
            'error': {
                'code': code,
                'message': message,
                'requestId': f'req_{uuid.uuid4().hex[:12]}',
                'retryable': False,
            }
        },
    )


def create_auth_router(*, get_db: Callable[..., Any]) -> APIRouter:
    router = APIRouter(prefix='/v1/auth', tags=['auth'])

    @router.post('/register')
    def register_account(
        payload: AuthRegisterRequest,
        settings: Settings = Depends(get_settings),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        if not settings.local_auth_enabled:
            raise _auth_error(
                status.HTTP_403_FORBIDDEN,
                'AUTH_DISABLED',
                'Đăng ký qua máy chủ backend đang tạm tắt.',
            )
        email = normalize_email(payload.email)
        if not validate_email_format(email):
            raise _auth_error(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                'INVALID_EMAIL',
                'Vui lòng nhập email hợp lệ.',
            )
        ok, pw_msg = is_strong_password(payload.password)
        if not ok:
            raise _auth_error(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                'WEAK_PASSWORD',
                pw_msg or 'Mật khẩu chưa đạt chuẩn mạnh.',
            )

        existing = db.scalar(select(LocalAuthAccount).where(LocalAuthAccount.email == email))
        if existing is not None:
            raise _auth_error(
                status.HTTP_409_CONFLICT,
                'EMAIL_EXISTS',
                'Email này đã có tài khoản. Vui lòng chuyển sang Đăng nhập.',
            )

        uid = f'loc_{uuid.uuid4().hex[:20]}'
        clean_alias = (payload.alias or '').strip() or email.split('@', 1)[0][:32]
        user = User(
            auth_subject=uid,
            alias=clean_alias,
            grade_band='Lớp 11',
            selected_subjects_json=['TOAN', 'NGU_VAN', 'TIENG_ANH'],
        )
        db.add(user)
        db.flush()

        account = LocalAuthAccount(
            user_id=user.id,
            email=email,
            password_hash=hash_password(payload.password),
        )
        db.add(account)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise _auth_error(
                status.HTTP_409_CONFLICT,
                'EMAIL_EXISTS',
                'Email này đã có tài khoản. Vui lòng chuyển sang Đăng nhập.',
            )

        access_token, refresh_token = issue_auth_tokens(
            uid=uid,
            email=email,
            settings=settings,
        )
        return {
            'uid': uid,
            'email': email,
            'alias': user.alias,
            'idToken': access_token,
            'refreshToken': refresh_token,
            'emailVerified': True,
            'provider': 'backend_postgres',
        }

    @router.post('/login')
    def login_account(
        payload: AuthLoginRequest,
        settings: Settings = Depends(get_settings),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        if not settings.local_auth_enabled:
            raise _auth_error(
                status.HTTP_403_FORBIDDEN,
                'AUTH_DISABLED',
                'Đăng nhập qua máy chủ backend đang tạm tắt.',
            )
        email = normalize_email(payload.email)
        account = db.scalar(select(LocalAuthAccount).where(LocalAuthAccount.email == email))
        if account is None or not verify_password(payload.password, account.password_hash):
            raise _auth_error(
                status.HTTP_401_UNAUTHORIZED,
                'INVALID_LOGIN_CREDENTIALS',
                'Email hoặc mật khẩu chưa đúng.',
            )
        user = db.get(User, account.user_id)
        if user is None:
            raise _auth_error(
                status.HTTP_401_UNAUTHORIZED,
                'INVALID_LOGIN_CREDENTIALS',
                'Tài khoản không tồn tại hoặc đã bị xóa.',
            )

        access_token, refresh_token = issue_auth_tokens(
            uid=user.auth_subject,
            email=account.email,
            settings=settings,
        )
        return {
            'uid': user.auth_subject,
            'email': account.email,
            'alias': user.alias,
            'idToken': access_token,
            'refreshToken': refresh_token,
            'emailVerified': True,
            'provider': 'backend_postgres',
        }

    @router.post('/refresh')
    def refresh_account_token(
        payload: AuthRefreshRequest,
        settings: Settings = Depends(get_settings),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        if not settings.local_auth_enabled:
            raise _auth_error(
                status.HTTP_403_FORBIDDEN,
                'AUTH_DISABLED',
                'Làm mới token backend đang tạm tắt.',
            )
        try:
            decoded = decode_local_auth_token(
                payload.refresh_token,
                settings,
                expected_type='refresh',
            )
        except ExpiredSignatureError:
            raise _auth_error(
                status.HTTP_401_UNAUTHORIZED,
                'TOKEN_EXPIRED',
                'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            )
        except InvalidTokenError:
            raise _auth_error(
                status.HTTP_401_UNAUTHORIZED,
                'INVALID_REFRESH_TOKEN',
                'Refresh token không hợp lệ.',
            )

        uid = str(decoded.get('sub', '')).strip()
        user = db.scalar(select(User).where(User.auth_subject == uid))
        account = (
            db.scalar(select(LocalAuthAccount).where(LocalAuthAccount.user_id == user.id))
            if user is not None
            else None
        )
        if user is None or account is None:
            raise _auth_error(
                status.HTTP_401_UNAUTHORIZED,
                'INVALID_REFRESH_TOKEN',
                'Tài khoản không còn tồn tại.',
            )

        access_token, new_refresh = issue_auth_tokens(
            uid=user.auth_subject,
            email=account.email,
            settings=settings,
        )
        return {
            'uid': user.auth_subject,
            'idToken': access_token,
            'refreshToken': new_refresh,
            'email': account.email,
        }

    return router
