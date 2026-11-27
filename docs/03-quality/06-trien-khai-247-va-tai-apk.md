# Kiến trúc Host 24/7 & Tải APK cho Android Dùng Thật

Tài liệu này tổng hợp lộ trình vận hành thực tế cho **MindClock Android (người dùng THPT thật)** khi chuyển từ môi trường dev (`http://127.0.0.1:8000`) sang chạy 24/7 ổn định ngoài Internet.

## 1. Hai thành phần cần vận hành 24/7 độc lập

| Thành phần | Yêu cầu thực tế 24/7 | Phương án tối ưu | Ghi chú chi phí & độ ổn định |
| --- | --- | --- | --- |
| Backend FastAPI (`/v1`) | Không sleep 40s, HTTPS SSL tự động, healthcheck `/v1/health`, tắt `LOCAL_DEV_BEARER_UID_FALLBACK` | [render.yaml](../../render.yaml) (Render `starter`, region `singapore`) hoặc VPS SG/VN + Docker Compose | Gói Render Free ngủ sau ~15 phút; chạy người dùng thật ổn định 24/7 dùng `starter` (\$7/tháng) hoặc VPS ~120k/tháng để tránh cold start |
| PostgreSQL 16 | Không tự pause sau 7 ngày, hỗ trợ pool kết nối và migration `alembic upgrade head` tới `0008_add_daily_reports` | Neon PostgreSQL (serverless wake < 300ms) hoặc PostgreSQL Docker có backup hàng ngày trên VPS | Miễn phí ở Neon tới 1 GB nếu chưa muốn thuê DB riêng |
| Kênh tải APK (Tester nhóm 10–100 người) | Quản lý version, email mời tự động | **Firebase App Distribution** qua [distribute_apk_firebase.ps1](../../scripts/distribute_apk_firebase.ps1) & workflow `.github/workflows/firebase-app-distribution.yml` | Miễn phí, gắn sẵn `projectId: mindclock`, `appId: 1:357973416738:android:5e09df39793b206a05a37b` |
| Kênh tải APK công khai (người dùng tự do 24/7) | Link cố định tốc độ cao, không giới hạn băng thông | **GitHub Releases** (`releases/latest/download/mindclock-android.apk`) hoặc **Cloudflare R2** | Miễn phí, không nghẽn như Google Drive; phát hành rộng nên qua Google Play Console |

## 2. Quy trình bắt buộc trước khi gửi APK ra ngoài

1. **Ký APK bằng Release Keystore cố định:** Trong [build.gradle.kts](../../app/android/app/build.gradle.kts) hiện `release` đang tạm dùng debug signing cho local dev. Trước khi gửi cho tester cài lâu dài, tạo `upload-keystore.jks` (giữ bí mật ngoài Git) và khai báo `key.properties` để các bản cập nhật sau cài đè không bị lỗi `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
2. **Trỏ URL backend HTTPS thật khi build:**
   ```powershell
   flutter build apk --release --dart-define=MINDCLOCK_API_BASE_URL=https://api.mindclock.example.com
   ```
   Không dùng `127.0.0.1:8000` cho máy người dùng thật.
3. **Chạy migration DB trước khi mở traffic:**
   ```bash
   cd services/api && python -m alembic upgrade head
   ```
4. **Kiểm tra sau triển khai:** Xác nhận `GET https://<domain>/v1/health` trả `{"status":"ok","dbReady":true,"dbDialect":"postgresql"}`, tạo tài khoản, sửa Hồ sơ (`/v1/me`), đặt chuông báo thức (chạy local độc lập mạng) và nộp Báo cáo ngày (`POST /v1/progress/daily-report`).

## 3. Liên kết tài liệu vận hành

- [Quy trình phát hành & kiểm thử](02-van-hanh-phat-hanh.md)
- [Hợp đồng API `/v1`](../02-engineering/04-hop-dong-api.md)
