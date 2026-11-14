import hashlib
import json
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import IdempotencyRecord


def compute_payload_hash(payload: Any) -> str:
    serialized = json.dumps(payload, sort_keys=True, ensure_ascii=False, default=str)
    return hashlib.sha256(serialized.encode('utf-8')).hexdigest()


def lookup_idempotency(
    db: Session,
    *,
    user_id: str,
    route: str,
    key: str | None,
    payload: Any,
) -> dict[str, Any] | None:
    if not key or not key.strip():
        return None
    clean_key = key.strip()
    existing = db.scalar(
        select(IdempotencyRecord).where(
            IdempotencyRecord.user_id == user_id,
            IdempotencyRecord.route == route,
            IdempotencyRecord.key == clean_key,
        )
    )
    if existing is None:
        return None
    incoming_hash = compute_payload_hash(payload)
    if existing.payload_hash != incoming_hash:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                'error': {
                    'code': 'IDEMPOTENCY_CONFLICT',
                    'message': 'Trùng Idempotency-Key nhưng payload khác.',
                    'requestId': 'req_409',
                    'retryable': False,
                }
            },
        )
    return existing.response_json


def save_idempotency(
    db: Session,
    *,
    user_id: str,
    route: str,
    key: str | None,
    payload: Any,
    response_json: dict[str, Any],
    status_code: int = 200,
) -> None:
    if not key or not key.strip():
        return
    clean_key = key.strip()
    record = IdempotencyRecord(
        user_id=user_id,
        route=route,
        key=clean_key,
        payload_hash=compute_payload_hash(payload),
        response_json=response_json,
        status_code=status_code,
    )
    db.add(record)
