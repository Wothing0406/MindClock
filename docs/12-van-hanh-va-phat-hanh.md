# Môi trường coding, vận hành và phát hành

> **Cập nhật CSDL 11/11/2026:** các bước Firebase Emulator/Firestore dưới đây thuộc kế hoạch cũ. Với backend SQL, dùng SQLite local cho demo và PostgreSQL cho tích hợp/pilot theo [docs/28](28-backend-sql.md); Firebase Authentication có thể tiếp tục dùng. Cập nhật lệnh chạy thật khi tạo code.

Tài liệu này là **kế hoạch triển khai**, chưa có hạ tầng hay mã nguồn tương ứng. Chủ sở hữu vận hành cần xác nhận ngân sách, tài khoản Google/Firebase và chính sách dữ liệu trước khi tạo production.

## 1. Cấu trúc repo dự kiến

```text
MindClock/
  AGENTS.md
  docs/                 # PRD, UX, kiến trúc, API, test, ADR
  apps/mobile/          # Flutter + Android native alarm bridge
  services/api/         # FastAPI + Gemini adapter + Firestore repository
  content/questions/    # Bộ câu có revision và nguồn sử dụng
  evals/                # Bộ đánh giá AI ẩn danh, quyền sử dụng rõ
  tests/                # Contract, integration, rules, end-to-end
  infra/                # Cấu hình Cloud Run/Firebase/CI, không chứa secret
```

Không tạo tất cả thư mục trống chỉ để giống sơ đồ. Tạo khi task đầu tiên thật sự dùng và cập nhật README chạy local.

## 2. Môi trường

| Môi trường | Mục đích | Dữ liệu |
| --- | --- | --- |
| `local` | Coding và test hằng ngày | Firebase Emulator, Gemini mock, ảnh thử có quyền |
| `staging` | Test tích hợp và thiết bị | Firebase project riêng, Gemini key giới hạn, tài khoản thử |
| `production` | Pilot/phát hành sau khi qua cổng chất lượng | Firebase project/key riêng, quy trình backup, monitoring |

Mỗi môi trường có `FIREBASE_PROJECT_ID`, `GOOGLE_CLOUD_PROJECT`, `GEMINI_API_KEY` (backend/Secret Manager), cấu hình model, timeout, giới hạn upload/rate, `APP_ENV`. Mobile chỉ có cấu hình Firebase client hợp lệ, URL API và feature flags công khai; **không** có Gemini key hoặc service account. Tên biến cụ thể có thể điều chỉnh khi code, nhưng phải có `.env.example` không chứa giá trị thật.

## 3. Quy trình local cho người mới

1. Cài Flutter/Android SDK và Python theo phiên bản được pin trong repo khi bắt đầu code.
2. Khởi chạy Firebase Emulator và API với Gemini mock. Đăng nhập tài khoản thử; nhập bộ câu demo có revision.
3. Chạy unit/contract/rules tests; mở app bằng Android emulator để kiểm tra UI.
4. Dùng một thiết bị Android thật để kiểm tra báo thức màn khóa và quyền hệ điều hành; ghi mẫu máy/OS/kết quả vào test report.
5. Chỉ bật Gemini thật ở staging với key riêng, hạn mức và ảnh có quyền sử dụng. Không dùng ảnh học sinh thật trong local/dev tùy tiện.

README code sau này phải liệt kê **lệnh chính xác**, yêu cầu phiên bản, cách seed dữ liệu, cách chạy mock và cách chạy tests. Tài liệu hiện chưa bịa lệnh khi code chưa tồn tại.

## 4. CI và cổng merge

Mọi thay đổi chạy format/lint, unit tests, API contract tests, Firebase rules emulator tests và kiểm tra không lộ secret. Task chạm báo thức cần checklist thiết bị thật; task chạm AI cần chạy bộ đánh giá cố định và báo khác biệt đúng/sai/uncertain; task chạm XP cần test transaction/idempotency. Không chạy test gọi Gemini thật cho mọi PR vì vừa tốn chi phí vừa không ổn định; dùng mock cho CI và lịch đánh giá riêng ở staging.

## 5. Phát hành staging và pilot

1. Review thay đổi schema/index/rules và khả năng rollback.
2. Deploy API staging, seed question bank đúng revision, chạy smoke test auth/challenge/session/attempt.
3. Cài bản Android staging trên ma trận thiết bị, thử báo thức offline, màn khóa, reboot và quyền bị từ chối.
4. Chạy AI evaluation trên ảnh có quyền, xem confusion matrix và latency/chi phí.
5. Kiểm tra xóa dữ liệu, log không PII, consent và tài liệu hỗ trợ.
6. Chỉ sau đó phát hành pilot giới hạn; theo dõi lỗi và có người nhận phản hồi.

**Rollback:** giữ revision API và bộ câu trước đó, có feature flag tắt chấm AI/ẩn tính năng mới, không hủy báo thức local khi backend rollback. Migration dữ liệu phải tương thích ngược ít nhất trong cửa sổ phát hành; nếu không, cần kế hoạch chuyển đổi và kiểm tra phục hồi.

## 6. Theo dõi vận hành

Dashboard kỹ thuật: tỷ lệ request lỗi, p50/p95 latency chấm, tỷ lệ `uncertain`, chi phí AI/ngày, số phiên/attempt/XP duplicate bị chặn, số người báo chấm sai, trạng thái xóa dữ liệu. Chỉ thu event tối thiểu không chứa ảnh, tên, nội dung bài làm, token hoặc giờ ngủ chi tiết. Báo thức local có thể cần telemetry opt-in vì liên quan giờ dậy; không xem “không có log” là bằng chứng chuông đã reo.

## 7. Xử lý sự cố

| Sự cố | Hành động ngay | Sau đó |
| --- | --- | --- |
| Gemini lỗi/chi phí tăng đột biến | Tắt chấm AI bằng feature flag; app vẫn cho tắt báo thức và hoàn thành không chấm | Xem latency, hạn mức, prompt, chi phí; thông báo rõ cho pilot |
| API/Firestore lỗi | Giữ báo thức local, xếp sự kiện sync; không tự chấm/điểm giả | Khôi phục dịch vụ, replay idempotent, đối soát ledger |
| Báo thức không reo trên nhóm máy | Tạm ngừng quảng bá hỗ trợ nhóm máy đó, hướng dẫn người thử dùng báo thức hệ thống | Tái hiện trên thiết bị, sửa quyền/lập lịch, test lại |
| Nghi lộ dữ liệu/secret | Thu hồi key/quyền, dừng đường upload liên quan, bảo toàn bằng chứng kỹ thuật tối thiểu | Điều tra phạm vi, sửa rules, thông báo theo nghĩa vụ áp dụng |
| Câu hỏi/đáp án sai | `retired` revision, ngừng chọn, gỡ khỏi cache khi sync | Rà soát phiên bị ảnh hưởng và điều chỉnh XP nếu cần |

## 8. Quyền trẻ em và phát hành cửa hàng

Trước pilot với học sinh chưa thành niên, xác định độ tuổi, căn cứ đồng ý, người được quyền xem dữ liệu, thời hạn lưu, cách xóa/rút đồng ý và chính sách cửa hàng ở thị trường phát hành. Các yêu cầu pháp lý/cửa hàng có thể thay đổi, nên cần kiểm tra nguồn chính thức tại thời điểm nộp app. Không coi tài liệu này là sự xác nhận đã tuân thủ pháp luật.

