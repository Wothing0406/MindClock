from dataclasses import dataclass
from typing import Any
import uuid

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db.models import User


@dataclass(frozen=True)
class AuthenticatedPrincipal:
    uid: str
    user: User


def _raise_api_error(status_code: int, code: str, message: str, retryable: bool = False) -> None:
    raise HTTPException(
        status_code=status_code,
        detail={
            'error': {
                'code': code,
                'message': message,
                'requestId': f'req_{uuid.uuid4().hex[:12]}',
                'retryable': retryable,
            }
        },
    )


def _decode_local_dev_uid(token: str) -> str | None:
    # Hỗ trợ định dạng token kiểm thử nội bộ từ FirebaseAuthGateway/Loopback (`token_<uid>_vN`)
    # hoặc `dev:<uid>` khi LOCAL_DEV_BEARER_UID_FALLBACK=true ở development.
    if token.startswith('dev:'):
        candidate = token.split(':', 1)[1].strip()
        return candidate if candidate else None
    if token.startswith('token_') and '_v' in token:
        body = token[len('token_') :]
        uid_part, version_part = body.rsplit('_v', 1)
        if uid_part and version_part.isdigit():
            return uid_part
    return None


def verify_bearer_token(
    authorization: str | None,
    settings: Settings,
) -> str:
    if not authorization or not authorization.startswith('Bearer '):
        _raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            'AUTH_EXPIRED',
            'Thiếu hoặc sai định dạng Authorization Bearer token.',
        )
    token = authorization[len('Bearer ') :].strip()
    if not token:
        _raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            'AUTH_EXPIRED',
            'Token trống.',
        )

    if settings.local_dev_bearer_uid_fallback and settings.app_env.lower() in {
        'development',
        'test',
        'local',
    }:
        dev_uid = _decode_local_dev_uid(token)
        if dev_uid:
            return dev_uid

    # Nếu chưa cấu hình Firebase Admin/project verifier thật ngoài dev fallback:
    _raise_api_error(
        status.HTTP_401_UNAUTHORIZED,
        'AUTH_EXPIRED',
        'Token hết hạn hoặc chưa xác minh được với Firebase project.',
    )
    raise AssertionError('Unreachable')


def resolve_or_create_user(db: Session, auth_subject: str) -> User:
    existing = db.scalar(select(User).where(User.auth_subject == auth_subject))
    if existing is not None:
        return existing
    created = User(
        auth_subject=auth_subject,
        alias=f'Học sinh {auth_subject[:8]}',
        grade_band='Lớp 9',
        selected_subjects_json=['TOAN', 'NGU_VAN', 'TIENG_ANH'],
    )
    db.add(created)
    db.commit()
    db.refresh(created)
    return created


def build_auth_dependency(get_db_dep: Any):
    def _current_principal(
        authorization: str | None = Header(default=None),
        settings: Settings = Depends(get_settings),
        db: Session = Depends(get_db_dep),
    ) -> AuthenticatedPrincipal:
        uid = verify_bearer_token(authorization, settings)
        user = resolve_or_create_user(db, uid)
        return AuthenticatedPrincipal(uid=uid, user=user)

    return _current_principal
