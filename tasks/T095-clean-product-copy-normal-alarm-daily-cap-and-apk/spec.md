# Đặc tả nhiệm vụ T095

## Vấn đề và kết quả mong muốn

1. Giao diện hiện còn nhiều từ ngữ kỹ thuật nội bộ (`local`, `cục bộ`, `máy chủ`, `server`, `offline`, `ngoại tuyến`, `GDPT 2018`, `chuẩn quy tắc`, `study-time-v0.1`, `OS`) và nhiều câu tự thanh minh dài dòng làm trải nghiệm rối.
2. `AlarmConfigScreen` trước đây khóa cứng `mode: AlarmMode.challenge` và bắt người dùng nhìn vòng tròn `Đi ngủ / Dậy` cùng thẻ câu hỏi sáng ngay cả khi người dùng chỉ muốn hẹn giờ báo thức bình thường.
3. Khi đặt nhiều báo thức trong cùng 1 ngày, cả client lẫn backend (`/v1/sessions/{id}/answers`, `/attempts`, `/progress/summary`) trước đây cho phép cộng điểm và đếm nhiều phiên báo thức hoàn thành trong cùng một ngày `local_date`.
4. Script `scripts/build_release_apk.ps1` bị dính ký tự lạ `x1` ở dòng 1, cần sửa sạch để build file APK release thực tế cho người dùng cài đặt.

## Phạm vi

- **Trong phạm vi:** Làm sạch toàn bộ chuỗi hiển thị UI Flutter, tách rõ `Hẹn giờ thường` vs `Báo thức dậy học`, khóa giới hạn tối đa 1 báo thức hoàn thành mỗi ngày trên Flutter & FastAPI/PostgreSQL, cập nhật `docs/01-product/09-giac-ngu-va-bao-thuc.md`, sửa `scripts/build_release_apk.ps1` và xuất file APK release.
- **Tài liệu chuẩn:** `AGENTS.md §3`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/01-product/03-he-thiet-ke.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Kiểm tra toàn bộ giao diện người dùng | Không còn hiển thị các từ `local`, `máy chủ`, `server`, `backend`, `GDPT 2018`, `chuẩn quy tắc`, `study-time-v0.1` trên màn hình chính thức; câu chữ ngắn gọn, đúng vai trò sản phẩm thật. | TC-01 |
| AC-02 | Người dùng tạo báo thức mới và không muốn lịch ngủ-dậy | Chọn `Hẹn giờ thường` (`alarm-mode-normal`) chỉ hiển thị chỉnh giờ, nhãn hẹn giờ, ngày lặp và âm chuông; lưu đúng `AlarmMode.normal` (có Hoãn 5 phút và Tắt chuông, không hiện vòng ngủ-dậy hay câu hỏi sáng). | TC-02 |
| AC-03 | Một ngày có nhiều báo thức (`alarm_1`, `alarm_2`, `alarm_3`) | Chỉ tính tối đa 1 báo thức hoàn thành mỗi ngày (`completedAlarmCountToday <= 1`); báo thức đầu hoàn thành nhận thưởng, các báo thức sau trong cùng ngày không cộng thêm EXP, không tăng số buổi hoàn thành ngày thứ 2 trên `/v1/progress/summary`, và trên máy cho phép tắt chuông ngay mà không bắt làm lại câu hỏi sáng. | TC-03, TC-04 |
| AC-04 | Xuất bản cài đặt Android | `scripts/build_release_apk.ps1` chạy thành công và tạo ra `dist/apk/mindclock-android.apk` hợp lệ. | TC-05 |

## Quyết định/mâu thuẫn

- Cập nhật `docs/01-product/09-giac-ngu-va-bao-thuc.md` ghi rõ: người dùng có thể chọn `Hẹn giờ thường` (không gắn lịch ngủ-dậy, không có câu hỏi) hoặc `Báo thức dậy học` (có lịch ngủ-dậy và câu hỏi mở ngày); nếu đặt nhiều báo thức trong 1 ngày thì hệ thống chỉ tính tối đa 1 báo thức hoàn thành mỗi ngày để tránh cày điểm bằng nhiều chuông liên tiếp.
