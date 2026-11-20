# Nhật ký

20/11/2026: thêm XpHistory model/repository, UI thẻ tiến độ tab Tôi và scope+epoch cho VM. Test bắt được semantics progress value sai định dạng, đã sửa. Rà auth expiry ẩn progress/history. PostgreSQL đã test trong database UUID riêng qua runner giữ credential trong memory; không đọc/in .env. Không thay đổi container API đang phục vụ hoặc DB dev. Giữ nguyên các file game WIP.

20/11/2026: T066 có backend, thiếu lịch sử EXP UI. Tab Tôi đang có avatar và account/community, chưa có thẻ tiến độ. VM fetch summary/session trực tiếp sau await, có nguy cơ response A ghi lại sau logout. Docker có postgres và api healthy (kiểm read-only). Không đọc/in secret .env.
