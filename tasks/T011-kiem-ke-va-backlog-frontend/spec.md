# Đặc tả nhiệm vụ T011 — Kiểm kê và lập backlog frontend MindClock

## Vấn đề và kết quả mong muốn

Trước khi mở các task coding Flutter Android đầu tiên (chưa có `pubspec.yaml`, mã Kotlin hay APK), đội ngũ cần một bản kiểm kê trung thực toàn bộ màn hình, phạm vi prototype vs MVP vs sau MVP, component/asset tái sử dụng từ `demo/`, danh sách lát cắt dọc frontend kèm tiêu chí nghiệm thu (`AC ↔ test`), và danh sách các mâu thuẫn tài liệu/quyết định còn thiếu.

Sau task này, chủ dự án và coding agent có tài liệu chuẩn [docs/54-kiem-ke-va-backlog-frontend.md](../../docs/54-kiem-ke-va-backlog-frontend.md) để mở lần lượt các task `T012+` mà không lẫn prototype vào sản phẩm chạy thật, không đưa roster/kit cũ vào kế hoạch, và luôn đặt hành trình `khách → đặt chuông → reo → câu hỏi → nhập bài → phản hồi → Hôm nay` làm ưu tiên P0.

## Phạm vi

- **Trong phạm vi:** đọc và kiểm kê các docs `04, 05, 13, 23, 27, 29, 30, 31, 32, 41, 42, 45, 47, 48, 52, 53` (kèm `07, 08, 09, 24, 39, 46, 49, 51` để đối chiếu), handoff `T009`/`T010`, `demo/` và `demo/assets/game/`; xuất tài liệu kiểm kê + backlog vào `docs/54-kiem-ke-va-backlog-frontend.md`, cập nhật `docs/README.md` và hồ sơ task `T011`.
- **Ngoài phạm vi:** không sửa code `demo/`, không khởi tạo Flutter/backend code trong task này (`chưa sửa code`), không tuyên bố kiểm kê là kiểm thử sản phẩm.
- **Dữ liệu/role/quyền liên quan:** chỉ phân tích đặc tả dữ liệu local vs API (khách local không đăng nhập; tài khoản online qua Firebase Auth + PostgreSQL; Đấu trường chỉ mở theo cohort flag).
- **Tài liệu chuẩn:** `AGENTS.md`, `docs/README.md`, `tasks/README.md`, `docs/04, 05, 07, 08, 09, 13, 23, 24, 27, 29, 30, 31, 32, 39, 41, 42, 45, 46, 47, 48, 49, 51, 52, 53`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống/tài liệu phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi kiểm kê toàn bộ màn hình trong docs và `demo/` | Bảng màn hình phải ghi đủ: mục đích, điểm vào/ra, hành động chính, trạng thái (loading/empty/error/offline/permission), dữ liệu local/API, mức ưu tiên và tài liệu nguồn | TC-01 (rà soát đối chiếu file thật) |
| AC-02 | Khi phân định phạm vi sản phẩm | Phải tách rõ 3 nhóm: prototype hiện có (`demo/`), MVP Android cần xây, mở rộng sau MVP; `Đấu trường` chỉ hiện khi mở cohort; không đưa roster/kit cũ (`docs/22, 35, 37, 40, 43 cũ`) vào kế hoạch | TC-02 (kiểm tra danh sách phạm vi & grep không có kit/roster cũ làm kế hoạch code) |
| AC-03 | Khi kiểm kê component và asset | Liệt kê component dùng chung Flutter và tình trạng tái sử dụng/bản quyền của từng nhóm asset trong `demo/assets/game/` | TC-03 (đối chiếu `demo/assets/game/manifest.json` và `docs/49, 52`) |
| AC-04 | Khi lập backlog theo lát cắt dọc | Ưu tiên hành trình `khách → đặt chuông → reo → câu hỏi → nhập bài → phản hồi → Hôm nay`; mỗi lát có AC theo EARS/kiểm chứng được và ánh xạ test (`A01–A14`, `L01–L10`, `U01–U10`, `G01–G08`, `F01–F10`, `P01–P09`, `AD01–AD09`, 320/360/390/600 dp, chữ 100/150/200%) | TC-04 (kiểm tra truy vết AC ↔ test trên từng lát cắt) |
| AC-05 | Khi phát hiện mâu thuẫn tài liệu/demo hoặc điểm thiếu | Ghi rõ từng mâu thuẫn kèm file + dòng/mục thực tế và quyết định đề xuất trước coding | TC-05 (xác minh mọi trích dẫn tồn tại thật trong repo) |
| AC-06 | Khi hoàn tất hồ sơ tài liệu và backup | Chạy `check_docs_links.py`, `check_task_records.py`, `git diff --check`, không sửa code ứng dụng và push lên `origin/main` | TC-06 (output lệnh kiểm tra và git push) |

## Hợp đồng và trường hợp biên

Không sửa API/schema/app code trong task này. Mọi thay đổi giới hạn ở tài liệu backlog (`docs/54`) và hồ sơ `tasks/T011`. Phải phân biệt rõ `kiểm kê tài liệu` với `kiểm thử sản phẩm/thiết bị thật`.

## Quyết định/mâu thuẫn

Các mâu thuẫn phát hiện trong quá trình kiểm kê (ví dụ `han_boi_thap` vs `han-boi-phap`, `docs/13` còn tham chiếu `docs/37`/`PetBadge`, `demo/index.html` có `+15 XP mẫu` và luôn hiện tab `Đấu trường`, `S01–S12` vs cấu trúc 4 tab + `Không gian học`/`Hồ sơ`, giới hạn 2 ảnh/phiên vs chụp lại `uncertain`, 3 câu vs 6 round PvP, quyền thương mại sprite) được tổng hợp thành bảng riêng tại Mục 5 của `docs/54-kiem-ke-va-backlog-frontend.md` để đội quyết định/đồng bộ trước hoặc trong task coding tương ứng.
