---
name: vietnamese-education-copy
description: Viết và rà soát tiếng Việt (vi-VN) chuẩn giáo dục THPT GDPT 2018 và giao tiếp EdTech tự nhiên, ngắn gọn cho MindClock (dựa trên trussary/vietnamese-language-skill, MIT license). Dùng khi soạn nội dung UI tiếng Việt, prompt AI trợ giảng, nhận xét học sinh hoặc thông báo không gian học.
---

# Tiếng Việt Giáo Dục & EdTech Tự Nhiên (`vi-VN`)

**Nguồn gốc & License:** Chắt lọc cho MindClock từ [trussary/vietnamese-language-skill](https://github.com/trussary/vietnamese-language-skill) (MIT License).

## 1. Xưng hô & Giọng điệu cho học sinh THPT

- **Trợ lý AI MindClock → học sinh THPT:** Xưng **mình – bạn** (bạn học đồng hành ngang hàng, tôn trọng) hoặc `em` khi đúng vai thầy/cô; giữ lời ngắn gọn **1–2 câu** mỗi lượt, không giảng đạo.
- **Không dùng câu sáo rỗng kiểu máy dịch:** Tránh mở đầu bằng *"Chắc chắn rồi!"*, *"Tôi rất vui được giúp bạn!"*, *"Tuyệt vời!"*, *"Đừng lo lắng!"* hay câu dài rào đón trước khi vào ý chính.
- **Growth Mindset & Nhận xét hành vi:** Chỉ rõ **bước làm hoặc kiến thức** cần sửa (*"Bước chuyển vế đang ngược dấu"*, *"Cần cố gắng thêm ở phần điều kiện xác định"*), tuyệt đối không dán nhãn cá nhân (*"học kém"*, *"lười"*).

## 2. Chuẩn thuật ngữ Bộ GD&ĐT (Thông tư 22/2021/TT-BGDĐT)

- Phân loại kết quả rèn luyện/học tập cấp THCS/THPT: `Tốt` / `Khá` / `Đạt` / `Chưa đạt` (không dùng nhãn cũ `Học sinh Tiên tiến`).
- Nhận xét khích lệ chuẩn: `Cần cố gắng` (tránh calque `"Cần cải thiện"`).
- Số thập phân trong văn xuôi tiếng Việt: dùng **dấu phẩy** (`3,5`, `1,5 A`) khi viết lời giải/nhận xét tiếng Việt; vẫn chấp nhận cả `.` và `,` khi học sinh nhập số ở input.

## 3. Áp dụng vào AI Prompt Runtime & Copy

- **Gợi ý trước khi nộp (`HINT_ONE_STEP`):** Tối đa `<= 180` ký tự gợi ý + `<= 120` ký tự câu hỏi tiếp theo; chỉ 1 bước tiếp, không lặp lại đề bài.
- **Phản hồi chấm bài (`GRADE_CANDIDATE`):** Nêu đúng phần đã đọc được + lỗi đầu tiên (nếu sai) hoặc trạng thái `uncertain` trung thực khi mờ/thiếu bước; không tiết lộ đáp án cuối trước khi phiên kết thúc.
- **Thông báo nhắc nhịp (`Học ngắt quãng`):** Trung tính, tích cực, không gây cảm giác tội lỗi hay ép giữ chuỗi.
