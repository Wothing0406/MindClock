import '../models/alarm_config.dart';

enum OsPermissionState {
  unknown,
  granted,
  denied,
}

class AlarmPermissionSnapshot {
  const AlarmPermissionSnapshot({
    required this.isOsBridgeConnected,
    required this.exactAlarm,
    required this.notifications,
    required this.fullScreenIntent,
  });

  const AlarmPermissionSnapshot.unbound()
      : isOsBridgeConnected = false,
        exactAlarm = OsPermissionState.unknown,
        notifications = OsPermissionState.unknown,
        fullScreenIntent = OsPermissionState.unknown;

  final bool isOsBridgeConnected;
  final OsPermissionState exactAlarm;
  final OsPermissionState notifications;
  final OsPermissionState fullScreenIntent;

  bool get allGranted =>
      isOsBridgeConnected &&
      exactAlarm == OsPermissionState.granted &&
      notifications == OsPermissionState.granted;
}

class AlarmServiceCapabilities {
  const AlarmServiceCapabilities({
    required this.isOsBridgeConnected,
    required this.supportsExactAlarm,
    required this.supportsFullScreenIntent,
    required this.statusSummaryVi,
  });

  final bool isOsBridgeConnected;
  final bool supportsExactAlarm;
  final bool supportsFullScreenIntent;
  final String statusSummaryVi;
}

class AlarmScheduleResult {
  const AlarmScheduleResult({
    required this.status,
    required this.messageVi,
    required this.permissionSnapshot,
    this.scheduledNextEpochMillis,
  });

  final AlarmSyncStatus status;
  final String messageVi;
  final AlarmPermissionSnapshot permissionSnapshot;
  final int? scheduledNextEpochMillis;
}

/// Interface dịch vụ báo thức để giai đoạn Android native (`MethodChannel` /
/// `AlarmManager`) nối vào mà không đổi luồng UI hoặc dữ liệu.
abstract interface class AlarmSchedulerService {
  bool get isOsBridgeConnected;

  Future<AlarmServiceCapabilities> checkCapabilities();

  Future<AlarmPermissionSnapshot> getPermissionStatus();

  Future<AlarmScheduleResult> scheduleAlarm(AlarmConfig alarm);

  Future<AlarmScheduleResult> cancelAlarm(String alarmId);
}

/// Triển khai mặc định khi chưa nối tầng native Android OS.
///
/// Quy tắc bắt buộc:
/// - Chỉ trả [AlarmSyncStatus.savedConfigOnly] ("Đã lưu cấu hình").
/// - Tuyệt đối KHÔNG trả [AlarmSyncStatus.scheduledReady] ("Đã sẵn sàng")
///   và KHÔNG giả lập quyền OS là đã cấp.
class UnboundAlarmSchedulerService implements AlarmSchedulerService {
  const UnboundAlarmSchedulerService();

  @override
  bool get isOsBridgeConnected => false;

  @override
  Future<AlarmServiceCapabilities> checkCapabilities() async {
    return const AlarmServiceCapabilities(
      isOsBridgeConnected: false,
      supportsExactAlarm: false,
      supportsFullScreenIntent: false,
      statusSummaryVi:
          'Đã lưu cấu hình trên máy. Chưa nối báo thức hệ điều hành Android ở giai đoạn này.',
    );
  }

  @override
  Future<AlarmPermissionSnapshot> getPermissionStatus() async {
    return const AlarmPermissionSnapshot.unbound();
  }

  @override
  Future<AlarmScheduleResult> scheduleAlarm(AlarmConfig alarm) async {
    return AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      messageVi: alarm.enabled
          ? 'Đã lưu cấu hình (chưa nối báo thức hệ thống OS).'
          : 'Đã lưu cấu hình (báo thức đang tắt).',
      permissionSnapshot: const AlarmPermissionSnapshot.unbound(),
      scheduledNextEpochMillis: null,
    );
  }

  @override
  Future<AlarmScheduleResult> cancelAlarm(String alarmId) async {
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      messageVi: 'Đã lưu cấu hình.',
      permissionSnapshot: AlarmPermissionSnapshot.unbound(),
      scheduledNextEpochMillis: null,
    );
  }
}
