# Nhật ký

20/11/2026: tạo art gốc bằng image_gen, không dùng key/CLI; tham chiếu master riêng cho từng nhân vật. Reaction source v1 vượt cell, yêu cầu edit chỉ giảm scale/tăng gutter, giữ nhận diện và thứ tự. V2 được chọn sau xem; xử lý qua skill pipeline với native alpha, all-components, strictQC và Lanczos, đóng gói256pxWebP. Nguồn/giai đoạn/preview/QA phân thư mục, processed là cache ignored. Không lấy GIF tự tạo của tool lướt các pose tĩnh làm animation pet.

Flutter: thay painter AI bằng file art, giữ tên public widget qua export để không vỡ imports; trạng thái blink/3mouth thật, mood và Reduced Motion. Tìm thấy isSpeaking trước đây dựa chat history, bỏ logic đó; nền học và cỡ avatar160 ở trợ lý chữ. MamPetView là widget nhận stage/reaction, chưa tự tạo pet group hoặc thưởng.

20/11/2026: người dùng yêu cầu tạo art thật, không thêm placeholder. Chọn image_gen built-in theo imagegen skill, không gọi API trả phí bằng key cục bộ. Character full-body motion video không có tool trong session; dùng biểu cảm/avatar UI và khai báo giới hạn rõ, không giả đã tạo video/sprite action đầy đủ.
