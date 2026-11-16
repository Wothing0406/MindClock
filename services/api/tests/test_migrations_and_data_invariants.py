from __future__ import annotations

import os
from pathlib import Path

from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.config import Config
from alembic.migration import MigrationContext
from fastapi.testclient import TestClient
import pytest
from sqlalchemy import inspect, select
from sqlalchemy.dialects import postgresql
from sqlalchemy.exc import IntegrityError
from sqlalchemy.schema import CreateIndex, CreateTable

from app.config import Settings
from app.db.backup import (
    ORDERED_TABLE_NAMES,
    restore_database_snapshot,
    restore_from_backup_file,
    write_backup_file,
)
from app.db.base import Base, build_engine, create_session_factory
from app.db.models import (
    Alarm,
    AlarmSession,
    Attempt,
    ConsentEvent,
    IdempotencyRecord,
    Question,
    StudySession,
    TimetableSlot,
    TopicProgress,
    User,
    XpLedger,
)
from app.db.seed import seed_approved_questions
from app.main import create_app

API_DIR = Path(__file__).resolve().parents[1]


def _make_alembic_config(db_url: str) -> Config:
    cfg = Config(str(API_DIR / 'alembic.ini'))
    cfg.set_main_option('script_location', str(API_DIR / 'alembic'))
    cfg.set_main_option('sqlalchemy.url', db_url)
    cfg.attributes['sqlalchemy.url'] = db_url
    return cfg


def test_alembic_upgrade_empty_db_and_schema_parity(tmp_path: Path) -> None:
    db_file = tmp_path / 'alembic_empty.db'
    db_url = f'sqlite+pysqlite:///{db_file.as_posix()}'
    alembic_cfg = _make_alembic_config(db_url)

    command.upgrade(alembic_cfg, 'head')

    engine = build_engine(Settings(app_env='test', database_url=db_url))
    try:
        inspector = inspect(engine)
        table_names = set(inspector.get_table_names())
        for expected_table in ORDERED_TABLE_NAMES:
            assert expected_table in table_names

        with engine.connect() as conn:
            mc = MigrationContext.configure(conn)
            diffs = compare_metadata(mc, Base.metadata)
            assert diffs == []
    finally:
        engine.dispose()

    # Kiểm chứng biên dịch DDL sang dialect PostgreSQL chuẩn cho toàn bộ bảng và chỉ mục
    pg_dialect = postgresql.dialect()
    compiled_sql: list[str] = []
    for table in Base.metadata.sorted_tables:
        ddl = str(CreateTable(table).compile(dialect=pg_dialect))
        compiled_sql.append(ddl)
        for index in table.indexes:
            idx_ddl = str(CreateIndex(index).compile(dialect=pg_dialect))
            compiled_sql.append(idx_ddl)

    joined_sql = '\n'.join(compiled_sql)
    assert 'CREATE TABLE users' in joined_sql
    assert 'ON DELETE CASCADE' in joined_sql
    assert 'uq_xp_ledger_idempotent' in joined_sql
    assert 'ix_questions_bank_lookup' in joined_sql
    assert 'ix_questions_subject_code' in joined_sql


def test_alembic_upgrade_with_existing_data_and_downgrade(tmp_path: Path) -> None:
    db_file = tmp_path / 'alembic_existing_data.db'
    db_url = f'sqlite+pysqlite:///{db_file.as_posix()}'
    alembic_cfg = _make_alembic_config(db_url)

    # 1) Lên revision 0001_initial_schema trước
    command.upgrade(alembic_cfg, '0001_initial_schema')

    engine = build_engine(Settings(app_env='test', database_url=db_url))
    session_factory = create_session_factory(engine)
    try:
        with session_factory() as db:
            seed_approved_questions(db)
            user = User(
                id='u_mig_1',
                auth_subject='mig_subj_1',
                alias='Minh Anh',
                grade_band='Lớp 11',
                selected_subjects_json=['TOAN', 'VAT_LY'],
            )
            db.add(user)
            db.flush()
            db.add(
                Alarm(
                    id='al_mig_1',
                    user_id=user.id,
                    local_time='05:45',
                    weekdays_json=[1, 2, 3, 4, 5],
                    challenge_mode='short_review',
                )
            )
            db.add(
                AlarmSession(
                    id='sess_mig_1',
                    user_id=user.id,
                    alarm_id='al_mig_1',
                    local_session_id='loc_mig_1',
                    question_id='math9-linear-001',
                    local_date='2026-11-16',
                    state='completed',
                )
            )
            db.add(
                XpLedger(
                    id='xp_mig_1',
                    user_id=user.id,
                    source_type='alarm_session',
                    source_id='sess_mig_1',
                    reason='challenge_correct',
                    delta=10,
                )
            )
            db.commit()

        # 2) Nâng cấp từ 0001 lên head (0002) trên DB đang có dữ liệu
        command.upgrade(alembic_cfg, 'head')

        inspector_head = inspect(engine)
        q_indexes_head = {idx['name'] for idx in inspector_head.get_indexes('questions')}
        assert 'ix_questions_subject_code' in q_indexes_head
        assert 'ix_questions_status' in q_indexes_head

        with session_factory() as db:
            loaded_user = db.get(User, 'u_mig_1')
            assert loaded_user is not None
            assert loaded_user.alias == 'Minh Anh'
            loaded_xp = db.get(XpLedger, 'xp_mig_1')
            assert loaded_xp is not None and loaded_xp.delta == 10

        # 3) Downgrade về 0001_initial_schema: dữ liệu vẫn nguyên vẹn
        command.downgrade(alembic_cfg, '0001_initial_schema')
        with session_factory() as db:
            assert db.get(User, 'u_mig_1') is not None
            assert db.get(Alarm, 'al_mig_1') is not None

        # 4) Downgrade về base và upgrade lại lên head
        command.downgrade(alembic_cfg, 'base')
        inspector_base = inspect(engine)
        user_tables_after_base = set(inspector_base.get_table_names()) - {'alembic_version'}
        assert user_tables_after_base == set()

        command.upgrade(alembic_cfg, 'head')
        inspector_reup = inspect(engine)
        assert 'users' in inspector_reup.get_table_names()
    finally:
        engine.dispose()


def test_unique_constraints_and_atomic_rollback(tmp_path: Path) -> None:
    db_file = tmp_path / 'invariants.db'
    db_url = f'sqlite+pysqlite:///{db_file.as_posix()}'
    command.upgrade(_make_alembic_config(db_url), 'head')

    engine = build_engine(Settings(app_env='test', database_url=db_url))
    session_factory = create_session_factory(engine)
    try:
        with session_factory() as db:
            u = User(id='u_inv', auth_subject='subj_inv', alias='Khoa', grade_band='Lớp 10')
            db.add(u)
            db.commit()

        # DATA-02: Không cho tạo trùng AlarmSession cùng (user_id, local_session_id)
        with session_factory() as db:
            s1 = AlarmSession(
                id='s_1',
                user_id='u_inv',
                alarm_id='a1',
                local_session_id='same_local_sid',
                question_id='math9-linear-001',
                local_date='2026-11-16',
            )
            db.add(s1)
            db.commit()

        with session_factory() as db:
            s2 = AlarmSession(
                id='s_2',
                user_id='u_inv',
                alarm_id='a1',
                local_session_id='same_local_sid',
                question_id='math9-linear-001',
                local_date='2026-11-16',
            )
            db.add(s2)
            with pytest.raises(IntegrityError):
                db.commit()
            db.rollback()

        # DATA-04: Rollback nguyên tử khi lỗi xảy ra giữa chừng (Attempt + XpLedger trùng)
        with session_factory() as db:
            db.add(
                XpLedger(
                    id='xp_existing',
                    user_id='u_inv',
                    source_type='alarm_session',
                    source_id='s_1',
                    reason='challenge_correct',
                    delta=10,
                )
            )
            db.commit()

        with session_factory() as db:
            # Cố tình ghi Attempt mới + XpLedger vi phạm uq_xp_ledger_idempotent trong cùng 1 transaction
            db.add(
                Attempt(
                    id='att_should_rollback',
                    session_id='s_1',
                    client_attempt_id='cli_att_rollback',
                    kind='text',
                    grade_status='correct',
                    feedback_json={'feedback': 'ok'},
                )
            )
            db.add(
                XpLedger(
                    id='xp_dup',
                    user_id='u_inv',
                    source_type='alarm_session',
                    source_id='s_1',
                    reason='challenge_correct',
                    delta=10,
                )
            )
            with pytest.raises(IntegrityError):
                db.commit()
            db.rollback()

        with session_factory() as db:
            # Attempt không được phép tồn tại sau khi transaction rollback
            assert db.get(Attempt, 'att_should_rollback') is None
            total_xp_rows = list(
                db.scalars(select(XpLedger).where(XpLedger.user_id == 'u_inv'))
            )
            assert len(total_xp_rows) == 1
    finally:
        engine.dispose()


def test_backup_and_restore_rehearsal(tmp_path: Path) -> None:
    src_db = tmp_path / 'source_prod.db'
    dst_db = tmp_path / 'restored_prod.db'
    backup_json = tmp_path / 'backup_snapshot.json'

    src_url = f'sqlite+pysqlite:///{src_db.as_posix()}'
    dst_url = f'sqlite+pysqlite:///{dst_db.as_posix()}'

    command.upgrade(_make_alembic_config(src_url), 'head')
    command.upgrade(_make_alembic_config(dst_url), 'head')

    src_engine = build_engine(Settings(app_env='test', database_url=src_url))
    dst_engine = build_engine(Settings(app_env='test', database_url=dst_url))
    src_factory = create_session_factory(src_engine)
    dst_factory = create_session_factory(dst_engine)

    try:
        with src_factory() as db:
            seed_approved_questions(db)
            user = User(
                id='u_bkp',
                auth_subject='subj_bkp',
                alias='Bảo Ngọc',
                grade_band='Lớp 12',
                selected_subjects_json=['TOAN', 'TIENG_ANH'],
            )
            db.add(user)
            db.flush()
            db.add(
                Alarm(
                    id='al_bkp',
                    user_id=user.id,
                    local_time='06:00',
                    weekdays_json=[1, 3, 5],
                )
            )
            db.add(
                TimetableSlot(
                    id='tt_bkp',
                    user_id=user.id,
                    weekday=1,
                    subject_code='TOAN',
                    topic_id='derivative_poly',
                    position=0,
                )
            )
            db.add(
                AlarmSession(
                    id='as_bkp',
                    user_id=user.id,
                    alarm_id='al_bkp',
                    local_session_id='loc_bkp',
                    question_id='math12-deriv-001',
                    local_date='2026-11-16',
                    state='completed',
                )
            )
            db.add(
                Attempt(
                    id='at_bkp',
                    session_id='as_bkp',
                    client_attempt_id='cli_bkp',
                    kind='text',
                    grade_status='correct',
                    feedback_json={'feedback': 'Đúng'},
                )
            )
            db.add(
                StudySession(
                    id='ss_bkp',
                    user_id=user.id,
                    client_session_id='cli_ss_bkp',
                    task_title='Ôn khảo sát hàm số',
                    subject_code='TOAN',
                    grade_band='Lớp 12',
                    target_minutes=25,
                    state='completed',
                    elapsed_wall_seconds=1500,
                    in_app_focus_seconds=1480,
                )
            )
            db.add(
                XpLedger(
                    id='xp_bkp',
                    user_id=user.id,
                    source_type='alarm_session',
                    source_id='as_bkp',
                    reason='challenge_correct',
                    delta=10,
                )
            )
            db.add(
                TopicProgress(
                    user_id=user.id,
                    topic_id='derivative_poly',
                    subject_code='TOAN',
                    attempts=1,
                    correct=1,
                )
            )
            db.add(
                IdempotencyRecord(
                    id='idem_bkp',
                    user_id=user.id,
                    route='POST:/v1/alarms',
                    key='k_bkp',
                    payload_hash='h123',
                    response_json={'id': 'al_bkp'},
                )
            )
            db.add(
                ConsentEvent(
                    id='ce_bkp',
                    user_id=user.id,
                    scope='gemini_live_opt_in',
                    version='2026-11',
                    granted=True,
                )
            )
            db.commit()

        snapshot = write_backup_file(src_engine, backup_json)
        assert backup_json.is_file()
        assert snapshot['rowCounts']['users'] == 1
        assert snapshot['rowCounts']['questions'] >= 8

        # Kiểm tra từ chối restore nếu bản backup bị sửa dữ liệu (sai SHA-256)
        tampered = dict(snapshot)
        tampered['sha256'] = '0' * 64
        with pytest.raises(ValueError, match='SHA-256'):
            restore_database_snapshot(dst_engine, tampered)

        # Restore chuẩn sang DB đích mới
        restored_counts = restore_from_backup_file(dst_engine, backup_json)
        assert restored_counts == snapshot['rowCounts']

        with dst_factory() as db:
            u_restored = db.get(User, 'u_bkp')
            assert u_restored is not None
            assert u_restored.alias == 'Bảo Ngọc'
            assert db.get(Attempt, 'at_bkp') is not None
            assert db.get(XpLedger, 'xp_bkp') is not None
            assert db.get(ConsentEvent, 'ce_bkp') is not None
    finally:
        src_engine.dispose()
        dst_engine.dispose()


def test_live_postgresql_migration_and_health_when_configured() -> None:
    pg_url = os.environ.get('POSTGRES_TEST_URL', '').strip()
    if not pg_url:
        pytest.skip('POSTGRES_TEST_URL chưa được cấu hình (Docker daemon tắt trên máy local; chạy trên CI postgres service).')

    alembic_cfg = _make_alembic_config(pg_url)
    command.downgrade(alembic_cfg, 'base')
    command.upgrade(alembic_cfg, 'head')

    settings = Settings(
        app_env='test',
        database_url=pg_url,
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )
    app = create_app(settings)
    with TestClient(app) as client:
        res = client.get('/v1/health')
        assert res.status_code == 200
        body = res.json()
        assert body['status'] == 'ok'
        assert body['dbReady'] is True
        assert body['dbDialect'] == 'postgresql'
