# Vận hành, phát hành và rollback

**Mục tiêu:** có thể đưa một Android build tới nhóm thử, biết bản nào chạy, dữ liệu nào được xử lý và cách dừng/khôi phục khi lỗi. Chưa có bằng chứng các cổng này đã đạt. [Test plan](01-ke-hoach-kiem-thu.md), [privacy](../01-product/04-tai-khoan-quyen-rieng-tu.md).

## 1. Môi trường

| Môi trường | App/API/DB | Quy tắc |
| --- | --- | --- |
| Local | Flutter debug, FastAPI local, SQLite có thể dùng để phát triển | `.env` local gitignored, fixture có nhãn, không dữ liệu học sinh thật. Chỉ kiểm luồng và unit. |
| CI | Build/test từ commit sạch, PostgreSQL service cho migration/API | Không có secret production; test code/contract/DB/security; tạo artifact gắn SHA. |
| Staging | Android build nội bộ, FastAPI + PostgreSQL + Firebase test project + model/config giới hạn | Dữ liệu giả/đã đồng ý; bật observability, test A/B, backup/restore và rollback. |
| Production/pilot | Build ký, HTTPS, PostgreSQL, Auth/AI theo policy đã duyệt | Feature flags, rate/quota budget, web route thử nghiệm tắt, giám sát/lịch on-call, retention/xóa có job. |

## 2. Cổng CI và merge

CI phải chạy lint/type/test Flutter, Kotlin unit, Python API/DB, Alembic migration trên PostgreSQL, docs link/task records, secret/dependency scan phù hợp; contract test khi API/schema đổi. PR mô tả AC, test thực, migration/rollback, dữ liệu/permission, màn ảnh nếu đổi UI. Không merge nếu Dừng khẩn cấp fail, key lộ, cross-account access, duplicate XP hoặc migration phá DB. Browser demo không thay Android E2E.

## 3. Release checklist

1. Khóa scope/feature flags; số build/version/commit, env, DB migration, model/prompt/content revision được ghi.
2. Test AD01–AD09 trên thiết bị mục tiêu; API PostgreSQL/Auth/AI eval theo [test plan](01-ke-hoach-kiem-thu.md); chữ lớn/TalkBack/màn hẹp; quyền bị từ chối/offline.
3. Xác minh signing, HTTPS, `debug`/local bearer fallback off, CORS chặt, `/demo` và `/product` không mount production, Gemini key chỉ server; không bundle corpus/asset không có quyền.
4. Xác minh privacy/consent/xóa/export/retention, thông báo người dùng, hỗ trợ/sự cố và chính sách độ tuổi với người phụ trách. Kiểm quyền art/audio, bản quyền câu.
5. Tạo backup trước migration, chạy migration trên staging rồi production có kế hoạch rollback; smoke `/v1/health`, đăng nhập test, alarm local độc lập. Phát hành giới hạn trước, theo dõi metrics, có nút tắt AI/PvP từ server.
6. Ghi release notes ngắn, Known Issues trung thực, người trực và điều kiện rollback.

## 4. Quan sát và chi phí

Theo dõi crash/ANR, chuông dự kiến vs sự kiện app ghi được (không suy OS đã reo từ API), tỷ lệ Dừng thành công, API status/latency, AI timeout/uncertain/cost, DB pool/migration/backup job, consent/deletion queue. Log có request ID và mã lỗi, không ảnh bài/token/đáp án cá nhân. Alert khi báo thức không dừng, lỗi 5xx tăng, AI bill vượt budget, delete job lỗi hoặc quyền dữ liệu. Mỗi model/feature có giới hạn ngày và đường tắt về text/offline.

## 5. Sự cố và rollback

- **Alarm lỗi:** dừng rollout, hướng dẫn người dùng dùng báo thức hệ thống, không giả lịch vẫn sẵn sàng; thu log/thiết bị/version và sửa/test lại AD01–07. Không tắt Dừng khẩn cấp bằng remote flag.
- **AI chấm sai/quota:** tắt chấm ảnh/AI theo feature flag, trả uncertain hoặc luyện không chấm; rà các attempt bị ảnh hưởng và bù trừ ledger có audit, thông báo khi cần.
- **Lộ key/dữ liệu:** thu hồi key/token, chặn endpoint, giữ bằng chứng kỹ thuật tối thiểu, xác định phạm vi, làm theo nghĩa vụ thông báo áp dụng, hậu kiểm. Không log thêm dữ liệu nhạy cảm để debug.
- **DB migration lỗi:** dừng ghi, restore/rollback theo rehearsal, kiểm integrity/ledger trước mở lại. Không sửa trực tiếp bảng live mà thiếu audit.

## 6. Pilot và quyết định tiếp tục

Nhóm nhỏ tự nguyện dùng 7 ngày, với đồng ý phù hợp; ghi chỉ số ở [PRD](../01-product/01-prd.md) và phỏng vấn về giá trị/khó chịu. Nếu chuông không tin cậy, việc học quá nặng lúc sáng hoặc AI chấm không công bằng, sửa/bỏ tính năng tương ứng trước khi mở rộng. iOS và PvP/ranked là nhánh riêng sau gate, không làm điều kiện phát hành P0.
