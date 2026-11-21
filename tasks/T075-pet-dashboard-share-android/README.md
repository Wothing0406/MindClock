# T075 — Pet trên Hôm nay, chia sẻ và bằng chứng Android

- **Trạng thái:** `verifying`
- **Mục tiêu:** đưa pet nhóm server lên màn Hôm nay, chọn pet chính, xuất thẻ PNG và mở Android share sheet; thay golden Ahem bằng ảnh/video emulator có font thật.
- **Nguồn yêu cầu:** yêu cầu người dùng 21/11/2026 về pet từ thử thách sáng, nhiều pet/nhóm, giao diện chính, ảnh/video test.
- **Chủ sở hữu/reviewer:** đội MindClock / Flutter + Android + backend reviewer.
- **Phạm vi file dự kiến:** migration/API membership primary; Flutter dashboard/share gateway/card; Kotlin MethodChannel/FileProvider; test/evidence/docs.
- **Liên quan:** T074 đã hoàn thành group/pet ledger; T076 phòng chờ/QR; T077 chat `@MindClock`.
- **Source refs đã đọc:** `AGENTS.md`, `docs/01-product/14-pet-nhom-va-the-chia-se.md`, `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`, design/testing/Android skill, T074 handoff, code TodayScreen/MainActivity.
- **Điểm tiếp tục:** chạy kiểm docs/task record, rà staged file/secret rồi commit và push đúng lát T075.

## Cổng trước coding

- [x] Đọc docs/skill và code liên quan.
- [x] Xác nhận ảnh khối vuông là Flutter Ahem, không phải font product.
- [x] Tách chat/media khỏi task này.

## Cổng kết thúc

- [x] AC/test đạt; PostgreSQL/Flutter/Android bridge sạch.
- [x] Ảnh PNG và video MP4 từ emulator có font thật, ghi rõ môi trường.
- [ ] Chỉ file T075 được commit/push và remote SHA được ghi.
