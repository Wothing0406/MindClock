# Kế hoạch và kết quả kiểm thử

Viết ca kiểm thử từ `spec.md` trước coding. Điền **lệnh thực và kết quả thực**, không ghi “pass” nếu chưa chạy.

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | ... | ... | ... | Chưa chạy |
| TC-02 | AC-02 | ... | ... | ... | Chưa chạy |

## Cổng theo rủi ro

- Báo thức: máy thật, màn khóa, offline, quyền bị từ chối, tắt/hoãn.
- Auth/dữ liệu: token sai, user A/B, deny-all, xóa dữ liệu.
- AI: đúng/sai/chưa chắc, ảnh mờ, prompt injection, không lộ nội dung.
- Điểm/thi đấu: nộp kép, retry, transaction, timeout, rating không đổi khi uncertain.
- UI: tiếng Việt, chữ lớn, TalkBack/VoiceOver, nút chính.

Chỉ giữ những dòng liên quan; thêm ca biên thực tế. Ghi rõ test không thể chạy và điều kiện để chạy sau.

