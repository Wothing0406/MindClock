import base64
from fastapi.testclient import TestClient
import pytest
from sqlalchemy import create_engine

from app.config import Settings
from app.db.base import Base
from app.main import create_app


@pytest.fixture
def client(tmp_path) -> TestClient:
    db_file = tmp_path / 'test_ocr.db'
    db_url = f'sqlite+pysqlite:///{db_file}'
    settings = Settings(
        app_env='test',
        database_url=db_url,
        local_dev_bearer_uid_fallback=True,
        gemini_mock_mode=True,
    )
    engine = create_engine(db_url, connect_args={'check_same_thread': False})
    Base.metadata.create_all(engine)
    app = create_app(settings=settings)
    return TestClient(app)


def test_parse_timetable_image_mock_mode(client: TestClient):
    fake_image_bytes = b'GIF89a\x01\x00\x01\x00\x80\x00\x00\xff\xff\xff\x00\x00\x00!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;'
    b64_str = base64.b64encode(fake_image_bytes).decode('ascii')

    headers = {'Authorization': 'Bearer dev:test_student_ocr'}
    resp = client.post(
        '/v1/timetable/parse-image',
        headers=headers,
        json={
            'imageBase64': b64_str,
            'mimeType': 'image/gif',
        },
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert 'slots' in data
    assert len(data['slots']) > 0
    first_slot = data['slots'][0]
    assert 'weekday' in first_slot
    assert 'position' in first_slot
    assert 'subjectCode' in first_slot
    assert first_slot['subjectCode'] in {'math', 'literature', 'english', 'physics'}


def test_parse_timetable_image_requires_auth(client: TestClient):
    resp = client.post(
        '/v1/timetable/parse-image',
        json={
            'imageBase64': 'SGVsbG8gV29ybGQhISEh',
            'mimeType': 'image/jpeg',
        },
    )
    assert resp.status_code == 401


def test_parse_timetable_image_rejects_invalid_base64(client: TestClient):
    headers = {'Authorization': 'Bearer dev:test_student_ocr'}
    resp = client.post(
        '/v1/timetable/parse-image',
        headers=headers,
        json={
            'imageBase64': '###not_base64###',
            'mimeType': 'image/jpeg',
        },
    )
    assert resp.status_code == 400
