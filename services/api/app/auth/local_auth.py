from __future__ import annotations

from datetime import datetime, timedelta, timezone
import hashlib
import hmac
import os
import re

import jwt

from app.config import Settings

LOCAL_AUTH_ISSUER = 'mindclock-local-auth'
_EMAIL_RE = re.compile(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')


def normalize_email(raw: str) -> str:
    return raw.strip().lower()


def validate_email_format(email: str) -> bool:
    return bool(_EMAIL_RE.match(email))


def is_strong_password(password: str) -> tuple[bool, str | None]:
    if len(password) < 8:
        return False, 'Mật khẩu phải có ít nhất 8 ký tự.'
    if not any('A' <= c <= 'Z' for c in password):
        return False, 'Mật khẩu phải có ít nhất 1 chữ cái in hoa (A–Z).'
    if not any('a' <= c <= 'z' for c in password):
        return False, 'Mật khẩu phải có ít nhất 1 chữ cái thường (a–z).'
    if not any('0' <= c <= '9' for c in password):
        return False, 'Mật khẩu phải có ít nhất 1 chữ số (0–9).'
    if not any(c in '!@#$%^&*(),.?":{}|<>_-+=[]\\/~`' for c in password):
        return False, 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt.'
    return True, None


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    derived = hashlib.scrypt(
        password.encode('utf-8'),
        salt=salt,
        n=16384,
        r=8,
        p=1,
        dklen=32,
    )
    return f'scrypt${salt.hex()}${derived.hex()}'


def verify_password(password: str, stored_hash: str) -> bool:
    parts = stored_hash.split('$')
    if len(parts) != 3 or parts[0] != 'scrypt':
        return False
    try:
        salt = bytes.fromhex(parts[1])
        expected = bytes.fromhex(parts[2])
    except ValueError:
        return False
    candidate = hashlib.scrypt(
        password.encode('utf-8'),
        salt=salt,
        n=16384,
        r=8,
        p=1,
        dklen=32,
    )
    return hmac.compare_digest(candidate, expected)


def issue_auth_tokens(
    *,
    uid: str,
    email: str,
    settings: Settings,
) -> tuple[str, str]:
    now = datetime.now(timezone.utc)
    secret = settings.get_local_auth_secret()
    access_payload = {
        'iss': LOCAL_AUTH_ISSUER,
        'sub': uid,
        'email': email,
        'typ': 'access',
        'iat': int(now.timestamp()),
        'exp': int(
            (now + timedelta(seconds=settings.local_auth_access_ttl_seconds)).timestamp()
        ),
    }
    refresh_payload = {
        'iss': LOCAL_AUTH_ISSUER,
        'sub': uid,
        'email': email,
        'typ': 'refresh',
        'iat': int(now.timestamp()),
        'exp': int(
            (now + timedelta(seconds=settings.local_auth_refresh_ttl_seconds)).timestamp()
        ),
    }
    access_token = jwt.encode(access_payload, secret, algorithm='HS256')
    refresh_token = jwt.encode(refresh_payload, secret, algorithm='HS256')
    return access_token, refresh_token


def decode_local_auth_token(
    token: str,
    settings: Settings,
    *,
    expected_type: str = 'access',
) -> dict[str, object]:
    payload = jwt.decode(
        token,
        settings.get_local_auth_secret(),
        algorithms=['HS256'],
        issuer=LOCAL_AUTH_ISSUER,
        options={'require': ['exp', 'iss', 'sub', 'typ']},
    )
    if payload.get('typ') != expected_type:
        raise jwt.InvalidTokenError('Sai loại token.')
    return payload
