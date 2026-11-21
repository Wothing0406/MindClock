# Worklog

## 21/11/2026

- Xác nhận screenshot khối vuông là font Ahem của Flutter test. Golden chỉ giữ vai trò layout regression; không dùng làm ảnh product.
- Mở T075 riêng, không trộn chat/media/game.
- Thêm migration `0006`, endpoint primary, fallback khi rời/xóa và partial unique index PostgreSQL.
- Lần test PostgreSQL đầu phát hiện `UniqueViolation`: ORM đổi hai cờ primary trong cùng batch. Sửa thành hạ primary cũ → flush → nâng primary mới trong cùng transaction; chạy lại đạt.
- Tách exporter PNG khỏi dialog để code có trách nhiệm rõ; widget test không dùng Ahem làm ảnh trình bày.
- Build APK debug và mở chính `TodayPetCard` trên emulator. Lần chụp đầu gặp System UI ANR nên bị loại; chuyển app về display 0 và chụp lại sạch.
- Xác minh file share thật 1080×1080, Android share sheet và video walkthrough. Không coi emulator là máy thật.
