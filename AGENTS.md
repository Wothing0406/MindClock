# MindClock — quy tắc AI coding trong repo

## 1. Bắt đầu đúng nguồn

Đọc [docs/README.md](docs/README.md), [hiện trạng](docs/00-start/01-hien-trang.md), [lộ trình](docs/00-start/02-lo-trinh.md) và [quy trình](docs/00-start/03-quy-trinh-vibe-code.md). Sau đó **chỉ đọc docs theo task** ở ma trận trong index. `docs/archive/` giữ lịch sử, không là nguồn coding. Mã thật: `app/` Flutter Android + Kotlin native, `services/api/` FastAPI/PostgreSQL, `assets/game/` art nghiên cứu. Có mã không đồng nghĩa đã build/test/release.

**Một sản phẩm:** Android Flutter là client phát hành đầu tiên. Không tạo trang web `/demo`, `/product` hoặc client web mới để thay màn Flutter. Hai route web trong API là WIP T022/T023, không là sản phẩm; trước release phải tắt/bỏ ở production và có test. iOS là nhánh sau Android P0.

## 2. Nguồn thẩm quyền

Yêu cầu người dùng hiện tại → quy tắc an toàn này → docs canonical (PRD cho hành vi, API cho giao tiếp, SQL cho lưu trữ, quality cho điều kiện release) → spec task hiện hành → code. Khi docs/code mâu thuẫn, ghi quyết định trong task và sửa docs/code/test cùng lần. Không tự lấy kit/HP, model ID, web prototype hoặc trạng thái “chưa có app” trong archive làm chuẩn. [Truy vết AC](docs/03-quality/03-truy-vet-yeu-cau.md).

## 3. Bất biến sản phẩm và dữ liệu

- Báo thức, Hoãn **chỉ mode thường**, Dừng khẩn cấp một chạm chạy local kể cả offline/API/token lỗi/app chưa mở UI. Mode thử thách **không Hoãn**; gợi ý chỉ từ lần `incorrect` rõ thứ 3; `uncertain` không tính sai. Không khóa điện thoại/app khác, cản gỡ app hay hứa OS tự mở khóa. UI chỉ báo đã lập lịch khi Android xác nhận. [Alarm](docs/02-engineering/02-bao-thuc-android.md).
- Câu MVP đến từ ngân hàng đã duyệt có rubric/revision/quyền. Gemini chỉ đề xuất đọc/chấm/gợi ý; backend quyết định `correct|incorrect|uncertain`, XP/tiến độ. AI không quyết gian lận, streak, HP/rank/coin. Sai/không chắc/dừng khẩn cấp không bị phạt. Không gửi key Gemini tới client. [Content](docs/02-engineering/05-ngan-hang-cau-hoi.md), [AI](docs/02-engineering/06-ai-va-cham-bai.md).
- Không nạp/công bố corpus hay ảnh bên thứ ba chỉ vì repo công khai. `data/sources/registry.json` là metadata; raw nghiên cứu gitignored. Art ở `assets/game/` chưa được duyệt quyền thương mại/đóng gói release.
- Không lưu ảnh bài làm mặc định, không log ảnh/token/lời giải cá nhân. Firebase ID token được backend xác minh; owner từ token, quyền API/SQL deny-all, test A/B. Client không ghi điểm có thẩm quyền. Session/attempt/XP có idempotency/transaction; PostgreSQL là nguồn online, SQLite chỉ local. [Privacy](docs/01-product/04-tai-khoan-quyen-rieng-tu.md), [SQL](docs/02-engineering/03-du-lieu-sql.md).
- UI `vi-VN`, chữ ngắn rõ chức năng, icon vector; không emoji hệ thống, khẩu hiệu/phóng đại hoặc mắng người học trong màn thường. Có đường nhập chữ thay camera, TalkBack/chữ lớn/Reduce Motion. [Design](docs/01-product/03-he-thiet-ke.md).
- PvP tự nguyện, cùng câu/rubric/chương trình; server chốt HP/event/result/rating, không dùng giờ dậy để xếp hạng. Giao hữu trước ranked, không bán sức mạnh, không mở ranked khi chấm/cân bằng/quyền chưa đạt. [Game](docs/04-game/01-pvp-gdd.md).
- Không tuyên bố đã chạy production từ mock, storyboard, video, test file hoặc response mẫu. Emulator không thay kiểm Android thật; SQLite không thay PostgreSQL; một ảnh AI không thay evaluation. [Test](docs/03-quality/01-ke-hoach-kiem-thu.md).

## 4. Quy trình bắt buộc khi thay code/config/UI/data

1. Đọc [tasks/README.md](tasks/README.md), task liên quan và `handoff.md`/worklog/test còn thiếu. Tạo hoặc tiếp tục `tasks/TNNN-ten-ngan/` từ `_template/` **trước sửa**; điền README, spec, plan, tests với AC ↔ TC và source refs. Docs-only/đọc-only không bắt buộc folder, trừ khi người dùng yêu cầu lưu tiến độ.
2. Làm một lát cắt dọc theo [roadmap](docs/00-start/02-lo-trinh.md), ưu tiên R0/R1. Không gộp alarm, UI, AI, PvP trong một task. Giữ hợp đồng API/state, sửa docs + contract tests khi đổi. Test theo rủi ro: OS/permission, A/B, uncertain, XP trùng, migration, offline.
3. Sau mỗi lát: cập nhật plan, chạy test phù hợp, ghi kết quả thực trong `tests.md`. Lỗi lặp: tái hiện → nguyên nhân → sửa → test lại ở `worklog.md`; sau ba vòng không tiến bộ, ghi giả thuyết và điểm cần quyết định, tiếp tục phần độc lập.
4. Trước bàn giao: rà diff/secret/dữ liệu/asset, chạy `python scripts/check_docs_links.py`, `python scripts/check_task_records.py` và test code liên quan. Điền `handoff.md` với trạng thái, thay đổi, test/ngày/môi trường, rủi ro, **điểm tiếp tục chính xác**. Không gắn `done` nếu AC/test bắt buộc chưa đạt. [Mẫu](docs/00-start/03-quy-trinh-vibe-code.md).

## 5. Skill và ranh giới nền tảng

Khi code Kotlin/Manifest/MethodChannel/quyền/báo thức/vòng đời Android, đọc `.agents/skills/mindclock-android-native/SKILL.md`; Flutter UI/test dùng skill Flutter phù hợp nếu hiện có, đối chiếu docs chính thức và mã repo. Skill không là package runtime, không tự thêm Hilt/Compose/Flutter Driver extension. iOS cần Mac/Xcode/iPhone và task riêng; không mô tả AlarmKit như cách khóa nút Dừng OS. [iOS](docs/05-future/01-ios.md).
