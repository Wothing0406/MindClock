from __future__ import annotations

from contextlib import contextmanager
import os
from pathlib import Path
import re
import uuid

from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.base import build_engine, create_session_factory
from app.db.models import Match, MatchEvent, MatchRound, Question, User
from app.main import create_app

API_DIR = Path(__file__).resolve().parents[1]


def _make_alembic_config(db_url: str) -> Config:
    cfg = Config(str(API_DIR / 'alembic.ini'))
    cfg.set_main_option('script_location', str(API_DIR / 'alembic'))
    cfg.set_main_option('sqlalchemy.url', db_url)
    cfg.attributes['sqlalchemy.url'] = db_url
    return cfg


def _get_live_postgres_url() -> str:
    pg_url = os.environ.get('POSTGRES_TEST_URL', '').strip()
    if pg_url.startswith('postgresql'):
        return pg_url
    db_url = os.environ.get('DATABASE_URL', '').strip()
    if db_url.startswith('postgresql'):
        return db_url
    return ''


def _seed_questions(
    session: Session,
    subject: str = 'TOAN',
    grade: str = 'Lớp 10',
    count: int = 6,
    *,
    curriculum: str = 'gdpt_2018',
    status: str = 'published',
    source_type: str = 'approved_bank',
    approved_by: str | None = 'reviewer_bgd_v1',
    rights_status: str = 'approved',
    id_prefix: str = 'q',
) -> list[Question]:
    created: list[Question] = []
    for i in range(count):
        q = Question(
            id=f'{id_prefix}_{subject.lower()}_{grade.replace(" ", "").lower()}_{curriculum}_{i}',
            subject_code=subject,
            grade_band=grade,
            topic_id='pt_bac_hai',
            prompt=f'Đề bài số {i}: Giải phương trình bậc hai {i}x^2 - 4x + 1 = 0.',
            reasoning_prompt_vi='Viết 1 bước tính biệt thức Delta.',
            answer_spec_json={'type': 'text', 'accepted': [f'x={i}']},
            rubric_json={
                'expected_steps': ['Tính delta', 'Biện luận nghiệm'],
                'curriculum': curriculum,
                'rights_status': rights_status,
            },
            rubric_revision=1,
            status=status,
            source_type=source_type,
            revision=1,
            approved_by=approved_by,
        )
        session.add(q)
        created.append(q)
    session.commit()
    return created


def _seed_user(session: Session, uid: str, alias: str, grade: str = 'Lớp 10') -> User:
    existing = session.get(User, uid)
    if existing is not None:
        return existing
    u = User(
        id=uid,
        auth_subject=f'firebase:{uid}',
        alias=alias,
        grade_band=grade,
    )
    session.add(u)
    session.commit()
    return u


def _auth_headers(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:firebase:{uid}'}


@contextmanager
def _pvp_client_context(db_url: str):
    """Khởi tạo DB qua Alembic head, chạy TestClient trong context manager và dispose engine sạch."""
    command.upgrade(_make_alembic_config(db_url), 'head')
    settings = Settings(
        app_env='test',
        database_url=db_url,
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
        firebase_project_id='',
    )
    seed_engine = build_engine(settings)
    seed_session_factory = create_session_factory(seed_engine)
    app = create_app(settings)
    try:
        with TestClient(app) as client:
            yield client, seed_session_factory
    finally:
        seed_engine.dispose()


def _sqlite_url(tmp_path: Path, name: str) -> str:
    return f'sqlite+pysqlite:///{(tmp_path / name).as_posix()}'


def test_pvp_matchmake_rejects_unapproved_or_mismatched_question_bank(tmp_path: Path) -> None:
    db_url = _sqlite_url(tmp_path, 'test_pvp_reject.db')
    with _pvp_client_context(db_url) as (client, session_factory):
        with session_factory() as db:
            _seed_user(db, 'usr_a', 'Hà Nhân THPT', 'Lớp 10')
            # 2 câu chuẩn hợp lệ (< 6)
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=2, id_prefix='ok')
            # Thêm các câu KHÔNG ĐỦ ĐIỀU KIỆN để chứng minh không bị tính nhầm:
            # 1) draft
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=2, status='draft', id_prefix='dr')
            # 2) thiếu reviewer approved_by
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=2, approved_by=None, id_prefix='noapp')
            # 3) ai_draft source_type
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=2, source_type='ai_draft', id_prefix='ai')
            # 4) bị thu hồi bản quyền
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=2, rights_status='revoked', id_prefix='rev')
            # 5) khác chương trình học (curriculum)
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=6, curriculum='legacy_2006', id_prefix='old')

        resp = client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_a'),
            json={
                'championId': 'ha_nhan',
                'subjectCode': 'TOAN',
                'gradeBand': 'Lớp 10',
                'curriculum': 'gdpt_2018',
            },
        )
        assert resp.status_code == 400
        data = resp.json()
        assert data['error']['code'] == 'INSUFFICIENT_APPROVED_QUESTIONS'
        assert 'Chưa đủ tối thiểu 6 câu hỏi' in data['error']['message']


def test_pvp_matchmake_pair_success_identical_question_and_outsider_403(tmp_path: Path) -> None:
    db_url = _sqlite_url(tmp_path, 'test_pvp_pair.db')
    with _pvp_client_context(db_url) as (client, session_factory):
        with session_factory() as db:
            _seed_user(db, 'usr_a', 'Nguyễn Văn A', 'Lớp 10')
            _seed_user(db, 'usr_b', 'Trần Thị B', 'Lớp 10')
            _seed_user(db, 'usr_c', 'Người ngoài trận C', 'Lớp 10')
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=8)

        # 1. User A tìm trận -> trạng thái waiting
        res_a1 = client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_a'),
            json={
                'championId': 'ha_nhan',
                'subjectCode': 'TOAN',
                'gradeBand': 'Lớp 10',
                'curriculum': 'gdpt_2018',
            },
        )
        assert res_a1.status_code == 200
        assert res_a1.json()['status'] == 'waiting'

        # 2. User B tìm trận cùng môn, khối, chương trình với alias legacy `han_boi_thap`
        res_b = client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_b'),
            json={
                'championId': 'han_boi_thap',
                'subjectCode': 'TOAN',
                'gradeBand': 'Lớp 10',
                'curriculum': 'gdpt_2018',
            },
        )
        assert res_b.status_code == 200
        snap_b = res_b.json()
        assert snap_b['status'] == 'in_progress'
        assert snap_b['mode'] == 'duel_1v1'
        assert snap_b['rule_version'] == 'solo-three-v0.1'
        assert snap_b['current_round'] == 1
        assert len(snap_b['players']) == 2
        b_player = next(p for p in snap_b['players'] if p['user_id'] == 'usr_b')
        assert b_player['champion_id'] == 'han_boi_phap'
        match_id = snap_b['match_id']

        # 3. User A lấy snapshot -> nhận cùng question_id, revision, rubric_revision, prompt, deadline
        res_a2 = client.get(f'/v1/pvp/matches/{match_id}', headers=_auth_headers('usr_a'))
        assert res_a2.status_code == 200
        snap_a = res_a2.json()
        r_a = snap_a['current_round_info']
        r_b = snap_b['current_round_info']
        assert r_a['question_id'] == r_b['question_id']
        assert r_a['question_revision'] == r_b['question_revision'] == 1
        assert r_a['rubric_revision'] == r_b['rubric_revision'] == 1
        assert r_a['prompt'] == r_b['prompt']
        assert r_a['deadline_at'] == r_b['deadline_at']
        assert r_a['reasoning_prompt_vi'] == r_b['reasoning_prompt_vi']
        # Không lộ rubric/đáp án chuẩn trước reveal
        assert 'rubric_json' not in r_a
        assert 'answer_spec_json' not in r_a
        assert 'expected_steps' not in str(snap_a)

        # 4. Event stream đồng bộ ban đầu
        evs_res = client.get(
            f'/v1/pvp/matches/{match_id}/events?after_sequence=0',
            headers=_auth_headers('usr_a'),
        )
        assert evs_res.status_code == 200
        events = evs_res.json()
        assert len(events) == 2
        assert events[0]['event_type'] == 'matched' and events[0]['sequence'] == 1
        assert events[1]['event_type'] == 'round_started' and events[1]['sequence'] == 2
        assert 'rubric_json' not in str(events)

        # 5. Người ngoài trận C bị chặn 403 trên mọi endpoint của trận
        assert client.get(f'/v1/pvp/matches/{match_id}', headers=_auth_headers('usr_c')).status_code == 403
        assert client.get(f'/v1/pvp/matches/{match_id}/events', headers=_auth_headers('usr_c')).status_code == 403
        assert (
            client.post(
                f'/v1/pvp/matches/{match_id}/rounds/1/submit',
                headers=_auth_headers('usr_c'),
                json={'answerText': 'x=1', 'reasoningText': 'Cố gắng can thiệp'},
            ).status_code
            == 403
        )
        assert (
            client.post(
                f'/v1/pvp/matches/{match_id}/rounds/1/action',
                headers=_auth_headers('usr_c'),
                json={'actionType': 'basic'},
            ).status_code
            == 403
        )


def test_pvp_matchmake_cancel_and_curriculum_grade_isolation(tmp_path: Path) -> None:
    db_url = _sqlite_url(tmp_path, 'test_pvp_cancel.db')
    with _pvp_client_context(db_url) as (client, session_factory):
        with session_factory() as db:
            _seed_user(db, 'usr_a', 'Hà Nhân A', 'Lớp 11')
            _seed_user(db, 'usr_b', 'Tuyệt Đỉnh B', 'Lớp 11')
            _seed_questions(db, subject='VAT_LY', grade='Lớp 11', curriculum='gdpt_2018', count=6)
            _seed_questions(db, subject='VAT_LY', grade='Lớp 11', curriculum='chuyen_ly', count=6)

        # A vào queue với gdpt_2018
        res_a = client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_a'),
            json={
                'championId': 'tuyet_dinh',
                'subjectCode': 'VAT_LY',
                'gradeBand': 'Lớp 11',
                'curriculum': 'gdpt_2018',
            },
        )
        assert res_a.status_code == 200
        assert res_a.json()['status'] == 'waiting'

        # B vào queue khác curriculum -> KHÔNG được ghép với A
        res_b = client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_b'),
            json={
                'championId': 'ha_nhan',
                'subjectCode': 'VAT_LY',
                'gradeBand': 'Lớp 11',
                'curriculum': 'chuyen_ly',
            },
        )
        assert res_b.status_code == 200
        assert res_b.json()['status'] == 'waiting'

        # A hủy tìm trận lần 1 -> True; lần 2 -> False
        res_cancel = client.post('/v1/pvp/matchmake/cancel', headers=_auth_headers('usr_a'))
        assert res_cancel.status_code == 200
        assert res_cancel.json()['cancelled'] is True

        res_cancel2 = client.post('/v1/pvp/matchmake/cancel', headers=_auth_headers('usr_a'))
        assert res_cancel2.status_code == 200
        assert res_cancel2.json()['cancelled'] is False


def test_pvp_submission_requires_reasoning_and_rejects_client_authoritative_fields(tmp_path: Path) -> None:
    db_url = _sqlite_url(tmp_path, 'test_pvp_reasoning.db')
    with _pvp_client_context(db_url) as (client, session_factory):
        with session_factory() as db:
            _seed_user(db, 'usr_a', 'Hà Nhân A', 'Lớp 10')
            _seed_user(db, 'usr_b', 'Tuyệt Đỉnh B', 'Lớp 10')
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=6)

        client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_a'),
            json={'championId': 'ha_nhan', 'subjectCode': 'TOAN', 'gradeBand': 'Lớp 10'},
        )
        res_b = client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_b'),
            json={'championId': 'tuyet_dinh', 'subjectCode': 'TOAN', 'gradeBand': 'Lớp 10'},
        )
        match_id = res_b.json()['match_id']

        # Client cố tình gửi điểm/HP/damage giả -> 422 Unprocessable Entity
        res_tamper = client.post(
            f'/v1/pvp/matches/{match_id}/rounds/1/submit',
            headers=_auth_headers('usr_a'),
            json={
                'answerText': 'x=0',
                'reasoningText': 'Bước giải hợp lệ',
                'hp': 100,
                'damage': 999,
            },
        )
        assert res_tamper.status_code == 422

        res_tamper_act = client.post(
            f'/v1/pvp/matches/{match_id}/rounds/1/action',
            headers=_auth_headers('usr_a'),
            json={'actionType': 'basic', 'damage': 999},
        )
        assert res_tamper_act.status_code == 422

        # Nộp đáp án nhưng không có bước trình bày: trước khi đối thủ nộp chỉ trả grading_pending
        res_sub_empty = client.post(
            f'/v1/pvp/matches/{match_id}/rounds/1/submit',
            headers=_auth_headers('usr_a'),
            json={'answerText': 'x=0', 'reasoningText': ''},
        )
        assert res_sub_empty.status_code == 200
        assert res_sub_empty.json()['grade_status'] == 'grading_pending'

        # Sau khi đối thủ B nộp bài -> reveal cho phép đọc đúng grade_status='incorrect' của A
        res_sub_b = client.post(
            f'/v1/pvp/matches/{match_id}/rounds/1/submit',
            headers=_auth_headers('usr_b'),
            json={'answerText': 'x=0', 'reasoningText': 'Bước giải hợp lệ của B'},
        )
        assert res_sub_b.status_code == 200
        snap_a = client.get(
            f'/v1/pvp/matches/{match_id}',
            headers=_auth_headers('usr_a'),
        ).json()
        assert snap_a['current_round_info']['my_submission']['grade_status'] == 'incorrect'
        assert 'bước trình bày' in snap_a['current_round_info']['my_submission']['feedback_vi']


def _run_full_lifecycle_duplicate_and_reconnect_assertions(
    client: TestClient,
    session_factory,
    *,
    uid_a: str = 'usr_a',
    uid_b: str = 'usr_b',
    uid_c: str = 'usr_c',
) -> str:
    # 1. Ghép trận A & B
    res_q = client.post(
        '/v1/pvp/matchmake',
        headers=_auth_headers(uid_a),
        json={'championId': 'ha_nhan', 'subjectCode': 'TOAN', 'gradeBand': 'Lớp 10'},
    )
    assert res_q.status_code == 200
    assert res_q.json()['status'] == 'waiting'

    res_pair = client.post(
        '/v1/pvp/matchmake',
        headers=_auth_headers(uid_b),
        json={'championId': 'tuyet_dinh', 'subjectCode': 'TOAN', 'gradeBand': 'Lớp 10'},
    )
    assert res_pair.status_code == 200
    match_id = res_pair.json()['match_id']

    # Kiểm tra outsider C bị 403
    assert client.get(f'/v1/pvp/matches/{match_id}', headers=_auth_headers(uid_c)).status_code == 403

    # 2. Đọc đề round 1 và nộp bài có bước giải
    snap_before = client.get(
        f'/v1/pvp/matches/{match_id}',
        headers=_auth_headers(uid_a),
    ).json()
    prompt = snap_before['current_round_info']['prompt']
    m = re.search(r'Đề bài số (\d+):', prompt)
    expected_ans = f'x={m.group(1)}' if m else 'x=0'

    sub_a = client.post(
        f'/v1/pvp/matches/{match_id}/rounds/1/submit',
        headers=_auth_headers(uid_a),
        json={
            'answerText': expected_ans,
            'reasoningText': 'Delta = 16 - 0 = 16 > 0, giải được ' + expected_ans,
        },
    )
    assert sub_a.status_code == 200
    assert sub_a.json()['grade_status'] == 'grading_pending'
    assert sub_a.json()['round_state'] == 'answering'

    sub_b = client.post(
        f'/v1/pvp/matches/{match_id}/rounds/1/submit',
        headers=_auth_headers(uid_b),
        json={
            'answerText': expected_ans,
            'reasoningText': 'Thay ' + expected_ans + ' vào phương trình thỏa mãn',
        },
    )
    assert sub_b.status_code == 200
    assert sub_b.json()['grade_status'] == 'correct'
    assert sub_b.json()['round_state'] == 'action_window'

    # Retry submit B sau khi round đã chuyển sang action_window -> vẫn idempotent is_duplicate=True
    sub_b_retry = client.post(
        f'/v1/pvp/matches/{match_id}/rounds/1/submit',
        headers=_auth_headers(uid_b),
        json={
            'answerText': expected_ans,
            'reasoningText': 'Retry gửi lại gói tin do rớt mạng',
        },
    )
    assert sub_b_retry.status_code == 200
    assert sub_b_retry.json()['is_duplicate'] is True

    # 3. Chọn action A & B -> settle đúng 1 lần
    act_a = client.post(
        f'/v1/pvp/matches/{match_id}/rounds/1/action',
        headers=_auth_headers(uid_a),
        json={'actionType': 'basic'},
    )
    assert act_a.status_code == 200
    assert act_a.json()['settle_result'] is None

    act_b = client.post(
        f'/v1/pvp/matches/{match_id}/rounds/1/action',
        headers=_auth_headers(uid_b),
        json={'actionType': 'basic'},
    )
    assert act_b.status_code == 200
    assert act_b.json()['settle_result']['round_settled'] is True
    assert act_b.json()['settle_result']['match_finished'] is False

    # Retry action B SAU KHI round 1 đã settle & match đã chuyển sang round 2 -> idempotent, không settle lại!
    act_b_retry = client.post(
        f'/v1/pvp/matches/{match_id}/rounds/1/action',
        headers=_auth_headers(uid_b),
        json={'actionType': 'basic'},
    )
    assert act_b_retry.status_code == 200
    assert act_b_retry.json()['is_duplicate'] is True
    assert act_b_retry.json()['settle_result'] is None

    # 4. Reconnect: đọc snapshot + event stream từ after_sequence=2
    snap = client.get(
        f'/v1/pvp/matches/{match_id}',
        headers=_auth_headers(uid_a),
    ).json()
    assert snap['current_round'] == 2
    assert snap['current_round_info']['round_no'] == 2
    assert snap['current_round_info']['state'] == 'answering'

    p_a = next(p for p in snap['players'] if p['user_id'] == uid_a)
    p_b = next(p for p in snap['players'] if p['user_id'] == uid_b)
    assert p_a['hp'] == 100 and p_a['armor'] == 22 and p_a['qi'] == 1
    assert p_b['hp'] == 100 and p_b['armor'] == 22 and p_b['qi'] == 1

    reconnect_evs = client.get(
        f'/v1/pvp/matches/{match_id}/events?after_sequence=2',
        headers=_auth_headers(uid_a),
    ).json()
    sequences = [ev['sequence'] for ev in reconnect_evs]
    assert sequences == sorted(sequences)
    assert len(set(sequences)) == len(sequences)
    settled_evs = [ev for ev in reconnect_evs if ev['event_type'] == 'round_settled']
    assert len(settled_evs) == 1
    assert settled_evs[0]['payload']['rule_version'] == 'solo-three-v0.1'
    assert settled_evs[0]['payload']['round_no'] == 1

    # Xác nhận số bản ghi MatchEvent trong DB khớp 1 round_settled
    with session_factory() as db:
        db_settled = (
            db.query(MatchEvent)
            .filter(MatchEvent.match_id == match_id, MatchEvent.event_type == 'round_settled')
            .all()
        )
        assert len(db_settled) == 1
    return match_id


def test_pvp_full_round_lifecycle_duplicate_action_single_settle_and_reconnect(tmp_path: Path) -> None:
    db_url = _sqlite_url(tmp_path, 'test_pvp_lifecycle.db')
    with _pvp_client_context(db_url) as (client, session_factory):
        with session_factory() as db:
            _seed_user(db, 'usr_a', 'Hà Nhân A', 'Lớp 10')
            _seed_user(db, 'usr_b', 'Tuyệt Đỉnh B', 'Lớp 10')
            _seed_user(db, 'usr_c', 'Outsider C', 'Lớp 10')
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=8)

        _run_full_lifecycle_duplicate_and_reconnect_assertions(client, session_factory)


def test_pvp_uncertain_submission_voids_round_without_hp_change(tmp_path: Path) -> None:
    db_url = _sqlite_url(tmp_path, 'test_pvp_uncertain.db')
    with _pvp_client_context(db_url) as (client, session_factory):
        with session_factory() as db:
            _seed_user(db, 'usr_a', 'Hà Nhân A', 'Lớp 10')
            _seed_user(db, 'usr_b', 'Tuyệt Đỉnh B', 'Lớp 10')
            _seed_questions(db, subject='TOAN', grade='Lớp 10', count=6)

        client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_a'),
            json={'championId': 'ha_nhan', 'subjectCode': 'TOAN', 'gradeBand': 'Lớp 10'},
        )
        res_pair = client.post(
            '/v1/pvp/matchmake',
            headers=_auth_headers('usr_b'),
            json={'championId': 'tuyet_dinh', 'subjectCode': 'TOAN', 'gradeBand': 'Lớp 10'},
        )
        match_id = res_pair.json()['match_id']
        q_id = res_pair.json()['current_round_info']['question_id']

        # Giả lập rubric/revision của câu bị thay đổi giữa round -> mất điều kiện công bằng -> uncertain/void
        with session_factory() as db:
            q = db.get(Question, q_id)
            assert q is not None
            q.rubric_revision = 99
            db.commit()

        sub_a = client.post(
            f'/v1/pvp/matches/{match_id}/rounds/1/submit',
            headers=_auth_headers('usr_a'),
            json={'answerText': 'x=0', 'reasoningText': 'Bước giải hợp lệ của A'},
        )
        assert sub_a.status_code == 200
        assert sub_a.json()['grade_status'] == 'grading_pending'

        sub_b = client.post(
            f'/v1/pvp/matches/{match_id}/rounds/1/submit',
            headers=_auth_headers('usr_b'),
            json={'answerText': 'x=0', 'reasoningText': 'Bước giải hợp lệ của B'},
        )
        assert sub_b.status_code == 200
        assert sub_b.json()['grade_status'] == 'uncertain'
        assert sub_b.json()['round_state'] == 'void'

        # Round 1 bị void (HP/armor/qi giữ nguyên) VÀ trận tự chuyển sang round 2 không bị treo chết
        snap = client.get(f'/v1/pvp/matches/{match_id}', headers=_auth_headers('usr_a')).json()
        assert snap['current_round'] == 2
        assert snap['current_round_info']['round_no'] == 2
        assert snap['current_round_info']['state'] == 'answering'
        for player in snap['players']:
            assert player['hp'] == 100
            assert player['armor'] == 50
            assert player['qi'] == 0

        # Không được phép chọn action trên round 1 đã void
        act_void = client.post(
            f'/v1/pvp/matches/{match_id}/rounds/1/action',
            headers=_auth_headers('usr_a'),
            json={'actionType': 'basic'},
        )
        assert act_void.status_code == 400
        assert act_void.json()['error']['code'] in {'INVALID_ROUND', 'ACTION_WINDOW_CLOSED'}

        evs = client.get(
            f'/v1/pvp/matches/{match_id}/events?after_sequence=0',
            headers=_auth_headers('usr_a'),
        ).json()
        assert any(ev['event_type'] == 'round_voided' for ev in evs)
        assert any(
            ev['event_type'] == 'round_started' and ev['payload'].get('round_no') == 2
            for ev in evs
        )


@contextmanager
def _isolated_postgres_db(base_pg_url: str):
    """Tạo DB tạm cô lập trên PostgreSQL để test live không đụng vào DB dev mindclock."""
    parsed = make_url(base_pg_url)
    temp_db = f'mindclock_pytest_pvp_{uuid.uuid4().hex[:8]}'
    admin_url = parsed.set(database='postgres')
    temp_url = parsed.set(database=temp_db).render_as_string(hide_password=False)

    admin_engine = create_engine(admin_url, isolation_level='AUTOCOMMIT')
    created = False
    try:
        with admin_engine.connect() as conn:
            conn.execute(text(f'CREATE DATABASE "{temp_db}"'))
            created = True
        yield temp_url
    finally:
        if created:
            with admin_engine.connect() as conn:
                conn.execute(text(f'DROP DATABASE IF EXISTS "{temp_db}" WITH (FORCE)'))
        admin_engine.dispose()


def test_pvp_live_postgresql_two_accounts_when_configured() -> None:
    pg_url = _get_live_postgres_url()
    if not pg_url:
        pytest.skip(
            'Chưa cấu hình POSTGRES_TEST_URL / DATABASE_URL PostgreSQL '
            '(cần bật PostgreSQL/Docker local hoặc chạy trên CI backend-api-postgres).'
        )

    with _isolated_postgres_db(pg_url) as isolated_pg_url:
        alembic_cfg = _make_alembic_config(isolated_pg_url)
        command.upgrade(alembic_cfg, '0002_align_question_indexes')
        command.upgrade(alembic_cfg, 'head')

        with _pvp_client_context(isolated_pg_url) as (client, session_factory):
            with session_factory() as db:
                _seed_user(db, 'pg_usr_a', 'PG Hà Nhân A', 'Lớp 10')
                _seed_user(db, 'pg_usr_b', 'PG Tuyệt Đỉnh B', 'Lớp 10')
                _seed_user(db, 'pg_usr_c', 'PG Outsider C', 'Lớp 10')
                _seed_questions(db, subject='TOAN', grade='Lớp 10', count=8, id_prefix='pgq')

            match_id = _run_full_lifecycle_duplicate_and_reconnect_assertions(
                client,
                session_factory,
                uid_a='pg_usr_a',
                uid_b='pg_usr_b',
                uid_c='pg_usr_c',
            )
            with session_factory() as db:
                m = db.get(Match, match_id)
                assert m is not None and m.mode == 'duel_1v1'
                r1 = (
                    db.query(MatchRound)
                    .filter(MatchRound.match_id == match_id, MatchRound.round_no == 1)
                    .first()
                )
                assert r1 is not None and r1.state == 'settled'

            # Kiểm tra không lỗi FK khi tài khoản từng đấu PvP gọi DELETE /v1/me trên PostgreSQL 16 thật
            del_a = client.delete('/v1/me', headers=_auth_headers('pg_usr_a'))
            assert del_a.status_code == 202
            assert del_a.json()['status'] == 'deleted'
