# Hồ sơ người học, avatar, huy hiệu và lịch sử

**Trạng thái:** hợp đồng sản phẩm/API/SQL để triển khai sau, chưa có backend hoặc lưu avatar thật. Bản xem thử web chỉ chọn avatar/ảnh **trong bộ nhớ trình duyệt**. Đăng ký theo [docs/24](24-dang-ky-va-quan-ly-tai-khoan.md), dữ liệu theo [docs/25](25-bao-mat-va-du-lieu.md), luật rank theo [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md) và [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md), ngôn từ/ảnh theo [docs/53](53-quy-dinh-ten-avatar-va-noi-dung-nguoi-dung.md).

## 1. Tách bốn đối tượng dễ nhầm

| Đối tượng | Dùng ở đâu | Chủ sở hữu/quyền | Nguồn |
| --- | --- | --- | --- |
| **Avatar hồ sơ** | Tôi, bảng tự nguyện, kết quả trận | Người dùng chọn avatar mặc định hoặc tải ảnh của mình; ảnh tải lên chờ duyệt trước khi công khai | `profile_avatar_asset_id` |
| **Khung avatar** | Viền trang trí quanh avatar | Cosmetic, có thể gắn bậc mỹ thuật hoặc chọn từ bộ đã mở, **không biểu thị RP nếu chưa có rank** | `equipped_frame_id` |
| **Huy hiệu hạng** | Thẻ rank trong hồ sơ, kết quả trận ranked, bảng | Server tính từ RP theo môn/khối/mùa; biểu trưng riêng với khung; có nhãn chữ+bậc số | `rank_profile`/`rank_ledger` |
| **Nhân vật đấu** | Màn chọn tướng và sân trận | ID/kit được khóa cho trận, không thay avatar hồ sơ | `equipped_character_id` và snapshot trận |

Sáu huy hiệu SVG độc lập: Đồng (dấu ấn một đỉnh), Bạc (hai nét), Vàng (vương miện), Bạch Kim (la bàn), Kim Cương (ngọc nhiều mặt), Tinh Anh (sao 8 hướng). Có thêm **Thường** dưới dạng chữ/trạng thái, không giả một huy hiệu hạng. Mỗi tier có 5 bậc số `1–5` theo docs/37; luật mapping RP phải chốt server trước coding. Badge có alt như `Huy hiệu Vàng, bậc 3`, kèm RP/scope/mùa; không dùng màu duy nhất. [Asset badge](../demo/assets/game/ui/rank/badges) khác [asset khung](../demo/assets/game/ui/rank).

## 2. Luồng “Tôi → Sửa hồ sơ”

1. Khách chưa đăng nhập: chọn avatar mặc định và biệt danh cục bộ, dữ liệu chỉ trên máy. Khi bấm đồng bộ/đấu trường mới vào luồng đăng ký docs/24.
2. Tài khoản: `Tôi` hiển thị avatar, biệt danh, khung đã chọn, nhân vật trang bị, môn đang học và tiến độ **riêng tư**. Nút `Sửa hồ sơ` cho đổi biệt danh, avatar, khung. Không yêu cầu ảnh thật hoặc tên thật.
3. `Chọn ảnh có sẵn`: 6 avatar mặc định gốc, không emoji hệ thống. Thay ngay trong preview; lưu server bằng ID allowlist sau khi người dùng bấm `Lưu`.
4. `Tải ảnh`: chọn JPEG/PNG/WebP tối đa **2 MB**; client xem preview local, crop 1:1, cho xoay/xóa/chọn lại. Nút `Lưu` mới gửi tới backend qua HTTPS nếu đã đăng nhập và có đồng ý ảnh. Backend kiểm MIME bằng magic bytes, kích thước/dimension, decode an toàn, bỏ EXIF/GPS, resize 256×256, tạo ID ngẫu nhiên; ảnh gốc tạm xóa sau xử lý. Không tự đưa ảnh vào Gemini hoặc log.
5. Avatar tải lên có trạng thái `pending → approved | rejected`. Khi pending/rejected, người khác vẫn thấy avatar mặc định gần nhất; chủ thấy ảnh trong preview với nhãn trạng thái/lý do ngắn và đường đổi/báo xem lại. Hủy ảnh pending hoặc xóa ảnh approved trả về avatar mặc định. Không cần upload ảnh để tham gia học.
6. `Khung`: người dùng chọn trong entitlement đã có; khung rank theo hạng chỉ hiển thị đúng khi rank server có hiệu lực. Đổi khung không đổi RP/nhân vật. Web demo cho xem mọi khung mỹ thuật nhưng ghi rõ là mẫu.

**Web demo:** file input preview trong trình duyệt; không gọi API, không lưu sau tải lại. Cần giải phóng Object URL khi đổi ảnh/thoát trang. Tên file không dùng làm biệt danh/alt công khai. Không có kiểm duyệt thật ở bản demo.

## 3. Nội dung hồ sơ và quyền xem

| Trường | Chủ tài khoản | Người khác (chỉ khi bật công khai) | Bảng |
| --- | --- | --- | --- |
| Biệt danh, avatar đã duyệt, khung, nhân vật | Có | Có khi `profile_visible=true` | Chỉ alias/avatar/badge đã đủ điều kiện |
| Môn/khối, mục tiêu thi, thời khóa biểu, task, tiến độ | Có | Không | Không |
| Badge/RP theo môn/khối/mùa | Có kể cả ẩn bảng | Chỉ scope tự công khai và rank hợp lệ | Theo board opt-in |
| Lịch sử đấu | Đủ trận của chính mình (chặn nội dung riêng đối thủ) | Tối đa 10 trận **ranked hợp lệ** nếu bật `battle_history_visible`; giao hữu riêng | Không đưa lịch sử vào bảng |
| Lịch sử báo thức/dậy đúng giờ | Có, theo ngày và trạng thái | **Không bao giờ** | Không bao giờ |
| Uy tín/trạng thái tài khoản | Chỉ trạng thái và đường khiếu nại | Không | Không |
| Email, UID, bài làm/ảnh, giờ chuông, trường/lớp | Có quyền xem phần của mình phù hợp | Không | Không |

Nếu `profile_visible=false`, `GET /v1/players/{public_id}` trả 404/ẩn tối thiểu, không lộ đã tồn tại. Khi rời bảng, ẩn projection/cache trước khi xác nhận thành công. Người khác không thể suy ra giờ dậy qua XP, streak hoặc badge. Hồ sơ trẻ em mặc định riêng tư; quyền chia sẻ và điều kiện tuổi/đồng ý phải được duyệt trước pilot. `public_id` không là Firebase UID.

## 4. Hai lịch sử và “uy tín”

**Lịch sử trận của chủ:** ngày, môn/phạm vi nội dung, giao hữu/ranked, kết quả `win/draw/loss/void/needs_review`, nhân vật, số round, RP trước/sau **chỉ khi ranked hợp lệ**, link xem bài của chính mình và `Báo kết quả chưa đúng`. Nếu đối thủ đã ẩn/xóa, hiện `Đối thủ` thay biệt danh. Trang công khai (nếu bật) chỉ ngày ở mức ngày, môn, kết quả và badge; không có ảnh bài, lời giải, MMR hoặc ID đối thủ.

**Lịch sử báo thức:** lưu sự kiện `scheduled`, `rang`, `completed_challenge`, `dismissed_emergency`, `dismissed_normal`, `missed_or_unknown` và thời điểm trên **máy chủ theo ngày địa phương đã chọn**, kèm `source=device_sync|local`. `Rang` hoặc người dùng tắt chuông **không chứng minh đã thức**; UI nói `Hoàn thành thử thách` thay “đã tỉnh táo”. Không chấm kỷ luật bằng camera/việc rời app. Chủ có lọc tuần/tháng, xóa/xuất theo chính sách; lịch sử cục bộ tồn tại khi chưa đăng nhập. Không hiển thị giờ chính xác trên profile công khai, không dùng giờ dậy cho bảng hay matchmaking.

**Uy tín:** nếu cần quản lý lạm dụng cộng đồng, chỉ giữ trạng thái nội bộ `normal/review/limited` từ hành vi đã được kiểm chứng như quấy rối, spam, mạo danh hoặc lạm dụng tài khoản. Không tạo điểm số uy tín công khai. **Không** trừ vì sai bài, chấm `uncertain`, ngủ muộn, bỏ báo thức, Dừng khẩn cấp, mất mạng hoặc phản hồi AI. Mọi hạn chế phải có lý do, thời hạn, người duyệt và đường kháng nghị; AI chỉ gắn cờ để người vận hành xem, không tự khóa/chấm gian lận. Không gộp uy tín với RP/XP/streak.

## 5. API/SQL dự kiến (chưa chạy)

Mọi đường cá nhân xác minh Firebase ID token và owner; `PATCH` dùng `If-Match/profile_version` để tránh ghi đè nhiều máy. Không nhận UID/RP/trạng thái moderation từ client. Endpoint đã có trong docs/24 là `GET/PATCH /v1/me`; **mở rộng** payload, không tạo đường `/me/profile` thứ hai.

| Endpoint | Ý nghĩa và quyền |
| --- | --- |
| `GET /v1/me` | Trả profile riêng, `profile_version`, avatar pending/approved, visibility, account standing, không nhúng mọi lịch sử |
| `PATCH /v1/me` | Alias, avatar mặc định ID, frame đã sở hữu, cờ hiển thị; validate; `409` version cũ |
| `PUT /v1/competition/visibility` | Đồng ý/rút khỏi bảng theo scope và consent version; ẩn projection trước khi trả thành công; không sửa alias/avatar độc lập |
| `POST /v1/me/avatar` | Multipart ảnh + idempotency key/consent version; trả `asset_id,status=pending`, có quota/rate limit; không ghi ảnh gốc vào log |
| `DELETE /v1/me/avatar` | Xóa pending/approved và projection, trả avatar mặc định, idempotent |
| `GET /v1/me/battles?cursor=` | Phân trang lịch sử của mình, owner only |
| `GET /v1/me/alarms/history?cursor=` | Lịch sử báo thức của mình, owner only, không có ảnh/mic |
| `GET /v1/players/{public_id}` | Projection công khai đã opt-in; chỉ trường allowlist, cờ lịch sử riêng; 404 khi ẩn |
| `POST /v1/reports` | Báo tên/avatar/hành vi; hạn chế spam và không lộ người báo |
| `POST /v1/me/appeals` | Khiếu nại moderation/kết quả, không tự đổi rank |

**SQL bổ sung khi mở feature:** mở rộng `users` của docs/28 bằng `public_id`, `avatar_asset_id`, `fallback_avatar_id`, `equipped_frame_id`, `profile_visible`, `battle_history_visible`, `version` (cột `alias` đã có); `avatar_assets(id, owner_id, state, mime, width, height, storage_key, created_at, reviewed_at, delete_after)`; `alarm_history_events(owner_id, local_day, event_type, source, created_at, dedupe_key)`; `content_reports` và `moderation_decisions` có reviewer/reason/evidence tối thiểu; `appeals` có status. `competition_profiles` chỉ là projection opt-in ở docs/28/44, không là bản hồ sơ thứ hai cho người dùng sửa độc lập. Lịch sử đấu đọc từ `match_results`/`match_players`, không sao chép bản chấm vào profile. Badge đọc `rank_profiles`/`rank_ledger`, không lưu điểm do client gửi. Index `(owner_id, created_at DESC)`, unique `(owner_id,dedupe_key)` cho đồng bộ sự kiện; RLS/endpoint deny-all rồi mở owner. Ảnh lưu object storage private và chỉ phát bản đã duyệt qua URL/CDN có kiểm soát opt-out/xóa; không lưu byte ảnh vào PostgreSQL.

## 6. Kiểm thử trước pilot

TC-P1: user A/B không đọc avatar pending, lịch báo thức/bài/lịch sử riêng của nhau; khách không đọc endpoint cá nhân. TC-P2: upload file giả MIME, >2MB, ảnh hỏng/EXIF GPS, trùng request, xóa trong lúc duyệt. TC-P3: đổi avatar/alias/ẩn profile cập nhật projection và cache; người đã ẩn không còn trên bảng/profile. TC-P4: trận void/giao hữu không tạo badge/RP; lịch dậy không đổi RP/uy tín. TC-P5: tên/ảnh bị từ chối có lý do và kháng nghị; không hiện ảnh pending cho người khác. TC-P6: máy dùng chung đăng xuất/đổi account không thấy lịch cũ. Cổng kiểm thử bảo mật và dữ liệu ở docs/25 vẫn áp dụng.
