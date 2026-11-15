# Kiểm toán khoảng trống còn lại

**Rà soát 11/11/2026.** Repo hiện là bộ đặc tả/prototype, chưa có app/API/PvP phát hành. Trang này ghi việc **chưa thể giải quyết bằng viết docs**, không phải danh sách tính năng được phép nhận là đã có. [Nhu cầu học sinh](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md) và [ma trận giao việc](42-ma-tran-yeu-cau-va-giao-viec.md) là đầu vào của từng task.

## 1. Đã được đặc tả để bắt đầu coding

| Mảng | Nguồn chuẩn | Còn phải làm thật |
| --- | --- | --- |
| Chuông, Dừng, offline | [04](04-prd-va-dac-ta-san-pham.md), [06](06-kien-truc-va-du-lieu.md), [31](31-bao-thuc-thu-thach.md) | Native Android, quyền OS, test nhiều thiết bị thật |
| Lịch, nhiều môn, việc trong ngày | [32](32-ho-so-hoc-tap-va-nhieu-mon.md), [41](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md) | Bộ câu phủ môn/chủ đề, sửa lịch nhanh, thử với học sinh |
| API, SQL, quyền, xóa | [07](07-hop-dong-api-va-ai.md), [24](24-dang-ky-va-quan-ly-tai-khoan.md), [25](25-bao-mat-va-du-lieu.md), [28](28-backend-sql.md) | Migration, kiểm quyền A/B, export/delete thực, backup/restore |
| Chấm bài có trình bày | [34](34-ngan-hang-cau-hoi-da-mon.md), [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md) | Người duyệt nội dung, bộ bài đánh giá, đo lỗi/`uncertain` |
| Giao hữu/PvP/rank/asset | [35](35-solo-rpg-dong-bo-va-ky-nang.md), [37](37-kinh-te-rank-va-nhan-vat-2d.md), [40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md) | Hai máy thật, cân bằng, chống lạm dụng, quyền asset, cổng ranked |
| iOS | [20](20-ios-demo-va-phat-hanh.md) | Mac/iPhone phù hợp, build ký và test AlarmKit; web prototype không chứng minh alarm iOS |

## 2. Quyết định/cổng chưa có bằng chứng

| Mức | Khoảng trống | Người chịu trách nhiệm đề xuất | Cổng quyết định |
| --- | --- | --- | --- |
| P0 | Thể lệ DevFest: phần được chuẩn bị trước, hạn nộp, thời lượng pitch | Trưởng nhóm | Có thông báo chính thức trước khi chốt demo |
| P0 | Báo thức có reo/dừng đủ tin cậy trên máy mục tiêu | Mobile + QA | Ma trận thiết bị [09](09-ke-hoach-kiem-thu.md) đạt; nếu không giới hạn thiết bị hỗ trợ |
| P0 | Quyền dùng từng câu ngoài và người duyệt chuyên môn | Nội dung + người phụ trách quyền | Mỗi câu published có provenance/licence/rubric và người duyệt; chưa rõ thì chỉ dùng câu tự biên soạn |
| P0 | Xử lý dữ liệu học sinh, tuổi/consent theo thị trường pilot | Product + người tư vấn pháp lý phù hợp | Rà soát trước khi mời người chưa thành niên, không dùng ảnh thật trên Gemini free tier khi chưa đủ điều kiện |
| P0 | Chấm oan/giải thích sai | AI/QA + giáo viên | Tập đánh giá và ngưỡng [09](09-ke-hoach-kiem-thu.md) đạt; fallback chữ/`uncertain` |
| P1 | Học sinh thấy câu buổi sáng hữu ích hay gây áp lực | Product/UX | 5–8 buổi usability và pilot 7 ngày theo [41](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md); giảm yêu cầu nếu phiền |
| P1 | Khả năng ghép hai người cùng lớp/môn/chương trình và công bằng HP/kỹ năng | Game/QA | Giao hữu hai máy, bộ câu hiệu chuẩn, đo latency/khiếu nại trước ranked |
| P1 | Chi phí API/hosting thật và nguồn thu phù hợp học sinh | Backend/Product | Đo cost/attempt và tải trước khi hứa miễn phí rộng; demo 0 đồng không suy ra vận hành 0 đồng |
| P2 | Asset 2D và map có bản quyền, chuyển động mượt máy yếu | Art/Mobile | Metadata licence, test 48 px, giảm chuyển động, máy yếu |

## 3. Những điều không được tuyên bố trước khi có bằng chứng

Không nói MindClock cải thiện điểm thi/giấc ngủ, chống gian lận tuyệt đối, khóa được điện thoại/gỡ app, chấm được mọi môn, có bảng xếp hạng online thật, hoặc có iOS alarm chỉ từ storyboard/mock. Dữ liệu nghiên cứu VNHSGE/VMLU trong `data/research` **không là ngân hàng đã nhập vào sản phẩm**; xem [38](38-nguon-du-lieu-va-duong-nhap-cau-hoi.md). Báo thức chỉ chứng minh trên thiết bị thật; prototype demo phải gắn nhãn.

## 4. Cổng mở rộng

MVP trước: alarm Android an toàn, một câu đã duyệt phù hợp lịch, nhập đáp án + cách làm, AI `uncertain`, tài khoản tùy chọn, quyền dữ liệu/xóa. Sau đó pilot học tập và giao hữu tự nguyện. Ranked, RP, cửa hàng, nhóm/lớp, giáo viên/phụ huynh, iOS alarm chỉ mở sau cổng riêng ở [08](08-ke-hoach-trien-khai.md), [09](09-ke-hoach-kiem-thu.md) và docs tính năng. Người dùng có thể rời bảng/thi đấu mà vẫn dùng báo thức và lịch.
