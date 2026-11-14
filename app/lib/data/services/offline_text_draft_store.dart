import 'dart:convert';

import '../../domain/models/personal_flow_models.dart';
import 'local_key_value_store.dart';

/// Lưu bản nháp bài chữ offline tối đa 24 giờ, cô lập hoàn toàn theo `ownerScopeKey` (`uid:<uid>` hoặc `guest`).
///
/// Tuyệt đối không lưu ảnh và không cho tài khoản sau đọc bản nháp của tài khoản trước (`docs/07 §8`, `docs/24 §4`).
class OfflineTextDraftStore {
  OfflineTextDraftStore({
    required LocalKeyValueStore store,
    int Function()? nowMillis,
  })  : _store = store,
        _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const String _keyPrefix = 'mindclock_offline_text_draft_v1_';

  final LocalKeyValueStore _store;
  final int Function() _nowMillis;

  String _storageKey(String ownerScopeKey) => '$_keyPrefix$ownerScopeKey';

  Future<OfflineTextDraft?> loadDraft(String ownerScopeKey) async {
    final String? raw = await _store.readString(_storageKey(ownerScopeKey));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clearDraft(ownerScopeKey);
        return null;
      }
      final OfflineTextDraft draft = OfflineTextDraft.fromJson(decoded);
      if (draft.ownerKey != ownerScopeKey || draft.isExpiredAt(_nowMillis())) {
        await clearDraft(ownerScopeKey);
        return null;
      }
      return draft;
    } catch (_) {
      await clearDraft(ownerScopeKey);
      return null;
    }
  }

  Future<OfflineTextDraft> saveDraft({
    required String ownerScopeKey,
    required String questionId,
    required int questionRevision,
    required String promptSnapshot,
    required String answerValue,
    required String reasoningText,
    required String clientAttemptId,
    required String idempotencyKey,
  }) async {
    final int now = _nowMillis();
    final OfflineTextDraft draft = OfflineTextDraft(
      ownerKey: ownerScopeKey,
      questionId: questionId,
      questionRevision: questionRevision,
      promptSnapshot: promptSnapshot,
      answerValue: answerValue,
      reasoningText: reasoningText,
      clientAttemptId: clientAttemptId,
      idempotencyKey: idempotencyKey,
      savedAtEpochMillis: now,
      expiresAtEpochMillis:
          now + OfflineTextDraft.maxRetention.inMilliseconds,
    );
    await _store.writeString(
      _storageKey(ownerScopeKey),
      jsonEncode(draft.toJson()),
    );
    return draft;
  }

  Future<void> clearDraft(String ownerScopeKey) async {
    await _store.remove(_storageKey(ownerScopeKey));
  }
}
