# Đặc tả kỹ thuật T061

1. **AC-01 (Cổng quyền & Đóng gói 6 Avatar + Sprite nhiều frame):** Trước khi đóng gói từ `assets/game/`, ghi rõ văn bản xác nhận quyền đóng gói của chủ dự án; cập nhật 6 avatar mặc định và `ArenaSpriteStage` phát chuỗi frame `f00..fNN` đúng `root_px/facing` kèm FX/SFX & fallback Reduce Motion.
2. **AC-02 (Luật trả lời câu -> Đánh thường / Tích Qi tung Chiêu 1–2):** Trả lời đúng 1 câu mở khóa Đánh thường (`0 qi`, `28 damage`) và tích `+1 qi` (tối đa `3`); đủ `1 qi` mới kích hoạt Chiêu 1, đủ `2 qi` mới kích hoạt Chiêu 2 kèm animation đòn đánh chuẩn tướng.
3. **AC-03 (PvP 1v1 giao hữu Client–Server thật):** Kết nối `POST /v1/pvp/matchmake`, `/cancel`, `GET /v1/pvp/matches/{id}`, `/events`, `/submit`, `/action`; đồng bộ 2 người chơi thật, state HP/armor/qi từ server quyết định, xử lý `uncertain` thành `void`, 0 RP.
4. **AC-04 (Cập nhật bộ ảnh & video demo mới):** Chạy trên `emulator-5554` quay mới `test_demo_android/` phản ánh đúng bản T056–T061 (không còn màn chọn chế độ/11 môn cũ, có To-Do/Calendar/Widget/Meet/Đốt nến/Toán UI/PvP).
