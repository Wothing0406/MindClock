import json
from pathlib import Path

from fastapi.testclient import TestClient
import httpx
from pydantic import SecretStr

from app.config import Settings
from app.main import create_app
from app.services.gemini_service import GeminiService


def _make_settings(
    tmp_path: Path,
    *,
    gemini_key: str = 'AQ.TEST_FAKE_KEY_NEVER_LEAK',
    mock_mode: bool = False,
) -> Settings:
    db_file = tmp_path / 'test_mindclock.db'
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr(gemini_key) if gemini_key else None,
        gemini_primary_model='gemini-3.8-flash',
        gemini_fast_model='gemini-3.5-flash-lite',
        gemini_live_model='gemini-3.8-live',
        gemini_mock_mode=mock_mode,
        local_dev_bearer_uid_fallback=True,
    )


def _headers(uid: str, *, idem: str | None = None) -> dict[str, str]:
    out = {'Authorization': f'Bearer dev:{uid}'}
    if idem is not None:
        out['Idempotency-Key'] = idem
    return out


def test_health_and_zero_secret_exposure(tmp_path: Path) -> None:
    app = create_app(_make_settings(tmp_path))
    with TestClient(app) as client:
        res = client.get('/v1/health')
        assert res.status_code == 200
        data = res.json()
        assert data['status'] == 'ok'
        assert data['dbReady'] is True
        assert data['dbDialect'] == 'sqlite'
        assert data['geminiConfigured'] is True
        assert data['geminiPrimaryModel'] == 'gemini-3.8-flash'
        assert data['geminiFastModel'] == 'gemini-3.5-flash-lite'
        assert data['geminiLiveModel'] == 'gemini-3.8-live'
        assert 'AQ.TEST_FAKE_KEY_NEVER_LEAK' not in res.text


def test_auth_and_profile_grade_subject_update(tmp_path: Path) -> None:
    app = create_app(_make_settings(tmp_path, mock_mode=True))
    with TestClient(app) as client:
        unauth = client.get('/v1/me')
        assert unauth.status_code == 401
        assert unauth.json()['error']['code'] == 'AUTH_EXPIRED'

        me = client.get('/v1/me', headers=_headers('student_a'))
        assert me.status_code == 200
        assert me.json()['gradeLevel'] == 'Lớp 9'

        patched = client.patch(
            '/v1/me',
            headers=_headers('student_a'),
            json={
                'alias': 'An Minh',
                'gradeLevel': 'Lớp 11',
                'selectedSubjects': ['toan', 'tin_hoc', 'tieng_anh'],
                'goalLabel': 'Ôn thi HSG Tin',
            },
        )
        assert patched.status_code == 200
        body = patched.json()
        assert body['alias'] == 'An Minh'
        assert body['gradeLevel'] == 'Lớp 11'
        assert body['selectedSubjects'] == ['TOAN', 'TIN_HOC', 'TIENG_ANH']
        assert body['goalLabel'] == 'Ôn thi HSG Tin'


def test_alarms_idempotency_and_cross_owner_403(tmp_path: Path) -> None:
    app = create_app(_make_settings(tmp_path, mock_mode=True))
    with TestClient(app) as client:
        payload = {
            'localTime': '06:00',
            'timeZone': 'Asia/Ho_Chi_Minh',
            'weekdays': [1, 2, 3, 4, 5],
            'enabled': True,
            'challengeMode': 'short_review',
        }
        r1 = client.post(
            '/v1/alarms',
            headers=_headers('user_a', idem='alarm-create-1'),
            json=payload,
        )
        r2 = client.post(
            '/v1/alarms',
            headers=_headers('user_a', idem='alarm-create-1'),
            json=payload,
        )
        assert r1.status_code == 200
        assert r2.status_code == 200
        assert r1.json()['id'] == r2.json()['id']

        conflict = client.post(
            '/v1/alarms',
            headers=_headers('user_a', idem='alarm-create-1'),
            json={**payload, 'localTime': '06:30'},
        )
        assert conflict.status_code == 409
        assert conflict.json()['error']['code'] == 'IDEMPOTENCY_CONFLICT'

        alarm_id = r1.json()['id']
        forbidden_patch = client.patch(
            f'/v1/alarms/{alarm_id}',
            headers=_headers('user_b'),
            json={**payload, 'localTime': '07:00'},
        )
        assert forbidden_patch.status_code == 403

        forbidden_del = client.delete(
            f'/v1/alarms/{alarm_id}',
            headers=_headers('user_b'),
        )
        assert forbidden_del.status_code == 403


def test_alarm_session_answers_hint_at_3_and_idempotent_xp(tmp_path: Path) -> None:
    app = create_app(_make_settings(tmp_path, mock_mode=True))
    with TestClient(app) as client:
        nxt = client.get(
            '/v1/challenges/next?subject=TOAN&date=2026-11-14',
            headers=_headers('user_xp'),
        )
        assert nxt.status_code == 200
        q_json = nxt.json()
        assert q_json['questionId'] == 'math9-linear-001'
        assert 'answerSpec' not in q_json
        assert 'rubric' not in q_json

        sess = client.post(
            '/v1/sessions',
            headers=_headers('user_xp'),
            json={
                'localSessionId': 'loc_100',
                'alarmId': 'primary_morning',
                'questionId': 'math9-linear-001',
                'localDate': '2026-11-14',
                'timeZone': 'Asia/Ho_Chi_Minh',
            },
        )
        assert sess.status_code == 200
        session_id = sess.json()['sessionId']

        # Sai 3 lần: chỉ từ lần sai thứ 3 mới mở gợi ý (`hint`)
        for idx in range(1, 4):
            wrong = client.post(
                f'/v1/sessions/{session_id}/answers',
                headers=_headers('user_xp', idem=f'wrong-{idx}'),
                json={'answerValue': 'x = 99', 'reasoningText': 'Thử thế số'},
            )
            assert wrong.status_code == 200
            w_data = wrong.json()
            assert w_data['result'] == 'incorrect'
            assert w_data['xpAwarded'] == 0
            if idx < 3:
                assert w_data['hint'] is None
            else:
                assert w_data['hint'] is not None

        # User B không được nộp đáp án vào session của User XP
        cross = client.post(
            f'/v1/sessions/{session_id}/answers',
            headers=_headers('user_b', idem='cross-1'),
            json={'answerValue': 'x = 8', 'reasoningText': 'x - 3 = 5'},
        )
        assert cross.status_code == 403

        # Nộp đúng 2 lần cùng Idempotency-Key -> XP chỉ cộng đúng 1 lần (+10)
        ok1 = client.post(
            f'/v1/sessions/{session_id}/answers',
            headers=_headers('user_xp', idem='ok-1'),
            json={'answerValue': 'x = 8', 'reasoningText': 'x - 3 = 5 => x = 8'},
        )
        ok2 = client.post(
            f'/v1/sessions/{session_id}/answers',
            headers=_headers('user_xp', idem='ok-1'),
            json={'answerValue': 'x = 8', 'reasoningText': 'x - 3 = 5 => x = 8'},
        )
        assert ok1.status_code == 200
        assert ok1.json()['result'] == 'correct'
        assert ok1.json()['xpAwarded'] == 10
        assert ok2.json()['attemptId'] == ok1.json()['attemptId']

        summary = client.get('/v1/progress/summary', headers=_headers('user_xp'))
        assert summary.status_code == 200
        assert summary.json()['xp'] == 10
        assert summary.json()['completedSessions'] == 1


def test_personalized_question_generation_gemini_38_and_isolation(tmp_path: Path) -> None:
    captured_requests: list[tuple[str, dict, str]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        captured_requests.append(
            (
                str(request.url),
                json.loads(request.content.decode('utf-8')),
                request.headers.get('x-goog-api-key', ''),
            )
        )
        payload = {
            'topic_id': 'vat_ly_dinh_luat_ohm',
            'prompt': 'Một mạch điện có U = 12V và R = 4Ω. Tính cường độ dòng điện I.',
            'reasoning_prompt_vi': 'Viết công thức định luật Ôm rồi thay số.',
            'accepted_answers': ['3A', '3 A', 'I = 3A'],
            'steps': ['Ghi công thức I = U / R', 'Thay U = 12, R = 4 được I = 3 A'],
            'hint_vi': 'Nhớ rằng cường độ dòng điện tỉ lệ thuận với hiệu điện thế.',
        }
        return httpx.Response(
            200,
            json={
                'candidates': [
                    {'content': {'parts': [{'text': json.dumps(payload, ensure_ascii=False)}]}}
                ]
            },
        )

    transport = httpx.MockTransport(handler)
    app = create_app(
        _make_settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=transport),
    )

    with TestClient(app) as client:
        client.patch(
            '/v1/me',
            headers=_headers('user_personal'),
            json={
                'alias': 'Minh Khoa',
                'gradeLevel': 'Lớp 9',
                'selectedSubjects': ['TOAN', 'VAT_LY'],
            },
        )

        # Tạo điểm yếu ở một topic Toán bằng cách trả lời sai 1 lần
        sess = client.post(
            '/v1/sessions',
            headers=_headers('user_personal'),
            json={'localSessionId': 'weak_seed_1', 'questionId': 'math9-linear-001'},
        ).json()
        client.post(
            f"/v1/sessions/{sess['sessionId']}/answers",
            headers=_headers('user_personal', idem='weak-1'),
            json={'answerValue': 'x = 1', 'reasoningText': 'Thử'},
        )

        gen = client.post(
            '/v1/questions/personalized',
            headers=_headers('user_personal'),
            json={
                'subjectCode': 'VAT_LY',
                'gradeLevel': 'Lớp 9',
                'topicHint': 'Định luật Ôm',
                'difficulty': 2,
                'saveToBank': True,
            },
        )
        assert gen.status_code == 200
        g_data = gen.json()
        assert g_data['subjectCode'] == 'VAT_LY'
        assert g_data['gradeBand'] == 'Lớp 9'
        assert g_data['status'] == 'draft'
        assert g_data['sourceType'] == 'ai_personalized_draft'
        assert g_data['modelVersion'] == 'gemini-3.8-flash'
        assert g_data['xpAwarded'] == 0
        assert g_data['fallbackUsed'] is False
        assert '12V' in g_data['prompt']

        # Kiểm tra đúng model `gemini-3.8-flash` & header `x-goog-api-key`
        assert len(captured_requests) == 1
        url, req_body, api_header = captured_requests[0]
        assert '/v1beta/models/gemini-3.8-flash:generateContent' in url
        assert api_header == 'AQ.TEST_FAKE_KEY_NEVER_LEAK'
        user_text = req_body['contents'][0]['parts'][0]['text']
        assert 'Lớp 9' in user_text
        assert 'VAT_LY' in user_text
        assert 'Định luật Ôm' in user_text

        # User A đọc được bản nháp cá nhân; User B không thấy
        list_a = client.get('/v1/questions/personalized', headers=_headers('user_personal'))
        list_b = client.get('/v1/questions/personalized', headers=_headers('user_other'))
        assert len(list_a.json()['items']) == 1
        assert list_b.json()['items'] == []

        # Ngân hàng báo thức /v1/challenges/next vẫn chỉ phục vụ câu `published` đã duyệt
        alarm_next = client.get(
            '/v1/challenges/next?subject=VAT_LY',
            headers=_headers('user_personal'),
        )
        assert alarm_next.status_code == 200
        assert alarm_next.json()['questionId'] == 'phys9-ohm-001'


def test_personalized_question_fallback_on_upstream_503(tmp_path: Path) -> None:
    def failing_handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(503, json={'error': {'message': 'unavailable'}})

    app = create_app(
        _make_settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(failing_handler)),
    )
    with TestClient(app) as client:
        res = client.post(
            '/v1/questions/personalized',
            headers=_headers('user_fallback'),
            json={'subjectCode': 'TOAN', 'difficulty': 1},
        )
        assert res.status_code == 200
        data = res.json()
        assert data['fallbackUsed'] is True
        assert data['status'] == 'published'
        assert data['xpAwarded'] == 0


def test_live_token_consent_guard_and_ephemeral_minting(tmp_path: Path) -> None:
    live_calls: list[tuple[str, dict]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        live_calls.append((str(request.url), json.loads(request.content.decode('utf-8'))))
        return httpx.Response(200, json={'name': 'auth_tokens/ephem_abc123'})

    app = create_app(
        _make_settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(handler)),
    )
    with TestClient(app) as client:
        client.patch(
            '/v1/me',
            headers=_headers('live_user'),
            json={'alias': 'Lan Anh', 'gradeLevel': 'Lớp 12', 'selectedSubjects': ['TIENG_ANH']},
        )

        # Chưa đồng ý rõ ràng -> 403 CONSENT_REQUIRED
        denied = client.post(
            '/v1/study/live-token',
            headers=_headers('live_user'),
            json={'subjectCode': 'TIENG_ANH', 'taskTitle': 'Luyện Speaking', 'consentGranted': False},
        )
        assert denied.status_code == 403
        assert denied.json()['error']['code'] == 'CONSENT_REQUIRED'
        assert live_calls == []

        # Đồng ý rõ ràng -> cấp ephemeral token `gemini-3.8-live`, không lộ master key
        granted = client.post(
            '/v1/study/live-token',
            headers=_headers('live_user'),
            json={
                'subjectCode': 'TIENG_ANH',
                'taskTitle': 'Luyện cấu trúc câu điều kiện',
                'responseModality': 'AUDIO',
                'consentGranted': True,
            },
        )
        assert granted.status_code == 200
        g_data = granted.json()
        assert g_data['tokenName'] == 'auth_tokens/ephem_abc123'
        assert 'BidiGenerateContentConstrained?access_token=auth_tokens/ephem_abc123' in g_data['wsUrl']
        assert g_data['model'] == 'gemini-3.8-live'
        assert g_data['isMock'] is False
        assert 'AQ.TEST_FAKE_KEY_NEVER_LEAK' not in granted.text

        assert len(live_calls) == 1
        call_url, call_body = live_calls[0]
        assert '/v1alpha/auth_tokens' in call_url
        assert call_body['uses'] == 1
        assert call_body['bidiGenerateContentSetup']['model'] == 'models/gemini-3.8-live'
        assert (
            call_body['bidiGenerateContentSetup']['generationConfig']['responseModalities']
            == ['AUDIO']
        )


def test_primary_38_upstream_error_falls_back_to_fast_35_model(tmp_path: Path) -> None:
    seen_urls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen_urls.append(str(request.url))
        if 'gemini-3.8-flash' in str(request.url):
            return httpx.Response(503, json={'error': {'message': 'busy'}})
        payload = {
            'topic_id': 'toan_pt_bac_nhat',
            'prompt': 'Giải phương trình 3x - 6 = 9.',
            'reasoning_prompt_vi': 'Viết 1 bước chuyển vế.',
            'accepted_answers': ['5', 'x=5'],
            'steps': ['3x = 15', 'x = 5'],
            'hint_vi': 'Cộng 6 vào hai vế.',
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
        _make_settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(handler)),
    )
    with TestClient(app) as client:
        res = client.post(
            '/v1/questions/personalized',
            headers=_headers('user_fast_fb'),
            json={'subjectCode': 'TOAN', 'gradeLevel': 'Lớp 9', 'difficulty': 1},
        )
        assert res.status_code == 200
        data = res.json()
        assert data['fallbackUsed'] is False
        assert data['modelVersion'] == 'gemini-3.5-flash-lite'
        assert data['status'] == 'draft'
        assert any('gemini-3.8-flash' in u for u in seen_urls)
        assert any('gemini-3.5-flash-lite' in u for u in seen_urls)


def test_study_session_help_and_idempotent_finish(tmp_path: Path) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content.decode('utf-8'))
        # Đảm bảo endpoint /v1/study/help vẫn dùng model 3.8 và kẹp lượt hội thoại <= 3
        prompt_text = body['contents'][0]['parts'][0]['text']
        assert 'turn-1' not in prompt_text
        assert 'turn-4' in prompt_text
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
                                            'message_vi': 'Thử chuyển vế số hạng tự do sang phải trước nhé.',
                                            'next_question_vi': 'Sau khi chuyển vế, vế trái còn lại gì?',
                                            'help_level': 'socratic',
                                            'safety_status': 'safe',
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
        _make_settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(handler)),
    )
    with TestClient(app) as client:
        created = client.post(
            '/v1/study/sessions',
            headers=_headers('study_u', idem='st-create-1'),
            json={
                'clientSessionId': 'cli_study_01',
                'taskTitle': 'Ôn phương trình',
                'subjectCode': 'TOAN',
                'targetMinutes': 25,
                'focusLevel': 'standard',
            },
        )
        assert created.status_code == 200
        srv_id = created.json()['sessionId']

        helped = client.post(
            '/v1/study/help',
            headers=_headers('study_u'),
            json={
                'clientSessionId': 'cli_study_01',
                'subject': 'TOAN',
                'grade': 'Lớp 9',
                'task': 'Ôn phương trình',
                'questionText': 'Mình bí bước tách nhân tử.',
                'recentTurns': [
                    {'role': 'user', 'contentVi': 'turn-1'},
                    {'role': 'assistant', 'contentVi': 'turn-2'},
                    {'role': 'user', 'contentVi': 'turn-3'},
                    {'role': 'assistant', 'contentVi': 'turn-4'},
                ],
            },
        )
        assert helped.status_code == 200
        assert helped.json()['model_version'] == 'gemini-3.8-flash'
        assert 'chuyển vế' in helped.json()['message_vi']

        fin1 = client.post(
            f'/v1/study/sessions/{srv_id}/finish',
            headers=_headers('study_u', idem='st-fin-1'),
            json={
                'clientSessionId': 'cli_study_01',
                'finalStatus': 'completed',
                'elapsedWallSeconds': 1500,
                'inAppFocusSeconds': 1420,
            },
        )
        fin2 = client.post(
            f'/v1/study/sessions/{srv_id}/finish',
            headers=_headers('study_u', idem='st-fin-1'),
            json={
                'clientSessionId': 'cli_study_01',
                'finalStatus': 'completed',
                'elapsedWallSeconds': 1500,
                'inAppFocusSeconds': 1420,
            },
        )
        assert fin1.status_code == 200
        assert fin1.json()['xpAwarded'] == 0
        assert fin1.json() == fin2.json()


def test_double_xp_guard_and_flutter_feedback_contract(tmp_path: Path) -> None:
    app = create_app(_make_settings(tmp_path, mock_mode=True))
    with TestClient(app) as client:
        sess = client.post(
            '/v1/sessions',
            headers=_headers('xp_guard'),
            json={'localSessionId': 'loc_guard_1', 'questionId': 'math9-linear-001'},
        ).json()
        sid = sess['sessionId']

        first = client.post(
            f'/v1/sessions/{sid}/answers',
            headers=_headers('xp_guard', idem='k1'),
            json={'answerValue': '8', 'reasoningText': 'x = 8'},
        )
        second = client.post(
            f'/v1/sessions/{sid}/answers',
            headers=_headers('xp_guard', idem='k2-different'),
            json={'answerValue': 'x = 8', 'reasoningText': 'Nộp lại'},
        )
        assert first.status_code == 200
        assert first.json()['xpAwarded'] == 10
        assert second.status_code == 200
        assert second.json()['xpAwarded'] == 0

        summary = client.get('/v1/progress/summary', headers=_headers('xp_guard'))
        assert summary.json()['xp'] == 10

        fb = client.post(
            f'/v1/sessions/{sid}/feedback',
            headers=_headers('xp_guard'),
            json={
                'attemptId': first.json()['attemptId'],
                'category': 'wrong_answer_explanation',
                'comment': 'Kiểm tra hiển thị tiếng Việt',
            },
        )
        assert fb.status_code == 200
        assert fb.json()['recorded'] is True


def test_photo_attempt_gemini_vision_grading_and_validation(tmp_path: Path) -> None:
    vision_calls = 0

    def handler(_request: httpx.Request) -> httpx.Response:
        nonlocal vision_calls
        vision_calls += 1
        # Trả JSON có bọc markdown fence để kiểm tra _parse_json_object
        fenced = '```json\n{"result": "correct", "observed_steps": ["2(x-3)=10", "x=8"], "first_issue": null, "feedback": "Bài viết tay rõ ràng và chính xác!"}\n```'
        return httpx.Response(
            200,
            json={'candidates': [{'content': {'parts': [{'text': fenced}]}}]},
        )

    app = create_app(
        _make_settings(tmp_path),
        gemini_factory=lambda s: GeminiService(s, transport=httpx.MockTransport(handler)),
    )
    with TestClient(app) as client:
        sid = client.post(
            '/v1/sessions',
            headers=_headers('photo_u'),
            json={'localSessionId': 'loc_photo_1', 'questionId': 'math9-linear-001'},
        ).json()['sessionId']

        # Sai MIME -> 415
        bad_mime = client.post(
            f'/v1/sessions/{sid}/attempts',
            headers=_headers('photo_u', idem='p-bad-mime'),
            files={'image': ('work.pdf', b'%PDF-1.4', 'application/pdf')},
        )
        assert bad_mime.status_code == 415

        # Quá 5MB -> 413
        too_big = client.post(
            f'/v1/sessions/{sid}/attempts',
            headers=_headers('photo_u', idem='p-big'),
            files={'image': ('work.jpg', b'x' * (5 * 1024 * 1024 + 1), 'image/jpeg')},
        )
        assert too_big.status_code == 413

        # Hợp lệ theo đúng field 'image' mà PersonalApiClient Flutter gửi
        ok1 = client.post(
            f'/v1/sessions/{sid}/attempts',
            headers=_headers('photo_u', idem='p-ok-1'),
            data={'answerValue': '8', 'reasoning_text': 'Chụp bài viết tay'},
            files={'image': ('solution.jpg', b'\xff\xd8\xff\xe0fake-jpeg', 'image/jpeg')},
        )
        ok2 = client.post(
            f'/v1/sessions/{sid}/attempts',
            headers=_headers('photo_u', idem='p-ok-1'),
            data={'answerValue': '8', 'reasoning_text': 'Chụp bài viết tay'},
            files={'image': ('solution.jpg', b'\xff\xd8\xff\xe0fake-jpeg', 'image/jpeg')},
        )
        assert ok1.status_code == 200
        d1 = ok1.json()
        assert d1['result'] == 'correct'
        assert d1['xpAwarded'] == 10
        assert d1['modelVersion'] == 'gemini-3.8-flash'
        assert ok2.json()['attemptId'] == d1['attemptId']
        assert vision_calls == 1


def test_timetable_subject_normalization_and_account_delete(tmp_path: Path) -> None:
    app = create_app(_make_settings(tmp_path, mock_mode=True))
    with TestClient(app) as client:
        client.patch(
            '/v1/me',
            headers=_headers('del_u'),
            json={'selectedSubjects': ['math', 'physics', 'biology'], 'gradeLevel': 'Lớp 9'},
        )
        tt_put = client.put(
            '/v1/timetable',
            headers=_headers('del_u'),
            json={
                'slots': [
                    {'weekday': 1, 'subjectCode': 'math', 'topicId': 'linear_equation_1var'},
                    {'weekday': 2, 'subjectCode': 'biology', 'topicId': 'mendel_law'},
                ]
            },
        )
        assert tt_put.status_code == 200
        assert tt_put.json()['slots'][0]['subjectCode'] == 'TOAN'
        assert tt_put.json()['slots'][1]['subjectCode'] == 'SINH_HOC'

        # Gọi /challenges/next bằng mã Flutter 'biology' -> trả câu SINH_HOC
        bio = client.get('/v1/challenges/next?subject=biology', headers=_headers('del_u'))
        assert bio.status_code == 200
        assert bio.json()['subject'] == 'SINH_HOC'

        # Tạo 1 báo thức rồi xóa tài khoản -> 202 & sạch toàn bộ
        client.post('/v1/alarms', headers=_headers('del_u'), json={'localTime': '06:15'})
        deleted = client.delete('/v1/me', headers=_headers('del_u'))
        assert deleted.status_code == 202
        assert deleted.json()['status'] == 'deleted'

        alarms_after = client.get('/v1/alarms', headers=_headers('del_u'))
        assert alarms_after.json()['items'] == []


def test_demo_console_and_bermuda_audio_route(tmp_path: Path) -> None:
    app = create_app(_make_settings(tmp_path, mock_mode=True))
    with TestClient(app) as client:
        page = client.get('/demo')
        assert page.status_code == 200
        assert 'MindClock — Demo Sandbox Live' in page.text
        assert 'AQ.TEST_FAKE_KEY_NEVER_LEAK' not in page.text

        audio = client.get('/demo/bermuda.mp3')
        assert audio.status_code in {200, 404}
        if audio.status_code == 200:
            assert audio.headers['content-type'].startswith('audio/')
