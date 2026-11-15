# Cấu trúc repo và ranh giới mã

```text
MindClock/
├─ app/                      Flutter Android: lib/ui, lib/domain, lib/data, android/, test/
├─ services/api/             FastAPI: routes, services, repositories, db, auth, alembic, tests
├─ assets/game/              art nghiên cứu; chưa là tài sản APK production
├─ data/sources/             metadata nguồn câu; raw nghiên cứu không commit
├─ docs/                     nguồn chuẩn theo vòng đời; archive riêng
├─ scripts/                  kiểm docs/task/asset; không chạy trong app
├─ tasks/                    task có spec/plan/tests/worklog/handoff
├─ AGENTS.md                 quy tắc agent
└─ README.md                 điểm vào repo và lệnh phát triển
```

## Quy tắc đặt và nối mã

| Ranh giới | Nơi đặt | Không được làm |
| --- | --- | --- |
| Màn/điều hướng/chuỗi `vi-VN` | `app/lib/ui/features/<feature>/`, `ui/core/` | Gọi Gemini/SQL trực tiếp, tự cấp XP/rank, hardcode token. |
| Model và giao diện nghiệp vụ | `app/lib/domain/` | Import Flutter UI/HTTP; giấu nhánh offline. |
| HTTP, local store, camera/MethodChannel | `app/lib/data/` + `app/android/` | Dùng debug fixture ở release; tin kết quả OS khi chưa schedule thực. |
| API endpoint/validation | `services/api/app/routes/v1.py` | Nhận `userId`, XP, rating từ client như nguồn sự thật. |
| Logic/AI/DB | `services/api/app/services/`, `repositories/`, `db/`, `alembic/` | Để AI tự cấp điểm; dùng `create_all()` trên production thay migration. |
| Câu hỏi và asset | `data/sources/`, `assets/game/` | Công bố corpus/ảnh không có quyền, đóng gói art nghiên cứu vào APK mặc định. |

`services/api/app/demo_ui.py` và `product_ui.py` là web thử nghiệm đang WIP, không phải lối mở app thật. Trước release, điều kiện bắt buộc là router này không được mount trong production hoặc được xóa, và có test kiểm. Không sửa/di chuyển mã WIP khi task docs này chưa được chủ sở hữu task bàn giao.

## Convention để AI không tạo hai sản phẩm

- **Client phát hành Android:** Flutter `app/`. iOS sau này có task riêng trong cùng Flutter project nếu khả thi và phải kiểm iPhone. Không tạo `web-product/`, `demo/` hoặc một client song song chỉ để “nhìn thấy kết quả”.
- **Backend phát hành:** một API `/v1`, PostgreSQL có migration; SQLite chỉ local. Hợp đồng [API](../02-engineering/04-hop-dong-api.md) phải có contract test hai bên.
- **Art:** `assets/game/` giữ source/research. Task PvP sau này nhập tài sản đã duyệt vào `app/assets/` bằng script có manifest/version/hash và test kích thước. Không đọc path repo ở runtime.
- **Tài liệu:** [index](../README.md) quyết định nguồn; archive không là nguồn coding. Tài liệu mới phải nêu trạng thái, owner, AC/test và quyết định nếu thay luật. Không thêm tài liệu đánh số liên tục ở root.
- **Task:** một folder cho một thay đổi dọc. Không tạo một folder mỗi prompt hoặc sửa lỗi cùng task. `tasks/_template/` là mẫu; kết quả test có lệnh/ngày/môi trường.

`mp3/` ở gốc hiện là nguồn âm của T020 và đang được web WIP đọc. Chỉ di chuyển/xóa bằng task âm thanh có cập nhật mọi đường dẫn/quyền; không phá trong task docs. `START-MINDCLOCK.cmd` là launcher web WIP, không phải entrypoint release. [Hiện trạng](01-hien-trang.md) là nguồn sự thật về mức kiểm chứng.
