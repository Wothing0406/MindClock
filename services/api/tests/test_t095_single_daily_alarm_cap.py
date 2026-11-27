from __future__ import annotations

import datetime as dt

from fastapi.testclient import TestClient

from app.main import create_app


def _auth_headers(
    email: str = 't095-daily-cap@mindclock.test',
    uid: str = 't095-user-1',
    idem: str | None = None,
) -> dict[str, str]:
    headers = {
        'Authorization': f'Bearer dev:{uid}:{email}',
    }
    if idem:
        headers['Idempotency-Key'] = idem
    return headers


def test_t095_single_completed_alarm_xp_cap_per_day() -> None:
    app = create_app()
    with TestClient(app) as client:
        today_iso = dt.date.today().isoformat()

        me_res = client.get('/v1/me', headers=_auth_headers())
        assert me_res.status_code == 200, me_res.text

        # 1. Tạo session báo thức thứ nhất trong ngày
        s1_res = client.post(
            '/v1/sessions',
            headers=_auth_headers(),
            json={
                'localSessionId': f't095-loc-{today_iso}-1',
                'alarmId': 'alarm-1',
                'questionId': 'math9-linear-001',
                'localDate': today_iso,
                'timeZone': 'Asia/Ho_Chi_Minh',
            },
        )
        assert s1_res.status_code == 200, s1_res.text
        s1_id = s1_res.json()['sessionId']

        ans1 = client.post(
            f'/v1/sessions/{s1_id}/answers',
            headers=_auth_headers(idem=f't095-ans1-{today_iso}'),
            json={'answerValue': '8', 'reasoningText': 'x = 8'},
        )
        assert ans1.status_code == 200, ans1.text
        data1 = ans1.json()
        assert data1['result'] == 'correct'
        assert data1['xpAwarded'] == 10

        # 2. Tạo session báo thức thứ hai trong cùng ngày
        s2_res = client.post(
            '/v1/sessions',
            headers=_auth_headers(),
            json={
                'localSessionId': f't095-loc-{today_iso}-2',
                'alarmId': 'alarm-2',
                'questionId': 'math9-linear-001',
                'localDate': today_iso,
                'timeZone': 'Asia/Ho_Chi_Minh',
            },
        )
        assert s2_res.status_code == 200, s2_res.text
        s2_id = s2_res.json()['sessionId']

        ans2 = client.post(
            f'/v1/sessions/{s2_id}/answers',
            headers=_auth_headers(idem=f't095-ans2-{today_iso}'),
            json={'answerValue': '8', 'reasoningText': 'x = 8'},
        )
        assert ans2.status_code == 200, ans2.text
        data2 = ans2.json()
        assert data2['result'] == 'correct'
        # Chuông thứ 2 trong cùng ngày không cộng thêm XP báo thức
        assert data2['xpAwarded'] == 0

        # 3. Kiểm tra /v1/progress/summary chỉ tính 1 báo thức hoàn thành
        summary_res = client.get('/v1/progress/summary', headers=_auth_headers())
        assert summary_res.status_code == 200, summary_res.text
        summary = summary_res.json()
        assert summary['completedSessions'] == 1
