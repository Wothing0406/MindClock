# Quy trình AI coding có thể quay lại và kiểm chứng

Tài liệu này là **hợp đồng làm việc** cho AI và thành viên. [AGENTS.md](../../AGENTS.md) có ưu tiên cao hơn khi thao tác trong repo; [tasks/README.md](../../tasks/README.md) định nghĩa trạng thái và tên folder. Không bắt AI đọc toàn bộ docs mỗi lượt: dùng [index](../README.md) tìm đúng nguồn chuẩn, đọc code/test/task liên quan rồi làm lát cắt nhỏ.

## Vòng làm một task

1. **Nhận mục tiêu:** viết một kết quả người dùng kiểm được, phạm vi và rủi ro. Xem [hiện trạng](01-hien-trang.md), [lộ trình](02-lo-trinh.md), [gói task đầu tiên](05-goi-task-dau-tien.md) và file nguồn tương ứng. Nếu yêu cầu mâu thuẫn hoặc phụ thuộc một [quyết định còn mở](06-quyet-dinh-va-gia-dinh.md), ghi quyết định vào `spec.md` và sửa nguồn chuẩn cùng code.
2. **Tạo/tiếp tục `tasks/TNNN-ten-ngan/` trước code/config/UI/data:** sao từ `_template`; điền `README.md`, `spec.md`, `plan.md`, `tests.md`. Một task gắn một lát cắt; sửa lỗi trong task chưa bàn giao dùng lại folder. Mỗi AC có ít nhất một TC và có trường hợp offline/quyền/timeout nếu liên quan.
3. **Đọc lớp đang đổi:** Flutter `ui → domain → data`, Android Kotlin, hoặc FastAPI `route → service → repository → DB`. Chốt hợp đồng trước khi sửa hai phía. Không viết web thay app Android. Không dùng fixture debug ở release.
4. **Thực hiện từng bước nhỏ:** test tái hiện/lỗi trước nếu có; sửa tối thiểu; chạy test đúng tầng; cập nhật `plan.md`, `tests.md`, `worklog.md` mỗi lát. Một lỗi lặp: tái hiện → nguyên nhân → sửa → test lại. Sau ba vòng không tiến triển, ghi giả thuyết và chặn riêng phần đó.
5. **Soát ngang:** auth/consent, idempotency, câu/đáp án, offline, Dừng khẩn cấp, copy tiếng Việt, accessibility, migration/API/docs/contract test. Xem diff và chắc không stage secret, dữ liệu học sinh, ảnh bài làm hoặc corpus chưa được phép.
6. **Bàn giao:** điền `handoff.md` theo [mẫu dưới](#mau-ban-giao), ghi test thật với môi trường/thiết bị/ngày, rủi ro, bước tiếp tục chính xác. `done` chỉ khi AC bắt buộc đạt; nếu không, `verifying`/`blocked` và nêu nguyên nhân. Cập nhật [hiện trạng](01-hien-trang.md) khi mức tin cậy thay đổi.

## Mẫu giao AI coding có thể dùng nguyên văn

```text
Mục tiêu: <một hành vi người dùng kiểm được>.
Nguồn chuẩn: docs/README.md → <file canonical cụ thể>; xem AGENTS.md và task liên quan.
Phạm vi: <Flutter/Kotlin/API/DB/docs>; ngoài phạm vi: <ghi rõ>.
Trước code: tạo/tiếp tục tasks/TNNN-... với README, spec, plan, tests; AC ↔ TC.
Trạng thái hiện có: <file/mã/test thực tế>; không suy diễn từ docs archive.
Trường hợp phải xử lý: offline, quyền bị từ chối, timeout, duplicate, A/B, Dừng khẩn cấp (nếu liên quan).
Sau code: chạy test phù hợp, ghi kết quả thật và môi trường, sửa docs/API/schema cùng lần, điền worklog/handoff.
Điều kiện xong: <AC đo được>; nếu thiếu máy/quyền/nguồn, giữ verifying/blocked và nêu bước tiếp tục.
```

## Ma trận đọc theo task

| Task | Đọc trước | Test/cổng |
| --- | --- | --- |
| Android alarm | [PRD](../01-product/01-prd.md), [alarm](../02-engineering/02-bao-thuc-android.md), [UX](../01-product/02-hanh-trinh-ux.md) | [test Android](../03-quality/01-ke-hoach-kiem-thu.md) AD01–AD09; máy thật. |
| API/Auth/SQL | [kiến trúc](../02-engineering/01-kien-truc.md), [dữ liệu](../02-engineering/03-du-lieu-sql.md), [API](../02-engineering/04-hop-dong-api.md), [quyền](../01-product/04-tai-khoan-quyen-rieng-tu.md) | Contract, PostgreSQL migration, A/B, idempotency. |
| AI/chấm/câu | [nội dung](../02-engineering/05-ngan-hang-cau-hoi.md), [AI](../02-engineering/06-ai-va-cham-bai.md) | Bộ đánh giá + fallback/uncertain + chi phí. |
| Không gian học | [đặc tả](../02-engineering/07-khong-gian-hoc.md), [UX](../01-product/02-hanh-trinh-ux.md) | Timer/lifecycle/permission/offline. |
| PvP/art | [game](../04-game/01-pvp-gdd.md), [asset](../04-game/02-nhan-vat-asset.md) | Hai máy, server authoritative, playtest, quyền art. |
| Release | [vận hành](../03-quality/02-van-hanh-phat-hanh.md), [test](../03-quality/01-ke-hoach-kiem-thu.md) | Build ký, pilot, rollback, quyền dữ liệu. |

## Mẫu bàn giao

```text
Trạng thái: done | verifying | blocked
Đã đổi: file và hành vi cụ thể
AC/TC: pass/fail/chưa chạy; lệnh, thiết bị, ngày, log hoặc ảnh chứng cứ
Rủi ro: dữ liệu/quyền/hệ điều hành/AI/bản quyền còn lại
Điểm tiếp tục: file, bước plan, lệnh test và điều kiện để mở tiếp
```
