import asyncio
import base64
import io
import json
import uuid
import wave
from datetime import datetime, timedelta, timezone

import httpx
import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import select

from app.config import Settings
from app.db.models import IdempotencyRecord
from app.main import create_app
from app.services.gemini_service import GeminiService, GeminiServiceError
from app.services.speech_service import synthesize_reply, validate_wav


def sample_wav():
    out = io.BytesIO()
    with wave.open(out, 'wb') as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(24000)
        audio.writeframes(b'\0\0' * 240)
    return out.getvalue()


def settings(tmp_path):
    return Settings(_env_file=None, app_env='test', database_url=f'sqlite+pysqlite:///{tmp_path}/voice.db',
        gemini_api_key=SecretStr('test-key'), gemini_mock_mode=False, local_dev_bearer_uid_fallback=True)


def test_provider_audio_and_no_storage_request(tmp_path):
    def handle(request):
        assert request.url.path == '/v1beta/interactions'
        payload = json.loads(request.content)
        assert payload['store'] is False
        assert payload['model'] == 'gemini-3.8-flash-tts'
        assert payload['response_format'] == {'type': 'audio'}
        return httpx.Response(200, json={'steps': [{'type': 'model_output', 'content': [
            {'type': 'audio', 'data': base64.b64encode(sample_wav()).decode()}]}]})
    service = GeminiService(settings(tmp_path), transport=httpx.MockTransport(handle))
    raw, model = asyncio.run(synthesize_reply(service, 'Câu trả lời ngắn.'))
    assert raw == sample_wav()
    assert 'tts' in model


@pytest.mark.parametrize('payload', [{}, {'steps': [{'type': 'model_output', 'content': [{'type': 'audio', 'data': 'not-base64'}]}]}])
def test_provider_malformed_audio(tmp_path, payload):
    service = GeminiService(settings(tmp_path), transport=httpx.MockTransport(lambda _: httpx.Response(200, json=payload)))
    with pytest.raises(GeminiServiceError, match='giọng'):
        asyncio.run(synthesize_reply(service, 'Một bước.'))


@pytest.mark.parametrize('raw', [b'RIFFinvalid', sample_wav()[:-4], b'x' * (4194304 + 1)], ids=['header', 'truncated', 'oversize'])
def test_wav_validation(raw):
    with pytest.raises(GeminiServiceError):
        validate_wav(raw)


def test_api_owner_consent_nonce_quota_and_no_audio_persistence(tmp_path):
    calls = []
    def handle(request):
        calls.append(1)
        return httpx.Response(200, json={'steps': [{'type': 'model_output', 'content': [
            {'type': 'audio', 'data': base64.b64encode(sample_wav()).decode()}]}]})
    cfg = settings(tmp_path)
    app = create_app(cfg, gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(handle)))
    h = lambda user, key=None: {'Authorization': f'Bearer dev:{user}', **({'Idempotency-Key': key} if key else {})}
    body = {'text': 'Hãy thử bước đầu.', 'consentGranted': True}
    with TestClient(app) as client:
        uid = client.get('/v1/me', headers=h('a')).json()['id']
        session = client.post('/v1/study/sessions', headers=h('a', str(uuid.uuid4())),
            json={'clientSessionId': 'local-voice', 'taskTitle': 'Ôn tập'}).json()['sessionId']
        path = f'/v1/study/sessions/{session}/speech'
        assert client.post(path, json=body).status_code == 401
        assert client.post(path, headers=h('b', str(uuid.uuid4())), json=body).status_code == 404
        assert client.post(path, headers=h('a', str(uuid.uuid4())), json={**body, 'consentGranted': False}).status_code == 403
        assert client.post(path, headers=h('a'), json=body).status_code == 422
        assert client.post(path, headers=h('a', str(uuid.uuid4())), json={**body, 'text': 'x' * 601}).status_code == 422
        key = str(uuid.uuid4())
        response = client.post(path, headers=h('a', key), json=body)
        assert response.status_code == 200, response.text
        assert response.headers['cache-control'] == 'no-store'
        assert base64.b64decode(response.json()['audioBase64']) == sample_wav()
        assert client.post(path, headers=h('a', key), json=body).status_code == 409
        for _ in range(4):
            assert client.post(path, headers=h('a', str(uuid.uuid4())), json=body).status_code == 200
        assert client.post(path, headers=h('a', str(uuid.uuid4())), json=body).status_code == 429
        assert len(calls) == 5
        from sqlalchemy import create_engine
        from sqlalchemy.orm import Session
        engine = create_engine(cfg.database_url)
        with Session(engine) as db:
            records = list(db.scalars(select(IdempotencyRecord).where(IdempotencyRecord.route == 'speech:v1')))
            assert len(records) == 5
            assert all(r.user_id == uid and r.response_json == {'reserved': True} and
                r.payload_hash == 'speech-reservation-v1' for r in records)
            for record in records:
                record.created_at = datetime.now(timezone.utc) - timedelta(minutes=2)
            db.commit()
        assert client.post(path, headers=h('a', str(uuid.uuid4())), json=body).status_code == 200
        with Session(engine) as db:
            for _ in range(24):
                db.add(IdempotencyRecord(user_id=uid, route='speech:v1', key=str(uuid.uuid4()),
                    payload_hash='speech-reservation-v1', response_json={'reserved': True},
                    created_at=datetime.now(timezone.utc) - timedelta(minutes=2)))
            db.commit()
        assert client.post(path, headers=h('a', str(uuid.uuid4())), json=body).status_code == 429
        client.post(f'/v1/study/sessions/{session}/finish', headers=h('a', str(uuid.uuid4())),
            json={'clientSessionId': 'local-voice', 'finalStatus': 'completed'})
        assert client.post(path, headers=h('a', str(uuid.uuid4())), json=body).status_code == 409
        engine.dispose()


def test_provider_failure_reservation_cannot_repeat(tmp_path):
    cfg = settings(tmp_path)
    app = create_app(cfg, gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(lambda _: httpx.Response(429))))
    key = str(uuid.uuid4())
    h = {'Authorization': 'Bearer dev:a', 'Idempotency-Key': key}
    with TestClient(app) as client:
        session = client.post('/v1/study/sessions', headers=h,
            json={'clientSessionId': 'failed-voice', 'taskTitle': 'Ôn tập'}).json()['sessionId']
        path = f'/v1/study/sessions/{session}/speech'
        assert client.post(path, headers=h, json={'text': 'Thử lại.', 'consentGranted': True}).status_code == 429
        assert client.post(path, headers=h, json={'text': 'Thử lại.', 'consentGranted': True}).status_code == 409


def test_missing_key_is_not_a_configuration_prompt_for_students(tmp_path):
    cfg = settings(tmp_path)
    cfg.gemini_api_key = SecretStr('')
    app = create_app(cfg)
    h = {'Authorization': 'Bearer dev:no_key', 'Idempotency-Key': str(uuid.uuid4())}
    with TestClient(app) as client:
        sid = client.post('/v1/study/sessions', headers=h,
            json={'clientSessionId': 'no_key_voice', 'taskTitle': 'Ôn tập'}).json()['sessionId']
        result = client.post(f'/v1/study/sessions/{sid}/speech', headers=h,
            json={'text': 'Thử lại.', 'consentGranted': True})
        assert result.status_code == 503
        assert 'GEMINI_API_KEY' not in result.text
        assert result.json()['error']['message'].startswith('Giọng AI chưa sẵn sàng')
