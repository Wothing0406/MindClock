import time
from unittest.mock import MagicMock, patch

import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import HTTPException
import pytest

from app.auth.verify_token import verify_bearer_token
from app.config import Settings


@pytest.fixture
def rsa_key_pair():
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )
    public_key = private_key.public_key()
    return private_key, public_key


def test_verify_missing_or_malformed_token():
    settings = Settings(app_env='development', local_dev_bearer_uid_fallback=True)
    with pytest.raises(HTTPException) as exc:
        verify_bearer_token(None, settings)
    assert exc.value.status_code == 401
    assert exc.value.detail['error']['code'] == 'AUTH_EXPIRED'

    with pytest.raises(HTTPException) as exc:
        verify_bearer_token('Basic 123456', settings)
    assert exc.value.status_code == 401
    assert exc.value.detail['error']['code'] == 'AUTH_EXPIRED'

    with pytest.raises(HTTPException) as exc:
        verify_bearer_token('Bearer   ', settings)
    assert exc.value.status_code == 401
    assert exc.value.detail['error']['code'] == 'AUTH_EXPIRED'


def test_verify_dev_fallback_tokens():
    settings = Settings(app_env='development', local_dev_bearer_uid_fallback=True)
    assert verify_bearer_token('Bearer dev:student_thpt_01', settings) == 'student_thpt_01'
    assert verify_bearer_token('Bearer token_student_thpt_02_v1', settings) == 'student_thpt_02'


def test_verify_dev_fallback_rejected_in_production():
    settings = Settings(
        app_env='production',
        local_dev_bearer_uid_fallback=True,
        firebase_project_id='mindclock',
    )
    with pytest.raises(HTTPException) as exc:
        verify_bearer_token('Bearer dev:student_thpt_01', settings)
    assert exc.value.status_code == 401
    assert exc.value.detail['error']['code'] == 'AUTH_EXPIRED'


def test_verify_missing_project_id_raises_auth_expired():
    settings = Settings(
        app_env='production',
        local_dev_bearer_uid_fallback=False,
        firebase_project_id='',
    )
    with pytest.raises(HTTPException) as exc:
        verify_bearer_token('Bearer some_real_jwt_token', settings)
    assert exc.value.status_code == 401
    assert exc.value.detail['error']['code'] == 'AUTH_EXPIRED'


def test_verify_valid_firebase_jwt(rsa_key_pair):
    private_key, public_key = rsa_key_pair
    settings = Settings(
        app_env='production',
        local_dev_bearer_uid_fallback=False,
        firebase_project_id='mindclock',
    )

    now = int(time.time())
    payload = {
        'iss': 'https://securetoken.google.com/mindclock',
        'aud': 'mindclock',
        'auth_time': now - 10,
        'user_id': 'firebase_student_99',
        'sub': 'firebase_student_99',
        'iat': now - 10,
        'exp': now + 3600,
        'email': 'student@mindclock.edu.vn',
        'email_verified': True,
    }
    token = jwt.encode(payload, private_key, algorithm='RS256', headers={'kid': 'test-key-id'})

    mock_signing_key = MagicMock()
    mock_signing_key.key = public_key

    with patch('app.auth.verify_token.get_jwks_client') as mock_client_factory:
        mock_client = MagicMock()
        mock_client.get_signing_key_from_jwt.return_value = mock_signing_key
        mock_client_factory.return_value = mock_client

        uid = verify_bearer_token(f'Bearer {token}', settings)
        assert uid == 'firebase_student_99'


def test_verify_expired_firebase_jwt(rsa_key_pair):
    private_key, public_key = rsa_key_pair
    settings = Settings(
        app_env='production',
        local_dev_bearer_uid_fallback=False,
        firebase_project_id='mindclock',
    )

    now = int(time.time())
    payload = {
        'iss': 'https://securetoken.google.com/mindclock',
        'aud': 'mindclock',
        'auth_time': now - 7200,
        'sub': 'firebase_student_expired',
        'iat': now - 7200,
        'exp': now - 3600,
    }
    token = jwt.encode(payload, private_key, algorithm='RS256', headers={'kid': 'test-key-id'})

    mock_signing_key = MagicMock()
    mock_signing_key.key = public_key

    with patch('app.auth.verify_token.get_jwks_client') as mock_client_factory:
        mock_client = MagicMock()
        mock_client.get_signing_key_from_jwt.return_value = mock_signing_key
        mock_client_factory.return_value = mock_client

        with pytest.raises(HTTPException) as exc:
            verify_bearer_token(f'Bearer {token}', settings)
        assert exc.value.status_code == 401
        assert exc.value.detail['error']['code'] == 'AUTH_EXPIRED'


def test_verify_invalid_audience_rejected(rsa_key_pair):
    private_key, public_key = rsa_key_pair
    settings = Settings(
        app_env='production',
        local_dev_bearer_uid_fallback=False,
        firebase_project_id='mindclock',
    )

    now = int(time.time())
    payload = {
        'iss': 'https://securetoken.google.com/other-project',
        'aud': 'other-project',
        'sub': 'intruder_uid',
        'iat': now - 10,
        'exp': now + 3600,
    }
    token = jwt.encode(payload, private_key, algorithm='RS256', headers={'kid': 'test-key-id'})

    mock_signing_key = MagicMock()
    mock_signing_key.key = public_key

    with patch('app.auth.verify_token.get_jwks_client') as mock_client_factory:
        mock_client = MagicMock()
        mock_client.get_signing_key_from_jwt.return_value = mock_signing_key
        mock_client_factory.return_value = mock_client

        with pytest.raises(HTTPException) as exc:
            verify_bearer_token(f'Bearer {token}', settings)
        assert exc.value.status_code == 401
        assert exc.value.detail['error']['code'] == 'AUTH_EXPIRED'
