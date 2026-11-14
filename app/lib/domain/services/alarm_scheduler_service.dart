import 'package:flutter/services.dart';

import '../models/alarm_config.dart';

enum OsPermissionState {
  unknown,
  granted,
  denied,
}

enum AlarmBridgeErrorCode {
  ok('OK'),
  bridgeUnbound('BRIDGE_UNBOUND'),
  unsupportedVersion('UNSUPPORTED_BRIDGE_VERSION'),
  invalidArgument('INVALID_ARGUMENT'),
  permissionExactAlarmDenied('PERMISSION_EXACT_ALARM_DENIED'),
  permissionNotificationDenied('PERMISSION_NOTIFICATION_DENIED'),
  permissionFullScreenDenied('PERMISSION_FULL_SCREEN_DENIED'),
  osScheduleFailed('OS_SCHEDULE_FAILED'),
  unknown('UNKNOWN_ERROR');

  const AlarmBridgeErrorCode(this.wireCode);
  final String wireCode;

  static AlarmBridgeErrorCode fromWire(String? code) {
    for (final AlarmBridgeErrorCode value in values) {
      if (value.wireCode == code) return value;
    }
    return AlarmBridgeErrorCode.unknown;
  }
}

enum AlarmPermissionAction {
  exactAlarmSettings('exact_alarm'),
  notificationSettings('notifications'),
  fullScreenIntentSettings('full_screen_intent'),
  batteryOptimizationSettings('battery_optimization');

  const AlarmPermissionAction(this.wireAction);
  final String wireAction;
}

class AlarmRingPayload {
  const AlarmRingPayload({
    required this.alarmId,
    required this.formattedTime,
    required this.mode,
    required this.label,
    this.subjectCode,
    this.triggeredAtEpochMillis,
  });

  final String alarmId;
  final String formattedTime;
  final AlarmMode mode;
  final String label;
  final String? subjectCode;
  final int? triggeredAtEpochMillis;

  factory AlarmRingPayload.fromMap(Map<dynamic, dynamic> map) {
    final String rawMode = map['mode'] as String? ?? 'normal';
    return AlarmRingPayload(
      alarmId: map['alarmId'] as String? ?? '',
      formattedTime: map['formattedTime'] as String? ?? '06:00',
      mode: AlarmMode.values.firstWhere(
        (AlarmMode m) => m.name == rawMode,
        orElse: () => AlarmMode.normal,
      ),
      label: map['label'] as String? ?? 'Báo thức buổi sáng',
      subjectCode: map['subjectCode'] as String?,
      triggeredAtEpochMillis: (map['triggeredAtEpochMillis'] as num?)?.toInt(),
    );
  }
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
      notifications == OsPermissionState.granted &&
      fullScreenIntent == OsPermissionState.granted;

  List<AlarmPermissionAction> missingActions() {
    if (!isOsBridgeConnected) return const <AlarmPermissionAction>[];
    final List<AlarmPermissionAction> actions = <AlarmPermissionAction>[];
    if (exactAlarm == OsPermissionState.denied) {
      actions.add(AlarmPermissionAction.exactAlarmSettings);
    }
    if (notifications == OsPermissionState.denied) {
      actions.add(AlarmPermissionAction.notificationSettings);
    }
    if (fullScreenIntent == OsPermissionState.denied) {
      actions.add(AlarmPermissionAction.fullScreenIntentSettings);
    }
    return actions;
  }

  factory AlarmPermissionSnapshot.fromMap(
    Map<dynamic, dynamic>? map, {
    required bool isConnected,
  }) {
    if (map == null || !isConnected) {
      return const AlarmPermissionSnapshot.unbound();
    }
    return AlarmPermissionSnapshot(
      isOsBridgeConnected: isConnected,
      exactAlarm: _parsePerm(map['exactAlarm'] as String?),
      notifications: _parsePerm(map['notifications'] as String?),
      fullScreenIntent: _parsePerm(map['fullScreenIntent'] as String?),
    );
  }

  static OsPermissionState _parsePerm(String? raw) {
    switch (raw) {
      case 'granted':
        return OsPermissionState.granted;
      case 'denied':
        return OsPermissionState.denied;
      default:
        return OsPermissionState.unknown;
    }
  }
}

class AlarmServiceCapabilities {
  const AlarmServiceCapabilities({
    required this.bridgeVersion,
    required this.isOsBridgeConnected,
    required this.supportsExactAlarm,
    required this.supportsFullScreenIntent,
    required this.statusSummaryVi,
    this.errorCode = AlarmBridgeErrorCode.ok,
  });

  final int bridgeVersion;
  final bool isOsBridgeConnected;
  final bool supportsExactAlarm;
  final bool supportsFullScreenIntent;
  final String statusSummaryVi;
  final AlarmBridgeErrorCode errorCode;
}

class AlarmScheduleResult {
  const AlarmScheduleResult({
    required this.status,
    required this.errorCode,
    required this.messageVi,
    required this.permissionSnapshot,
    this.scheduledNextEpochMillis,
  });

  final AlarmSyncStatus status;
  final AlarmBridgeErrorCode errorCode;
  final String messageVi;
  final AlarmPermissionSnapshot permissionSnapshot;
  final int? scheduledNextEpochMillis;
}

/// Interface dịch vụ báo thức để nối Android native (`MethodChannel` / `AlarmManager`).
abstract interface class AlarmSchedulerService {
  static const int currentBridgeVersion = 1;
  static const String channelName = 'mindclock/alarm_scheduler';

  int get bridgeVersion;

  bool get isOsBridgeConnected;

  Future<AlarmServiceCapabilities> checkCapabilities();

  Future<AlarmPermissionSnapshot> getPermissionStatus();

  Future<AlarmScheduleResult> scheduleAlarm(AlarmConfig alarm);

  Future<AlarmScheduleResult> cancelAlarm(String alarmId);

  Future<AlarmScheduleResult> snoozeAlarm(AlarmConfig alarm, {int minutes = 5});

  Future<AlarmScheduleResult> triggerEmergencyStop(String? alarmId);

  Future<bool> openPermissionSettings(AlarmPermissionAction action);

  Future<AlarmRingPayload?> consumePendingRingLaunch();
}

/// Triển khai mặc định khi không chạy trên Android native hoặc trong unit test tách OS.
class UnboundAlarmSchedulerService implements AlarmSchedulerService {
  const UnboundAlarmSchedulerService();

  @override
  int get bridgeVersion => AlarmSchedulerService.currentBridgeVersion;

  @override
  bool get isOsBridgeConnected => false;

  @override
  Future<AlarmServiceCapabilities> checkCapabilities() async {
    return AlarmServiceCapabilities(
      bridgeVersion: bridgeVersion,
      isOsBridgeConnected: false,
      supportsExactAlarm: false,
      supportsFullScreenIntent: false,
      errorCode: AlarmBridgeErrorCode.bridgeUnbound,
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
      errorCode: AlarmBridgeErrorCode.bridgeUnbound,
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
      errorCode: AlarmBridgeErrorCode.bridgeUnbound,
      messageVi: 'Đã lưu cấu hình.',
      permissionSnapshot: AlarmPermissionSnapshot.unbound(),
      scheduledNextEpochMillis: null,
    );
  }

  @override
  Future<AlarmScheduleResult> snoozeAlarm(
    AlarmConfig alarm, {
    int minutes = 5,
  }) async {
    if (alarm.mode == AlarmMode.challenge) {
      return const AlarmScheduleResult(
        status: AlarmSyncStatus.savedConfigOnly,
        errorCode: AlarmBridgeErrorCode.invalidArgument,
        messageVi: 'Chế độ thử thách không hỗ trợ Hoãn.',
        permissionSnapshot: AlarmPermissionSnapshot.unbound(),
      );
    }
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      errorCode: AlarmBridgeErrorCode.bridgeUnbound,
      messageVi: 'Đã ghi nhận hoãn cục bộ (chưa nối báo thức OS).',
      permissionSnapshot: AlarmPermissionSnapshot.unbound(),
    );
  }

  @override
  Future<AlarmScheduleResult> triggerEmergencyStop(String? alarmId) async {
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã dừng chuông trên ứng dụng.',
      permissionSnapshot: AlarmPermissionSnapshot.unbound(),
    );
  }

  @override
  Future<bool> openPermissionSettings(AlarmPermissionAction action) async {
    return false;
  }

  @override
  Future<AlarmRingPayload?> consumePendingRingLaunch() async {
    return null;
  }
}

/// Triển khai nối tầng Android Kotlin thông qua [MethodChannel] có version & mã lỗi ổn định.
class AndroidMethodChannelAlarmSchedulerService
    implements AlarmSchedulerService {
  AndroidMethodChannelAlarmSchedulerService({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel(AlarmSchedulerService.channelName);

  final MethodChannel _channel;
  bool _bridgeConfirmed = false;

  @override
  int get bridgeVersion => AlarmSchedulerService.currentBridgeVersion;

  @override
  bool get isOsBridgeConnected => _bridgeConfirmed;

  Map<String, dynamic> _versionedArgs([Map<String, dynamic>? extra]) {
    return <String, dynamic>{
      'bridgeVersion': bridgeVersion,
      if (extra != null) ...extra,
    };
  }

  bool _isCompatibleVersion(Map<dynamic, dynamic> response) {
    final int? reportedVersion =
        (response['bridgeVersion'] as num?)?.toInt();
    return reportedVersion == bridgeVersion;
  }

  @override
  Future<AlarmServiceCapabilities> checkCapabilities() async {
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'checkCapabilities',
        _versionedArgs(),
      );
      if (response == null) {
        _bridgeConfirmed = false;
        return const UnboundAlarmSchedulerService().checkCapabilities();
      }
      if (!_isCompatibleVersion(response)) {
        _bridgeConfirmed = false;
        return AlarmServiceCapabilities(
          bridgeVersion: (response['bridgeVersion'] as num?)?.toInt() ?? -1,
          isOsBridgeConnected: false,
          supportsExactAlarm: false,
          supportsFullScreenIntent: false,
          errorCode: AlarmBridgeErrorCode.unsupportedVersion,
          statusSummaryVi:
              'Phiên bản bridge Android không khớp (kỳ vọng v$bridgeVersion).',
        );
      }
      final bool connected = response['isOsBridgeConnected'] as bool? ?? true;
      _bridgeConfirmed = connected;
      return AlarmServiceCapabilities(
        bridgeVersion: bridgeVersion,
        isOsBridgeConnected: connected,
        supportsExactAlarm: response['supportsExactAlarm'] as bool? ?? false,
        supportsFullScreenIntent:
            response['supportsFullScreenIntent'] as bool? ?? false,
        errorCode: AlarmBridgeErrorCode.fromWire(
          response['errorCode'] as String?,
        ),
        statusSummaryVi: response['statusSummaryVi'] as String? ??
            'Đã kết nối dịch vụ báo thức local Android.',
      );
    } on MissingPluginException {
      _bridgeConfirmed = false;
      return const UnboundAlarmSchedulerService().checkCapabilities();
    } on PlatformException catch (e) {
      _bridgeConfirmed = false;
      return AlarmServiceCapabilities(
        bridgeVersion: bridgeVersion,
        isOsBridgeConnected: false,
        supportsExactAlarm: false,
        supportsFullScreenIntent: false,
        errorCode: AlarmBridgeErrorCode.fromWire(e.code),
        statusSummaryVi:
            e.message ?? 'Không thể kiểm tra dịch vụ báo thức hệ điều hành.',
      );
    }
  }

  @override
  Future<AlarmPermissionSnapshot> getPermissionStatus() async {
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'getPermissionStatus',
        _versionedArgs(),
      );
      if (response == null || !_isCompatibleVersion(response)) {
        _bridgeConfirmed = false;
        return const AlarmPermissionSnapshot.unbound();
      }
      _bridgeConfirmed = true;
      return AlarmPermissionSnapshot.fromMap(
        response,
        isConnected: true,
      );
    } on MissingPluginException {
      _bridgeConfirmed = false;
      return const AlarmPermissionSnapshot.unbound();
    } on PlatformException {
      return const AlarmPermissionSnapshot.unbound();
    }
  }

  @override
  Future<AlarmScheduleResult> scheduleAlarm(AlarmConfig alarm) async {
    if (!alarm.enabled) {
      return cancelAlarm(alarm.id);
    }
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'scheduleAlarm',
        _versionedArgs(alarm.toJson()),
      );
      if (response == null) {
        _bridgeConfirmed = false;
        return const UnboundAlarmSchedulerService().scheduleAlarm(alarm);
      }
      return _parseScheduleResponse(response);
    } on MissingPluginException {
      _bridgeConfirmed = false;
      return const UnboundAlarmSchedulerService().scheduleAlarm(alarm);
    } on PlatformException catch (e) {
      return AlarmScheduleResult(
        status: AlarmSyncStatus.osFailed,
        errorCode: AlarmBridgeErrorCode.fromWire(e.code),
        messageVi: e.message ?? 'Không lập lịch được báo thức trên Android.',
        permissionSnapshot: const AlarmPermissionSnapshot.unbound(),
      );
    }
  }

  @override
  Future<AlarmScheduleResult> cancelAlarm(String alarmId) async {
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'cancelAlarm',
        _versionedArgs(<String, dynamic>{'alarmId': alarmId}),
      );
      if (response == null) {
        _bridgeConfirmed = false;
        return const UnboundAlarmSchedulerService().cancelAlarm(alarmId);
      }
      return _parseScheduleResponse(response);
    } on MissingPluginException {
      _bridgeConfirmed = false;
      return const UnboundAlarmSchedulerService().cancelAlarm(alarmId);
    } on PlatformException catch (e) {
      return AlarmScheduleResult(
        status: AlarmSyncStatus.osFailed,
        errorCode: AlarmBridgeErrorCode.fromWire(e.code),
        messageVi: e.message ?? 'Không hủy được lịch báo thức trên Android.',
        permissionSnapshot: const AlarmPermissionSnapshot.unbound(),
      );
    }
  }

  @override
  Future<AlarmScheduleResult> snoozeAlarm(
    AlarmConfig alarm, {
    int minutes = 5,
  }) async {
    if (alarm.mode == AlarmMode.challenge) {
      return AlarmScheduleResult(
        status: AlarmSyncStatus.osFailed,
        errorCode: AlarmBridgeErrorCode.invalidArgument,
        messageVi: 'Chế độ thử thách không hỗ trợ Hoãn.',
        permissionSnapshot: await getPermissionStatus(),
      );
    }
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'snoozeAlarm',
        _versionedArgs(<String, dynamic>{
          ...alarm.toJson(),
          'snoozeMinutes': minutes,
        }),
      );
      if (response == null) {
        return const UnboundAlarmSchedulerService().snoozeAlarm(
          alarm,
          minutes: minutes,
        );
      }
      return _parseScheduleResponse(response);
    } on MissingPluginException {
      return const UnboundAlarmSchedulerService().snoozeAlarm(
        alarm,
        minutes: minutes,
      );
    } on PlatformException catch (e) {
      return AlarmScheduleResult(
        status: AlarmSyncStatus.osFailed,
        errorCode: AlarmBridgeErrorCode.fromWire(e.code),
        messageVi: e.message ?? 'Không đặt được Hoãn trên Android.',
        permissionSnapshot: const AlarmPermissionSnapshot.unbound(),
      );
    }
  }

  @override
  Future<AlarmScheduleResult> triggerEmergencyStop(String? alarmId) async {
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'emergencyStop',
        _versionedArgs(<String, dynamic>{'alarmId': alarmId ?? ''}),
      );
      if (response == null) {
        return const UnboundAlarmSchedulerService().triggerEmergencyStop(alarmId);
      }
      return _parseScheduleResponse(response);
    } on MissingPluginException {
      return const UnboundAlarmSchedulerService().triggerEmergencyStop(alarmId);
    } on PlatformException {
      return const AlarmScheduleResult(
        status: AlarmSyncStatus.savedConfigOnly,
        errorCode: AlarmBridgeErrorCode.ok,
        messageVi: 'Đã gửi yêu cầu dừng khẩn cấp cục bộ.',
        permissionSnapshot: AlarmPermissionSnapshot.unbound(),
      );
    }
  }

  @override
  Future<bool> openPermissionSettings(AlarmPermissionAction action) async {
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'openPermissionSettings',
        _versionedArgs(<String, dynamic>{'action': action.wireAction}),
      );
      if (response == null || !_isCompatibleVersion(response)) {
        return false;
      }
      return response['opened'] as bool? ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<AlarmRingPayload?> consumePendingRingLaunch() async {
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'consumePendingRingLaunch',
        _versionedArgs(),
      );
      if (response == null || !_isCompatibleVersion(response)) {
        return null;
      }
      final Object? rawPayload = response['payload'];
      if (rawPayload is Map<dynamic, dynamic>) {
        return AlarmRingPayload.fromMap(rawPayload);
      }
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  AlarmScheduleResult _parseScheduleResponse(Map<dynamic, dynamic> response) {
    if (!_isCompatibleVersion(response)) {
      _bridgeConfirmed = false;
      return AlarmScheduleResult(
        status: AlarmSyncStatus.osFailed,
        errorCode: AlarmBridgeErrorCode.unsupportedVersion,
        messageVi: 'Phiên bản bridge Android không khớp (kỳ vọng v$bridgeVersion).',
        permissionSnapshot: const AlarmPermissionSnapshot.unbound(),
      );
    }

    _bridgeConfirmed = true;
    final AlarmBridgeErrorCode code = AlarmBridgeErrorCode.fromWire(
      response['errorCode'] as String?,
    );
    final AlarmPermissionSnapshot perms = AlarmPermissionSnapshot.fromMap(
      response['permissions'] as Map<dynamic, dynamic>?,
      isConnected: true,
    );

    final String rawStatus = response['status'] as String? ?? 'savedConfigOnly';
    AlarmSyncStatus parsedStatus = AlarmSyncStatus.values.firstWhere(
      (AlarmSyncStatus s) => s.name == rawStatus,
      orElse: () => AlarmSyncStatus.savedConfigOnly,
    );

    // Chốt an toàn: tuyệt đối không trả scheduledReady nếu mã lỗi khác OK
    // hoặc thiếu bất kỳ quyền cốt lõi nào.
    if (parsedStatus == AlarmSyncStatus.scheduledReady &&
        (code != AlarmBridgeErrorCode.ok || !perms.allGranted)) {
      parsedStatus = AlarmSyncStatus.osPermissionMissing;
    }

    return AlarmScheduleResult(
      status: parsedStatus,
      errorCode: code,
      messageVi: response['messageVi'] as String? ?? 'Đã lưu cấu hình.',
      permissionSnapshot: perms,
      scheduledNextEpochMillis:
          (response['scheduledNextEpochMillis'] as num?)?.toInt(),
    );
  }
}
