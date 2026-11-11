# Tổ chức coding agent và cách bàn giao

Tài liệu này dùng khi đội chia việc cho người hoặc coding agent. Không giả định có tác vụ chạy song song ngay lúc viết tài liệu. [AGENTS.md](../AGENTS.md) là chỉ dẫn chung cho mọi agent trong repo; tài liệu này mô tả vai và hợp đồng bàn giao.

**Quy trình bắt buộc cho mỗi lần coding:** xem [tasks/README.md](../tasks/README.md). Task card ở §2 là bản tóm tắt giao việc; thư mục `tasks/TNNN-ten-ngan/` mới là hồ sơ thực thi gồm spec, plan, tests, worklog và handoff. Một yêu cầu tiếp diễn giữ cùng ID để người/AI mới biết quay lại ở bước nào.

## 1. Vai và vùng sở hữu

| Vai | Chịu trách nhiệm | Được sửa chính | Cần báo trước khi sửa |
| --- | --- | --- | --- |
| Product/UX agent | Làm rõ user story, acceptance, chuỗi tiếng Việt, storyboard | `docs/04*`, `docs/05*`, tài sản UX sau này | Quy tắc điểm, API, dữ liệu |
| Mobile agent | Flutter, Android alarm bridge, cache local, camera, accessibility | `apps/mobile/**` (khi tạo) | API contract, state machine |
| Backend agent | FastAPI, Firebase Auth cho online, PostgreSQL, session, XP, bảo mật | `services/api/**`, migration/config backend | API contract, schema, điểm |
| AI/Content agent | Question bank, rubric, Gemini adapter, evaluator, gợi ý | `services/api/ai/**`, `content/**`, `evals/**` | `result` semantics, rubric, ngưỡng |
| QA/Release agent | Test plan, emulator, device matrix, CI gates, báo lỗi | `tests/**`, `evals/**`, `docs/09*` | Không sửa production logic nếu chưa phối hợp chủ sở hữu |
| Integration lead | Khóa scope, duyệt thay đổi liên vùng, xử lý mâu thuẫn, release | Toàn repo theo PR/review | Bất kỳ thay đổi phá hợp đồng |

Đường dẫn trên là **cấu trúc repo dự kiến**, chưa tồn tại. Agent đầu tiên chỉ tạo cấu trúc sau khi đội duyệt stack.

## 2. Quy tắc chia task

Mỗi task phải có: `ID`, mục tiêu, tài liệu nguồn, vùng file, phụ thuộc, đầu ra, test cần chạy, tiêu chí chấp nhận và người review. Không giao task “làm app MindClock” chung chung. Một agent không được tự thay đổi hợp đồng API, schema hoặc quy tắc XP để code của mình chạy; nếu phát hiện bất hợp lý, ghi đề xuất rồi cập nhật tài liệu liên quan trước khi tích hợp.

### Mẫu task card

```text
ID: T05 — Báo thức Android local
Mục tiêu: chuông reo và Dừng khẩn cấp khi app đóng/mất mạng; Hoãn chỉ mode thường.
Tài liệu: PRD §5; Kiến trúc §2–3; Test A01–A07/A13; docs/41 U01/U03.
Vùng sửa: apps/mobile/**.
Phụ thuộc: cấu hình app, quyền Android, local question cache interface.
Đầu ra: UI trạng thái quyền, native bridge, hướng dẫn thử thiết bị.
Kiểm thử: unit next-fire; 3 thiết bị thật; màn khóa, reboot, offline.
Chấp nhận: một chạm Dừng tắt âm/rung local; không duplicate alarm/session.
Bàn giao: file thay đổi, quyết định kỹ thuật, kết quả test, rủi ro còn lại.
```

## 3. Thứ tự phối hợp agent

1. **Product/UX + integration lead** khóa PRD, chuỗi tiếng Việt và câu demo; ghi các quyết định còn mở.
2. **Backend + mobile** thống nhất contract `/v1` và state machine; có mock response để hai bên làm độc lập.
3. **AI/content** làm rubric và bộ đánh giá; backend chỉ nhận adapter tuân schema, không tích hợp prompt chưa kiểm thử.
4. **QA** viết test từ tiêu chí chấp nhận và phản biện trạng thái lỗi sớm, đặc biệt offline/tắt khẩn cấp.
5. **Integration lead** ghép dọc một luồng chạy được trước khi mở thêm tính năng.

## 4. Hợp đồng bàn giao

Mọi agent kết thúc task bằng `tasks/TNNN-ten-ngan/handoff.md` và cập nhật `README.md` của task. Bản ghi ngắn tối thiểu:

```text
Đã làm: [hành vi cụ thể]
File thay đổi: [danh sách]
Kiểm tra: [lệnh/kịch bản, kết quả, thiết bị nếu có]
Tài liệu cập nhật: [PRD/API/test/ADR]
Chưa xong/rủi ro: [nếu có]
Việc bên khác cần làm: [chỉ rõ người/vai và phụ thuộc]
```

Không ghi “hoàn thành” khi mới có giao diện không nối backend hoặc báo thức chỉ chạy khi app mở. Không nói “AI chấm chính xác” nếu chỉ thử một ảnh mẫu.

## 5. Các điểm cần review liên vùng

| Thay đổi | Bắt buộc cùng review |
| --- | --- |
| Thêm/sửa endpoint, enum, error code | Mobile + backend + QA |
| Thay quy tắc XP/streak/rank | Product + backend + QA |
| Thay ngưỡng `uncertain`/rubric | AI/content + product + QA |
| Quyền Android/báo thức | Mobile + QA trên thiết bị |
| Ảnh, consent, log, xóa dữ liệu | Backend + product + QA/privacy |
| Nhóm lớp/đấu/linh thú | Product + QA/privacy trước khi code |

## 6. Gợi ý prompt giao việc cho agent

> “Thực hiện task Txx trong [kế hoạch triển khai](08-ke-hoach-trien-khai.md). Đọc [AGENTS.md](../AGENTS.md), PRD, kiến trúc, API và test case liên quan. Chỉ sửa vùng sở hữu hoặc báo rõ khi cần thay đổi liên vùng. Triển khai đến tiêu chí chấp nhận, chạy kiểm thử phù hợp, cập nhật tài liệu thay đổi và bàn giao theo mẫu §4. Không tự thêm tính năng tương lai.”

Prompt này là mẫu cho coding; không buộc dùng một công cụ AI cụ thể. Nếu một agent phải dừng vì thiếu quyết định sản phẩm, hãy hoàn tất phần độc lập và nêu lựa chọn, hệ quả, đề xuất mặc định.

**Prompt cập nhật cho mọi task:** “Đọc `AGENTS.md`, `tasks/README.md` và docs liên quan. Tạo/tiếp tục task folder trước khi sửa code; viết spec, plan, test có AC liên kết. Thực hiện từng bước, ghi vòng sửa và kết quả kiểm thử thực. Bàn giao trạng thái cùng điểm tiếp tục chính xác. Không báo xong khi test/AC chưa đạt.”

