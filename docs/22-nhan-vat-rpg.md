# Nhân vật RPG — trạng thái thiết kế

**Quyết định 12/11/2026:** bộ linh thú/nhân vật trước đây đã bị hủy theo yêu cầu chủ dự án. Không dùng tên, ID, hình, lời thoại, kỹ năng hay asset cũ để coding. Ba tên dưới đây do chủ dự án đề xuất là **working names**, chưa phải roster/kit/artwork được duyệt. Cần xác minh nguồn/quyền dùng tên và tránh tạo hình giống nhân vật phim trước khi phát hành.

**Bản thiết kế chi tiết đang thử nghiệm:** [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) có luật, hai chiêu + nội tại cho mỗi nhân vật, prompt concept, asset và test cân bằng. Bảng dưới chỉ là tóm tắt vai.

| Tên tạm | Vai trò để thử nghiệm | Nội tại/chiêu thức | Asset |
| --- | --- | --- | --- |
| Hà Nhân | Bền bỉ, dễ tiếp cận | Chưa chốt; hướng thử: giữ giáp qua chuỗi lời giải rõ | Chưa có |
| Tuyệt Đỉnh | Tích lực, tấn công theo nhịp | Chưa chốt; hướng thử: dùng khí lực từ câu khó chung | Chưa có |
| Hàn Bối Tháp | Phòng thủ, phản công | Chưa chốt; hướng thử: chắn một đòn khi giáp cạn | Chưa có |

Ba vai trên là giả thuyết để playtest, không phải đặc tả sức mạnh. Mọi câu hỏi bí mật phải xuất hiện công bằng cho hai bên; không để nhân vật tự quyết độ khó riêng của đối thủ. Chỉ số 100 HP/50 giáp là đề xuất của chủ dự án, chưa có công thức damage/cooldown và chưa được phép bật ranked.

## Ranh giới hiện hành

- Báo thức và [Không gian học](45-khong-gian-hoc-va-che-do-tap-trung.md) chạy **không cần nhân vật**. Không đặt avatar trên màn chuông hoặc màn đang làm bài.
- Đấu trường có thể dùng avatar hình học tạm **có nhãn mô phỏng** ở prototype. Không xây catalog, cửa hàng hay thẻ riêng theo bộ nhân vật đã hủy.
- Khi chốt roster mới, tạo quyết định gồm tên/ID gốc, bản quyền, silhouette 48 dp, vai chiến thuật, nội tại, hai kỹ năng, ngân sách sức mạnh, bản tĩnh và sprite 2D; cập nhật docs/35, 37, 40, 43–44 và contract/test trong cùng task.
- Không dựa vào nhân vật phim, game hoặc meme có sẵn để xuất bản nếu chưa có quyền phù hợp.

## Hướng mỹ thuật còn dùng được

UI học tập tối giản theo [13](13-he-thiet-ke-ui.md) và [30](30-ngon-ngu-va-tai-san-giao-dien.md). Nếu triển khai đấu trường, sprite 2D phải rõ ở avatar 48 dp, có bản tĩnh, nguồn asset/quyền sử dụng và Reduce Motion. Tránh hình phạt, bệnh tật hoặc xúc phạm người học. Đây là ràng buộc chất lượng, **chưa phải brief vẽ nhân vật**.
