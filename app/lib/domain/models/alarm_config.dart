enum AlarmMode {
  normal,
  challenge,
}

enum AlarmSoundOption {
  gentleDawn('gentle_dawn', 'Chuông sáng dịu'),
  clearBell('clear_bell', 'Chuông rõ'),
  silentVibrateOnly('vibrate_only', 'Chỉ rung (không âm)');

  const AlarmSoundOption(this.id, this.labelVi);
  final String id;
  final String labelVi;

  static AlarmSoundOption fromId(String? id) {
    for (final AlarmSoundOption option in values) {
      if (option.id == id) return option;
    }
    return gentleDawn;
  }
}

/// Trạng thái đồng bộ cấu hình báo thức với hệ điều hành.
enum AlarmSyncStatus {
  /// Chưa nối tầng native OS: chỉ mới lưu cấu hình cục bộ trên máy.
  savedConfigOnly,

  /// Đã nối OS và đang chờ hệ thống đặt lịch.
  pendingOsSync,

  /// CHỈ dùng khi OS thật sự xác nhận đặt lịch thành công.
  scheduledReady,

  /// Thiếu quyền OS (exact alarm / notification / full-screen intent).
  osPermissionMissing,

  /// Lỗi khi gọi OS đặt lịch.
  osFailed,
}

/// Trạng thái đồng bộ cấu hình báo thức với backend `/v1/alarms` (`docs/07 §§2–3, 8`).
///
/// Tách biệt hoàn toàn khỏi [AlarmSyncStatus]: server lỗi không bao giờ hủy chuông local.
enum AlarmServerSyncStatus {
  localOnly,
  syncing,
  synced,
  syncFailed;

  static AlarmServerSyncStatus fromWire(String? value) {
    for (final AlarmServerSyncStatus status in values) {
      if (status.name == value) return status;
    }
    return AlarmServerSyncStatus.localOnly;
  }
}

/// Cấu hình một báo thức local do người dùng tự đặt và giữ nguyên cho tới khi người dùng sửa.
class AlarmConfig {
  const AlarmConfig({
    required this.id,
    required this.hour,
    required this.minute,
    this.repeatWeekdays = const <int>[1, 2, 3, 4, 5],
    this.enabled = true,
    this.soundEnabled = true,
    this.soundOption = AlarmSoundOption.gentleDawn,
    this.vibrateEnabled = true,
    this.mode = AlarmMode.normal,
    this.subjectCode,
    this.label = 'Báo thức buổi sáng',
    this.syncStatus = AlarmSyncStatus.savedConfigOnly,
    this.serverSyncStatus = AlarmServerSyncStatus.localOnly,
    this.serverAlarmId,
    this.serverRevision,
    this.serverSyncedOwnerScope,
    this.lastServerSyncErrorVi,
  });

  final String id;
  final int hour;
  final int minute;
  final List<int> repeatWeekdays;
  final bool enabled;
  final bool soundEnabled;
  final AlarmSoundOption soundOption;
  final bool vibrateEnabled;
  final AlarmMode mode;
  final String? subjectCode;
  final String label;
  final AlarmSyncStatus syncStatus;
  final AlarmServerSyncStatus serverSyncStatus;
  final String? serverAlarmId;
  final int? serverRevision;
  final String? serverSyncedOwnerScope;
  final String? lastServerSyncErrorVi;

  int get totalMinutes => (hour % 24) * 60 + (minute % 60);

  String get formattedTime =>
      '${(hour % 24).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

  bool get snoozeAllowed => mode == AlarmMode.normal;

  AlarmConfig copyWith({
    String? id,
    int? hour,
    int? minute,
    List<int>? repeatWeekdays,
    bool? enabled,
    bool? soundEnabled,
    AlarmSoundOption? soundOption,
    bool? vibrateEnabled,
    AlarmMode? mode,
    String? subjectCode,
    bool clearSubjectCode = false,
    String? label,
    AlarmSyncStatus? syncStatus,
    AlarmServerSyncStatus? serverSyncStatus,
    String? serverAlarmId,
    bool clearServerAlarmId = false,
    int? serverRevision,
    bool clearServerRevision = false,
    String? serverSyncedOwnerScope,
    bool clearServerSyncedOwnerScope = false,
    String? lastServerSyncErrorVi,
    bool clearLastServerSyncError = false,
  }) {
    return AlarmConfig(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundOption: soundOption ?? this.soundOption,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
      mode: mode ?? this.mode,
      subjectCode: clearSubjectCode ? null : (subjectCode ?? this.subjectCode),
      label: label ?? this.label,
      syncStatus: syncStatus ?? this.syncStatus,
      serverSyncStatus: serverSyncStatus ?? this.serverSyncStatus,
      serverAlarmId:
          clearServerAlarmId ? null : (serverAlarmId ?? this.serverAlarmId),
      serverRevision:
          clearServerRevision ? null : (serverRevision ?? this.serverRevision),
      serverSyncedOwnerScope: clearServerSyncedOwnerScope
          ? null
          : (serverSyncedOwnerScope ?? this.serverSyncedOwnerScope),
      lastServerSyncErrorVi: clearLastServerSyncError
          ? null
          : (lastServerSyncErrorVi ?? this.lastServerSyncErrorVi),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'hour': hour,
        'minute': minute,
        'repeatWeekdays': repeatWeekdays,
        'enabled': enabled,
        'soundEnabled': soundEnabled,
        'soundOption': soundOption.id,
        'vibrateEnabled': vibrateEnabled,
        'mode': mode.name,
        'subjectCode': subjectCode,
        'label': label,
        'syncStatus': syncStatus.name,
        'serverSyncStatus': serverSyncStatus.name,
        'serverAlarmId': serverAlarmId,
        'serverRevision': serverRevision,
        'serverSyncedOwnerScope': serverSyncedOwnerScope,
        'lastServerSyncErrorVi': lastServerSyncErrorVi,
      };

  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawWeekdays =
        json['repeatWeekdays'] as List<dynamic>? ?? <dynamic>[1, 2, 3, 4, 5];
    final String rawMode = json['mode'] as String? ?? 'normal';
    final String rawSync = json['syncStatus'] as String? ?? 'savedConfigOnly';

    return AlarmConfig(
      id: json['id'] as String? ?? 'primary_morning',
      hour: (json['hour'] as num?)?.toInt() ?? 6,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      repeatWeekdays: rawWeekdays
          .whereType<num>()
          .map((num n) => n.toInt())
          .where((int d) => d >= 1 && d <= 7)
          .toList(growable: false),
      enabled: json['enabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      soundOption: AlarmSoundOption.fromId(json['soundOption'] as String?),
      vibrateEnabled: json['vibrateEnabled'] as bool? ?? true,
      mode: AlarmMode.values.firstWhere(
        (AlarmMode m) => m.name == rawMode,
        orElse: () => AlarmMode.normal,
      ),
      subjectCode: json['subjectCode'] as String?,
      label: json['label'] as String? ?? 'Báo thức buổi sáng',
      syncStatus: AlarmSyncStatus.values.firstWhere(
        (AlarmSyncStatus s) => s.name == rawSync,
        orElse: () => AlarmSyncStatus.savedConfigOnly,
      ),
      serverSyncStatus:
          AlarmServerSyncStatus.fromWire(json['serverSyncStatus'] as String?),
      serverAlarmId: json['serverAlarmId'] as String?,
      serverRevision: (json['serverRevision'] as num?)?.toInt(),
      serverSyncedOwnerScope: json['serverSyncedOwnerScope'] as String?,
      lastServerSyncErrorVi: json['lastServerSyncErrorVi'] as String?,
    );
  }
}
