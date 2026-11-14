# Đặc tả nhiệm vụ T012 — Chốt ngôn từ, thiết kế và quy chuẩn icon frontend

## Vấn đề và kết quả mong muốn

Qua kiểm kê `T011` (`docs/54 §5`), tài liệu thiết kế và ngôn từ đang rải rác ở `docs/05, 13, 27, 30, 31, 45, 46, 52, 53` và còn vài điểm lệch tên nút (`Mở câu hỏi` vs `Bắt đầu`, `Dừng khẩn cấp` vs `Tắt khẩn cấp` / `Tắt chuông`, `Chụp nháp` vs `Chụp bài`), tham chiếu cũ (`docs/13` trỏ `docs/37`), thông số demo HTML (`+15 XP mẫu`, `44 px`, in hoa toàn bộ), và chưa chốt bộ icon vector duy nhất để coder Flutter dùng ngay.

Sau task này, đội có tài liệu chuẩn [docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md](../../docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md) làm bảng tra duy nhất cho chuỗi tiếng Việt (`AppStrings`), từ cấm, thuật ngữ tách bạch, design tokens, và danh mục icon + `semanticLabel` cho từng màn P0/P1/M3.

## Phạm vi

- **Trong phạm vi:** chốt ngôn từ UI (`vi-VN`), bộ chuỗi theo màn, từ cấm, token màu/chữ/spacing/bo góc/motion, quy chuẩn icon + phương án bộ icon Flutter có licence mở, và đồng bộ tham chiếu trong `docs/13`, `docs/54`, `docs/README.md`.
- **Ngoài phạm vi:** chưa viết code Flutter/Dart/Kotlin, chưa sửa `demo/index.html`, chưa tự tải package font/icon bên ngoài.
- **Dữ liệu/role/quyền liên quan:** tách bạch thuật ngữ hiển thị cho khách local vs tài khoản online vs Đấu trường (cohort-gated).
- **Tài liệu chuẩn:** `docs/05, 13, 23, 27, 30, 31, 32, 39, 45, 46, 51, 52, 53, 54`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi tài liệu phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi chốt ngôn từ cho các nút và thông báo dễ mâu thuẫn | Chọn đúng 1 nhãn chuẩn cho mỗi hành động (`Mở câu hỏi`, `Dừng khẩn cấp`, `Hoãn 5 phút`, `Chụp nháp`, `Gửi bài`, `Hoàn thành không chấm`) và ghi rõ không dùng lại nhãn cũ trong app Flutter | TC-01 |
| AC-02 | Khi quy định giọng nói và nội dung `vi-VN` | Liệt kê đầy đủ quy tắc viết, bảng từ/cụm cấm dùng, tách bạch `XP / Hạng học tập / RP / Khung / Huy hiệu / Uy tín` và bảng chuỗi cho mọi trạng thái (`loading/empty/offline/permission/uncertain/error`) | TC-02 |
| AC-03 | Khi tổng hợp chuẩn thiết kế & icon | Gom đủ token màu, typography, spacing, bo góc, motion, vùng chạm `≥48×48 dp`, danh sách icon 24 dp stroke 2 px theo từng màn kèm `semanticLabel`, cấm emoji và đưa ra lựa chọn thư viện icon có licence rõ | TC-03 |
| AC-04 | Khi đồng bộ tài liệu liên quan | Cập nhật `docs/13` (bỏ tham chiếu nhân vật `docs/37`, đồng bộ `Dừng khẩn cấp`), ghi chú đã chốt tại `docs/54` và thêm mục vào `docs/README.md`; chạy `check_docs_links.py`, `check_task_records.py`, `git diff --check` exit 0 | TC-04 |

## Hợp đồng và trường hợp biên

Không thay đổi API `/v1` hay SQL schema. Trường hợp biên ngôn từ: màn hình hẹp `320 dp` và cỡ chữ `200%` không được làm cắt nhãn nút `Dừng khẩn cấp` hoặc nhãn 4 tab; chế độ thử thách không hiện `Hoãn 5 phút`; offline không hiển thị kết luận `Đúng` cho bài tự do.

## Quyết định/mâu thuẫn

Chốt trực tiếp trong `docs/55`:
1. Nút reo chính: `Mở câu hỏi`; nút an toàn: `Dừng khẩn cấp` (chuẩn hóa thay `Tắt khẩn cấp` ở `docs/13`).
2. Nút chọn đường chụp trên `S08`: `Chụp nháp`; tiêu đề luồng hướng dẫn `S09`: `Chụp bài làm`; nút chụp lại/nộp: `Chụp lại` · `Gửi bài`.
3. Vùng chạm Flutter: `≥48×48 dp` (bỏ mức `44 px` của web demo).
4. XP hiển thị chỉ dùng thang chuẩn `docs/04` (`+10/+6/+2`), bỏ `+15 XP mẫu` và `160/250 XP` của `demo/index.html`.
5. Bộ icon: đề xuất `Lucide` (ISC, 24×24, stroke 2, bo tròn) làm phương án chính hoặc `Material Symbols Rounded` (Apache-2.0) làm phương án dự phòng — chốt 1 bộ duy nhất trước khi `pubspec.yaml` thêm dependency.
