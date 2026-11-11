# Đấu trường và bảng xếp hạng — phạm vi sản phẩm

**Trạng thái:** giai đoạn sau MVP; chưa có trận online/rank đang chạy. Luật trận, HP, kỹ năng và đồng bộ hiện hành ở [35](35-solo-rpg-dong-bo-va-ky-nang.md), kinh tế/RP ở [37](37-kinh-te-rank-va-nhan-vat-2d.md), bài có trình bày ở [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), nhân vật/FX ở [40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md). Tài liệu này chốt hành trình xã hội, bảng và quyền hiển thị. [Docs/33](33-dau-truong-solo-ranked-gdd.md) là luật cũ lưu trữ, không dùng để coding.

## 1. Học sinh tự chọn tham gia

Từ `Luyện tập → Đấu trường`, người học xem luật giao hữu, thời lượng dự kiến, môn/khối/bộ nội dung, HP và cách nộp đáp án kèm lời giải. Không đưa lời mời thi vào màn báo thức. Trận đầu là **giao hữu không tính hạng** với mã mời hoặc ghép khi có đủ người và quy trình phù hợp. Không có chat tự do; chỉ dùng câu nói/biểu cảm có sẵn đã duyệt hoặc tắt tương tác. Có đường thoát/hủy tìm trận, trạng thái mạng và lý do trận vô hiệu rõ.

Ranked và bảng chỉ mở khi người dùng chủ động bật, chọn biệt danh/avatar và hiểu ai sẽ thấy. Trường/lớp cụ thể, vị trí, lịch học, giờ dậy, ảnh bài làm và tên thật **không** xuất hiện trên bảng. Rút khỏi bảng phải ẩn ngay ở API, xử lý cache/projection và lịch sử theo [25](25-bao-mat-va-du-lieu.md). Tham gia/rời thi đấu không thay alarm, lịch, XP học cá nhân hay nhân vật đã sở hữu. Người chưa thành niên chỉ được mở tính năng theo quy trình tuổi/đồng ý đã được rà soát cho thị trường pilot.

## 2. Bốn chỉ số không gộp

| Chỉ số | Ý nghĩa và nơi hiển thị | Nguồn dữ liệu |
| --- | --- | --- |
| XP | Tiến độ học cá nhân, riêng tư mặc định; không dùng xếp bảng | `xp_ledger` server |
| Chuỗi ôn tập | Ngày có hoạt động hợp lệ, có thể ẩn; nghỉ không trừ điểm/coin | Server sau đồng bộ đủ điều kiện |
| RP và bậc | Chỉ trận có hạng đã chốt, theo môn/khối/mùa; xem docs/37 | `rank_ledger` server |
| Đồng Mực | Tiền trong app kiếm qua nhiệm vụ/trận, mở nhân vật/phụ kiện; không bán sức mạnh | Ví/ledger server theo docs/37 |

Không xếp hạng theo giờ dậy, streak hay số phút dùng app. Không đẩy thông báo “tụt hạng” hoặc tạo áp lực dậy sớm.

## 3. Bảng và nhóm theo giai đoạn

| Giai đoạn | Màn có thể mở | Quy tắc hiển thị |
| --- | --- | --- |
| M3 đầu | Giao hữu và lịch sử trận riêng | Không RP, không bảng công khai, không phạt thua |
| Sau cổng ranked | Bảng mùa theo `{subject, gradeBand, curriculumScope, season}` | Chỉ người opt-in, top 20 và vị trí bản thân; cùng RP cùng hạng, thứ tự hàng đồng điểm ổn định theo ID nội bộ, không lộ ID hoặc xét giờ dậy |
| Sau thử quyền nhóm | Nhóm/lớp tự nguyện và thử thách tuần | Không nêu cá nhân nghỉ/sai; nhóm đủ quy mô mới có bảng, thành viên rời được |

Bảng học tập tuần nếu làm sau này dùng **điểm hoạt động riêng** có trần/ngày và `scoreRuleVersion`, không lấy XP hoặc giờ báo thức làm điểm. Đề xuất mở bảng nhóm chỉ khi có tối thiểu 10 người tự tham gia một phân vùng để giảm nguy cơ nhận diện; ngưỡng này cần đánh giá trong pilot trước khi bật. Nếu ít người, hiện tiến độ riêng thay bảng. Alias đổi/opt-out phải cập nhật view công khai, không để tên cũ trong cache.

## 4. Ghép người và kết quả

Backend ghép theo cùng môn, khối, phạm vi chương trình và pool câu đã duyệt; scope không đủ người thì cho mã mời/giao hữu hoặc báo chưa ghép được, không âm thầm trộn lớp/môn. Hai người nhận cùng bộ ba câu và deadline theo server; chấm bài có trình bày theo rubric/revision đã khóa. Tốc độ chỉ dùng trong luật được kiểm chứng, không lấy tốc độ upload ảnh/mạng yếu làm lợi thế. Trận `uncertain`, lỗi câu/rubric, mất kết nối không đủ bằng chứng hoặc khiếu nại hợp lệ chuyển `needs_review`/`voided`; **không đổi RP** khi chưa chốt. Chỉ server ghi HP/outcome/rating, retry cùng idempotency key không nhân điểm; dữ liệu bài đối thủ chỉ lộ phần đã được phép sau khi chốt.

Khiếu nại: người học chọn `Báo kết quả chưa đúng`, thấy trạng thái xử lý và kết quả cuối; nếu cần giữ ảnh làm chứng cứ thì xin consent riêng và đặt thời hạn xóa. Không lưu ảnh mặc định. SLA/đội duyệt và ngưỡng chấm ranked phải được chốt **trước pilot ranked** theo [19](19-kiem-toan-khoang-trong.md), không bịa thời hạn khi chưa có người vận hành.

## 5. API/SQL và kiểm thử

Định nghĩa chi tiết endpoint/trạng thái/transaction trận ở [35](35-solo-rpg-dong-bo-va-ky-nang.md), bảng ví/RP ở [37](37-kinh-te-rank-va-nhan-vat-2d.md), SQL chung ở [28](28-backend-sql.md), hợp đồng bảng/nhân vật/test ở [44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md); mọi endpoint cạnh tranh phải xác minh Firebase ID token, owner/participant và opt-in. Bảng `competition_profiles`, `matches`, `match_rounds`, `round_submissions`, `rank_ledger`, `leaderboard_entries`, `boards`, `groups`, `group_memberships` chỉ được tạo khi giai đoạn yêu cầu; không cho client ghi trực tiếp.

Test trước bật: hai máy thật/cùng câu, mạng lệch/đồng hồ máy sai, nộp lặp và concurrent settle, AI `uncertain`, appeal/void, rời bảng/đổi alias, truy cập chéo tài khoản, đồng điểm/pagination, câu bị retired và lạm dụng gặp lại một đối thủ. Kiểm thử quyền trẻ em và cảm giác áp lực với người dùng thật; giao hữu trước ranked. Cổng đầy đủ ở [09](09-ke-hoach-kiem-thu.md), [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md) và [41](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md).
