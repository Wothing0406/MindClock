# Đặc tả T088 — Release Gates, Live PostgreSQL Verification & GitHub Release

## Acceptance Criteria

- **AC-01 (Production Route Gate):** Khi `app_env == 'production'`, `/demo` và `/product` trả HTTP `404` (không mount WIP routes).
- **AC-02 (Direct Host APK Mirror):** `GET /download` trả HTML trang tải và `GET /download/mindclock-android.apk` tải được file APK release thật khi có mặt tại `dist/apk/mindclock-android.apk`.
- **AC-03 (Live HTTPS PostgreSQL E2E & Real GitHub Release):** Toàn bộ luồng `/v1` hoạt động HTTP `200`/`201` trên `https://api.ieltsoasis.site` (Docker PostgreSQL 16) và link `https://github.com/Wothing0406/MindClock/releases/latest/download/mindclock-android.apk` tải được file thật.
