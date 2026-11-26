# Nhật ký
- Mobile: chuyển sang asset riêng và 4 màn scoped web. Sửa alarm POST trùng thành POST idempotent rồi PATCH; bổ sung metadata queue cho finish offline; kiểm Node handlers/retry/restore và pytest asset. Không chỉnh demo_ui.py đang có thay đổi ngoài task.
- Vòng AI: HTTP200 fallback -> gọi upstream trực tiếp chỉ in loại exception -> ImportError -> xác nhận thiếu socksio -> cài socksio 1.0.0 và thêm extra httpx[socks]. Không log secret; kiểm live tiếp theo còn phụ thuộc mạng/model.
- 14/11: tạo file UI/route riêng để tránh chỉnh chồng T022.
- Tái hiện AI HTTP200 nhưng trả hướng dẫn dự phòng; UI sửa nhận safety_status/model offline, không coi là live; Node VM test pass.
- Một lệnh shell chỉnh HTML lỗi quoting, chưa sửa file; chuyển script Python và test lại pass.
- CUA bị URL guard dừng, không vượt guard; API/logic kiểm qua TestClient/Node, không thay browser QA.
