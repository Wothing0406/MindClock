import '../models/alarm_config.dart';

class RemoteAlarmRecord {
  const RemoteAlarmRecord({
    required this.serverAlarmId,
    required this.revision,
    required this.localTime,
    required this.weekdays,
    required this.enabled,
    required this.challengeMode,
    this.snoozeMinutes,
  });

  final String serverAlarmId;
  final int revision;
  final String localTime;
  final List<int> weekdays;
  final bool enabled;
  final String challengeMode;
  final int? snoozeMinutes;

  factory RemoteAlarmRecord.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDays =
        json['weekdays'] as List<dynamic>? ?? const <dynamic>[];
    return RemoteAlarmRecord(
      serverAlarmId: (json['alarmId'] ?? json['id'] ?? '').toString(),
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      localTime: json['localTime'] as String? ?? '06:00',
      weekdays: rawDays.whereType<num>().map((num d) => d.toInt()).toList(),
      enabled: json['enabled'] as bool? ?? true,
      challengeMode: json['challengeMode'] as String? ?? 'none',
      snoozeMinutes: (json['snoozeMinutes'] as num?)?.toInt(),
    );
  }
}

/// Sự kiện báo thức (bao gồm `dismiss` từ Dừng khẩn cấp) lưu cục bộ tối đa 7 ngày
/// để đồng bộ sau lên server mà KHÔNG bao giờ phát lại chuông (`docs/07 §8`).
class PendingAlarmServerEvent {
  const PendingAlarmServerEvent({
    required this.idempotencyKey,
    required this.ownerScopeKey,
    required this.sessionId,
    required this.alarmId,
    required this.eventType,
    required this.version,
    required this.occurredAtUtcIso,
    required this.createdAtEpochMs,
  });

  final String idempotencyKey;
  final String ownerScopeKey;
  final String sessionId;
  final String alarmId;
  final String eventType;
  final int version;
  final String occurredAtUtcIso;
  final int createdAtEpochMs;

  bool isExpiredAt(DateTime now) {
    return now.millisecondsSinceEpoch - createdAtEpochMs >
        const Duration(days: 7).inMilliseconds;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'idempotencyKey': idempotencyKey,
        'ownerScopeKey': ownerScopeKey,
        'sessionId': sessionId,
        'alarmId': alarmId,
        'eventType': eventType,
        'version': version,
        'occurredAtUtcIso': occurredAtUtcIso,
        'createdAtEpochMs': createdAtEpochMs,
      };

  factory PendingAlarmServerEvent.fromJson(Map<String, dynamic> json) {
    return PendingAlarmServerEvent(
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      ownerScopeKey: json['ownerScopeKey'] as String? ?? 'guest',
      sessionId: json['sessionId'] as String? ?? '',
      alarmId: json['alarmId'] as String? ?? '',
      eventType: json['eventType'] as String? ?? 'dismiss',
      version: (json['version'] as num?)?.toInt() ?? 1,
      occurredAtUtcIso: json['occurredAtUtcIso'] as String? ?? '',
      createdAtEpochMs: (json['createdAtEpochMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Gateway đồng bộ cấu hình báo thức & sự kiện dừng khẩn cấp với backend (`/v1`).
abstract interface class AlarmSyncGateway {
  bool get isDebugFixture;

  Future<List<RemoteAlarmRecord>> fetchRemoteAlarms();

  Future<RemoteAlarmRecord> upsertRemoteAlarm({
    required AlarmConfig localAlarm,
    required String timeZone,
    required String idempotencyKey,
  });

  Future<void> deleteRemoteAlarm({required String serverAlarmId});

  Future<void> sendSessionLifecycleEvent(PendingAlarmServerEvent event);
}
