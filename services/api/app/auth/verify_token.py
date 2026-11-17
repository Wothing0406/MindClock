from dataclasses import dataclass
from typing import Any
import uuid

from fastapi import Depends, Header, HTTPException, status
import jwt
from jwt import PyJWKClient
from jwt.exceptions import ExpiredSignatureError, InvalidTokenError, PyJWKError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db.models import User


GOOGLE_FIREBASE_JWKS_URL = (
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
)
_jwks_client: PyJWKClient | None = None


def get_jwks_client() -> PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        _jwks_client = PyJWKClient(
            GOOGLE_FIREBASE_JWKS_URL,
            cache_jwk_set=True,
            lifespan=3600,
            timeout=5,
        )
    return _jwks_client


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

    project_id = (settings.firebase_project_id or '').strip()
    if not project_id:
        _raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            'AUTH_EXPIRED',
            'Chưa cấu hình Firebase Project ID để xác minh danh tính.',
        )

    try:
        signing_key = get_jwks_client().get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=['RS256'],
            audience=project_id,
            issuer=f'https://securetoken.google.com/{project_id}',
            options={'require': ['exp', 'iss', 'aud', 'sub']},
        )
        uid = str(payload.get('sub', '')).strip()
        if not uid:
            _raise_api_error(
                status.HTTP_401_UNAUTHORIZED,
                'AUTH_EXPIRED',
                'Firebase ID token không chứa định danh người dùng (sub).',
            )
        return uid
    except ExpiredSignatureError:
        _raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            'AUTH_EXPIRED',
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        )
    except (InvalidTokenError, PyJWKError) as exc:
        _raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            'AUTH_EXPIRED',
            f'Token xác thực Firebase không hợp lệ: {str(exc)}',
        )
    except Exception as exc:
        _raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            'AUTH_EXPIRED',
            f'Không thể xác minh Firebase ID token: {str(exc)}',
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
