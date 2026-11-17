# Đặc tả T041

## Vấn đề và kết quả mong muốn

Luồng cũ bắt chọn môn lại, có mức nhắc phát âm và thiếu quy tắc EXP. Tài liệu mới cho phép vào phiên nhanh theo lịch cá nhân, bảo đảm học sâu im lặng và mô tả thưởng sau phiên.

## Phạm vi

- **Trong phạm vi:** PRD, phòng học, kỹ thuật timer/EXP, ca nghiệm thu, truy vết, roadmap.
- **Ngoài phạm vi:** code, API/schema thực thi, PvP, tính năng bạn bè.
- **Dữ liệu/quyền:** EXP do server xác nhận theo owner; mic/cam mặc định tắt.
- **Tài liệu chuẩn:** `docs/01-product/08-phong-hoc-ai-va-ban-be.md` và `docs/02-engineering/07-khong-gian-hoc.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi được mô tả | Bằng chứng |
| --- | --- | --- | --- |
| AC-01 | Vào phòng | Hai lựa chọn chính, gợi ý từ kế hoạch/TKB, không bắt chọn môn lại | TC-01 |
| AC-02 | Chọn Học sâu | Không âm nền, chuông chặng, nhắc hay AI tự nói ở cả hai chế độ | TC-02 |
| AC-03 | Kết thúc phiên | EXP theo phút running trọn vẹn, có cap, offline dự kiến và retry idempotent | TC-03 |

## Hợp đồng và trường hợp biên

Task chỉ đổi docs; chưa có API/schema được triển khai. Phiên dưới 5 phút, hủy và thời gian không chắc nhận 0 EXP. Mất mạng hiển thị dự kiến, không nhận là đã cộng. Học một mình không khởi tạo AI.

## Quyết định

Mốc thử nghiệm là 1 EXP/5 phút, tối đa 12/phiên và 30/ngày; cần pilot trước phát hành rộng. EXP thời gian không là bằng chứng đã học và không cộng RP.
