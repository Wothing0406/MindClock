# MindClock — baseline để làm ứng dụng thật

**Ngày chốt lại: 15/11/2026.** Tài liệu này là điểm vào cho mọi task sản phẩm mới. Nó cập nhật **trạng thái mã hiện có**, không thay luật nghiệp vụ ở [PRD](04-prd-va-dac-ta-san-pham.md), [kiến trúc](06-kien-truc-va-du-lieu.md), [API](07-hop-dong-api-va-ai.md), [SQL](28-backend-sql.md) hay [an toàn dữ liệu](25-bao-mat-va-du-lieu.md). Khi một tài liệu cũ ghi “repo chưa có app/backend” hoặc hướng AI làm web demo, dùng trạng thái và thứ tự ở đây.

## 1. Sản phẩm cần đạt

MindClock là **ứng dụng Android Flutter**, với phần báo thức chạy bằng Android native, và **FastAPI + PostgreSQL** cho tài khoản, câu hỏi, chấm và tiến độ. Người dùng phải có thể đặt báo thức và Dừng khẩn cấp khi không có mạng/đăng nhập. Sau khi dậy, họ có thể làm câu phù hợp lịch học, nhập đáp án và trình bày; AI chỉ hỗ trợ đọc/chấm/gợi mở, backend chốt kết quả. Không gian học có timer local. PvP/rank là phần mở rộng sau khi luồng cá nhân ổn định.

**Không lấy trang HTML `/demo` hoặc `/product` làm đầu ra sản phẩm.** Chúng là thử nghiệm giao diện cũ, đang có thay đổi chưa hoàn tất tại T022/T023; không chứng minh báo thức Android, đóng gói APK, dữ liệu nhiều người hay AI đáng tin cậy. Từ task tiếp theo, UI sản phẩm làm trong `app/lib/`; API nghiệp vụ ở `services/api/app/routes/v1.py` và tầng service/repository. Không tạo thêm web client trùng chức năng Android nếu task không yêu cầu rõ.

## 2. Kiểm kê hiện trạng và mức tin cậy

| Mảng | Mã hiện có | Điều đã xác minh / còn thiếu |
| --- | --- | --- |
| Flutter Android | `app/lib/` có luồng khách, hồ sơ học tập, lịch, báo thức, luyện tập, không gian học; `app/android/` có Kotlin alarm/camera/focus bridge | **Có mã**, chưa có bằng chứng build và vòng báo thức AD01–AD09 trên máy Android thật trong repo; các task T014–T021 ghi nhiều test Flutter bị chặn bởi môi trường Windows. |
| Backend | `services/api/` có FastAPI `/v1`, SQLAlchemy/Alembic, seed câu, auth gateway, Gemini gateway, test Python | **Có mã**; các test API local từng được ghi đạt ở T021. Cần chạy lại trong CI, PostgreSQL thật, Firebase project thật, đo AI và kiểm quyền trước pilot. `create_all()` chỉ chạy dev/test/local; production phải dùng migration. |
| AI | Endpoint gợi ý/chấm ảnh/câu cá nhân hóa/Live token đã viết | Có code và một số smoke local theo T021; chưa có đánh giá sai/chưa chắc trên bộ bài được phép dùng, ngân sách và consent phù hợp. Không gọi một phản hồi model là kiểm chứng sư phạm. |
| Sân đấu/game | `assets/game/` chứa art, FX, âm, map, avatar/rank từ prototype | **Chưa có trận online, backend authoritative, playtest cân bằng hoặc quyền phát hành art**. Không đóng gói asset/game vào bản Android P0. |
| Web cũ | FastAPI còn route `/demo`, `/product` từ T022/T023 | Chỉ dùng nội bộ nếu cần tham chiếu. Trước release, tắt route này ở production hoặc bỏ hẳn, có test không truy cập được. |

Đọc `tasks/T014`–`T023` để biết bằng chứng lịch sử; **chạy lại** test hiện hành trước khi nâng trạng thái. Trạng thái `blocked` trong task cũ không được tự chuyển thành `done` chỉ vì thư mục mã tồn tại.

## 3. Lát cắt triển khai theo phụ thuộc

| Lát cắt | Việc người dùng thật làm được | AC để kết thúc | Test bắt buộc |
| --- | --- | --- | --- |
| P0.0 — build và môi trường | Cài APK debug, mở app trên Android mục tiêu; API local chạy từ cấu hình mẫu, không lộ khóa | Build lặp lại được trên máy đội và CI; môi trường dev/staging/prod tách; `/v1/health` và migration trống đạt | `flutter analyze`, `flutter test`, Gradle unit, `pytest`, Alembic upgrade trên PostgreSQL, scan secret; ghi version thiết bị/SDK. |
| P0.1 — đồng hồ tin cậy | Đặt/sửa/hủy chuông, chọn âm/rung/chế độ; khi reo có Dừng khẩn cấp ngay | Chuông hoạt động khi app đóng, màn khóa, offline, reboot/đổi giờ/quyền bị thu hồi; UI chỉ báo “Đã sẵn sàng” sau xác nhận OS; thử thách không Hoãn | Ma trận AD01–AD09 ở [47](47-demo-android-va-moi-truong-kiem-thu.md) trên ít nhất hai máy thật/phiên bản Android khác nhau; test âm lượng và fallback. Lỗi P0 ở dừng chuông chặn release. |
| P0.2 — học buổi sáng | Cấu hình lớp/môn/tổ hợp, TKB và câu đã duyệt; nhập đáp án + một bước trình bày bằng chữ, camera tùy chọn | Offline có câu dự phòng và hoàn thành không chấm; câu có revision/rubric; `uncertain` không phạt; bài sai có đường thử lại; ảnh không lưu mặc định | Widget/integration test luồng khách, mất mạng, quyền camera từ chối; test schema câu và reviewer; Android E2E chuông → câu → dừng. |
| P0.3 — tài khoản và đồng bộ | Đăng nhập, đồng bộ lịch và tiến độ trên hai máy; xóa tài khoản | Token Firebase được backend xác minh, không truy cập chéo A/B, idempotency phiên/attempt/XP, xung đột revision rõ, xóa dữ liệu theo chính sách | Contract/API test, PostgreSQL transaction/migration, test A/B, duplicate/retry/offline queue, xóa/thu hồi consent. |
| P0.4 — AI có kiểm soát | Gửi bài sau xác nhận, nhận correct/incorrect/uncertain và gợi ý Socratic | Model không cấp XP/rank, không log ảnh/token, timeout có fallback, key server-side, chỉ dùng câu được duyệt | Bộ đánh giá độc lập theo [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md): chữ rõ/mờ/ảnh sai/bài nhiều cách/prompt injection; đo độ trễ và chi phí. Không mở nếu false-correct/false-incorrect chưa đạt ngưỡng do đội chốt. |
| P1 — không gian học | Timer local, task hôm nay, hỏi gợi ý theo lượt; rời app không mất phiên | Dùng được offline; camera/mic mặc định tắt; không hứa khóa app khác; đồng bộ phiên không chặn kết thúc | Lifecycle/background/kill/restart, quyền bị từ chối, token budget, UI TalkBack/chữ lớn. |
| P2 — giao hữu | Hai người cùng môn/lớp/chương trình, cùng một câu/rubric; thử ba nhân vật | Server chốt thời gian, event, HP/giáp và kết quả; reconnect/idempotency; không dùng giờ dậy trong rating | Test hai thiết bị, mất mạng/reconnect, duplicate action, công bằng câu/chấm và cân bằng theo [46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md). |
| P3 — ranked/kinh tế | Chọn tham gia, xem rank/bảng/hồ sơ | Qua cổng chất lượng học tập, chống farm, quyền trẻ em, moderation, playtest; không bán sức mạnh | Ledger transaction, season reset, kháng nghị, access control, tải lớn, kiểm UX học sinh. iOS là nhánh riêng sau Android. |

**Thứ tự làm ngay:** P0.0 → P0.1. Sau khi chuông ổn, P0.2 có thể phát triển song song phần nội dung nhưng không gọi hoàn thành trước Android E2E. Tách backlog thành task dọc từng lát cắt; một task không nên đồng thời “làm hết UI + AI + PvP”.

## 4. Định nghĩa “có thể dùng thật” và cổng release

1. Người thử cài APK từ quy trình CI và dùng 7 ngày; ghi số lần chuông dự kiến/chuông thực, Dừng khẩn cấp, lỗi và cách khôi phục. Nếu OS/OEM chặn báo thức, app nói rõ trạng thái và hướng xử lý.
2. Không có kết quả “đúng/sai” thiếu rubric/nguồn được duyệt; bài không chắc là `uncertain` hoặc hoàn thành không chấm. Không phạt vì sai, offline, hoãn thường hay dừng khẩn cấp.
3. PostgreSQL staging chạy migration/rollback và backup/restore thử; API có auth A/B, rate limit, timeout, idempotency, logging không chứa bài/ảnh/token, monitoring lỗi/tỉ lệ thành công. Không dùng SQLite làm production nhiều người.
4. Chính sách riêng tư/đồng ý cho học sinh, đường xuất/xóa dữ liệu, hạn lưu, quyền avatar/nội dung và xử lý khiếu nại được rà trước pilot. Chỉ thu dữ liệu cần cho chức năng.
5. Test accessibility, màn nhỏ/chữ lớn, offline/quyền bị từ chối, pin/OEM và máy yếu; đo thời gian mở app, thời gian tới câu, độ trễ chấm, dung lượng APK. Ghi số đo thay vì đoán.
6. Bản build release có signing, cấu hình môi trường, migration, rollback, changelog và người chịu trách nhiệm xử lý sự cố. Web route nội bộ không được mount ở production.

**Sản phẩm chưa đạt các cổng này ở thời điểm viết.** Tài liệu là kế hoạch kiểm chứng, không phải chứng nhận production.

## 5. Cách giao AI coding một task

Mỗi task bắt đầu từ [cấu trúc repo](57-cau-truc-repo-production.md) và nguồn chuẩn tính năng; tạo `tasks/TNNN-.../{README,spec,plan,tests,worklog,handoff}.md` trước code. Spec có AC theo hành vi người dùng và trường hợp offline/lỗi; tests gắn từng AC. AI sửa **Flutter/Kotlin hoặc FastAPI tương ứng**, không tự làm một web thay thế; ghi bằng chứng lệnh, thiết bị và test chưa đạt. Sau mỗi lát cắt kiểm lại API/schema/docs nếu hợp đồng đổi. Chỉ báo `done` khi test bắt buộc đạt; nếu bị chặn, bàn giao lệnh/bước tiếp tục cụ thể.
