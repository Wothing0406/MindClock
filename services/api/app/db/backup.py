from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
from typing import Any

from sqlalchemy import Engine, delete, insert, select

import app.db.models  # noqa: F401
from app.db.base import Base

# Thứ tự bảng theo chiều phụ thuộc khóa ngoại (cha -> con khi restore; ngược lại khi xóa)
ORDERED_TABLE_NAMES: tuple[str, ...] = (
    'users',
    'alarms',
    'timetable_slots',
    'questions',
    'alarm_sessions',
    'attempts',
    'study_sessions',
    'xp_ledger',
    'topic_progress',
    'idempotency_records',
    'consent_events',
    'match_queue',
    'matches',
    'match_players',
    'match_rounds',
    'round_submissions',
    'round_actions',
    'match_events',
)


def _serialize_value(value: Any) -> Any:
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.isoformat()
    return value


def _deserialize_row(table_name: str, row: dict[str, Any]) -> dict[str, Any]:
    table = Base.metadata.tables[table_name]
    out: dict[str, Any] = {}
    for col_name, raw_val in row.items():
        if raw_val is None or col_name not in table.c:
            out[col_name] = raw_val
            continue
        col = table.c[col_name]
        if hasattr(col.type, 'python_type') and col.type.python_type is datetime and isinstance(raw_val, str):
            parsed = datetime.fromisoformat(raw_val.replace('Z', '+00:00'))
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            out[col_name] = parsed
        else:
            out[col_name] = raw_val
    return out


def _compute_tables_sha256(tables_payload: dict[str, list[dict[str, Any]]]) -> str:
    canonical = json.dumps(tables_payload, sort_keys=True, ensure_ascii=False, separators=(',', ':'))
    return hashlib.sha256(canonical.encode('utf-8')).hexdigest()


def export_database_snapshot(engine: Engine) -> dict[str, Any]:
    """Xuất toàn bộ dữ liệu nghiệp vụ theo thứ tự bảng kèm mã băm toàn vẹn SHA-256."""
    tables_payload: dict[str, list[dict[str, Any]]] = {}
    with engine.connect() as conn:
        for table_name in ORDERED_TABLE_NAMES:
            table = Base.metadata.tables[table_name]
            pk_cols = [c for c in table.primary_key.columns]
            stmt = select(table).order_by(*pk_cols) if pk_cols else select(table)
            rows = conn.execute(stmt).mappings().all()
            tables_payload[table_name] = [
                {k: _serialize_value(v) for k, v in dict(r).items()}
                for r in rows
            ]

    checksum = _compute_tables_sha256(tables_payload)
    return {
        'schemaVersion': '0003_add_pvp_match_tables',
        'exportedAt': datetime.now(timezone.utc).isoformat(),
        'tableOrder': list(ORDERED_TABLE_NAMES),
        'rowCounts': {k: len(v) for k, v in tables_payload.items()},
        'sha256': checksum,
        'tables': tables_payload,
    }


def write_backup_file(engine: Engine, output_path: Path) -> dict[str, Any]:
    snapshot = export_database_snapshot(engine)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(snapshot, indent=2, ensure_ascii=False),
        encoding='utf-8',
    )
    return snapshot


def restore_database_snapshot(
    engine: Engine,
    snapshot: dict[str, Any],
    *,
    clear_existing: bool = True,
) -> dict[str, int]:
    """Khôi phục dữ liệu từ bản snapshot trong một DB transaction nguyên tử (ACID)."""
    tables_payload = snapshot.get('tables')
    if not isinstance(tables_payload, dict):
        raise ValueError('Snapshot thiếu mục tables hợp lệ.')

    expected_sha = snapshot.get('sha256')
    actual_sha = _compute_tables_sha256(tables_payload)
    if expected_sha != actual_sha:
        raise ValueError('Checksum SHA-256 của bản backup không khớp; từ chối phục hồi.')

    restored_counts: dict[str, int] = {}
    with engine.begin() as conn:
        if clear_existing:
            for table_name in reversed(ORDERED_TABLE_NAMES):
                table = Base.metadata.tables[table_name]
                conn.execute(delete(table))

        for table_name in ORDERED_TABLE_NAMES:
            rows = tables_payload.get(table_name, [])
            if not rows:
                restored_counts[table_name] = 0
                continue
            table = Base.metadata.tables[table_name]
            deserialized = [_deserialize_row(table_name, r) for r in rows]
            conn.execute(insert(table), deserialized)
            restored_counts[table_name] = len(deserialized)

    return restored_counts


def restore_from_backup_file(engine: Engine, input_path: Path) -> dict[str, int]:
    raw = json.loads(input_path.read_text(encoding='utf-8'))
    return restore_database_snapshot(engine, raw, clear_existing=True)
