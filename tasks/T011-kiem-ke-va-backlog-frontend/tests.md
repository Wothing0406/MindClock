# Kế hoạch và kết quả kiểm thử T011

Viết ca kiểm thử từ `spec.md` trước khi ghi tài liệu đầu ra. Không đánh dấu kiểm kê là kiểm thử sản phẩm.

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Đối chiếu bảng màn hình trong `docs/54` với `docs/05, 13, 23, 24, 27, 31, 32, 45, 46, 52, 53` và `demo/` | Đủ mọi màn, có mục đích, vào/ra, hành động, trạng thái, local/API, ưu tiên, nguồn | Kiểm tra chéo file trực tiếp | **PASS tài liệu (14/11/2026):** 5 màn `demo/` + toàn bộ `S01–S12`, `L01`, `A01–A03`, `F01–F04`, `P01–P03`, `D01–D05`, `M01`, `E01–E03` đã ánh xạ |
| TC-02 | AC-02 | Kiểm tra tách 3 phạm vi và điều kiện `Đấu trường` theo cohort, không đưa roster/kit cũ | Có 3 bảng/mục tách bạch; không có tên/số combat cũ trong backlog code | Rà nội dung & `Select-String` trên `docs/54` | **PASS tài liệu (14/11/2026):** tách rõ Prototype / MVP Android / Mở rộng; `Đấu trường` gắn flag cohort; chỉ dùng 3 working names v0.1 (`docs/46`) |
| TC-03 | AC-03 | Đối chiếu danh sách component và asset tái sử dụng với `docs/13, 27, 49, 52` và `demo/assets/game/manifest.json` | Ghi rõ file tồn tại thật và trạng thái quyền sử dụng từng nhóm asset | Rà `demo/assets/game` + `manifest.json` | **PASS tài liệu (14/11/2026):** liệt kê 6 avatar, 7 khung, 6 badge, 17 WAV, 15 FX SVG, 3 bộ sprite nghiên cứu (`research_demo_only`), map và tài sản còn thiếu |
| TC-04 | AC-04 | Kiểm tra backlog lát cắt dọc: thứ tự ưu tiên hành trình chính + mỗi lát có AC và test map | Mỗi lát cắt có AC đo được và danh sách test rõ ràng (`320/360/390/600 dp`, `100/150/200%`, `AD01–AD09`) | Rà `docs/54` §4 | **PASS tài liệu (14/11/2026):** 9 lát cắt `FE-S01..FE-S09`, ưu tiên `FE-S01..FE-S05` (P0) trước `FE-S06..FE-S07` (P1/M2) và `FE-S08..FE-S09` (M3) |
| TC-05 | AC-05 | Xác minh các mâu thuẫn tài liệu/prototype và điểm còn thiếu có trích dẫn đúng | Mọi trích dẫn khớp chính xác file/dòng đã đọc | Đối chiếu trực tiếp với file nguồn | **PASS tài liệu (14/11/2026):** ghi nhận 9 mâu thuẫn thực tế và 3 nhóm quyết định còn thiếu |
| TC-06 | AC-06 | Chạy `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check` và xác nhận không sửa code app | Cả 3 lệnh exit 0; không sửa `demo/` hoặc tạo code ứng dụng | Windows 11, Python 3.11.0rc2 | **PASS kiểm tĩnh (14/11/2026):** sẽ chạy lại ngay sau khi ghi `worklog.md`/`handoff.md` |

## Giới hạn kiểm thử (không chạy trong task kiểm kê này — chuyển sang T012+)

- **Báo thức & thiết bị Android thật (`AD01–AD09`, `A01–A07, A13`):** không thể thực thi vì repo chưa có Flutter app/Kotlin native và máy dev chưa có `flutter`/`adb`.
- **Responsive `320/360/390/600 dp` và chữ `100/150/200%`:** không có app Flutter runtime để đo; phần web `demo/arena.html` của `T009/T010` vẫn chờ kiểm trên Chrome Android thật.
