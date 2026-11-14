import '../../domain/models/alarm_config.dart';
import '../../domain/services/alarm_sync_gateway.dart';
import '../services/personal_api_client.dart';

/// Gateway đồng bộ `/v1/alarms` & `/v1/sessions/{id}/events` tái sử dụng `PersonalApiClient`.
///
/// Server không bao giờ ghi đè trạng thái lập lịch OS local; chỉ đồng bộ metadata cấu hình.
class RemoteAlarmSyncGateway implements AlarmSyncGateway {
  const RemoteAlarmSyncGateway({required PersonalApiClient apiClient})
      : _apiClient = apiClient;

  final PersonalApiClient _apiClient;

  @override
  bool get isDebugFixture => false;

  @override
  Future<List<RemoteAlarmRecord>> fetchRemoteAlarms() async {
    final Map<String, dynamic> json = await _apiClient.getJson('/alarms');
    final List<dynamic> items =
        json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(RemoteAlarmRecord.fromJson)
        .where((RemoteAlarmRecord r) => r.serverAlarmId.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<RemoteAlarmRecord> upsertRemoteAlarm({
    required AlarmConfig localAlarm,
    required String timeZone,
    required String idempotencyKey,
  }) async {
    final String challengeMode =
        localAlarm.mode == AlarmMode.challenge ? 'short_review' : 'none';
    final int? snoozeMinutes = localAlarm.snoozeAllowed ? 5 : null;

    if (localAlarm.serverAlarmId != null &&
        localAlarm.serverAlarmId!.isNotEmpty) {
      final Map<String, dynamic> json = await _apiClient.patchJson(
        '/alarms/${localAlarm.serverAlarmId}',
        idempotencyKey: idempotencyKey,
        body: <String, dynamic>{
          'localTime': localAlarm.formattedTime,
          'timeZone': timeZone,
          'weekdays': localAlarm.repeatWeekdays,
          'enabled': localAlarm.enabled,
          'challengeMode': challengeMode,
          'snoozeMinutes': snoozeMinutes,
          'revision': localAlarm.serverRevision ?? 1,
        },
      );
      return RemoteAlarmRecord.fromJson(json);
    }

    final Map<String, dynamic> json = await _apiClient.postJson(
      '/alarms',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'localTime': localAlarm.formattedTime,
        'timeZone': timeZone,
        'weekdays': localAlarm.repeatWeekdays,
        'enabled': localAlarm.enabled,
        'challengeMode': challengeMode,
        'snoozeMinutes': snoozeMinutes,
      },
    );
    return RemoteAlarmRecord.fromJson(json);
  }

  @override
  Future<void> deleteRemoteAlarm({required String serverAlarmId}) async {
    await _apiClient.deleteNoContent('/alarms/$serverAlarmId');
  }

  @override
  Future<void> sendSessionLifecycleEvent(PendingAlarmServerEvent event) async {
    await _apiClient.postJson(
      '/sessions/${event.sessionId}/events',
      idempotencyKey: event.idempotencyKey,
      body: <String, dynamic>{
        'eventType': event.eventType,
        'occurredAt': event.occurredAtUtcIso,
        'version': event.version,
      },
    );
  }
}
