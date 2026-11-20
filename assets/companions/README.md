# MindClock — pet Mầm và AI mentor v1

Art gốc tạo bằng **image_gen built-in**, không lấy nhân vật thương mại hay ảnh người thật. Model ID và chi phí không được tool trả, không tự ghi đoán. Nguồn PNG đầy đủ + prompt/provenance giữ trong repo; các file WebP app đã tối ưu riêng. Đây là bản lựa chọn sau rà hình của trợ lý, còn có thể sửa theo phản hồi người dùng.

## Gói đã có

- `pet-mam/source/`: master, atlas 4 giai đoạn, reaction v1 bị loại và v2 đã sửa khoảng cách. `runtime/`: stage-1…4, idle/happy/sleep/snack/reading/celebrate. Các pose pet là **ảnh tĩnh**; chưa có video/chu kỳ đi/ăn/nâng cấp toàn thân.
- `mindclock-ai/source/`: master và atlas 9 biểu cảm UI. `runtime/`: neutral/blink/listening/thinking/encouraging/focused + 3 mức mở miệng. Các biểu cảm dùng cùng nhân vật, không trộn khuôn mặt hoặc art game.
- `environment/`: nền góc học không có người/mascot, có khoảng trống giữa để compositing.
- `review/`: contact sheet trên nền sáng/tối, preview WebP chớp mắt và nhịp miệng. Preview nói là vòng minh họa chuyển frame, không phải cuộc gọi hay tiếng nói đang chạy.
- `manifest.json`: nguồn/hash, file runtime/app, state map và giới hạn. [QA](qa-report.md) giữ cả cảnh báo nguồn và bản bị loại, không gọi tất cả check nguồn đều sạch.

19 tile RGBA 256×256 + nền 960×640: tổng 777.138 byte (~759 KiB); source/preview không đóng gói vào APK. Giữ nguyên canvas/BoxFit.contain, không crop từng frame bằng BoxFit.cover hoặc căn theo bbox lại lúc runtime. Các giai đoạn pet dùng shared scale để giai đoạn nhỏ vẫn nhỏ; phản ứng riêng có framing khác và không nối thành animation liên tục.

## Trong Flutter

`MindClockAiAnimatedAvatar` đã thay painter mặt tròn bằng file art. Nghỉ có blink 120ms mỗi 4 giây, nói có 3 mức mở miệng; có audioLevel thì theo mức âm thực, nếu chưa có mức âm chỉ dùng nhịp generic 140ms khi caller báo isSpeaking. Không phải lip sync theo âm vị. Reduce Motion/animate=false/TickerMode tắt đều ngừng chuyển frame. Trả lời chữ không bật isSpeaking; không biến chat history thành cử động nói. Học sâu dùng ảnh tĩnh. Có nhãn MindClock AI rõ.

`MamPetView` chỉ vẽ stage/reaction được truyền vào; không tự tính level/EXP/chuỗi hoặc mở pet ngoài UI nhóm. Hệ thống nhóm/care ledger/share vẫn chưa triển khai. Không thay avatar hồ sơ hoặc tướng chiến đấu bằng pet.

## Tái tạo đóng gói

Các lệnh dùng công cụ sprite có trong `.agents/skills` của dự án; image generation không phải bước Python này. Khi tạo lại ảnh phải dùng image_gen và lưu non-destructive, không vẽ lại nhân vật bằng code.

```powershell
python .agents/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/companions/mindclock-ai/source/expressions.png --target asset --mode sheet --rows 3 --cols 3 --grid-rounding nearest --background-mode native_alpha --cell-size 512 --fit-scale 0.82 --align feet --anchor-mode stance --component-mode all --resampler lanczos --output-dir assets/companions/mindclock-ai/processed/expressions --strict-qc --max-body-scale-cv 0.08
python .agents/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/companions/pet-mam/source/stages.png --target creature --mode evolution --rows 2 --cols 2 --background-mode native_alpha --cell-size 512 --fit-scale 0.82 --align feet --anchor-mode stance --shared-scale --component-mode all --resampler lanczos --output-dir assets/companions/pet-mam/processed/stages --strict-qc
python .agents/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/companions/pet-mam/source/reactions-v2.png --target asset --mode sheet --rows 2 --cols 3 --grid-rounding nearest --background-mode native_alpha --cell-size 512 --fit-scale 0.82 --align feet --anchor-mode stance --component-mode all --resampler lanczos --output-dir assets/companions/pet-mam/processed/reactions-v2 --strict-qc
python scripts/package_companion_assets.py
python scripts/check_companion_assets.py
```

Tool process từ chối ghi đè output đã tồn tại: tái tạo vào folder mới khi thay nguồn, không xóa master đang dùng. `processed/` là cache local, không commit. Raw reaction v1 vượt biên nên không dùng. Không phát `processed/animation.gif` như motion hoàn chỉnh: đó chỉ là preview mặc định của tool lướt qua các ảnh tĩnh.

Archive để lấy file: `dist/mindclock-companions-v1.zip` (local build artifact, không commit). Android/WebRTC/Gemini Live/audio playback thực chưa được kiểm bởi gói art này.
