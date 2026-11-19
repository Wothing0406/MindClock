# Kế hoạch thực hiện T062

## Điểm bắt đầu

- Repo đang ở SHA `0c90cf4` (`origin/main`), `pytest` PG16 = 64 passed, `flutter test` = 94 passed.
- Đã tái hiện lỗi thực tế trên ảnh TKB lớp 12/20 (`media_1795104908791_f6e57b17.jpg`): `gemini-3.1-flash-lite` bị `ReadTimeout` với ảnh TKB, `gemini-3-flash-preview` đọc đúng 22/22 môn chính khóa nhưng rớt 4 tiết đặc thù; Docker `api-api-1` đang chạy image cũ.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Backend Vision TKB + `mode=ai_regen` cho `/challenges/next` + unit test + test live trên ảnh TKB user + rebuild Docker `api-api-1` | Parse ảnh TKB của user nhận đủ 27/27 tiết (22 môn + 5 sinh hoạt/địa phương), `pytest` pass | [x] |
| 2 | Mở rộng kho câu hỏi offline có đáp án/rubric cho các môn THPT (`SoloTrainingQuestionBank`, `SubjectCatalog`, `MorningQuestionSelector`) & luồng offline/online regen (`PersonalFlowViewModel`, `PracticeSessionScreen`) | Mất mạng không còn kẹt 1 câu `2x+4=12`; có mạng nạp được câu AI sinh từ đề gốc vào phiên | [x] |
| 3 | Timer chọn theo người dùng + bộ câu hỏi liên tục ở Solo (`SoloArenaViewModel`, `ArenaScreen`) & countdown `deadlineAt` ở PvP (`ArenaPvpLobby`) | Hết giờ tự chuyển lượt; nạp/quay vòng câu liên tục không đóng băng; test widget pass | [x] |
| 4 | Phân giải môn từ TKB khi mở từ `AlarmRingScreen` + test E2E/widget + xóa sạch nhãn `demo`/`mẫu`/`Thử phiên` trên UI | Không còn chữ demo/thử phiên trong `app/lib/ui/` & `debug_fixture_pvp_gateway.dart` | [x] |
| 5 | Chạy full verify (`pytest`, `flutter analyze`, `RAW_HEX_COLOR_HITS`, `flutter test`, build APK, `check_docs_links`, `check_task_records`), cập nhật docs & push `origin/main` | Mọi check xanh sạch và commit/SHA xác nhận trên remote | [x] |

## Rủi ro và đường lui

- Nếu model Vision `gemini-3-flash-preview` tạm thời quá tải mạng từ Google, fallback về `gemini-3.1-flash-lite` với timeout rộng hơn (25s) và thông báo retry sạch cho user.
- Timer định kỳ trong `SoloArenaViewModel` và `ArenaPvpLobby` phải cancel trong `dispose()`, khi rời màn, và không chạy infinite timer lúc `noTimeLimit == true` hoặc `enableTimers == false` để widget tests ổn định.
