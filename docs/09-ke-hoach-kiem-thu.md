# Kế hoạch kiểm thử MindClock

> **Bổ sung bắt buộc khi code:** kiểm thử chế độ không Hoãn/gợi ý sau ba lần sai trong [docs/31](31-bao-thuc-thu-thach.md), và chọn câu nhiều môn/tổ hợp/nhắc lịch trong [docs/32](32-ho-so-hoc-tap-va-nhieu-mon.md). Các ca Hoãn/gợi ý sớm phía dưới chỉ áp dụng chế độ thường hoặc test hồi quy cũ.

> **Khi mở đấu trường/cửa hàng/kho dữ liệu:** thêm acceptance S01–S12 ở [docs/35](35-solo-rpg-dong-bo-va-ky-nang.md), E01–E08 ở [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md) và contract import/quyền nguồn ở [docs/38](38-nguon-du-lieu-va-duong-nhap-cau-hoi.md). Test ví/RP cần PostgreSQL concurrent, hai máy thật cho đồng bộ, và kiểm tra asset 2D khi giảm chuyển động.

**Mục tiêu:** kiểm chứng sản phẩm hoạt động an toàn, tin cậy và nói đúng khả năng. Kiểm thử theo rủi ro; ưu tiên báo thức, quyền tắt, dữ liệu cá nhân và chấm bài.

## 1. Các mức kiểm thử

| Mức | Nội dung | Chủ trì |
| --- | --- | --- |
| Unit | Tính lần reo kế tiếp, ngày học, state machine, XP/streak, validator kết quả | Mobile/backend |
| Contract | Request/response/error của `/v1`; schema câu hỏi và AI; tương thích client-server | Backend + mobile |
| Integration | Firebase Auth/Firestore emulator, Gemini mock, idempotency và transaction | Backend |
| Thiết bị | Báo thức khi khóa màn, app đóng, không mạng, reboot, quyền bị từ chối | Mobile + QA |
| AI evaluation | Ảnh viết tay thật có nhãn người chấm, đúng/sai/chưa rõ; lỗi bước giải | AI + giáo viên duyệt |
| Usability | Học sinh hiểu cách dùng và cách tắt chuông, không bị căng thẳng | Product + QA |
| Security/privacy | Truy cập chéo tài khoản, upload, log, xóa dữ liệu, rules | Backend + QA |

## 2. Ma trận P0 — phải đạt trước pilot

| ID | Tình huống | Kỳ vọng |
| --- | --- | --- |
| A01 | Đến giờ, app bị đóng/màn khóa | Chuông hiển thị/phát theo quyền OS; hoãn/tắt được |
| A02 | Đến giờ, không Internet | Chuông hoạt động local; câu dự phòng hoặc chế độ chỉ báo thức |
| A03 | Đến giờ, token hết hạn | Không chặn chuông; chỉ yêu cầu đăng nhập khi đồng bộ |
| A04 | Quyền exact alarm/full-screen bị từ chối hoặc thu hồi | App báo rõ hạn chế, không hiển thị “đã đảm bảo đúng giờ” |
| A05 | Reboot, đổi múi giờ, đổi giờ báo thức | Lần reo tiếp theo được tính/lập lịch lại, không chuông trùng |
| A06 | Đang chấm hoặc API treo | Tắt khẩn cấp hoạt động ngay; sau timeout có đường kết thúc |
| A07 | Hoãn nhiều lần | Không tạo nhiều phiên/XP; vẫn có tắt khẩn cấp |
| A08 | Cùng `Idempotency-Key` gửi 2 lần | Một attempt/XP; payload khác trả xung đột |
| A09 | Ảnh sai nhưng AI nói đúng, validator bất đồng | `uncertain`, không cấp XP đúng |
| A10 | Ảnh mờ/cắt thiếu | Không kết luận “sai” hay “gian lận”; chụp lại/nhập đáp án |
| A11 | User A gọi session/user B | `403` hoặc `404`; không lộ dữ liệu |
| A12 | Ảnh/token trong log hoặc crash report | Không xuất hiện |
| A13 | Bấm tắt khẩn cấp ở mọi màn chuông | Âm thanh/rung dừng, state `dismissed`, không phạt |
| A14 | Xóa tài khoản | Không còn truy cập dữ liệu cá nhân; tiến trình xóa có trạng thái rõ |

## 3. Test case chi tiết cho quy tắc học tập

| ID | Input | Kỳ vọng |
| --- | --- | --- |
| L01 | Thứ Hai có Toán, chủ đề phương trình | Câu Toán đã duyệt đúng lớp/chủ đề |
| L02 | Ngày không có môn | Câu ôn dự phòng hoặc chỉ báo thức theo cài đặt |
| L03 | Câu hết `revision`/bị retired | Không dùng để chấm mới; fallback an toàn |
| L04 | Đúng lần đầu | `+10 XP`, một ledger entry, streak ngày đó tăng 1 |
| L05 | Sai rồi đúng | `+6 XP`, một ledger entry, gợi ý không chứa đáp án cuối |
| L06 | Hai lần sai | Cho xem lời giải và kết thúc, không trừ XP |
| L07 | Hoàn thành không chấm | `+2 XP` tối đa 1 lần nếu đã có nỗ lực; không gắn nhãn đúng |
| L08 | Hoãn/tắt khẩn cấp | `0 XP`, không trừ điểm, không công khai |
| L09 | Hai alarm trong cùng ngày hoàn thành | Streak tăng tối đa 1 ngày; XP theo từng phiên hợp lệ |
| L10 | Client gửi `xpAwarded=9999` hoặc `correct=true` | Bỏ qua/từ chối; server tự tính |

## 4. Bộ đánh giá AI

### Dữ liệu

- D0: ít nhất 10 ảnh như [kế hoạch nghiên cứu](03-nghien-cuu-va-kiem-chung.md).
- M1 trước pilot: ít nhất **50 bài** có nhãn người chấm, gồm 20 đúng, 20 sai nhiều kiểu, 10 khó đọc/thiếu bước. Mỗi bài có `questionId`, ảnh được phép sử dụng, bản chép bước, kết luận, bước sai đầu tiên và mức rõ nét.
- Hai người chấm bất đồng thì giải quyết trước khi dùng làm chuẩn; không tính ảnh không đồng ý hoặc thiếu quyền sử dụng.
- Tách bộ tinh chỉnh prompt và bộ đánh giá cuối; không dùng cùng ảnh để vừa tối ưu vừa báo độ chính xác.

### Chỉ số và ngưỡng đề xuất để mở pilot

Đây là **ngưỡng mục tiêu**, chưa phải kết quả: không có trường hợp ảnh sai rõ ràng được tự động cấp XP `correct` trong bộ đánh giá; ít nhất 90% ảnh đúng rõ ràng được chấm đúng hoặc chuyển `uncertain` hợp lý; ít nhất 85% lỗi bước đầu được chỉ đúng trên ảnh sai rõ ràng; 100% ảnh khó đọc được phép chụp lại/không bị phạt. Nếu không đạt, giảm phạm vi câu, tăng `uncertain` hoặc dùng đáp án nhập thay ảnh. Ghi confusion matrix và khoảng tin cậy khi báo cáo, không quảng bá tỷ lệ từ 10 ảnh demo như hiệu năng thực tế.

## 5. Ma trận thiết bị Android

Ít nhất 3 thiết bị thật ở các phiên bản Android phổ biến trong nhóm dùng mục tiêu; bao gồm một máy có chính sách pin chặt. Thử mỗi ca: app foreground/background/force-stopped nếu OS cho phép, màn khóa, chế độ im lặng, tiết kiệm pin, reboot, đổi quyền, thay đổi giờ, kết nối yếu. Ghi model/OS/quyền/kết quả/giờ đặt/giờ reo. Mục tiêu trước pilot: **không có báo thức bị lỡ trong ma trận đã hỗ trợ**, sai lệch giờ theo đặc tính OS và quyền đã công bố. Nếu không thể đạt, giới hạn thiết bị hỗ trợ hoặc sửa chiến lược báo thức trước pilot.

## 6. Kiểm thử quyền riêng tư và an toàn

Test Firestore rules với user A/B, người chưa đăng nhập, vai trò biên tập; Storage deny-all nếu chưa dùng; tệp ảnh tạm được dọn cả khi exception; không có API key trong APK; không có ảnh/chữ viết/token trong log; kiểm tra giới hạn size/MIME/magic bytes, rate limit, prompt injection trong ảnh, phản hồi AI chứa nội dung ngoài rubric; thử xóa dữ liệu và thu hồi quyền. Kiểm tra nội dung tiếng Việt không gán nhãn học sinh theo năng lực hoặc trừng phạt khi sai.

## 7. Pilot người dùng

5–10 học sinh tự nguyện trong 7 ngày, có quy trình đồng ý phù hợp. Trước pilot: hỏi cách dậy/ôn hiện tại. Trong pilot: theo dõi lỗi kỹ thuật và mức khó chịu hằng ngày. Sau pilot: hỏi liệu một câu ngắn có hữu ích, có muốn tiếp tục, ảnh chụp có phiền không. Có quyền rút và xóa dữ liệu. Không suy luận cải thiện điểm số hoặc sức khỏe từ pilot nhỏ.

## 8. Cổng phát hành

**D0 demo:** demo đúng nhãn live/mô phỏng, không kẹt luồng. **M1 nội bộ:** toàn bộ P0 pass, API contract pass, kiểm thử thiết bị thật, không có lỗi lộ dữ liệu. **M2 pilot:** bộ AI đạt ngưỡng hoặc có đường thay thế an toàn, quy trình đồng ý/xóa dữ liệu, người phụ trách hỗ trợ. **Production:** thêm giám sát, khôi phục sự cố, pháp lý/quyền trẻ em, chính sách cửa hàng và kiểm thử tải/chi phí. Không dùng số ngày sprint làm tiêu chí thay cho cổng chất lượng.

## 9. Bộ kiểm thử cho phần mở rộng

**iOS:** dùng checklist và tiêu chí máy thật trong [docs/20](20-ios-demo-va-phat-hanh.md); lưu bản OS/Xcode/model/quyền và video chứng minh từng trạng thái. Prototype/web chỉ đạt cổng demo UI, không đạt cổng báo thức iOS.

**Đấu trường:** hai máy thật hoặc hai phiên độc lập, cùng đề và deadline server; thử nộp lặp, mạng yếu, đồng hồ máy lệch, AI `uncertain`, khiếu nại, rút khỏi bảng, thay alias, truy cập trái quyền. Rating chỉ đạt cổng khi một match có tối đa hai ledger hợp lệ và retry không thay kết quả; xem [docs/21](21-dau-truong-xep-hang.md).

**Nhân vật:** kiểm tra silhouette 48 px, alt text, giảm chuyển động, không che nút Dừng, không hiển thị trạng thái trừng phạt và không có asset thiếu quyền sử dụng; xem [docs/22](22-nhan-vat-rpg.md).

