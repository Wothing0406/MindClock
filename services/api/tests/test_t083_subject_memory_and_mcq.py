from pathlib import Path

from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings
from app.main import create_app


def _settings(tmp_path: Path) -> Settings:
    db_file = tmp_path / 't083_subject_memory.db'
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('AQ.TEST_FAKE_KEY'),
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_t083_timetable_morning_mcq_subject_memory_miniquiz_and_abandon(tmp_path: Path) -> None:
    app = create_app(_settings(tmp_path))
    with TestClient(app) as client:
        headers = _h('student_t083')

        me = client.get('/v1/me', headers=headers)
        assert me.status_code == 200
        client.patch(
            '/v1/me',
            headers=headers,
            json={'gradeLevel': 'Lớp 11', 'selectedSubjects': ['TOAN', 'NGU_VAN', 'TIENG_ANH']},
        )

        # 2026-11-27 là Thứ 6 (weekday = 5) -> đặt TKB Thứ 6 chỉ có Tiếng Anh & Ngữ văn
        tt = client.put(
            '/v1/timetable',
            headers=headers,
            json={
                'slots': [
                    {'weekday': 5, 'subjectCode': 'TIENG_ANH', 'topicId': ''},
                    {'weekday': 5, 'subjectCode': 'NGU_VAN', 'topicId': ''},
                ]
            },
        )
        assert tt.status_code == 200

        mem_res = client.get('/v1/curriculum/memory', headers=headers)
        assert mem_res.status_code == 200
        assert len(mem_res.json()['items']) >= 3

        patch_mem = client.patch(
            '/v1/curriculum/memory/TIENG_ANH',
            headers=headers,
            json={'currentWeek': 14},
        )
        assert patch_mem.status_code == 200
        assert patch_mem.json()['currentWeek'] == 14

        # 1. Lấy câu hỏi sáng auto theo TKB Thứ 6 (mức Cơ bản ABCD)
        ch = client.get(
            '/v1/challenges/next?subject=auto&date=2026-11-27&difficulty=basic',
            headers=headers,
        )
        assert ch.status_code == 200
        body = ch.json()
        assert body['subject'] in {'TIENG_ANH', 'NGU_VAN'}
        assert body['questionFormat'] == 'mcq'
        assert len(body['options']) == 4
        assert 'Thứ 6' in body['sourceScheduleReasonVi']

        # Tạo alarm & session rồi thử nộp sai -> đúng ABCD
        alarm = client.post(
            '/v1/alarms',
            headers=headers,
            json={
                'localTime': '06:00',
                'timeZone': 'Asia/Ho_Chi_Minh',
                'weekdays': [1, 2, 3, 4, 5],
                'challengeMode': 'challenge',
                'enabled': True,
            },
        )
        assert alarm.status_code == 200
        alarm_id = alarm.json()['id']
        sess = client.post(
            '/v1/sessions',
            headers=headers,
            json={
                'localSessionId': 'loc_t083_1',
                'alarmId': alarm_id,
                'questionId': body['questionId'],
                'localDate': '2026-11-27',
            },
        )
        assert sess.status_code == 200
        session_id = sess.json()['sessionId']

        # Thử tìm đáp án đúng (với 4 lựa chọn, ít nhất 1 lựa chọn phải correct)
        got_correct = False
        for idx in range(4):
            ans = client.post(
                f'/v1/sessions/{session_id}/answers',
                headers=headers,
                json={'selectedIndex': idx, 'reasoningText': 'Chọn nhanh ABCD'},
            )
            assert ans.status_code == 200
            if ans.json()['result'] == 'correct':
                got_correct = True
                assert ans.json()['xpAwarded'] == 10
                assert ans.json()['scorePercent'] == 100
                assert ans.json()['masteryScore'] >= 47
                break
        assert got_correct is True

        # 2. Lấy đề ngắn nâng cao >= 70%
        adv = client.get(
            '/v1/challenges/next?subject=NGU_VAN&date=2026-11-27&difficulty=advanced',
            headers=headers,
        )
        assert adv.status_code == 200
        adv_body = adv.json()
        assert adv_body['questionFormat'] == 'mini_quiz'
        assert len(adv_body['subQuestions']) == 4
        assert adv_body['passThreshold'] == 0.7

        sess2 = client.post(
            '/v1/sessions',
            headers=headers,
            json={
                'localSessionId': 'loc_t083_2',
                'alarmId': alarm_id,
                'questionId': adv_body['questionId'],
                'localDate': '2026-11-27',
            },
        ).json()
        s2_id = sess2['sessionId']

        # Nộp đáp án toàn index 0 -> có thể < 70%, rồi kiểm tra Bỏ cuộc ngay lập tức
        fail_ans = client.post(
            f'/v1/sessions/{s2_id}/answers',
            headers=headers,
            json={'quizAnswers': [0, 0, 0, 0]},
        )
        assert fail_ans.status_code == 200
        assert fail_ans.json()['scorePercent'] is not None

        if fail_ans.json()['result'] != 'correct':
            quit_res = client.post(
                f'/v1/sessions/{s2_id}/abandon?immediate=true',
                headers=headers,
            )
            assert quit_res.status_code == 200
            assert quit_res.json()['state'] == 'abandoned'
            assert quit_res.json()['xpAwarded'] == 0
