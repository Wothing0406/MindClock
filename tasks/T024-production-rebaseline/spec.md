# Đặc tả T024

## Vấn đề và kết quả

Repo lẫn bản xem thử web với app Android thật. README/docs cũ nói chưa có Flutter/API dù mã đã tồn tại. Hai thư mục `demo/` và `demo_video/` làm AI tiếp tục ưu tiên web; người dùng muốn loại bỏ và có cấu trúc cùng kế hoạch làm sản phẩm thật.

## Phạm vi và quyết định

- Xóa `demo/` và `demo_video/` ở gốc repo theo yêu cầu. Chuyển `demo/assets/game/` thành `assets/game/` trước khi xóa để giữ master/sprite/FX/audio/map/avatar/rank; không nhập asset này vào Flutter runtime cho tới khi có quyền phát hành và task tích hợp.
- Web `/demo` và `/product` trong FastAPI vẫn là mã thử nghiệm riêng đang có thay đổi chưa commit bởi T022/T023; không sửa/ghi đè chúng trong task này. Không gọi chúng là sản phẩm.
- Giữ `app/` làm Android Flutter, `services/api/` làm API, `assets/` làm nguồn art, `data/` cho nội dung, `scripts/` cho công cụ, `docs/` cho nguồn chuẩn, `tasks/` cho bằng chứng.
- Tài liệu cũ là lịch sử thiết kế; tài liệu rebaseline mới nêu trạng thái thực và ưu tiên khi mâu thuẫn. Không tự tuyên bố báo thức/AI/online đã đạt production.
- `demo_video/` là thư mục untracked 12,9 MB gồm video và project dựng; xóa theo yêu cầu, không đưa lên Git. File âm thanh gốc ở `mp3/` là đầu vào đang dùng bởi T020, ngoài phạm vi xóa.

## Điều kiện nghiệm thu

| ID | Điều kiện | Kết quả cần có | Test |
| --- | --- | --- | --- |
| AC-01 | Sau tái cấu trúc | Gốc repo không còn `demo/`, `demo_video/`; tài sản game nằm ở `assets/game/`, manifest và script build/check dùng đường dẫn mới | TC-01 |
| AC-02 | Người/AI mở repo | README, docs index và AGENTS chỉ đúng entrypoint Android/API, trạng thái thực và backlog; web local không được mô tả là product | TC-02 |
| AC-03 | Bắt đầu task coding tiếp theo | Có lộ trình production theo lát cắt, phụ thuộc, AC/test/cổng release và quy tắc cấu trúc rõ ràng | TC-03 |
| AC-04 | Mã đang làm dở | Không làm mất các thay đổi chưa commit ở `services/api`, `app`, `docs/54-web-mobile-local.md`, T022/T023 | TC-04 |

## Hợp đồng/biên

Không đổi API/schema hoặc alarm behavior. Chỉ đổi đường dẫn script asset và xóa prototype web tĩnh cũ. Test lịch sử trỏ `demo/` được giữ như bằng chứng lịch sử, không coi là test production. Tài sản art chưa được nhập vào APK; quyền thương mại cần kiểm riêng.
