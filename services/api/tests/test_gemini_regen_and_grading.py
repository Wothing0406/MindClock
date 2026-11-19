import json
from pathlib import Path

from fastapi.testclient import TestClient
import httpx
from pydantic import SecretStr

from app.config import Settings
from app.main import create_app
from app.services.answer_normalizer import is_answer_accepted
from app.services.gemini_service import GeminiService


def _settings(tmp_path: Path) -> Settings:
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{tmp_path / "t060.db"}',
        gemini_api_key=SecretStr('AQ.FAKE_TEST_SECRET_DO_NOT_LOG'),
        gemini_mock_mode=False,
        local_dev_bearer_uid_fallback=True,
    )


def _headers(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer token_{uid}_v1'}


def test_t060_default_models_and_staged_bank_regeneration(tmp_path: Path) -> None:
    defaults = Settings()
    assert defaults.gemini_primary_model == 'gemini-3.1-flash-lite'
    assert defaults.gemini_fast_model == 'gemini-3-flash-preview'
    assert defaults.gemini_live_model == 'gemini-3.1-flash-live-preview'

    captured_prompts: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers.get('x-goog-api-key') == 'AQ.FAKE_TEST_SECRET_DO_NOT_LOG'
        body = json.loads(request.content.decode('utf-8'))
        user_txt = body['contents'][0]['parts'][0]['text']
        sys_txt = body['systemInstruction']['parts'][0]['text']
        captured_prompts.append(sys_txt + '\n' + user_txt)
        payload = {
            'topic_id': 'vat_ly_chuyen_dong',
            'prompt': 'Một xe máy tăng tốc đều với a = 2 m/s^2 từ vận tốc đầu 4 m/s trong 5 s. Tính vận tốc cuối (m/s).',
            'reasoning_prompt_vi': 'Viết công thức v = v0 + a*t và thay số.',
            'accepted_answers': ['14', '14 m/s', 'v = 14 m/s'],
            'steps': ['Bước 1: Áp dụng v = v0 + a*t', 'Bước 2: v = 4 + 2*5 = 14 m/s'],
            'hint_vi': 'Nhân gia tốc với thời gian rồi cộng vận tốc đầu.',
        }
        return httpx.Response(
            200,
            json={
                'candidates': [
                    {'content': {'parts': [{'text': json.dumps(payload, ensure_ascii=False)}]}}
                ]
            },
        )

    app = create_app(
        _settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(handler)),
    )
    with TestClient(app) as client:
        health = client.get('/v1/health').json()
        assert health['geminiConfigured'] is True
        assert health['geminiPrimaryModel'] == 'gemini-3.1-flash-lite'
        assert health['geminiFastModel'] == 'gemini-3-flash-preview'
        assert 'AQ.FAKE_TEST_SECRET' not in json.dumps(health)

        # Lấy 1 câu gốc đã duyệt trong seed bank
        next_q = client.get(
            '/v1/challenges/next?subject=TOAN',
            headers=_headers('user_t060_a'),
        )
        assert next_q.status_code == 200
        seed_id = next_q.json()['questionId']

        regen = client.post(
            '/v1/questions/personalized',
            headers=_headers('user_t060_a'),
            json={
                'subjectCode': 'TOAN',
                'gradeLevel': 'Lớp 11',
                'topicHint': 'Tối ưu doanh thu thực tế',
                'difficulty': 3,
                'stage': 'advanced',
                'seedQuestionId': seed_id,
            },
        )
        assert regen.status_code == 200
        data = regen.json()
        assert data['stage'] == 'advanced'
        assert data['seedQuestionId'] == seed_id
        assert data['modelVersion'] == 'gemini-3.1-flash-lite'
        assert 'AQ.FAKE_TEST_SECRET' not in json.dumps(data)
        assert captured_prompts
        assert '<seed_bank_question' in captured_prompts[-1]
        assert 'Vận dụng cao' in captured_prompts[-1]


def test_t060_grading_symbolic_math_fractions_percentages_and_three_states(tmp_path: Path) -> None:
    assert is_answer_accepted('3x² + 2', ["f'(x) = 3x^2 + 2"])
    assert is_answer_accepted("f'(x) = 3 x^2 + 2", ['3x^2+2'])
    assert is_answer_accepted('25%', ['25 %', '25%'])
    assert is_answer_accepted('3/4', ['0,75', r'\frac{6}{8}'])

    def photo_handler(request: httpx.Request) -> httpx.Response:
        # Trả uncertain rõ ràng khi ảnh mờ / không đọc được
        return httpx.Response(
            200,
            json={
                'candidates': [
                    {
                        'content': {
                            'parts': [
                                {
                                    'text': json.dumps(
                                        {
                                            'result': 'uncertain',
                                            'observed_steps': ['f\'(x) = ... (mờ)'],
                                            'first_issue': None,
                                            'feedback': 'Ảnh hơi mờ ở số mũ, không trừ điểm.',
                                        },
                                        ensure_ascii=False,
                                    )
                                }
                            ]
                        }
                    }
                ]
            },
        )

    app = create_app(
        _settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(photo_handler)),
    )
    with TestClient(app) as client:
        challenge = client.get(
            '/v1/challenges/next?subject=TOAN',
            headers=_headers('user_t060_b'),
        )
        assert challenge.status_code == 200
        qid = challenge.json()['questionId']
        started = client.post(
            '/v1/sessions',
            headers=_headers('user_t060_b'),
            json={'localSessionId': 'local_t060_sess_1', 'alarmId': 'alarm_1', 'questionId': qid},
        )
        assert started.status_code == 200
        sid = started.json()['sessionId']

        # 1. Nộp chữ thiếu lập luận -> uncertain, không tăng wrongAttempts
        unc = client.post(
            f'/v1/sessions/{sid}/answers',
            headers=_headers('user_t060_b'),
            json={'answerValue': '', 'reasoningText': 'uncertain'},
        ).json()
        assert unc['result'] == 'uncertain'
        assert unc['confirmedIncorrectCount'] == 0

        # 2. Nộp ảnh mờ -> uncertain via Gemini Vision, không tăng wrongAttempts
        photo_unc = client.post(
            f'/v1/sessions/{sid}/attempts',
            headers=_headers('user_t060_b'),
            files={'image': ('work.png', b'\x89PNG\r\n\x1a\n1234', 'image/png')},
            data={'reasoning_text': "f'(x) = 3x^2", 'answerValue': '3x^2'},
        ).json()
        assert photo_unc['result'] == 'uncertain'
        assert photo_unc['confirmedIncorrectCount'] == 0

        # 3. Nộp sai 3 lần -> hint xuất hiện lần 3
        for attempt_idx in range(1, 4):
            wrong = client.post(
                f'/v1/sessions/{sid}/answers',
                headers=_headers('user_t060_b'),
                json={'answerValue': f'999{attempt_idx}', 'reasoningText': 'Đoán thử'},
            ).json()
            assert wrong['result'] == 'incorrect'
            assert wrong['confirmedIncorrectCount'] == attempt_idx
            if attempt_idx < 3:
                assert wrong['hint'] is None
            else:
                assert wrong['hint'] is not None
