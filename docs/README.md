# MindClock — nguồn chuẩn để làm sản phẩm

**Bắt đầu tại đây.** Bộ docs này dành cho việc xây **sản phẩm Android Flutter + Kotlin native, FastAPI + PostgreSQL** cho người dùng thật, không theo lịch hay kịch bản cuộc thi. Hành trình chính: tài khoản → lớp/môn/avatar → plan xác nhận → dashboard → lịch/báo thức → ôn bài → phòng học → cộng đồng/game. Trang web `/demo` và `/product` trong API là WIP nội bộ. [Hiện trạng có bằng chứng](00-start/01-hien-trang.md) phân biệt có mã với đã test/phát hành.

## Thứ tự đọc một lần cho thành viên/AI mới

1. [Hiện trạng](00-start/01-hien-trang.md): phần nào có mã, phần nào chưa qua máy thật/DB/AI eval.
2. [Lộ trình](00-start/02-lo-trinh.md), [gói task đầu tiên](00-start/05-goi-task-dau-tien.md) và [quyết định còn mở](00-start/06-quyet-dinh-va-gia-dinh.md).
3. [Quy trình vibe coding](00-start/03-quy-trinh-vibe-code.md), [quy tắc skill](00-start/07-quy-tac-skills-va-ai-agent.md) và [AGENTS.md](../AGENTS.md): tạo task, AC ↔ test, vòng sửa, bàn giao.
4. [PRD](01-product/01-prd.md) và [ma trận truy vết](03-quality/03-truy-vet-yeu-cau.md): hành vi cần đạt và test.
5. Chỉ đọc tài liệu chuyên môn đúng task ở bảng dưới; **không cần đọc 58 file archive**.

## Bản đồ nguồn chuẩn

| Khi làm | Nguồn hành vi/thiết kế | Contract/kỹ thuật | Test/cổng |
| --- | --- | --- | --- |
| Onboarding → dashboard | [PRD](01-product/01-prd.md), [journey/UX](01-product/02-hanh-trinh-ux.md), [đăng ký/lộ trình](01-product/07-dang-ky-va-khoi-tao-lo-trinh.md), [design](01-product/03-he-thiet-ke.md) | [Catalog/planner](02-engineering/10-catalog-chuong-trinh-va-ke-hoach.md), [API](02-engineering/04-hop-dong-api.md) | ON/UX/AUTH ở [ca nghiệm thu](03-quality/05-ca-nghiem-thu.md) |
| Giấc ngủ, alarm, câu | [Lịch ngủ/báo thức](01-product/09-giac-ngu-va-bao-thuc.md), [cảnh và nguồn video](01-product/11-canh-mo-man-va-nguon-video.md), [UX](01-product/02-hanh-trinh-ux.md) | [Alarm Android](02-engineering/02-bao-thuc-android.md), [câu](02-engineering/05-ngan-hang-cau-hoi.md) | AD/SLEEP/MORNING/MEDIA/LEARN ở [test plan](03-quality/01-ke-hoach-kiem-thu.md) |
| Lịch học, nhắc việc, hồ sơ | [Kế hoạch ngày](01-product/05-lich-hoc-nhac-viec.md), [hồ sơ/xã hội](01-product/06-ho-so-tien-do-xa-hoi.md) | [SQL](02-engineering/03-du-lieu-sql.md), [mobile↔API](02-engineering/08-tich-hop-mobile-api.md) | PLAN/PROFILE ở [ca nghiệm thu](03-quality/05-ca-nghiem-thu.md) |
| Tài khoản/riêng tư | [Account/consent](01-product/04-tai-khoan-quyen-rieng-tu.md) | [SQL](02-engineering/03-du-lieu-sql.md), [API](02-engineering/04-hop-dong-api.md) | AUTH/DATA + [release](03-quality/02-van-hanh-phat-hanh.md) |
| Backend/tích hợp | [PRD](01-product/01-prd.md) | [Kiến trúc](02-engineering/01-kien-truc.md), [repo](00-start/04-cau-truc-repo.md), [SQL](02-engineering/03-du-lieu-sql.md), [API](02-engineering/04-hop-dong-api.md), [mobile↔API](02-engineering/08-tich-hop-mobile-api.md) | Contract/DB/CI ở [quality](03-quality/01-ke-hoach-kiem-thu.md), [runbook](03-quality/04-moi-truong-chay-thu.md) |
| AI và nội dung | [Ngân hàng câu](02-engineering/05-ngan-hang-cau-hoi.md) | [EduSkills-VN adapter](02-engineering/11-eduskills-vn-tich-hop.md), [AI/chấm](02-engineering/06-ai-va-cham-bai.md) | CONTENT/EDU/AI eval ở [quality](03-quality/01-ke-hoach-kiem-thu.md) |
| Phòng học một mình/AI/bạn | [Hành vi phòng](01-product/08-phong-hoc-ai-va-ban-be.md), [UX](01-product/02-hanh-trinh-ux.md) | [Học local](02-engineering/07-khong-gian-hoc.md), [realtime](02-engineering/09-phong-hoc-realtime.md) | FOCUS/ROOM + lifecycle/2 máy/quota |
| MultiCal, ghép phòng, pet nhóm | [Lịch chung và nhóm](01-product/12-lich-chung-ghep-phong-va-pet-nhom.md) | [Ghép phòng/ledger](02-engineering/12-lich-chung-va-ghep-phong.md), [SQL](02-engineering/03-du-lieu-sql.md) | GROUP-01–08, PostgreSQL/2–4 máy/privacy |
| Động lực và thử người dùng | [Vòng giá trị và thí nghiệm](01-product/10-dong-luc-va-kiem-chung.md) | [Quyền dữ liệu](01-product/04-tai-khoan-quyen-rieng-tu.md) | Khó chịu, bỏ dùng, ngủ, consent trước mở rộng |
| PvP, nhân vật, rank | [GDD thử nghiệm](04-game/01-pvp-gdd.md), [asset](04-game/02-nhan-vat-asset.md), [rank/mùa/coin](04-game/03-rank-mua-va-kinh-te.md) | [API](02-engineering/04-hop-dong-api.md) chỉ mở task sau cổng | Hai máy/playtest/quyền trước ranked |
| Pilot/release/iOS | [Lộ trình](00-start/02-lo-trinh.md) | [Vận hành](03-quality/02-van-hanh-phat-hanh.md), [iOS sau](05-future/01-ios.md) | Máy thật, PostgreSQL, privacy, rollback |

## Cấu trúc docs

```text
docs/
├─ README.md                  điều hướng và quyền ưu tiên
├─ 00-start/                 hiện trạng, roadmap, workflow, task đầu, quyết định, skill
├─ 01-product/               PRD, UX, design, tài khoản, lịch, hồ sơ, phòng học, ngủ, cảnh, lịch nhóm
├─ 02-engineering/           kiến trúc, alarm, SQL, API, câu, AI, học, realtime, catalog, EduSkills, ghép phòng
├─ 03-quality/               test, nghiệm thu, môi trường, release, truy vết
├─ 04-game/                  PvP v0.1, art/asset, rank/mùa/coin thử nghiệm
├─ 05-future/                iOS và các nhánh chưa mở
└─ archive/2026-11/          58 tài liệu đánh số cũ, chỉ để truy nguồn
```

**Thứ tự ưu tiên khi mâu thuẫn:** yêu cầu người dùng hiện tại → `AGENTS.md`/quy tắc an toàn → docs canonical tại đây (PRD cho hành vi, API cho giao tiếp, SQL cho lưu trữ, test/release cho cổng) → spec task hiện hành → code thực. Nếu docs và code khác nhau, **không chọn ngầm**: ghi quyết định trong task và sửa docs + code + contract test cùng lần. [Archive](archive/README.md) không là nguồn coding.

## Trạng thái và quy tắc cập nhật

Docs mô tả **đích và điều kiện đạt**, không tự chứng minh app chạy. Mỗi task có `tasks/TNNN-...` với README/spec/plan/tests/worklog/handoff trước code, test thực sau code. Khi một AC/route/migration thay đổi, cập nhật mọi tài liệu và test liên quan trong cùng PR. Không thêm tài liệu đánh số ở root, không tạo web client thay Android, không công bố corpus/asset chưa có quyền. Chạy `python scripts/check_docs_links.py` và `python scripts/check_task_records.py` trước bàn giao.
