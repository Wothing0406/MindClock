# Handoff

- **Trạng thái:** `done`.
- **Đã làm:** primary pet server-authoritative; pet card Hôm nay; preview riêng tư; PNG 1080; Kotlin MethodChannel/FileProvider; widget/API/PostgreSQL test; APK + ảnh/video emulator.
- **Bằng chứng:** `docs/03-quality/evidence/T075/t075_pet_dashboard_emulator.png`, `t075_pet_share_preview_emulator.png`, `t075_exported_share_1080.png`, `t075_android_share_sheet.png`, `t075_pet_share_walkthrough.mp4`.
- **Môi trường:** Android emulator API 37 (`emulator-5554`), 1080×2400 display 0; video H.264 720×1600. Chưa chạy máy Android thật.
- **Test:** Flutter 8/8; analyzer 0 lỗi; backend SQLite/PostgreSQL 6/6; APK debug build thành công ngày 21/11/2026.
- **Rủi ro còn lại:** art pet là asset research theo registry hiện hành; máy thật/share target OEM và TalkBack cần cổng release riêng. Chat `@MindClock` không thuộc T075.
- **Điểm tiếp tục:** mở T076 riêng cho QR có thời hạn, phòng chờ/duyệt và lịch hẹn; sau đó mới T077 chat `@MindClock`.
- **Git:** nhánh `main`; commit nguồn T075 `9b80d89b9283597621d87c8de2110ef7e334b9a6`; đã push và xác minh `origin/main` trùng SHA ngày 21/11/2026.
