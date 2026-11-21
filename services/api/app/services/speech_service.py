"""Ephemeral AI speech; never persists transcript/audio."""
import base64
import binascii
import io
import wave
from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session
from app.db.models import IdempotencyRecord, StudySession, User
from app.services.gemini_service import GeminiService, GeminiServiceError

SPEECH_ROUTE = 'speech:v1'
MAX_AUDIO_BYTES = 4 * 1024 * 1024


def validate_wav(raw: bytes) -> None:
    try:
        if not 44 < len(raw) <= MAX_AUDIO_BYTES:
            raise ValueError('audio size')
        with wave.open(io.BytesIO(raw), 'rb') as audio:
            if (audio.getnchannels() not in (1, 2) or audio.getsampwidth() != 2
                    or not 8000 <= audio.getframerate() <= 48000
                    or not 0 < audio.getnframes() / audio.getframerate() <= 90):
                raise ValueError('audio format')
            if len(audio.readframes(audio.getnframes())) != audio.getnframes() * audio.getnchannels() * 2:
                raise ValueError('truncated audio')
    except (ValueError, wave.Error, EOFError) as exc:
        raise GeminiServiceError(code='SPEECH_INVALID_AUDIO',
            message_vi='Dịch vụ giọng nói trả âm thanh không hợp lệ.', status_code=502) from exc


def reserve_speech(db: Session, *, user_id: str, session_id: str, key: str,
                   consent: bool, now: datetime | None = None) -> None:
    """Commit BEFORE provider IO; user row lock serializes across workers."""
    now = now or datetime.now(timezone.utc)
    db.scalar(select(User).where(User.id == user_id).with_for_update())
    session = db.scalar(select(StudySession).where(
        StudySession.id == session_id, StudySession.user_id == user_id))
    if session is None:
        raise GeminiServiceError(code='STUDY_SESSION_NOT_FOUND',
            message_vi='Không tìm thấy phiên học của bạn.', status_code=404, retryable=False)
    if session.ended_at is not None or session.state not in ('active', 'running'):
        raise GeminiServiceError(code='STUDY_SESSION_ENDED',
            message_vi='Phiên học đã kết thúc.', status_code=409, retryable=False)
    if not consent:
        raise GeminiServiceError(code='SPEECH_CONSENT_REQUIRED',
            message_vi='Cần đồng ý gửi nội dung để tạo giọng AI.', status_code=403, retryable=False)
    if db.scalar(select(IdempotencyRecord.id).where(
            IdempotencyRecord.user_id == user_id, IdempotencyRecord.route == SPEECH_ROUTE,
            IdempotencyRecord.key == key)):
        raise GeminiServiceError(code='SPEECH_REQUEST_USED', message_vi='Yêu cầu giọng đọc này đã được xử lý.',
            status_code=409, retryable=False)
    base = select(func.count(IdempotencyRecord.id)).where(
        IdempotencyRecord.user_id == user_id, IdempotencyRecord.route == SPEECH_ROUTE)
    minute = db.scalar(base.where(IdempotencyRecord.created_at >= now - timedelta(minutes=1))) or 0
    day = db.scalar(base.where(IdempotencyRecord.created_at >= now.replace(hour=0, minute=0, second=0, microsecond=0))) or 0
    if minute >= 5 or day >= 30:
        raise GeminiServiceError(code='SPEECH_QUOTA', message_vi='Đã đạt giới hạn giọng đọc. Bạn vẫn có thể đọc câu trả lời.',
            status_code=429, retryable=False)
    db.add(IdempotencyRecord(user_id=user_id, route=SPEECH_ROUTE, key=key,
        payload_hash='speech-reservation-v1', response_json={'reserved': True},
        status_code=202, created_at=now))
    db.commit()


async def synthesize_reply(gemini: GeminiService, text: str) -> tuple[bytes, str]:
    settings = gemini._settings
    if settings.gemini_mock_mode:
        raise GeminiServiceError(code='SPEECH_NOT_AVAILABLE', message_vi='Giọng AI chưa được bật trên máy chủ.', retryable=False)
    data = await gemini._post_json('/v1beta/interactions', {
        'model': settings.gemini_tts_model,
        'input': [{'type': 'user_input', 'content': [{'type': 'text', 'text': text,
            'annotations': [{'type': 'speech_metadata', 'style': 'Read in natural Vietnamese, calm, clear, warm, at a moderate pace.'}]}]}],
        'response_format': {'type': 'audio'},
        'generation_config': {'speech_config': [{'voice': settings.gemini_tts_voice}]},
        'store': False,
    }, timeout_override=settings.gemini_tts_timeout_seconds)
    encoded = None
    for step in data.get('steps', []):
        if not isinstance(step, dict) or step.get('type') != 'model_output':
            continue
        for part in step.get('content', []):
            if isinstance(part, dict) and part.get('type') == 'audio':
                encoded = part.get('data')
    try:
        if not isinstance(encoded, str) or len(encoded) > MAX_AUDIO_BYTES * 4 // 3 + 8:
            raise ValueError('missing or large audio')
        raw = base64.b64decode(encoded, validate=True)
    except (ValueError, binascii.Error) as exc:
        raise GeminiServiceError(code='SPEECH_INVALID_AUDIO', message_vi='Chưa tạo được giọng đọc.', status_code=502) from exc
    validate_wav(raw)
    return raw, settings.gemini_tts_model
