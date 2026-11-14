enum DigitalWellbeingTarget {
  digitalWellbeing,
  systemSettings,
  unavailable,
}

class DigitalWellbeingOpenResult {
  const DigitalWellbeingOpenResult({
    required this.opened,
    required this.target,
    required this.messageVi,
  });

  final bool opened;
  final DigitalWellbeingTarget target;
  final String messageVi;
}

enum StudyNotificationPermission {
  unknown,
  granted,
  denied,
}

/// Cầu nối hẹp sang Android native cho Không gian học (`mindclock/study_focus`).
///
/// Tuyệt đối tách biệt với `AlarmSchedulerService` (`mindclock/alarm_scheduler`),
/// không dùng Accessibility, overlay, UsageStats hay kiosk lock-task.
abstract interface class StudyFocusBridge {
  bool get isPlatformConnected;

  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings();

  Future<StudyNotificationPermission> getNotificationPermissionStatus();

  Future<StudyNotificationPermission> requestNotificationPermission();

  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  });

  Future<void> cancelStudyReminder();

  Future<void> playSessionEndCue();
}

class UnboundStudyFocusBridge implements StudyFocusBridge {
  const UnboundStudyFocusBridge();

  @override
  bool get isPlatformConnected => false;

  @override
  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings() async {
    return const DigitalWellbeingOpenResult(
      opened: false,
      target: DigitalWellbeingTarget.unavailable,
      messageVi:
          'Thiết bị hiện chưa nối cài đặt Digital Wellbeing Focus mode. MindClock không khóa các app khác; bạn có thể tự bật Focus mode trong Cài đặt Android.',
    );
  }

  @override
  Future<StudyNotificationPermission> getNotificationPermissionStatus() async {
    return StudyNotificationPermission.unknown;
  }

  @override
  Future<StudyNotificationPermission> requestNotificationPermission() async {
    return StudyNotificationPermission.denied;
  }

  @override
  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  }) async {}

  @override
  Future<void> cancelStudyReminder() async {}

  @override
  Future<void> playSessionEndCue() async {}
}
