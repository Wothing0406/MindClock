import 'dart:convert';

import '../../domain/models/study_focus_models.dart';
import 'local_key_value_store.dart';

/// Kho lưu trữ cục bộ Không gian học tách biệt hoàn toàn theo từng `ownerScopeKey`.
///
/// Tuân thủ `docs/45 §2, §5, §6 (F07)`: không dùng chung snapshot hay lịch sử
/// giữa `guest`, tài khoản A và tài khoản B; hoàn thành phiên là idempotent theo `sessionId`.
class LocalStudyFocusRepository {
  LocalStudyFocusRepository({
    required LocalKeyValueStore store,
  }) : _store = store;

  static const String _snapshotPrefix = 'mindclock.study_focus.snapshot.v1::';
  static const String _historyPrefix = 'mindclock.study_focus.history.v1::';
  static const int _maxHistoryRecords = 50;

  final LocalKeyValueStore _store;

  String _normalizeScope(String ownerScopeKey) {
    final String clean = ownerScopeKey.trim();
    return clean.isEmpty ? 'guest' : clean;
  }

  String _snapshotKey(String ownerScopeKey) =>
      '$_snapshotPrefix${_normalizeScope(ownerScopeKey)}';

  String _historyKey(String ownerScopeKey) =>
      '$_historyPrefix${_normalizeScope(ownerScopeKey)}';

  Future<StudyFocusSessionSnapshot?> loadSnapshot(String ownerScopeKey) async {
    final String? raw = await _store.readString(_snapshotKey(ownerScopeKey));
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final StudyFocusSessionSnapshot snapshot =
            StudyFocusSessionSnapshot.fromJson(decoded);
        if (snapshot.sessionId.isEmpty) return null;
        return snapshot;
      }
    } catch (_) {
      // Dữ liệu hỏng cục bộ không được làm vỡ app hoặc báo thức.
    }
    return null;
  }

  Future<void> saveSnapshot(StudyFocusSessionSnapshot snapshot) async {
    await _store.writeString(
      _snapshotKey(snapshot.ownerScopeKey),
      jsonEncode(snapshot.toJson()),
    );
  }

  Future<void> clearSnapshot(String ownerScopeKey) async {
    await _store.remove(_snapshotKey(ownerScopeKey));
  }

  Future<List<StudyFocusRecord>> loadHistory(String ownerScopeKey) async {
    final String? raw = await _store.readString(_historyKey(ownerScopeKey));
    if (raw == null || raw.trim().isEmpty) return const <StudyFocusRecord>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(StudyFocusRecord.fromJson)
            .where((StudyFocusRecord r) => r.sessionId.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      return const <StudyFocusRecord>[];
    }
    return const <StudyFocusRecord>[];
  }

  /// Lưu bản ghi hoàn thành phiên học cục bộ với tính chất idempotent theo `sessionId`.
  Future<List<StudyFocusRecord>> saveRecordIdempotent(
    StudyFocusRecord record,
  ) async {
    final List<StudyFocusRecord> existing =
        await loadHistory(record.ownerScopeKey);
    final int idx = existing.indexWhere(
      (StudyFocusRecord item) => item.sessionId == record.sessionId,
    );

    final List<StudyFocusRecord> updated;
    if (idx >= 0) {
      // Đã có sessionId này -> cập nhật ghi chú mà không tạo bản ghi thứ 2.
      updated = List<StudyFocusRecord>.from(existing);
      updated[idx] = record;
    } else {
      updated = <StudyFocusRecord>[record, ...existing];
      if (updated.length > _maxHistoryRecords) {
        updated.removeRange(_maxHistoryRecords, updated.length);
      }
    }

    await _store.writeString(
      _historyKey(record.ownerScopeKey),
      jsonEncode(
        updated.map((StudyFocusRecord r) => r.toJson()).toList(growable: false),
      ),
    );
    return updated;
  }

  Future<void> clearScopeData(String ownerScopeKey) async {
    await clearSnapshot(ownerScopeKey);
    await _store.remove(_historyKey(ownerScopeKey));
  }
}
