# Runbook môi trường phát triển và kiểm trên thiết bị

**Mục tiêu:** thành viên mới có thể kiểm mã hiện có, không phải mở web để giả app. Các lệnh dưới đây cần môi trường cài đúng và kết quả phải ghi vào task; chưa được coi là đã pass trên máy này. [Repo](../00-start/04-cau-truc-repo.md), [release](02-van-hanh-phat-hanh.md).

## 1. Công cụ theo vai

| Vai | Cần | Không cần cho P0 |
| --- | --- | --- |
| Flutter/Android | Git, Flutter SDK, Android SDK/Platform Tools, Android Studio hoặc editor, Android thật + cáp/ADB, JDK phù hợp Gradle project | Mac/Xcode/iOS simulator. |
| Backend | Python 3.11+, venv, Docker Desktop hoặc PostgreSQL local, editor, công cụ xem log/DB | Android Studio nếu chỉ API. |
| Content/QA | Bản build nội bộ, Android thật, bảng câu/rubric có quyền, tài khoản test, mẫu test không có ảnh học sinh thật | Quyền production key. |

Không cài tool bằng cách đoán version. Kiểm `flutter doctor -v`, `flutter devices`, `adb devices`, Python/Java/Docker version và ghi vào task B01. Windows Application Control có thể chặn Dart runtime; nếu xảy ra, dùng máy/CI được phép chạy và ghi lỗi, không đổi sang web mock.

## 2. Flutter Android

```powershell
cd app
Copy-Item .env.example .env
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env
```

`app/.env` gitignored. `MINDCLOCK_API_BASE_URL` phải là URL máy Android có thể tới: emulator thường dùng `10.0.2.2`; thiết bị thật có thể dùng `adb reverse` rồi `127.0.0.1` hoặc IP LAN; HTTPS bắt buộc khi staging/production. `MINDCLOCK_DEBUG_FIXTURE=false` khi kiểm tích hợp thật. Chỉ đặt Firebase Web API key cần cho Auth trong client; **Gemini key chỉ backend**. Nếu chưa có Firebase test project, ghi phần Auth chưa kiểm và chỉ dùng guest/local.

Mỗi lần đổi native alarm/Manifest, chạy AD01–AD07 trên Android thật; `flutter test` không thay thế. APK debug chỉ dùng nội bộ, không gọi release ký. Ghi build hash, model/API level/OEM/quyền và giờ chuông thực tế. Trong T030 (B01b), `flutter analyze` đạt `No issues found!`, `gradlew.bat testDebugUnitTest` đạt 6/6 ca Kotlin và `:app:assembleDebug` xuất thành công `app/build/app/outputs/flutter-apk/app-debug.apk` với `JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"`; riêng `flutter_tester.exe` bị Windows Application Control chặn trên máy host nên chạy qua `.github/workflows/ci.yml`.

## 3. FastAPI local và PostgreSQL

```powershell
cd services/api
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

`.env.example` mặc định SQLite local; **chỉ phục vụ phát triển**. Trước test PostgreSQL, đặt password dev riêng trong `.env`, chạy `docker compose up -d --build` từ `services/api/` (compose có `postgres` + `api`; Dockerfile chạy `alembic upgrade head` trước `uvicorn`), rồi kiểm `GET /v1/health` trả `dbDialect=postgresql`. Không dùng password mẫu cho staging/production. Docker cần engine đang chạy; nếu không, ghi điều kiện thiếu. Tắt `LOCAL_DEV_BEARER_UID_FALLBACK` và `GEMINI_MOCK_MODE` theo policy của môi trường test thực; **không dùng token `dev:*` để chứng minh production auth**. Model ID/chi phí/quota trong `.env.example` phải được kiểm với tài liệu nhà cung cấp trước live.

Trong phiên T024, `pytest --collect-only` thấy 14 ca nhưng runtime bị treo ở ca health; T029 (B01a) đã tắt `PRAGMA journal_mode=WAL` trên SQLite test/in-memory, đặt `busy_timeout=5000`, khóa `/demo` và `/product` khi `app_env=production`, và xác nhận `15 passed` trên Windows Python 3.11. Không chạy AI live bằng ảnh học sinh thật khi chưa có consent/chính sách phù hợp.

## 4. Cách ghi một ca máy thật

```text
TC: AD05 Dừng khẩn cấp khi đang chấm
Build/commit: ...
Device/OEM/API level: ...
Quyền OS, mạng, pin: ...
Giờ dự kiến / thực tế: ...
Thao tác: ...
Kết quả âm/rung/UI: pass | fail | chưa chạy
Log/video (không dữ liệu cá nhân): ...
Nguyên nhân/điểm tiếp tục nếu fail: ...
```

## 5. Trước khi gửi bản cho tester

Đảm bảo tài khoản test/consent, seed câu đội tự viết đã duyệt, không có secret trong repo/APK/log, URL server truy cập được, báo thức test không ảnh hưởng giờ ngủ thật, Dừng khẩn cấp đã qua máy thật, policy quyền trẻ em được review. Nếu một điều kiện thiếu, ghi rõ bản là **build nội bộ để kiểm riêng một luồng**, không giới thiệu như sản phẩm đã sẵn sàng.
