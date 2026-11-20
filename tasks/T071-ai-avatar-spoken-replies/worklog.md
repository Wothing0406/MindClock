# Nhật ký

20/11/2026: T070 chỉ có frame renderer, isSpeaking=false ở màn text. Pet chưa có nhóm/ledger nên không thể cấp level từ ảnh. Chọn nối đọc text chủ động trước, theo P1 TTS trong docs phòng học. Đối chiếu Android TextToSpeech/UtteranceProgressListener chính thức: init trước speak, query TTS_SERVICE, stop/shutdown và callback theo utterance.

Vòng sửa: cache app/build chỉ đọc làm Flutter/Gradle không xóa unit_test_assets/packaged_res. Xác minh đường tuyệt đối dưới app/build, không reparse rồi gỡ ReadOnly riêng cache, không đụng source/SDK. Test đầu bắt lỗi await hàm void và timer phát sinh từ stop dù chưa có request; sửa bridge chỉ stop khi có request. Test lifecycle lần hai dùng chuỗi paused→resumed không hợp lệ và kiểm frame khi app paused; sửa test đi inactive→hidden→paused→hidden→inactive→resumed, xác minh stop ngay khi background và hình sau resume. Lượt cuối 18 PASS. Native test hai ca PASS nhưng chỉ có callback error/fallback, giữ verifying cho playback thực.
