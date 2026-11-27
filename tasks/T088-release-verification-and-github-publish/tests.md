# Kiểm thử T088

| Test ID | Mapping AC | Lệnh kiểm tra | Trạng thái | Ngày / Môi trường |
| --- | --- | --- | --- | --- |
| `TC-01` | `AC-01`, `AC-02` | `.\.venv\Scripts\python.exe -m pytest -q` (`test_t088_release_gates.py`, `94 passed, 10 skipped`) | `passed` | `2026-11-27` / Windows + FastAPI `TestClient` |
| `TC-02` | `AC-03` | Live HTTPS E2E tới `https://api.ieltsoasis.site`: `/v1/health` (200), `/download` (200), `HEAD /download/mindclock-android.apk` (200, `70295061` bytes), `/v1/auth/register` -> `/v1/me` -> `/v1/curriculum/memory` -> `/v1/challenges/next` (`mcq`) -> `/v1/profile/showcase` -> `/v1/leaderboard/weekly` -> `DELETE /v1/me` | `passed` | `2026-11-27` / Live Docker PostgreSQL 16 + Cloudflare Tunnel |
