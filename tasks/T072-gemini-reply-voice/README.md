# T072 — Giọng Gemini cho câu trả lời trợ lý

**Trạng thái:** `verifying`
Nguồn: yêu cầu tiếp tục hoàn thiện voice ngày 21/11/2026; T071 offline chưa có playback thành công.
source_refs: docs/01-product/08-phong-hoc-ai-va-ban-be.md ROOM-07/11; docs/02-engineering/09-phong-hoc-realtime.md; docs/02-engineering/04-hop-dong-api.md; AGENTS.md.

Phạm vi: đọc câu trả lời qua Gemini TTS server, phát WAV native và callback avatar; lựa chọn voice cloud có consent rõ. Không gọi là Gemini Live/full-duplex, không tự bật mic/cam hoặc đổi timer/XP.
