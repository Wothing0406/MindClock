# Hồ sơ trình bày GDG DevFest — MindClock

> Tài liệu này phục vụ trình bày & demo **GDG DevFest**, tách biệt hoàn toàn khỏi đặc tả sản phẩm dài hạn tại [`docs/README.md`](../README.md). Mọi số liệu, endpoint, file nguồn và kết quả test bên dưới đều đối chiếu trực tiếp từ mã nguồn và nhật ký kiểm thử ngày `21/11/2026`; **không** bịa khảo sát người dùng hoặc số liệu triển khai production.

---

## 1. Vấn đề và nhu cầu người học

- Học sinh THPT (lớp 10–12 theo Chương trình GDPT 2018) thường tắt báo thức theo phản xạ rồi ngủ lại, hoặc thiếu nhịp ôn tập kiến thức cốt lõi ngắn vào buổi sáng.
- Các ứng dụng báo thức đại trà tập trung vào rung/chuông hoặc tác vụ vật lý rời rạc (chụp ảnh/lắc máy), chưa gắn kết trực tiếp với môn học THPT, thời khóa biểu cá nhân và không gian học tập.
- Thực trạng tại Việt Nam đòi hỏi báo thức phải **chạy cục bộ độc lập** (khi mất mạng, máy khóa màn hình, hoặc token hết hạn), dữ liệu học tập minh bạch (học sinh giữ quyền chủ động xác nhận lộ trình AI, mặc định không lưu ảnh bài viết, có đường nhập chữ thay camera).

## 2. Giải pháp đề xuất — MindClock

MindClock là ứng dụng Android-first phát triển bằng **Flutter + Kotlin native** kết nối backend **FastAPI + PostgreSQL 16**, kết hợp 4 trụ cột trong một shell thống nhất:
1. **Báo thức kỷ luật offline-first:** Mode thường (có Hoãn) và Mode thử thách (không Hoãn, luôn giữ nút **Dừng khẩn cấp** một chạm ở mức OS/Kotlin).
2. **Thử thách ôn tập buổi sáng & Luyện tập theo môn:** Câu hỏi theo danh mục Bộ GD&ĐT (`gdpt-2018-v1`), 3 trạng thái chấm (`correct`, `incorrect`, `uncertain` — `uncertain` không tính sai), gợi ý từ lần sai rõ thứ 3 và nút bỏ lượt từ lần thứ 5.
3. **Lập kế hoạch & Không gian học tập trung:** Quét ảnh thời khóa biểu (OCR Vision), việc cần làm trong ngày, chế độ Đốt nến đếm giờ tập trung, trợ giảng AI 2D (gắn nhãn AI) và nhóm cam kết riêng tư (`≤ 4` thành viên).
4. **Đấu trường học tập (Opt-in):** 3 tướng gốc Võ đường (`Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bối Pháp`) chạy bằng sprite animation từ `assets/game/`, Sảnh chờ, Bảng xếp hạng kiến thức opt-in và Daily Shop thuần thẩm mỹ (không pay-to-win).

## 3. Kiến trúc hệ thống

- **Client Android (`app/`):** Flutter UI phân tầng (`ui/features/*`, `domain/*`, `data/*`), theme tập trung tại `MindClockTheme` (`0` raw hex color trong màn chính), liên kết Kotlin native (`app/android/.../MainActivity.kt`, `AlarmReceiver`, `AlarmRingActivity`, `EmergencyStop`) qua `MethodChannel`.
- **Backend API (`services/api/`):** FastAPI + SQLAlchemy 2 + Alembic (`0001` → `0007`), hỗ trợ PostgreSQL 16 (Docker `postgres:16-alpine` trong dev/production) và SQLite parity cho unit test; tích hợp Redis/rate-limit, idempotency key và xác thực JWT kép (PostgreSQL local auth HS256 `scrypt` + Firebase ID Token RS256 JWKS).
- **Lưu trữ cục bộ & offline (`app/lib/data/`):** Báo thức, draft văn bản offline và 37 câu hỏi ôn tập dự phòng nằm cục bộ trên máy; mọi hành động AI, đồng bộ TKB, nhóm cam kết và trận đấu chốt trạng thái tại PostgreSQL backend.

## 4. Tích hợp công nghệ Google

- **Flutter & Dart:** Một codebase UI/state chính cho Android (`app/`), responsive `320dp` ở tỷ lệ chữ `200%`.
- **Android Platform APIs:** `AlarmManager` (`setAlarmClock` / exact alarm), `FullScreenIntent`, Notification channels, `MethodChannel` có versioning, Speech-to-Text intent (nhập nháp có xác nhận người dùng) và Android TTS.
- **Gemini API & Firebase Auth gateway:**
  - `services/api` tích hợp Gemini (`gemini-3.1-flash-lite` cho đọc/chấm/gợi ý & OCR TKB; `gemini-3-flash-preview` xử lý nhanh; `gemini-3.1-flash-live-preview` định hướng Live/TTS WAV có consent).
  - `FirebaseAuthGateway` hỗ trợ Firebase Authentication REST API và tự động fallback sang PostgreSQL `/v1/auth/*` khi dự án chưa bật Email/Password trên Firebase Console (`OPERATION_NOT_ALLOWED`).

## 5. Tích hợp AI & Giới hạn kiểm soát an toàn

- **Nguyên tắc AI hỗ trợ, không độc quyền quyết định:** Bản nháp kế hoạch học, kết quả OCR TKB hay gợi ý đáp án từ Gemini đều phải đi qua kiểm định rubric phía backend và quyền xác nhận của học sinh.
- **Chống phạt oan & giới hạn AI:** Khi ảnh mờ hoặc model trả kết quả thiếu chắc chắn (`uncertain`), điểm sai và chuỗi ngày học không bị trừ; khi mất mạng hoặc AI lỗi/timeout, app tự rơi về ngân hàng câu hỏi cục bộ và kế hoạch rule-based (`rule-plan-v0.1`).
- **Quyền riêng tư:** API key Gemini không bao giờ gửi xuống client; mặc định không lưu ảnh chụp bài làm; `DELETE /v1/me` xóa cascade dữ liệu người dùng (bao gồm `local_auth_accounts`).

## 6. Trải nghiệm người dùng (UX)

- **Welcome & Auth minh bạch:** Giải thích quyền hệ thống đúng ngữ cảnh, yêu cầu mật khẩu mạnh (`≥ 8` ký tự, hoa/thường/số/ký tự đặc biệt) và 2 checkbox xác nhận Chính sách bảo mật `v2026-11` + nhóm tuổi THPT; giữ nút **Chỉ dùng báo thức khi mất mạng** để không khóa báo thức cục bộ.
- **Dashboard Hub `Hôm nay`:** Mở ngay đồng hồ thời gian thực ở đầu màn cùng **Danh mục 6 tính năng MVP** (`Báo thức`, `Luyện tập`, `Không gian học`, `TKB & Việc ngày`, `Đấu trường`, `Nhóm & Hồ sơ`) cho điều hướng 1 chạm, tách thẻ `Mầm Xanh` xuống khu Cộng đồng/Động lực bên dưới.
- **Tiếp cận (Accessibility):** Ngôn ngữ `vi-VN` tự nhiên theo Chương trình GDPT 2018, hỗ trợ chữ lớn 200%, độ tương phản chuẩn, có đường nhập văn bản thay camera/mic.

## 7. Hiện trạng triển khai thực tế trong repo

- **Đã chạy & xác minh trong môi trường phát triển (`21/11/2026`):**
  - **Backend PostgreSQL 16 + FastAPI (`services/api`):** Toàn bộ migration `0001` → `0007_local_auth_accounts`; endpoints `/v1/auth/{register,login,refresh}`, `/v1/me`, `/v1/timetable*`, `/v1/alarms*`, `/v1/sessions*`, `/v1/rooms*`, `/v1/commitment-groups*`, `/v1/pvp*`, `/v1/health`.
  - **Flutter Android APK chính thức (`dist/mindclock-debug.apk`, build từ `app/lib/main.dart`):** Chạy trọn vẹn trên `emulator-5554` (API 37) nối trực tiếp Docker PostgreSQL 16 (`10.0.2.2:8000`): Đăng ký thật (`e2ehs76@mindclock.vn` / `MinhKhang12A`) → ghi DB `local_auth_accounts` & `users` → Onboarding Lớp 12 + avatar `Hà Nhân` → vào full Dashboard Hub `Hôm nay` & `Đấu trường` 3 tướng gốc.
  - **Đấu trường (`T064`/`T065`):** 204 runtime asset trong `app/assets/game/`, 3 tướng animated, Sảnh đấu, BXH kiến thức, Daily Shop, ký hiệu toán học/hóa học không nuốt đơn vị.
- **Tài liệu hiện trạng chi tiết:** Xem [`docs/00-start/01-hien-trang.md`](../00-start/01-hien-trang.md).

## 8. Thách thức kỹ thuật đã xử lý

1. **Tính chính xác giữa ORM và Migration trên PostgreSQL 16:** Đồng bộ partial unique index `uq_commitment_primary_per_user` giữa SQLAlchemy `Base.metadata` và Alembic (`0006`) trên cả PostgreSQL và SQLite.
2. **Firebase Auth REST error shape vs Fallback PostgreSQL:** Xử lý khác biệt kiểu JSON `error.code` (`400` kiểu `int` từ Identity Toolkit so với `String` code từ backend) để cơ chế fallback `/v1/auth/*` không bị `TypeError` trên APK thật.
3. **Ranh giới báo thức OS Android:** Đảm bảo báo thức cục bộ và nút Dừng khẩn cấp không bị chặn bởi vòng đời auth hay mạng, tránh mọi cơ chế khóa máy trái phép.
4. **Cạnh tranh slot phòng học:** Khóa transaction ở PostgreSQL khi `join`/`leave` phòng học giới hạn 2–8 thành viên và giữ idempotency khi client retry.

## 9. Kịch bản demo đề xuất (DevFest)

1. **Khởi động & Đăng ký tài khoản thật (`Welcome → Auth → PG16`):** Tạo tài khoản THPT mật khẩu mạnh + đồng ý chính sách `v2026-11`, xác nhận ghi bản ghi mới vào `users` & `local_auth_accounts` trong Docker PostgreSQL 16.
2. **Khởi tạo lộ trình (`Onboarding`):** Chọn Lớp 12, môn theo Chương trình GDPT 2018, avatar gốc (`Hà Nhân`), xem bản kế hoạch nháp và xác nhận vào Dashboard.
3. **Dashboard Command Center (`Hôm nay`):** Quan sát đồng hồ thời gian thực và 6 ô **Danh mục tính năng**, mở **Luyện tập / Không gian học (Đốt nến)** / **TKB OCR**.
4. **Đấu trường Võ đường (`Đấu trường`):** Xem animation 3 tướng gốc (`Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bối Pháp`), chế độ Luyện đơn và Daily Shop / Bảng xếp hạng opt-in.

## 10. Kiểm thử và kết quả đo được (`21/11/2026`)

| Thành phần | Lệnh / Kịch bản | Kết quả thực tế |
| ---------- | --------------- | --------------- |
| Backend FastAPI + PostgreSQL 16 + SQLite | `.venv\Scripts\python.exe -m pytest -q` (biến môi trường `APP_ENV=test`, `postgres:16-alpine`) | **96 passed**, 0 failed, 1 warning (starlette `BlockingPortal` deprecation) |
| Phân tích tĩnh Flutter | `flutter analyze --no-pub` | **No issues found** (`TODAY_RAW_HEX_HITS=0`) |
| Bộ test unit & widget Flutter | `flutter test --no-pub -j 1` | **162/162 passed** (bao gồm `T047`–`T076`, `T064`, `T065`) |
| Android Kotlin native unit test | Gradle `:app:testDebugUnitTest` | **12/12 passed** |
| E2E Emulator API 37 + Docker PG16 | Build `dist/mindclock-debug.apk` (`163.20 MB`), cài lên `emulator-5554`, đăng ký `e2ehs76@mindclock.vn` → Onboarding → Dashboard → Đấu trường | HTTP `POST /v1/auth/register`, `POST /v1/me/consent`, `PATCH /v1/me`, `PUT /v1/timetable` đều `200 OK`; DB có row mới; ảnh chụp tại `test_demo_android/screenshots/` |
| Kiểm tra docs & game assets | `check_docs_links.py`, `check_task_records.py`, `check_game_assets.py` | **PASS** |

*Giới hạn kiểm thử đã ghi nhận:* Chưa hoàn tất kiểm thử **2 máy Android vật lý** cho chuông qua Doze/reboot/lock-screen (R1), chưa đo benchmark độ chính xác AI trên tập đề độc lập (R4), và chưa mở **PvP Ranked / 2v2 nhiều máy thật** (R8).

## 11. Lộ trình tiếp theo

- **Ngắn hạn (R1–R2):** Kiểm thử báo thức & voice/TTS thực tế trên **2 thiết bị Android vật lý** (API 29–35); bổ sung đồng bộ sự kiện/lịch hẹn đa thiết bị.
- **Trung hạn (R4–R6):** Chạy bộ đánh giá định lượng Gemini OCR/chấm bài sáng + tối ưu quota/cost; hoàn thiện Live voice full-duplex & moderation phòng học có consent.
- **Dài hạn (R7–R9):** Mở PvP 1v1 thời gian thực hai máy ổn định, kiểm định cân bằng tướng và bản quyền asset trước khi mở chế độ Ranked hoặc nhánh iOS.

## 12. Định hướng phát triển tương lai

- Mở rộng ngân hàng câu hỏi và hướng dẫn chấm (rubric) do tổ bộ môn/cộng tác viên thẩm định cho đầy đủ tổ hợp THPT.
- Đồng bộ đa nền tảng (mở nhánh iOS AlarmKit/Activity sau khi Android đạt tiêu chí phát hành ổn định R9).
- Nâng cấp trợ giảng AI giọng nói song công độ trễ thấp kèm cơ chế tắt an toàn khi rời phòng hoặc mất kết nối.
