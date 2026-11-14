import '../../domain/models/alarm_config.dart';
import '../../domain/services/alarm_sync_gateway.dart';

/// Fixture debug mô phỏng `/v1/alarms` khi bật `MINDCLOCK_DEBUG_FIXTURE=true` ở chế độ debug.
class DebugFixtureAlarmSyncGateway implements AlarmSyncGateway {
  @override
  bool get isDebugFixture => true;

  @override
  Future<List<RemoteAlarmRecord>> fetchRemoteAlarms() async {
    return const <RemoteAlarmRecord>[];
  }

  @override
  Future<RemoteAlarmRecord> upsertRemoteAlarm({
    required AlarmConfig localAlarm,
    required String timeZone,
    required String idempotencyKey,
  }) async {
    return RemoteAlarmRecord(
      serverAlarmId: localAlarm.serverAlarmId ?? 'debug_alarm_${localAlarm.id}',
      revision: (localAlarm.serverRevision ?? 0) + 1,
      localTime: localAlarm.formattedTime,
      weekdays: localAlarm.repeatWeekdays,
      enabled: localAlarm.enabled,
      challengeMode:
          localAlarm.mode == AlarmMode.challenge ? 'short_review' : 'none',
      snoozeMinutes: localAlarm.snoozeAllowed ? 5 : null,
    );
  }

  @override
  Future<void> deleteRemoteAlarm({required String serverAlarmId}) async {}

  @override
  Future<void> sendSessionLifecycleEvent(PendingAlarmServerEvent event) async {}
}
