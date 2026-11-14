import 'dart:convert';

import '../../domain/services/alarm_sync_gateway.dart';
import 'local_key_value_store.dart';

/// Lưu hàng đợi sự kiện `dismiss` / `emergency_stop` theo `ownerScopeKey` (tối đa 7 ngày, `docs/07 §8`).
class PendingAlarmEventStore {
  PendingAlarmEventStore({
    required LocalKeyValueStore store,
    DateTime Function()? nowProvider,
  })  : _store = store,
        _nowProvider = nowProvider ?? DateTime.now;

  static const String _keyPrefix = 'mindclock.pending_alarm_events.v1::';

  final LocalKeyValueStore _store;
  final DateTime Function() _nowProvider;

  String _scopeKey(String ownerScopeKey) {
    final String clean = ownerScopeKey.trim();
    return '$_keyPrefix${clean.isEmpty ? "guest" : clean}';
  }

  Future<List<PendingAlarmServerEvent>> loadEvents(String ownerScopeKey) async {
    final String? raw = await _store.readString(_scopeKey(ownerScopeKey));
    if (raw == null || raw.trim().isEmpty) {
      return const <PendingAlarmServerEvent>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const <PendingAlarmServerEvent>[];
      final DateTime now = _nowProvider();
      final List<PendingAlarmServerEvent> valid = decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingAlarmServerEvent.fromJson)
          .where(
            (PendingAlarmServerEvent e) =>
                e.idempotencyKey.isNotEmpty &&
                e.sessionId.isNotEmpty &&
                !e.isExpiredAt(now),
          )
          .toList(growable: false);
      return valid;
    } catch (_) {
      return const <PendingAlarmServerEvent>[];
    }
  }

  Future<void> enqueue(PendingAlarmServerEvent event) async {
    final List<PendingAlarmServerEvent> existing =
        await loadEvents(event.ownerScopeKey);
    if (existing.any(
      (PendingAlarmServerEvent item) =>
          item.idempotencyKey == event.idempotencyKey,
    )) {
      return;
    }
    final List<PendingAlarmServerEvent> updated = <PendingAlarmServerEvent>[
      ...existing,
      event,
    ];
    await _saveList(event.ownerScopeKey, updated);
  }

  Future<void> removeByIdempotencyKey({
    required String ownerScopeKey,
    required String idempotencyKey,
  }) async {
    final List<PendingAlarmServerEvent> existing = await loadEvents(ownerScopeKey);
    final List<PendingAlarmServerEvent> updated = existing
        .where((PendingAlarmServerEvent e) => e.idempotencyKey != idempotencyKey)
        .toList(growable: false);
    await _saveList(ownerScopeKey, updated);
  }

  Future<void> clearScope(String ownerScopeKey) async {
    await _store.remove(_scopeKey(ownerScopeKey));
  }

  Future<void> _saveList(
    String ownerScopeKey,
    List<PendingAlarmServerEvent> list,
  ) async {
    if (list.isEmpty) {
      await _store.remove(_scopeKey(ownerScopeKey));
      return;
    }
    await _store.writeString(
      _scopeKey(ownerScopeKey),
      jsonEncode(list.map((PendingAlarmServerEvent e) => e.toJson()).toList()),
    );
  }
}
