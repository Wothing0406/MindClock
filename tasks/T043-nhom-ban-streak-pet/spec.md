# Đặc tả T043

## Vấn đề

T042 đặt pet như phần thưởng phụ sau timer, chưa nối vòng báo thức → bạn thật → chuỗi đúng giờ → pet chung. T043 sửa luồng và dữ liệu chuẩn để đội triển khai đúng ý.

## Phạm vi

- Trong phạm vi: chỉnh docs; ngoài phạm vi: code, schema migration, asset, media.
- Quyền: group invite có chấp nhận; chỉ một nhóm chăm chính/ngày; dữ liệu alarm riêng.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi được mô tả | Test |
| --- | --- | --- | --- |
| AC-01 | Mời bạn | Link/mã có hạn, xác nhận tham gia, nhóm nhỏ và quyền rời/chặn | TC-01 |
| AC-02 | Báo thức theo lịch, câu đúng | Chuỗi đúng giờ tách chuỗi ôn sáng, care vào một nhóm chính | TC-02 |
| AC-03 | Nhóm nuôi pet | Ngày chăm chung, bonus khi cùng làm, không trừ cấp/điểm người khác | TC-03 |
| AC-04 | AI/giờ học | AI là trợ giảng tự chọn, deep im lặng, study care phụ có trần | TC-04 |

## Biên và quyết định

Mốc 15 phút mở lượt/60 phút hoàn thành là thử nghiệm, không chứng minh tỉnh giấc. Ngày nghỉ/lỗi OS/AI uncertain không gán bỏ cuộc. Một thành viên vắng không làm pet mất cấp; không dùng áp lực bêu tên. Contract mới chỉ ở docs, chưa triển khai.
