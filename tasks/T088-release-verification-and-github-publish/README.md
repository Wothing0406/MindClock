# T088 — Cổng Release Production, Trang Tải APK Trực Tiếp & Phát Hành GitHub Release v1.0.0

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. Xác minh và test chặt cổng production: tắt `/demo` và `/product` khi `APP_ENV=production` (`test_t088_release_gates.py`), và thêm endpoint `/download` + `/download/mindclock-android.apk` phục vụ trực tiếp trên máy chủ cá nhân (`https://api.ieltsoasis.site/download`) song song với GitHub Releases.
  2. Kiểm chứng **live E2E thật** toàn bộ luồng chính (Auth register -> `/v1/me` -> `/v1/curriculum/memory` -> `/v1/challenges/next` -> `/v1/profile/showcase` -> `/v1/leaderboard/weekly` -> `DELETE /v1/me` -> `/download/mindclock-android.apk`) trên PostgreSQL 16 + Cloudflare Tunnel HTTPS thật.
  3. Tạo GitHub Release `v1.0.0` và đính kèm file `mindclock-android.apk` lên `https://github.com/Wothing0406/MindClock/releases` để đường link tải công khai hoạt động thực sự.
- **Nguồn yêu cầu:** Yêu cầu hoàn thành lần cuối, kiểm chứng thật, push git và hiện Release tải được thật (`27/11/2026`).
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file đã sửa:**
  - `services/api/app/main.py`, `services/api/docker-compose.yml`, `services/api/tests/test_t088_release_gates.py`
  - `docs/download/index.html`
- **Liên quan:** Kế thừa `T080`, `T085`, `T087`.
- **Source refs đã đọc:** `services/api/app/main.py`, `services/api/docker-compose.yml`, `docs/download/index.html`.
- **Điểm tiếp tục:** Đã xong cổng production web-route, mirror `/download`, live E2E PostgreSQL và phát hành GitHub Release `v1.0.0`.

## Cổng trước coding

- [x] Đã kiểm tra nguyên nhân GitHub Actions fail (tài khoản bị khóa billing runner) nên cần phát hành Release `v1.0.0` + đính kèm APK trực tiếp và bật thêm mirror tải tại `https://api.ieltsoasis.site/download`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt và test xanh.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] `handoff.md` nêu cách kiểm tra, link Release thật và điểm tiếp tục.
