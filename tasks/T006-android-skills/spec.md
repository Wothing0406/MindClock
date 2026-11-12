# Đặc tả T006

## Vấn đề và phạm vi

Repo có skill Flutter UI/architecture/widget test nhưng thiếu quy trình Android native cho báo thức và kiểm thử tích hợp trên thiết bị. Thêm skill đúng phạm vi repo, không cài Flutter SDK/Android Studio, không thay code ứng dụng.

| ID | Điều kiện | Kỳ vọng | Test |
| --- | --- | --- | --- |
| AC-01 | Agent làm báo thức/focus Android | Có skill dự án chỉ rõ ranh giới OS, offline, dừng khẩn cấp và kiểm thử máy thật | TC-01 |
| AC-02 | Agent làm kiểm thử Android/Flutter | Có skill kiểm thử phù hợp, biết dùng Android native testing và Flutter integration test đúng lúc | TC-02 |
| AC-03 | Agent đọc docs skill | Biết nguồn, mục đích, giới hạn và không lầm skill là tính năng đã chạy | TC-03 |

## Quyết định

Ưu tiên nguồn Android/Flutter chính thức, thêm skill MindClock riêng cho quy tắc báo thức vì skill chung không bao phủ. Không cài skill Jetpack Compose cho UI Flutter. Không sử dụng skill để vượt giới hạn Android lock task hoặc quyền camera nền.
