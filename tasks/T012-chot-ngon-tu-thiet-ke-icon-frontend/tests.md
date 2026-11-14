# Kế hoạch và kết quả kiểm thử T012

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Kiểm tra bảng chốt nhãn mâu thuẫn trong `docs/55` đối chiếu `docs/04, 05, 13, 27, 30, 31` | Chỉ còn 1 nhãn chuẩn cho mỗi nút (`Mở câu hỏi`, `Dừng khẩn cấp`, `Hoãn 5 phút`, `Chụp nháp`, `Gửi bài`, `Hoàn thành không chấm`) | Rà tài liệu trực tiếp | **PASS tài liệu (14/11/2026):** 9 điểm mâu thuẫn nhãn/scale/XP đã chốt trong `docs/55 §1` |
| TC-02 | AC-02 | Kiểm tra bảng từ cấm, tách thuật ngữ và chuỗi theo màn/trạng thái | Có đủ từ cấm, phân biệt XP/Hạng học tập/RP/Khung/Badge/Uy tín, đủ chuỗi trạng thái `S01–S12`, `F01–F04`, `D01–D05` | Rà tài liệu trực tiếp | **PASS tài liệu (14/11/2026):** `docs/55 §2–§3` phủ đầy đủ từ cấm, 6 khái niệm và `AppStrings` mọi trạng thái |
| TC-03 | AC-03 | Kiểm tra bảng tokens, typography, spacing, motion, `48×48 dp` và bảng icon kèm `semanticLabel` | Đủ hex tokens, cỡ chữ, bo góc, không emoji, ≥15 icon map rõ màn và ý nghĩa | Rà tài liệu trực tiếp | **PASS tài liệu (14/11/2026):** `docs/55 §4–§5` có bảng token, 17 mục icon + `semanticLabel` và 2 phương án icon package |
| TC-04 | AC-04 | Kiểm tra `docs/13`, `docs/54`, `docs/README.md` và chạy script kiểm tra | `check_docs_links.py`, `check_task_records.py`, `git diff --check` exit 0 | Windows 11, Python 3.11.0rc2 | **PASS kiểm tĩnh (14/11/2026):** 57 files/0 broken links, Task records OK, diff check exit 0 |

## Giới hạn kiểm thử

Chưa có app Flutter/APK nên chưa kiểm tra tương phản pixel thực tế, TalkBack, `320/360/390/600 dp` và chữ `100/150/200%` trên thiết bị Android; phần này chuyển sang task coding `FE-S01` (`T013`).
