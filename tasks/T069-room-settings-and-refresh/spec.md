# Đặc tả

AC01: PATCH /study-rooms/{id}/settings chỉ host; title trim 2–80, maxMembers 2–8, visibility public/invite_only và AI boolean; extra/null/empty patch 422. Khóa cùng room row với join/leave, capacity dưới active member trả409; không đuổi người đang học khi đổi riêng tư. Retry absolute values không nhân sự kiện/thưởng.
AC02: fetch room detail qua repo thật; VM riêng quản lý polling không chồng request, pause background/dispose; refresh sau resume, ignore response cũ sau mutation/leave/đổi room. 403/404/401 bỏ room UI, lỗi mạng giữ snapshot và ghi chưa cập nhật. Timer học độc lập.
AC03: UI host có editor; member không có, lỗi rõ và retry. Nút refresh và chỉ báo sync. Mặc định mic/cam vẫn off; không tuyên bố metadata là media live.
AC04: test API A/B, PostgreSQL sửa capacity tranh join, model/repo/VM race/lifecycle và widget 320dp200%/Reduce Motion. Android thật/media vẫn là cổng release riêng.

AC05: REST metadata không là media thật; mặc định mic/cam chưa khả dụng và không cho bật trong UI khi chưa nối cuộc gọi. Không hiện trạng thái đang phát camera chỉ từ boolean server.
