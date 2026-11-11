# Ma trận yêu cầu từ học sinh đến coding

**Mục đích:** khi mở một thư mục `tasks/TNNN-...`, chọn một lát cắt và chép ID liên quan vào `spec.md`/`tests.md`. [Docs/41](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md) là nguồn nhu cầu U01–U10, [04](04-prd-va-dac-ta-san-pham.md) là luật sản phẩm, [07](07-hop-dong-api-va-ai.md) là contract. Bảng là kế hoạch, không chứng minh tính năng đã chạy.

| Nhu cầu/AC | Lát cắt giao việc (đầu ra quan sát được) | Nguồn đặc tả | Test bắt buộc | Giai đoạn/chủ trì |
| --- | --- | --- | --- | --- |
| U01 | Khách local đặt/thử chuông, thấy quyền OS và lần reo kế | [05](05-ux-va-noi-dung-tieng-viet.md), [06](06-kien-truc-va-du-lieu.md), [31](31-bao-thuc-thu-thach.md) | A01–A05, thiết bị thật khóa màn/offline | M1 P0 · mobile |
| U02 | Nhập/sửa lịch nhanh, giờ gợi ý có phép tính và chỉ lưu sau xác nhận | [32](32-ho-so-hoc-tap-va-nhieu-mon.md), [07](07-hop-dong-api-va-ai.md) | lịch rỗng/đổi tiết/múi giờ; không tự đổi alarm | M1 P0 · mobile/API |
| U03 | Dừng khẩn cấp ở mọi màn, kể cả AI treo, không phạt | [31](31-bao-thuc-thu-thach.md), [06](06-kien-truc-va-du-lieu.md) | A06/A13, kiểm âm/rung thật, không phụ thuộc token | M1 P0 · mobile |
| U04 | Nhập đáp án + lý do thay camera | [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), [05](05-ux-va-noi-dung-tieng-viet.md), [07](07-hop-dong-api-va-ai.md) | camera từ chối, chữ 200%, lý do thiếu/sai | M1 P0 · mobile/API |
| U05 | `uncertain` có đường sửa/nhập chữ/kết thúc, không phạt | [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), [14](14-vai-tro-va-quy-dinh-ai.md) | A09/A10, timeout/bất đồng, XP idempotent | M1 P0 · AI/API |
| U06 | Chọn nhiều môn, câu ba phiên đầu dễ; ngày nghỉ không mất nhân vật/coin | [32](32-ho-so-hoc-tap-va-nhieu-mon.md), [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), [37](37-kinh-te-rank-va-nhan-vat-2d.md) | lịch trống/môn không có câu, tăng khó chỉ theo bằng chứng, ngày nghỉ | M1/M2 · product/API |
| U07 | Nhận một lỗi cụ thể và một việc ôn sau giờ học | [34](34-ngan-hang-cau-hoi-da-mon.md), [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), [32](32-ho-so-hoc-tap-va-nhieu-mon.md) | giáo viên duyệt feedback; không lộ đáp án trước khi kết thúc | M2 · nội dung/AI |
| U08 | Giao hữu trước; opt-in bảng, biệt danh, rút khỏi bảng | [35](35-solo-rpg-dong-bo-va-ky-nang.md), [21](21-dau-truong-xep-hang.md), [25](25-bao-mat-va-du-lieu.md) | hai máy/owner A-B, ẩn bảng, không lộ giờ dậy | M3 · backend/game |
| U09 | Giao diện đọc được máy yếu/giảm chuyển động; FX không che đề/nút | [13](13-he-thiet-ke-ui.md), [27](27-quy-chuan-giao-dien-va-figma.md), [40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md) | chữ 200%, reduce motion, fps/pin trên máy mục tiêu | M1/M3 · UI/mobile |
| U10 | Đổi tài khoản không lộ nháp/lịch/bài của người trước | [24](24-dang-ky-va-quan-ly-tai-khoan.md), [25](25-bao-mat-va-du-lieu.md), [07](07-hop-dong-api-va-ai.md) | shared-device, export/delete/owner A-B, draft TTL 24h | M1 P0 · API/mobile |

## Thứ tự task đề xuất cho người bắt đầu code

1. **P0A — guest + báo thức local:** U01/U03, một thiết bị Android thật, không cần API. Đừng báo hoàn thành khi mới có màn chuông mô phỏng.
2. **P0B — lịch và câu đã duyệt:** U02/U06, ít nhất một câu tự biên soạn có rubric; prompt cache không kèm đáp án; offline `không chấm`.
3. **P0C — bài chữ và ba kết quả:** U04/U05, FastAPI/PostgreSQL, Firebase Auth chỉ cho online, idempotency/owner, lỗi AI an toàn.
4. **P0D — dữ liệu cá nhân và bàn giao:** U10, consent, export/delete, test A/B và shared-device. Sau đó mới pilot.
5. **M2/M3 — giá trị học và game:** U07–U09; đo tác dụng/lỗi với người học trước khi mở ranked hoặc bán nhân vật.

## Mẫu điền task để tránh hiểu nhầm

Trong `spec.md`: `Nguồn: docs/41 U04,U05; docs/07 §2,§8; docs/39 G01–G08` và viết điều kiện đầu vào/kết quả/ngoại lệ cụ thể. Trong `tests.md`: ánh xạ từng AC tới test tự động, máy thật hoặc thử người dùng; ghi **kết quả thật**, không đánh dấu pass từ tài liệu. Trong `handoff.md`: ghi trạng thái, môi trường/thiết bị đã thử, test còn thiếu, rủi ro và một điểm tiếp tục cụ thể. Nếu contract hoặc hành vi đổi, sửa docs nguồn cùng task trước khi chốt code.

**Cổng không thể điền bằng giả định:** quyền dataset, người duyệt câu, thể lệ thi, kết quả usability/pilot, lỗi chấm trên bài thật, máy Android/iOS thật, chi phí online. Chủ sở hữu/cổng ở [19](19-kiem-toan-khoang-trong.md). Ghi `chưa kiểm chứng` cho các mục đó; không biến thành khẳng định sản phẩm.
