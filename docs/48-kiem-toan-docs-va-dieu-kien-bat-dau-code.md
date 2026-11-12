# Kiểm toán bộ docs MindClock — 12/11/2026

**Kết luận:** bộ docs **đủ để mở task coding Android P0 có kiểm soát**, **chưa đủ để tuyên bố sản phẩm/demo Android đã chạy hoặc mở ranked/iOS**. Đây là kiểm toán tài liệu và repo, không phải QA sản phẩm. Nguồn chuẩn để tìm tài liệu là [README](README.md); cách giao việc ở [AGENTS](../AGENTS.md) và [tasks](../tasks/README.md).

## 1. Đã kiểm tra

| Vùng | Tài liệu nguồn hiện hành | Kết quả |
| --- | --- | --- |
| Vòng báo thức/học P0 | 04, 06, 07, 09, 31, 32, 39, 41–42 | Có yêu cầu Dừng khẩn cấp local, offline, câu duyệt, ba kết quả chấm, quyền dữ liệu và test A01–A14; đủ viết task P0 |
| Demo Android | [47](47-demo-android-va-moi-truong-kiem-thu.md), [26](26-bo-cong-cu-mien-phi-va-kich-ban-demo.md), [02](02-ke-hoach-thi-va-demo.md) | Có môi trường Windows, điện thoại/emulator, lệnh điều kiện, AD01–AD10, kịch bản và dự phòng; **chưa có APK để thực thi** |
| Không gian học | [45](45-khong-gian-hoc-va-che-do-tap-trung.md) | Có luồng timer/UI/AI/camera và test F01–F10; không hứa khóa app khác |
| PvP/nhân vật | [46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md), [43](43-thiet-ke-nhan-vat-avatar-khung-rank-va-bang.md), [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md) | Ba working names, luật 100 HP/50 giáp/6 round, skill, asset prompt, networking, test P01–P09; số **thử nghiệm**, chưa có art/balance/câu được duyệt cho ranked |
| Kinh tế/rank | 21, 37, 44 | RP/MMR/ledger và quyền bảng có hướng thiết kế; catalog/giá/ownership cũ đã đóng băng, chưa mở coding |
| iOS | [20](20-ios-demo-va-phat-hanh.md) | Chuyển rõ thành nhánh sau Android P0, không nằm trong demo cuộc thi |
| Quy trình agent/skill | 10, 16, 42, AGENTS, tasks/README | Có định tuyến tài liệu, task spec/plan/tests/handoff, skill Android native/Flutter test |

Kiểm tĩnh: toàn bộ link Markdown **nội bộ** trong `docs/*.md` được rà theo đường dẫn file; không thấy link đứt ở thời điểm kiểm. `python scripts/check_task_records.py` kiểm cấu trúc task; `git diff --check` kiểm whitespace. Nguồn lịch công khai [Hackathon GDG MienTrung](https://gdg.community.dev/events/details/google-gdg-mientrung-presents-hackathon_gdg-devfest-mientrung-2026/) hiển thị 14/11/2026, 06:00–13:00 GMT+7; **chưa có quy chế xây dựng trước/hạn nộp/thời lượng pitch chính thức** trong nguồn đã đọc.

## 2. Chưa đạt và không được suy diễn

| Mức | Khoảng trống | Điều kiện để đóng |
| --- | --- | --- |
| P0 trước gọi “app chạy” | Repo chưa có `pubspec.yaml`, AndroidManifest, APK, FastAPI app, migrations hay test runtime; trên máy kiểm hiện không thấy lệnh `flutter`/`adb` trong PATH | Tạo task app Android, cài SDK theo docs/47, chạy emulator và máy Android thật, ghi build/test |
| P0 trước demo báo thức thật | Chưa có bằng chứng AD01–AD09 trên máy đem thi, đặc biệt màn khóa/app đóng/offline/Dừng khẩn cấp | Có APK, chạy ma trận docs/47 và lưu kết quả theo máy/API level |
| P0 trước AI live | Chưa có bộ câu/rubric đủ và bộ ảnh được phép dùng đã kiểm định; Gemini quota/dữ liệu demo chưa đo | Câu đội tự viết/duyệt, người chấm độc lập, fixture fallback có nhãn, test `uncertain` |
| Trước online/PvP | Chưa có auth/backend PostgreSQL hai máy, contract action/event đã khóa, test reconnect/ledger | Chốt schema/API docs/46, contract test, hai máy thật và quyền A/B |
| Trước ranked/cửa hàng | Chưa có playtest cân bằng, consent/độ tuổi được xác nhận, quyền tên/hình nhân vật, chính sách sở hữu/giá mới | Qua cổng docs/39, 46; xác minh IP/nguồn asset; quyết định riêng economy/rank |
| Trước iOS | Không có Mac/Xcode/iPhone/build/AlarmKit test | Chỉ mở sau Android P0, theo docs/20 |
| Trước cuộc thi | Quy chế dùng phần chuẩn bị trước, giờ nộp, định dạng pitch chưa xác nhận | Hỏi ban tổ chức và cập nhật docs/02 trước khi chốt kế hoạch buổi sáng |

## 3. Thứ tự làm tiếp

1. **Android local P0:** tạo Flutter app + native alarm + guest flow; làm câu demo tự biên soạn và nhập chữ; chạy AD01–AD07 trên máy thật. Không cần Gemini/PvP để chứng minh chuông.
2. **Chấm an toàn:** FastAPI/PostgreSQL/Auth chỉ khi cần online; schema câu/rubric đã duyệt, kết quả `correct/incorrect/uncertain`, idempotency/owner; chạy test docs/09/39.
3. **Demo sân khấu:** dùng docs/47, ghi bảng phần nào live/mô phỏng, tập 3 lần, chuẩn bị video/PDF/offline.
4. **Sau cuộc thi:** Không gian học, giao hữu PvP ba concept sau kiểm chấm/câu; ranked/cửa hàng rồi iOS là các cổng độc lập. Mỗi lát cắt mở task theo `tasks/README.md`.

**Quy tắc bàn giao:** khi code xuất hiện, cập nhật dòng trạng thái `chưa có app` trong docs/README, 20, 26, 47, 48 bằng bằng chứng build/test cụ thể. Không biến checklist trống thành lời xác nhận đã chạy.
