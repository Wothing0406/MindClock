# Bàn giao

Trạng thái verifying cho Git. Đã có art gốc tạo thực bằng image_gen built-in, lựa chọn sau trợ lý xem hình; user có thể phản hồi thay thiết kế.

Assets: assets/companions/{pet-mam,mindclock-ai,environment}/source và runtime; 19WebP256px alpha + nền960×640, source/prompt/hash/QA và contact sheet, WebP preview chớp/miệng; ZIP dist/mindclock-companions-v1.zip. App copies app/assets/companions. Asset runtime tổng777138bytes. Pet4stage+6reaction là ảnh tĩnh, không video full-body; AI9expression có blink/miệngframeUI, không lip sync âm vị. Giữ mọi WARN/FAIL nguồn (v1 đã loại) ở qa-report.md.

Code: avatar renderer mới + MamPetView, nối art/nền vào màn AI; Reduce Motion/ticker tắt giữ tĩnh, speaking không còn suy từ chat history. Mic/cam/Live/EXP/pet ledger không thay đổi. Giữ nguyên art tướng/game WIP.

Kiểm: 19tile/hash/alpha/app copies/previews PASS, 7asset tests PASS, 21regression tests PASS ở lượt trước bổ sung2assetcases. Analyze/links/task checks xem tests.md. Chưa APK mới/máy thật/FPS hoặc tích hợp voice playback thực. Điểm tiếp: người dùng review thiết kế; nếu giữ master thì motion full-body bằng video2dsprite khi có video route, nối group/pet ledger/share sau kiểm ngày chăm. Không giả art là bằng chứng đã có nuôi pet online.

Chưa commit/push; sẽ stage riêng art/avatar và3 dòng pubspec companions, không gộp game/asset/key WIP khác.
