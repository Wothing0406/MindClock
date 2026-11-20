# Đặc tả

- AC01: mỗi câu AI an toàn có nút Nghe sau thao tác user ở phòng AI nhịp ngắt quãng; không tự đọc khi nhận chat. Học sâu/một mình/đăng xuất không phát lời.
- AC02: speaking chỉ sau callback started của engine đúng utterance; kết thúc/lỗi/dừng về tĩnh. Callback cũ không mở miệng lại.
- AC03: dừng khi background/rời màn/đổi account/phiên; hủy lúc chờ init không được nói muộn. Android cũng dừng native khi onPause/audio focus loss/destroy.
- AC04: thiếu giọng vi-VN offline/engine/timeout không phá timer/text; lỗi tiếng Việt, thử lại bằng thao tác; không log/lưu nội dung, không dùng mic.
- AC05: test controller/bridge/widget, analyze, build Android; bằng chứng emulator nếu có. Máy thật/giọng tự nhiên/live full-duplex là cổng chưa đạt, không gọi sản phẩm toàn bộ hoàn thành.

Quyết định: dùng TTS Android offline có sẵn để biến text thành tiếng, không thay Gemini Socratic backend và không nhận là voice Gemini. Native callback là tiến trình phát TTS, không đo âm lượng/phoneme. Chỉ hỗ trợ vi-VN khi máy có voice offline phù hợp, không tự tải dữ liệu hay chuyển sang mạng.
