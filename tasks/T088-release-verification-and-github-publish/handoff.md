# Bàn giao nhiệm vụ T088

- **Trạng thái cuối:** `done`
- **Đã làm:**
  - Tắt WIP routes `/demo` & `/product` ngoài `development/test/local` (được verify bởi `test_t088_release_gates.py`).
  - Thêm `/download` & `/download/mindclock-android.apk` vào `main.py` và mount read-only `dist/apk` + `docs/download` trong `services/api/docker-compose.yml`.
  - Xác minh E2E trực tiếp trên `https://api.ieltsoasis.site` (Docker PostgreSQL 16 + Cloudflare Tunnel).
  - Xuất bản GitHub Release `v1.0.0` kèm binary `mindclock-android.apk`.
- **Link tải & xác minh:**
  - GitHub Release: `https://github.com/Wothing0406/MindClock/releases/tag/v1.0.0`
  - Link tải APK chính thức: `https://github.com/Wothing0406/MindClock/releases/latest/download/mindclock-android.apk`
  - Link tải & trang hướng dẫn dự phòng từ máy chủ cá nhân: `https://api.ieltsoasis.site/download`
- **Điểm tiếp tục chính xác:** Người dùng có thể bấm link tải APK trực tiếp từ GitHub Releases hoặc `https://api.ieltsoasis.site/download` để cài lên điện thoại Android thật.
