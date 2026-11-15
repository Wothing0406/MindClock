# Cấu trúc repo production và quy tắc đặt file

**Nguồn chuẩn cho task mới từ 15/11/2026.** [Baseline sản phẩm](56-baseline-san-pham-android.md) quyết định ưu tiên, [AGENTS](../../../AGENTS.md) quyết định quy trình agent. Tài liệu [50](50-cau-truc-du-an-va-asset-game.md) chỉ còn hợp đồng art/sprite lịch sử; không dùng cây thư mục web cũ.

```text
MindClock/
├─ app/                     ứng dụng Flutter Android duy nhất
│  ├─ lib/
│  │  ├─ ui/features/        màn + view model theo tính năng
│  │  ├─ ui/core/            theme, icon, widget, chuỗi vi-VN
│  │  ├─ domain/             model + interface nghiệp vụ, không phụ thuộc UI/HTTP
│  │  └─ data/               repository, HTTP/local store, debug fixture chỉ dev/test
│  ├─ android/               Kotlin alarm, notification, camera/focus bridge
│  ├─ test/                  unit/widget/contract
│  └─ integration_test/      hành trình trên thiết bị
├─ services/api/             FastAPI, không phải web client sản phẩm
│  ├─ app/routes/v1.py       HTTP contract
│  ├─ app/services/          điều phối nghiệp vụ/AI
│  ├─ app/repositories/      truy xuất dữ liệu/idempotency
│  ├─ app/db/                SQLAlchemy models, seed đã duyệt
│  ├─ app/auth/              xác minh token/quyền
│  ├─ alembic/               migration có phiên bản
│  └─ tests/                 API, DB, quyền, AI stub/contract
├─ assets/game/              nguồn art nghiên cứu; chưa đóng gói vào APK P0
│  ├─ characters/<slug>/     source/runtime/poses/fx/audio theo từng nhân vật
│  ├─ effects/ maps/ ui/ audio/
│  └─ manifest.json          kích thước/anchor/nguồn asset
├─ data/sources/             metadata nguồn câu; không đồng nghĩa quyền nạp corpus
├─ docs/                     nguồn chuẩn + tài liệu lịch sử ghi rõ trạng thái
├─ scripts/                  công cụ build/check asset/docs/task, không chạy trong app
├─ tasks/                    hồ sơ một thay đổi: AC, plan, test, worklog, handoff
├─ AGENTS.md                 ràng buộc AI làm việc trong repo
└─ README.md                 trạng thái thật và lệnh bắt đầu
```

## Ranh giới file và phụ thuộc

1. **Android là client sản phẩm.** Màn mới vào `app/lib/ui/features/<feature>/`; logic thuần vào `domain/`; giao tiếp native/HTTP/local vào `data/` và `app/android/`. UI không gọi trực tiếp Gemini, SQL hoặc tự ghi XP/rank. Không để một mock/fixture trong release build.
2. **FastAPI là server nghiệp vụ.** `routes` kiểm input/auth và trả contract; `services` quyết định luồng; `repositories` ghi DB; migration là cách đổi schema staging/production. Chỉ backend giữ Gemini key và chốt attempt/ledger. Web route thử nghiệm `/demo`, `/product` còn trong `services/api/app/` do WIP T022/T023; đưa ra khỏi app production trước release và kiểm bằng test cấu hình.
3. **Art là nguồn riêng.** `assets/game/` giữ master và bản runtime để không mất công sáng tác. Khi mở PvP Flutter, tạo task nhập đúng asset vào `app/assets/game/` (hoặc copy có version/hash bằng script), khai báo `pubspec.yaml`, đo dung lượng/hiệu năng. Không để app đọc ngược path repo `../../assets` lúc chạy. Kiểm quyền phát hành từng file trước đóng gói.
4. **Âm báo thức không thuộc `assets/game/audio`.** Bản Android hiện có `app/android/app/src/main/res/raw/alarm_bermuda.mp3`; file `mp3/` ở gốc là nguồn đầu vào T020 chưa hoàn tất. Task âm thanh kế tiếp phải chốt quyền/tên chuẩn rồi chuyển nguồn vào thư mục asset đầu vào phù hợp; không xóa trong lần tái cấu trúc này.
5. **Tài liệu và task không phải runtime.** Docs cũ mô tả demo/web là lịch sử, không cho AI suy ra tính năng đã chạy. Nếu đổi hợp đồng hành vi/API/schema, sửa docs chuẩn cùng code/test. Không viết thêm trang “product” HTML để thay một màn Flutter.

## Quy tắc tên và chất lượng

- Thư mục/source code tiếng Anh `snake_case` hoặc theo convention ngôn ngữ; chuỗi người dùng tiếng Việt `vi-VN` ở `app/lib/ui/core/strings/`. ID nguồn ổn định; tên hiển thị đổi được, không dùng tên nhân vật làm key DB.
- Cấu hình dev/staging/prod qua biến môi trường hoặc `dart-define`; `.env` không commit. API key chỉ server. Không hardcode URL localhost hoặc secret vào build release.
- Code generated/build cache gitignored; không thêm video render, APK, DB local hoặc corpus nghiên cứu vào Git. Asset nguồn có provenance và trạng thái quyền.
- Có test đúng tầng: Dart unit/widget/contract, Kotlin unit + máy thật, Python API/DB/migration, E2E thiết bị. Test chạy máy nào ghi máy đó; không thay “đã có test file” bằng “đã pass”.
- Root chỉ giữ entrypoint chung; không tạo `demo*`, `product*` hoặc bản UI song song. Task mới phải giải thích lý do trước khi thêm top-level folder.

## Di chuyển trong T024 và việc để task tiếp theo

- T024: bỏ `demo/` (HTML/JS cũ) và `demo_video/` (project render chưa commit), chuyển `demo/assets/game/` sang `assets/game/`; sửa đường dẫn script và docs hiện hành.
- Không ghi đè WIP T022/T023 trong API/Flutter. Task tiếp theo cần quyết định xóa web route thử nghiệm hoặc giữ dev-only và thêm test **production không mount**; `services/api/app/main.py` hiện còn include hai router.
- Chưa đổi `app/` thành `mobile/` hay `services/api/` thành `backend/`: chúng đã có mã/test/handoff, đổi tên sẽ phá import/build mà không tăng giá trị. Chuẩn nằm ở ranh giới rõ, không ở việc đổi tên cho đẹp.
