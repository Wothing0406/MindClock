/// Chuỗi tiếng Việt `vi-VN` chuẩn hóa theo `docs/05`, `docs/30`, `docs/31`, `docs/32`, `docs/55`.
///
/// Không dùng emoji hệ thống, không khẩu hiệu phóng đại, không báo `Đã sẵn sàng`
/// khi chưa nối dịch vụ báo thức hệ điều hành Android.
class AppStrings {
  const AppStrings._();

  static const String appName = 'MindClock';
  static const String guestBadge = 'Chế độ khách · Lưu trên máy';

  // S01 Chào mừng
  static const String welcomeTitle = 'Dậy đúng giờ. Nghĩ bằng chính mình.';
  static const String welcomeSubtitle =
      'Chọn lịch học và đặt báo thức trên máy, không cần tạo tài khoản.';
  static const String tryGuestCta = 'Dùng thử không cần tài khoản';
  static const String setupLaterCta = 'Để sau';
  static const String alarmOnlyCta = 'Chỉ báo thức';
  static const String guestPrivacyNote =
      'Dữ liệu lớp, môn học, thời khóa biểu và báo thức chỉ lưu trên máy của bạn.';

  // 3 tab điều hướng (lược bỏ hoàn toàn Đấu trường)
  static const String navToday = 'Hôm nay';
  static const String navPractice = 'Luyện tập';
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
  static const String alarmSubjectTitle = 'Môn kèm theo buổi sáng (tùy chọn)';
  static const String alarmModeTitle = 'Chế độ khi báo thức reo';
  static const String normalModeTitle = 'Báo thức thường';
  static const String normalModeDesc = 'Có nút Hoãn 5 phút và Dừng khẩn cấp.';
  static const String challengeModeTitle = 'Báo thức thử thách (tự chọn)';
  static const String challengeModeNotice =
      'Không có nút Hoãn. Bạn sẽ làm một câu ngắn để hoàn thành. Dừng khẩn cấp luôn có 1 chạm.';
  static const String unapprovedSubjectExplain =
      'Môn này chưa có câu ôn được duyệt. Bạn vẫn đặt được báo thức; khi reo hệ thống dùng chế độ thường / Chỉ báo thức để không khóa chuông.';
  static const String saveAlarmButton = 'Lưu cấu hình báo thức';

  // Trạng thái dịch vụ báo thức & OS Android
  static const String alarmSavedConfigOnly = 'Đã lưu cấu hình';
  static const String alarmReadyOs = 'Đã sẵn sàng';
  static const String alarmPermissionMissingLabel = 'Thiếu quyền báo thức OS';
  static const String alarmOsUnboundExplain =
      'Chưa nối báo thức hệ thống Android ở giai đoạn này. Quyền OS ở trạng thái chưa kiểm tra; hệ thống không báo Đã sẵn sàng giả.';
  static const String alarmPermissionMissingExplain =
      'Hệ thống chưa thể báo Đã sẵn sàng vì Android đang thiếu quyền báo thức, thông báo hoặc toàn màn hình khóa.';
  static const String batteryOptimizationNote =
      'Trên một số máy Android (Xiaomi/Samsung/Oppo), chế độ tiết kiệm pin nghiêm ngặt có thể làm trễ chuông nếu tắt nền.';

  // S07 Màn chuông đang reo
  static const String ringOpenQuestion = 'Mở câu hỏi';
  static const String ringSnooze5m = 'Hoãn 5 phút';
  static const String ringEmergencyStop = 'Dừng khẩn cấp';
  static const String ringChallengeHint =
      'Chế độ thử thách không hỗ trợ Hoãn. Dừng khẩn cấp luôn hoạt động 1 chạm.';
  static const String ringNormalHint =
      'Chế độ thường: bạn có thể Hoãn 5 phút hoặc dừng chuông ngay.';

  // Gợi ý giờ dậy
  static const String wakeSuggestionTitle = 'Gợi ý giờ dậy theo lịch (tùy chọn)';
  static const String useWakeSuggestionButton = 'Dùng giờ này';
  static const String wakeFormulaLabel = 'Phép tính giờ dậy muộn nhất';
  static const String wakeScheduleChangedNotice =
      'Lịch học đã đổi. Giờ báo thức bạn tự chọn vẫn giữ nguyên; bạn có thể tự xem lại gợi ý nếu muốn.';
}
