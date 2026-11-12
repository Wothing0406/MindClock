# Nhân vật RPG — trạng thái thiết kế

**Quyết định 12/11/2026:** bộ linh thú/nhân vật trước đây đã bị hủy theo yêu cầu chủ dự án. Ba tên dưới đây là **working names**. Đã có kit v0.1 và web demo nghiên cứu theo [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) và [docs/49–51](49-sprite-ba-nhan-vat-va-web-demo.md), nhưng chưa có asset được duyệt quyền phát hành, playtest cân bằng hay PvP thật. Tránh tạo hình giống nhân vật phim trước khi phát hành.

**Bản thiết kế chi tiết đang thử nghiệm:** [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) có luật, hai chiêu + nội tại cho mỗi nhân vật, prompt concept, asset và test cân bằng. Bảng dưới chỉ là tóm tắt vai.

| Tên tạm | Vai trò để thử nghiệm | Nội tại/chiêu thức | Asset |
| --- | --- | --- | --- |
| Hà Nhân | Đấu sĩ bền bỉ | Giữ Nhịp; Bước Vững; Tĩnh Tâm Phản Kích | Sprite web nghiên cứu, chưa duyệt quyền |
| Tuyệt Đỉnh | Kiếm sĩ sát thương | Kiếm Ý; Một Nét Thành Chiêu; Đường Kiếm Cuối Trang | Sprite web nghiên cứu, chưa duyệt quyền |
| Hàn Bối Pháp (`han_boi_thap`) | Hộ pháp phòng thủ | Tháp Còn Đứng; Dựng Tháp; Trấn Tháp | Sprite web nghiên cứu, chưa duyệt quyền |

Ba vai và thông số ở docs/46 là giả thuyết để playtest, chưa được phép bật ranked. Mọi câu hỏi bí mật phải xuất hiện công bằng cho hai bên; nhân vật không tự quyết độ khó riêng của đối thủ. Chỉ số 100 HP/50 giáp và damage v0.1 đã được ghi ở docs/46; cần kiểm thử cân bằng trước backend.

## Ranh giới hiện hành

- Báo thức và [Không gian học](45-khong-gian-hoc-va-che-do-tap-trung.md) chạy **không cần nhân vật**. Không đặt avatar trên màn chuông hoặc màn đang làm bài.
- Sân luyện web hiện có avatar/khung mẫu và ba sprite nghiên cứu, luôn ghi **mô phỏng**. Không xây catalog, cửa hàng hay thẻ riêng theo bộ nhân vật đã hủy.
- Khi chốt roster mới, tạo quyết định gồm tên/ID gốc, bản quyền, silhouette 48 dp, vai chiến thuật, nội tại, hai kỹ năng, ngân sách sức mạnh, bản tĩnh và sprite 2D; cập nhật docs/35, 37, 40, 43–44 và contract/test trong cùng task.
- Không dựa vào nhân vật phim, game hoặc meme có sẵn để xuất bản nếu chưa có quyền phù hợp.

## Hướng mỹ thuật còn dùng được

UI học tập tối giản theo [13](13-he-thiet-ke-ui.md) và [30](30-ngon-ngu-va-tai-san-giao-dien.md). Nếu triển khai đấu trường, sprite 2D phải rõ ở avatar 48 dp, có bản tĩnh, nguồn asset/quyền sử dụng và Reduce Motion. Tránh hình phạt, bệnh tật hoặc xúc phạm người học. Đây là ràng buộc chất lượng, **chưa phải brief vẽ nhân vật**.
