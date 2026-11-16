"""Unit tests cho answer_normalizer (T040)."""

import pytest
from app.services.answer_normalizer import is_answer_accepted, parse_answer


def test_parse_answer_decimals():
    p1 = parse_answer('0,5')
    assert p1.is_numeric is True
    assert p1.numeric_value == 0.5
    assert p1.unit is None

    p2 = parse_answer('3.14')
    assert p2.is_numeric is True
    assert p2.numeric_value == pytest.approx(3.14)

    p3 = parse_answer('2.50')
    assert p3.is_numeric is True
    assert p3.numeric_value == 2.5


def test_parse_answer_fractions():
    p1 = parse_answer('3/4')
    assert p1.is_numeric is True
    assert p1.numeric_value == 0.75
    assert p1.fraction == (3, 4)

    p2 = parse_answer(r'\frac{1}{2}')
    assert p2.is_numeric is True
    assert p2.numeric_value == 0.5
    assert p2.fraction == (1, 2)

    p3 = parse_answer('6/8')
    assert p3.fraction == (3, 4)
    assert p3.numeric_value == 0.75


def test_parse_answer_variables_and_units():
    p1 = parse_answer('x = 8')
    assert p1.variable == 'x'
    assert p1.numeric_value == 8.0

    p2 = parse_answer('I = 2A')
    assert p2.variable == 'i'
    assert p2.numeric_value == 2.0
    assert p2.unit == 'a'

    p3 = parse_answer('v = 10 m/s')
    assert p3.variable == 'v'
    assert p3.numeric_value == 10.0
    assert p3.unit == 'm/s'

    p4 = parse_answer('2,5 kg')
    assert p4.numeric_value == 2.5
    assert p4.unit == 'kg'


def test_is_answer_accepted_decimals():
    # Học sinh nhập dấu phẩy, accepted dùng dấu chấm
    assert is_answer_accepted('0,5', ['0.5']) is True
    assert is_answer_accepted('3,14', ['3.14']) is True
    assert is_answer_accepted('2.50', ['2.5']) is True
    assert is_answer_accepted('0.5', ['0,5']) is True


def test_is_answer_accepted_fractions():
    # Học sinh nhập phân số, accepted là số thập phân hoặc ngược lại
    assert is_answer_accepted('3/4', ['0.75']) is True
    assert is_answer_accepted('0.75', ['3/4']) is True
    assert is_answer_accepted('0,75', ['3/4']) is True
    assert is_answer_accepted(r'\frac{3}{4}', ['0.75']) is True
    assert is_answer_accepted('6/8', ['3/4']) is True
    assert is_answer_accepted('1/2', ['0,5']) is True


def test_is_answer_accepted_variables():
    # Học sinh nhập kèm x= hoặc không kèm
    assert is_answer_accepted('x = 8', ['8']) is True
    assert is_answer_accepted('8', ['x = 8']) is True
    assert is_answer_accepted('x=8', ['8']) is True
    assert is_answer_accepted("y'(2) = 9", ['9']) is True


def test_is_answer_accepted_units():
    # Đơn vị đo lường: dòng điện
    assert is_answer_accepted('2A', ['2', '2 a', '2A']) is True
    assert is_answer_accepted('2 A', ['2A']) is True
    assert is_answer_accepted('2 a', ['2A']) is True
    assert is_answer_accepted('I = 2A', ['2A']) is True
    assert is_answer_accepted('2', ['2A']) is True  # Học sinh chỉ ghi số khi đề đã có đơn vị

    # Đơn vị đo lường: vận tốc
    assert is_answer_accepted('10 m/s', ['10m/s']) is True
    assert is_answer_accepted('10m/s', ['10 m/s']) is True
    assert is_answer_accepted('v = 10 m/s', ['10 m/s']) is True

    # Khác đơn vị phải bị tính sai
    assert is_answer_accepted('2V', ['2A']) is False
    assert is_answer_accepted('10 km/h', ['10 m/s']) is False


def test_is_answer_accepted_text():
    # Giữ nguyên tính đúng đắn cho văn bản/tiếng Anh/sinh học
    assert is_answer_accepted('ẩn dụ', ['ẩn dụ', 'an du']) is True
    assert is_answer_accepted('An Du', ['ẩn dụ', 'an du']) is True
    assert is_answer_accepted('has lived', ["'s lived", 'has lived']) is True
    assert is_answer_accepted('Aa', ['100% Aa', 'Aa']) is True
    assert is_answer_accepted('sai hoan toan', ['ẩn dụ']) is False


def test_v1_route_submit_answer_normalizer_decimal_and_fractions(tmp_path):
    from pathlib import Path
    from pydantic import SecretStr
    from starlette.testclient import TestClient
    from app.main import create_app
    from app.config import Settings

    db_file = tmp_path / 'test_norm.db'
    settings = Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('FAKE_KEY'),
        local_dev_bearer_uid_fallback=True,
    )
    app = create_app(settings)

    with TestClient(app) as client:
        # Lấy câu hỏi seed: math9-linear-001 (đáp án chuẩn là 8, x=8)
        # Tạo phiên cho user
        headers = {'Authorization': 'Bearer dev:user_norm'}
        sess = client.post(
            '/v1/sessions',
            headers=headers,
            json={
                'localSessionId': 'loc_norm_1',
                'alarmId': 'primary_norm',
                'questionId': 'math9-linear-001',
                'localDate': '2026-11-17',
                'timeZone': 'Asia/Ho_Chi_Minh',
            },
        )
        assert sess.status_code == 200
        sid = sess.json()['sessionId']

        # Học sinh nộp số thập phân 8.00 hoặc 8,0 (tương đương 8)
        ans_resp = client.post(
            f'/v1/sessions/{sid}/answers',
            headers={**headers, 'Idempotency-Key': 'idem-norm-1'},
            json={
                'answerValue': '8,0',
                'reasoningText': 'Giải phương trình bậc nhất x = 8',
            },
        )
        assert ans_resp.status_code == 200
        data = ans_resp.json()
        assert data['result'] == 'correct', f"Expected correct, got {data}"


