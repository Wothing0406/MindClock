from datetime import datetime, timedelta, timezone
from pathlib import Path

from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings
from app.main import create_app


def _settings(tmp_path: Path) -> Settings:
    db_file = tmp_path / 't085_showcase.db'
    return Settings(
        app_env='test',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('AQ.TEST_FAKE_KEY'),
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=True,
    )


def _h(uid: str) -> dict[str, str]:
    return {'Authorization': f'Bearer dev:{uid}'}


def test_t085_profile_showcase_and_weekly_leaderboard_privacy(tmp_path: Path) -> None:
    app = create_app(_settings(tmp_path))
    with TestClient(app) as client:
        h_a = _h('student_a')
        h_b = _h('student_b')

        # Khởi tạo user A & B với 2 nhóm chuỗi và thử thách sáng
        client.patch(
            '/v1/me',
            headers=h_a,
            json={
                'alias': 'Minh Anh 11A1',
                'gradeLevel': 'Lớp 11',
                'selectedSubjects': ['TOAN', 'TIENG_ANH'],
            },
        )
        client.patch(
            '/v1/me',
            headers=h_b,
            json={
                'alias': 'Quốc Bảo 11A2',
                'gradeLevel': 'Lớp 11',
                'selectedSubjects': ['TOAN', 'VAT_LY'],
            },
        )

        # Chỉ user A opt-in bảng xếp hạng học bá tuần
        opt_a = client.post(
            '/v1/me/consent',
            headers=h_a,
            json={'scope': 'weekly_leaderboard_opt_in', 'version': '2026-11', 'granted': True},
        )
        assert opt_a.status_code == 200

        # Tạo 1 nhóm cam kết cho A và 1 báo thức (giờ 05:15 không được lộ trên showcase/BXH)
        grp = client.post(
            '/v1/commitment-groups',
            headers=h_a,
            json={'name': 'Nhóm 6h sáng', 'petName': 'Mầm Xanh'},
        )
        assert grp.status_code == 201
        alarm = client.post(
            '/v1/alarms',
            headers=h_a,
            json={
                'localTime': '05:15',
                'timeZone': 'Asia/Ho_Chi_Minh',
                'weekdays': [1, 2, 3, 4, 5],
                'challengeMode': 'challenge',
                'enabled': True,
            },
        )
        alarm_id = alarm.json()['id']

        today_vn = datetime.now(timezone(timedelta(hours=7))).date().isoformat()
        ch = client.get(f'/v1/challenges/next?subject=TOAN&date={today_vn}&difficulty=basic', headers=h_a)
        assert ch.status_code == 200
        q_id = ch.json()['questionId']

        sess = client.post(
            '/v1/sessions',
            headers=h_a,
            json={
                'localSessionId': 'loc_t085_a1',
                'alarmId': alarm_id,
                'questionId': q_id,
                'localDate': today_vn,
            },
        )
        sid = sess.json()['sessionId']
        # Nộp đáp án đúng để nhận XP và cập nhật SubjectMemory
        got_correct = False
        for idx in range(4):
            ans = client.post(
                f'/v1/sessions/{sid}/answers',
                headers=h_a,
                json={
                    'selectedIndex': idx,
                    'reasoningText': 'Chọn đáp án đúng',
                },
            )
            assert ans.status_code == 200
            if ans.json()['result'] == 'correct':
                got_correct = True
                break
        assert got_correct is True

        # 1. Kiểm tra GET /v1/profile/showcase cho user A
        sc = client.get('/v1/profile/showcase', headers=h_a)
        assert sc.status_code == 200
        body = sc.json()
        assert body['alias'] == 'Minh Anh 11A1'
        assert body['seasonRank']['tier'] in {'dong', 'bac', 'vang', 'bach_kim', 'cao_thu'}
        assert len(body['stamps']) == 3
        assert any(s['id'] == 'early_bird' for s in body['stamps'])
        assert body['earlyBirdDaysThisWeek'] >= 1
        assert body['topSubject']['subjectCode']
        assert len(body['groups']) == 1
        assert body['groups'][0]['name'] == 'Nhóm 6h sáng'
        assert body['leaderboardOptIn'] is True

        # 2. Kiểm tra GET /v1/leaderboard/weekly?subject=TOAN chỉ hiện người opt-in (A), không hiện B, không lộ 05:15
        lb = client.get('/v1/leaderboard/weekly?subject=TOAN', headers=h_b)
        assert lb.status_code == 200
        lb_body = lb.json()
        assert lb_body['subjectCode'] == 'TOAN'
        assert lb_body['currentUserOptedIn'] is False
        assert len(lb_body['entries']) == 1
        entry = lb_body['entries'][0]
        assert entry['alias'] == 'Minh Anh 11A1'
        assert entry['rank'] == 1
        assert '05:15' not in str(lb_body)
        assert 'localTime' not in entry
        assert 'alarms' not in entry
