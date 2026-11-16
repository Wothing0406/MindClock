# Kiểm chứng T034

| TC | Cách kiểm | Kết quả |
| --- | --- | --- |
| TC-01 | Xem ảnh logo, kiểm file, kích thước và chữ/emoji | Đạt phần asset: concept 1254×1254 RGB xem được; SVG parse hợp lệ, hình học không có chữ/emoji và có biên 76/512 px. Chưa kiểm crop trên launcher Android. |
| TC-02 | So brand docs với token UI và asset | Đạt: bốn màu SVG khớp token design; SVG chính, PNG concept được phân biệt và không dùng runtime. |
| TC-03 | Chạy docs links/task records, kiểm staged diff, Git push/remote | Links 410 Markdown PASS, task records PASS, diff các file tài liệu không có lỗi whitespace; staged/remote chờ kiểm. |
