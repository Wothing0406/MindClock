# Logo MindClock v1

**Dấu hiệu chính:** [mindclock-mark.svg](mindclock-mark.svg) là bản vector do nhóm dựng cho app icon; [ảnh khám phá](source/mindclock-logo-concept-v1.png) là bản AI tạo để khảo sát hướng hình, không phải file runtime.

- Vòng đồng hồ mở ở góc trang: báo thức gắn với việc học.
- Chấm vàng: điểm sáng buổi sáng. Kim đồng hồ: hành động đúng giờ, không dùng hình não, bóng đèn hay tướng PvP.
- Màu lấy từ [design system](../../docs/01-product/03-he-thiet-ke.md): `night #101A30`, `primary #126F73`, `sunrise #F4B95F`, `paper #F7F7F2`.

Giữ dấu hiệu trong khung vuông với vùng an toàn tối thiểu 12% mỗi cạnh. Không thêm chữ nhỏ, emoji, hiệu ứng sáng hoặc gradient. Logo không thay hình avatar người học, nhân vật game hoặc huy hiệu rank. Khi tích hợp launcher Android, xuất adaptive foreground/background từ vector, kiểm cắt trên launcher tròn/vuông, kích thước 48/72/192px và nền sáng/tối; không lấy ảnh concept có texture làm icon phát hành. Kiểm khả năng phân biệt với nhãn hiệu/app đang có trước khi công bố rộng. Hiện chưa thay launcher icon hay kiểm trên máy thật.

Prompt dùng cho ảnh khám phá (built-in image generation, 16/11/2026): *Single square logo for educational alarm app; deep navy background; incomplete teal clock ring folding into a notebook page; small warm sunrise dot; pale clock hands; minimal vector-like geometry; no text, emoji, brain, mascot, trophy or 3D.* Bản vector được dựng riêng bằng hình học SVG để giữ nét và token màu ổn định.
