/// Chuỗi tiếng Việt `vi-VN` chuẩn hóa theo `docs/05`, `docs/30`, `docs/31`, `docs/32`, `docs/55`.
///
/// Không dùng emoji hệ thống, không khẩu hiệu phóng đại, không báo `Đã sẵn sàng`
/// khi chưa nối dịch vụ báo thức hệ điều hành Android.
class AppStrings {
  const AppStrings._();

  static const String appName = 'MindClock';
  static const String guestBadge = 'Tài khoản MindClock';

  // S01 Chào mừng
  static const String welcomeTitle = 'Dậy đúng giờ. Nghĩ bằng chính mình.';
  static const String welcomeSubtitle =
      'Tạo tài khoản để đồng bộ lịch học, báo thức và không gian học tập trung.';
  static const String tryGuestCta = 'Bắt đầu ngay';
  static const String setupLaterCta = 'Tiếp tục';
  static const String alarmOnlyCta = 'Bắt đầu ngay';
  static const String guestPrivacyNote =
      'Ảnh bài làm xử lý tạm thời không lưu mặc định; giờ dậy và TKB chi tiết luôn được giữ riêng tư.';

  // 4 tab điều hướng (Hôm nay, Luyện tập, Đấu trường G1, Tôi)
  static const String navToday = 'Hôm nay';
  static const String navPractice = 'Luyện tập';
  static const String navArena = 'Đấu trường';
  static const String navMe = 'Tôi';

  // S03 / S05 Hồ sơ học tập & TKB 7 ngày
  static const String onboardingTitle = 'Thiết lập học tập nhanh';
  static const String onboardingSubtitle =
      'Bạn có thể bỏ qua bất kỳ bước nào hoặc sửa lại sau.';
  static const String selectGradeTitle = '1. Lớp đang học';
  static const String selectSubjectsTitle = '2. Môn đang học (chọn nhiều môn)';
  static const String selectPrioritiesTitle = '3. Môn ưu tiên ôn thi (tối đa 5 môn)';
  static const String goalLabelTitle = '4. Mục tiêu cá nhân (có thể sửa)';
  static const String goalLabelHint = 'Ví dụ: Ôn thi học kỳ, Vào lớp 10...';
  static const String finishSetupAndSave = 'Lưu thiết lập';
  static const String skipToAlarmOnly = 'Chỉ báo thức · Để sau';

  static const String timetableTitle = 'Thời khóa biểu & Hồ sơ';
  static const String restDayLabel = 'Ngày nghỉ';
  static const String addPeriodButton = 'Thêm tiết môn';
  static const String editPeriodTitle = 'Chỉnh sửa tiết học';
  static const String savePeriodButton = 'Lưu tiết';
  static const String deletePeriodButton = 'Xóa tiết';
  static const String editProfileSection = 'Chỉnh sửa lớp, môn & mục tiêu';
  static const String saveProfileChanges = 'Lưu thay đổi hồ sơ';

  // S06 Cấu hình báo thức & gợi ý giờ dậy
  static const String alarmConfigTitle = 'Cấu hình báo thức';
  static const String alarmTimeTitle = 'Giờ báo thức (tự chọn)';
  static const String alarmRepeatTitle = 'Ngày lặp trong tuần';
  static const String alarmSoundTitle = 'Âm thanh chuông';
  static const String alarmVibrateLabel = 'Rung khi chuông reo';
  static const String alarmEnabledLabel = 'Bật cấu hình báo thức này';
  static const String normalModeTitle = 'Báo thức thường';
  static const String normalModeDesc = 'Có nút Hoãn 5 phút và Dừng khẩn cấp.';
  static const String challengeModeTitle = 'Báo thức thử thách';
  static const String challengeModeNotice =
      'Không có nút Hoãn. Bạn sẽ làm một câu ngắn để hoàn thành. Dừng khẩn cấp luôn có 1 chạm.';
  static const String saveAlarmButton = 'Lưu cấu hình báo thức';

  // Trạng thái dịch vụ báo thức
  static const String alarmSavedConfigOnly = 'Đã lưu cấu hình';
  static const String alarmReadyOs = 'Đã sẵn sàng';
  static const String alarmPermissionMissingLabel = 'Cần cấp quyền báo thức';
  static const String alarmOsUnboundExplain =
      'Chuông báo thức hoạt động trực tiếp trên điện thoại ngay cả khi bạn chưa mở ứng dụng.';
  static const String alarmPermissionMissingExplain =
      'Vui lòng cấp quyền báo thức và thông báo để chuông reo đúng giờ trên màn hình khóa.';
  static const String batteryOptimizationNote =
      'Trên một số máy Android (Xiaomi/Samsung/Oppo), chế độ tiết kiệm pin nghiêm ngặt có thể làm trễ chuông nếu tắt nền.';

  // S07 Màn chuông đang reo
  static const String ringOpenQuestion = 'Mở câu hỏi';
  static const String ringSnooze5m = 'Hoãn 5 phút';
  static const String ringEmergencyStop = 'Dừng khẩn cấp';
  static const String ringSoundStoppedReviewNotice =
      'Đã dừng âm báo · Hoàn thành câu ôn để nhận thưởng.';
  static const String ringChallengeHint =
      'Chế độ thử thách không hỗ trợ Hoãn. Dừng khẩn cấp luôn hoạt động 1 chạm.';
  static const String ringNormalHint =
      'Chế độ thường: bạn có thể Hoãn 5 phút hoặc dừng chuông ngay.';

  // T017 Luồng cá nhân online/offline & quyền riêng tư ảnh
  static const String debugFixtureLabel = 'Chế độ thử nghiệm';
  static const String photoPrivacyNotice =
      'Ảnh bài làm sẽ được gửi để nhận phản hồi. Không chụp tên hoặc thông tin riêng. Bạn có thể nhập đáp án thay thế.';
  static const String draftUploadConfirmQuestion =
      'Gửi bài này để nhận nhận xét?';

  // Không gian học
  static const String studySpaceTitle = 'Không gian học';
  static const String studyStartCta = 'Bắt đầu học';
  static const String studyNoAppLockExplain =
      'MindClock không khóa các ứng dụng khác trên điện thoại. Bạn tự chủ động quản lý thời gian tập trung của mình.';
  static const String studyNoCameraAiScopeNotice =
      'Camera và micro đang tắt. Ứng dụng không tự quay video hay ghi âm khi bạn học.';
  static const String studyPausedLabel = 'Đang tạm nghỉ';
  static const String studyInterruptedLabel = 'Phiên đã gián đoạn';
  static const String studyResumeCta = 'Tiếp tục học';
  static const String studyPauseCta = 'Tạm nghỉ';
  static const String studyFinishCta = 'Kết thúc';
  static const String studySaveCta = 'Lưu phiên';

  // Gợi ý giờ dậy
  static const String wakeSuggestionTitle = 'Gợi ý giờ dậy theo lịch (tùy chọn)';
  static const String useWakeSuggestionButton = 'Dùng giờ này';
  static const String wakeFormulaLabel = 'Phép tính giờ dậy muộn nhất';
  static const String wakeScheduleChangedNotice =
      'Lịch học đã đổi. Giờ báo thức bạn tự chọn vẫn giữ nguyên; bạn có thể tự xem lại gợi ý nếu muốn.';
}
