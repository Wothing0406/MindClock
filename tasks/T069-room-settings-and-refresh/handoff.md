# Bàn giao

Trạng thái done. AC01–05 của lát settings/REST refresh đạt bằng API/PostgreSQL/Flutter. Không có media live hoặc pet trong task này.

Đã đổi: API settings host-only; capacity row lock; repo GET/PATCH; VM room có polling foreground/lifecycle/epoch; editor host, refresh, lỗi/retry/closed; panel giữ trong phiên timer. Không dùng flag mic/cam làm bằng chứng đang truyền media, UI mặc định disabled/chưa khả dụng.

Kiểm 20/11/2026: 25 Flutter test, 5 SQLite API test, 2 PostgreSQL concurrency test PASS; analyze sạch. Chưa build APK hay rebuild Docker API đang phục vụ app; không suy ra từ harness đã login thật/điện thoại thật. Xem tests.md.

Git: code commit `d7d99cfd29e84225516f4a6f751dfdb528744aca` trên main đã push 20/11/2026, xác minh đúng SHA qua git ls-remote. Bản ghi này đi sau bằng commit bàn giao; không stage WIP game/asset/Firebase.

Bước tiếp: mã mời TTL/rotate/QR và quyền tham gia trước mở media; session/presence TTL, unfriend/moderation/rate-limit, host transfer/kick. Pet cần group membership/ledger ngày đủ điều kiện và asset gốc duyệt; không dùng streak ôn làm bằng chứng dậy đúng giờ. Game T065 còn WIP, không stage vào task này.
