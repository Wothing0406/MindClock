# Tiến độ cá nhân và cộng đồng — kế hoạch triển khai

## Nền tiến độ (T066)

EXP chính thức là tổng xp_ledger của owner. Level `progress-v1`: mốc tổng EXP cấp L là `100*(L-1)^2`; cấp 1 bắt đầu 0, cấp 2 ở 100, cấp 3 ở 400. Không tăng sức mạnh PvP từ cấp tài khoản. Chỉ server tính, đọc profile không cấp thưởng; unique ledger hiện có chống nhận lại cùng nguồn/lý do. Không đổi thưởng cũ khi chỉnh đường cong, phải version policy.

`streak` trong progress summary là **chuỗi ngày ôn**, không phải dậy sớm: ngày có ledger `challenge_correct` delta dương, theo thời điểm server ghi thưởng chuyển sang timezone tài khoản. Trùng ngày chỉ tính một; chưa làm hôm nay vẫn giữ chuỗi của hôm qua đến hết ngày. Ngày thiếu làm chuỗi về 0, không trừ EXP. Không tin ngày thiết bị gửi. Offline đồng bộ muộn tính ngày server ghi nhận theo policy này; chưa có hồi tố/system-grace. Chuỗi dậy đúng giờ cần task riêng xác minh alarm/session/grace trước chăm pet. Thay timezone có thể đổi projection lịch sử; cần snapshot ngày thưởng bền vững trước mở thưởng nhóm có giá trị.

## Điều hướng cộng đồng cần hoàn thiện

Một mục Bạn học gồm Bạn bè, Lời mời, Nhóm của tôi và Tìm phòng. Tìm theo mã/biệt danh được công khai; yêu cầu hai chiều, pending/accepted/rejected/cancelled/blocked. Không tự thêm từ danh bạ. Chặn phải có hiệu lực cho lời mời và join room; lời mời hết hạn và giới hạn tần suất ở server.

Tìm phòng: lọc khối/môn, học sâu/ngắt quãng, thời lượng, còn chỗ, bạn bè/công khai, mic/cam/AI theo lựa chọn. Thẻ có host, chủ đề, số người/capacity, trạng thái và điều kiện vào. Người dùng xem chi tiết rồi tự chọn; ghép gợi ý không tự mở cam/mic hoặc đưa vào phòng. API phải kiểm quyền và capacity trong transaction kể cả hai người bấm cùng lúc. Phòng đầy/đóng/không được phép có thông báo và trở về danh sách.

Host đặt tên/mục tiêu, public hoặc invite-only, giới hạn thành viên trong trần server, cho khách vào hay cần duyệt, cho chat/ảnh/AI, quyền mời, tắt tiếng/xóa thành viên và chuyển host. Khách không sửa setting. QR/link là token TTL có thể thu hồi, không là quyền truy cập vĩnh viễn. Tìm phòng người lạ chỉ mở sau consent/moderation/room security; ưu tiên mời bạn hiện có.

## Hội nhóm và pet chung

Theo [đặc tả nhóm](12-lich-chung-ghep-phong-va-pet-nhom.md): một pet chung, không mất máu hoặc hạ cấp khi bạn nghỉ. Ngày chăm từ event server đủ điều kiện; unique nguồn sự kiện + nhóm + ngày; không nhân thưởng khi retry hoặc tham gia nhiều nhóm. Tách chuỗi ôn, chuỗi chăm nhóm, EXP cá nhân và RP thi đấu.

UI pet cần màn tổ ấm, thanh chăm hôm nay, chuỗi nhóm, lịch nghỉ và lịch sử đóng góp tự nguyện. Asset cần master gốc được duyệt, idle/happy/feed/sleep/level-up, thumbnail, vật phẩm trang trí, reduced-motion still và manifest quyền/anchor/frame/duration. Chưa có bằng chứng asset này đã tạo hoặc API chăm pet hoạt động.

## Các lát tiếp theo và điều kiện nghiệm thu

T067 đã nối thẻ tiến độ vào tab Tôi: cấp, tổng EXP, thanh theo mốc server, chuỗi ôn và lịch sử EXP có xem thêm/cập nhật/lỗi/rỗng. Lịch sử hiển thị giờ thiết bị, không công khai. Response từ tài khoản cũ hoặc refresh cũ bị bỏ; hết phiên ẩn dữ liệu. Đây là phần tiến độ hồ sơ, chưa hoàn thành đồng bộ avatar/tiểu sử, danh hiệu hay hồ sơ công khai đa thiết bị. PostgreSQL migration và ledger unique đã kiểm trong DB test riêng; Android thực tế và hai điện thoại vẫn cần kiểm.

1. T066: summary streak/level và XP history owner-only, test mốc/ngày/A-B. Còn PostgreSQL, Flutter integration và test hai thiết bị.
2. Profile thống nhất: avatar/biệt danh/tiểu sử, cấp + thanh EXP, danh hiệu đeo, năng lực theo môn riêng, rank mùa riêng; lịch sử ôn/học/đấu. Logout/đổi account xóa cache; offline hiện lần đồng bộ, hai máy đọc cùng server.
3. Danh hiệu: catalog version, tiêu chí xác minh được, grant ledger unique, equip có ownership; “Học bá” không suy từ giờ ngồi học. Hiệu ứng lên cấp một lần theo event xác nhận, Reduce Motion dùng thẻ tĩnh.
4. Bạn/nhóm/phòng: dùng lại API và sheet hiện có; kiểm end-to-end search/request/accept/block/join/capacity/settings với 2–4 tài khoản. Không tạo thêm hệ bạn bè local song song.
5. Pet: nối event đủ điều kiện sau khi streak dậy đúng giờ và system grace có test. Grant transaction, membership thời điểm event, timezone nhóm cố định.
6. Wallet/shop/leaderboard: gỡ người mẫu khỏi chế độ online, ví/ownership/purchase ledger server, giá catalog server, mua atomic chống số dư âm, retry không mua đôi; rỗng thì hiện chưa có dữ liệu. Không đổi EXP thành RP hay bán sức mạnh.
7. PvP: event sequence/replay/reconnect và hiệu ứng đúng attacker/target, hai máy cùng câu/rubric/deadline; evaluation chấm và balance đạt trước ranked. Ranked cần rating ledger/mùa/appeal và task riêng, không chỉ bật nút.

Mỗi lát mở task spec/plan/tests/handoff riêng, commit/push sau khi đạt cổng tương ứng. Tài liệu này là kế hoạch, không chứng minh các chức năng trên đã triển khai.
