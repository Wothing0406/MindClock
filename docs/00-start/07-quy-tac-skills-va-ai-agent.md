# Quy tắc chọn skill và giao AI coding

**Mục tiêu:** AI làm đúng một lát cắt sản phẩm Android, không đọc bừa archive rồi tạo một web demo. [AGENTS.md](../../AGENTS.md) là quy tắc bắt buộc; [quy trình task](03-quy-trinh-vibe-code.md) là cách thực hiện. Skill là hướng dẫn thiết kế/kiểm, **không phải dependency runtime** và không tự cài thêm package/CLI chỉ vì skill gợi ý.

## Trước một task coding

1. Đọc `docs/README.md`, [hiện trạng](01-hien-trang.md), PRD ID liên quan, contract và test; chọn một bước từ [lộ trình](02-lo-trinh.md). Nếu yêu cầu mới khác docs, cập nhật nguồn chuẩn cùng task.
2. Tạo/tiếp tục `tasks/TNNN-...` trước code/config/UI/data. Ghi AC có trigger + kết quả quan sát được, TC theo AC, quyền/offline/timeout/duplicate/thiết bị cần test.
3. Chỉ dùng skill đúng phần file đang đổi, đọc SKILL.md; kiểm output skill với docs hiện hành, mã hiện có và tài liệu nhà cung cấp. Không để skill chung tự chọn framework khác Flutter/Kotlin/FastAPI/PostgreSQL.
4. Mỗi lượt: một lát cắt dọc có UI/domain/API/DB/test đủ khi liên quan; nếu chưa có backend, UI phải ghi trạng thái mock/feature flag rõ, không gắn `done`.

## Skill routing

| Phần việc | Skill được ưu tiên nếu có | Bắt buộc đối chiếu |
| --- | --- | --- |
| PRD/hành trình/AC | `requirements-writing`, `product-discovery` khi kiểm giả thuyết | PRD, traceability, ca nghiệm thu; không lấy ý tưởng làm bằng chứng. |
| Flutter kiến trúc/UI | `flutter-apply-architecture-best-practices`, `flutter-custom-design-system`, `flutter-add-widget-test` | Design/UX, cấu trúc `app/`; không thêm web/React cho Android. |
| Kotlin alarm/quyền/DND | `.agents/skills/mindclock-android-native/SKILL.md`, `testing-setup` nếu cần native harness | Android official docs hiện hành, AD01–AD09 máy thật; không hứa khóa máy/DND toàn hệ thống. |
| API/SQL | `api-design-principles`, `requirements-writing` | API/SQL canonical, migration PostgreSQL, Auth A/B/idempotency. |
| AI/câu/chương trình | EduSkills-VN: `tao-quiz-bgd`, skill môn phù hợp, `giai-chi-tiet` chỉ sau lượt; `requirements-writing` | [Adapter EduSkills](../02-engineering/11-eduskills-vn-tich-hop.md), Bộ GD&ĐT/reviewer, rubric/rights/eval; không đưa nguyên prompt giải trọn bài vào hint/chấm trước reveal. Skill môn không tự publish corpus. |
| PvP/art/sprite | `game-design`, `game-art`, `generate2dsprite` khi task đã mở | GDD v0.1, asset provenance, balance/playtest; không lấy sprite web làm arena Flutter. |
| iOS sau này | `apple-hig-expert`, `ios-flows` | iOS riêng, Mac/Xcode/iPhone; không bê giới hạn Android sang iOS. |

`frontend-design` và `web-design-guidelines` chỉ tham khảo nguyên tắc thị giác/nội dung khi có lý do; không tạo React/web client thay app. `agent-browser`/`browser-use` dùng để kiểm trang web tài liệu/admin nếu task đó tồn tại, không chứng minh alarm trên máy. Skill sprite/video chỉ mở sau khi master art/licensing được duyệt. Không cài mới hàng loạt skill từ GitHub trong task feature; một skill mới cần mục đích, nguồn/license, file tác động, test và reviewer.

## Prompt giao task chuẩn

```text
Mục tiêu người dùng: <một hành vi kiểm được>.
Nguồn chuẩn: docs/README.md → <PRD ID + UX + contract + TC>; không dùng docs/archive.
Hiện trạng mã: <file, test thật và giới hạn>.
Phạm vi: <Flutter/Kotlin/API/SQL/asset>; feature flag/gate: <nếu có>.
Trước code: tasks/TNNN-* README/spec/plan/tests, AC ↔ TC.
Yêu cầu lỗi: offline, OS permission, Auth/consent, quota/timeout, duplicate, dữ liệu A/B, accessibility.
Sau code: test đúng tầng, Android thật nếu alarm/media, PostgreSQL nếu nghiệp vụ, AI eval nếu chấm; ghi môi trường và kết quả.
Bàn giao: trạng thái, diff, AC/TC, rủi ro, điểm tiếp tục. Không gọi mock là sản phẩm.
```

Nếu AI gặp câu “đánh thức bằng cách không thể tắt”, “khóa app khác”, “AI chửi học sinh”, “chống gian lận tuyệt đối”, phải quay lại [PRD](../01-product/01-prd.md), [alarm](../02-engineering/02-bao-thuc-android.md) và [phòng học](../01-product/08-phong-hoc-ai-va-ban-be.md), ghi quyết định an toàn trong task, không thực hiện hành vi trái quy tắc.

Đối với EduSkills-VN, đọc skill môn **để trích quy tắc chuyên ngành**, rồi xuất prompt nhỏ theo `AUTHOR_DRAFT|GRADE_CANDIDATE|HINT_ONE_STEP|POST_ATTEMPT_EXPLAIN`. Không dán nguyên `giai-chi-tiet` hoặc prompt bốn tầng vào trợ lý trước khi học sinh nộp; nó có thể tiết lộ lời giải. Nội dung generated phải có nguồn, revision, người duyệt và test trước khi vào ngân hàng scored. Bộ OCR của EduSkills dùng để gợi đọc chữ in/TKB, không dùng Tesseract làm trọng tài chữ viết tay. [Hợp đồng](../02-engineering/11-eduskills-vn-tich-hop.md).
