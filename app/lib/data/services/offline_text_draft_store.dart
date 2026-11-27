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

  String _activeChallengeKey(
    String ownerScopeKey,
    String alarmId,
    String localDate,
  ) =>
      'mindclock_active_challenge_v1_${ownerScopeKey}_${alarmId}_$localDate';

  Future<void> saveActiveChallenge({
    required String ownerScopeKey,
    required String alarmId,
    required String localDate,
    required ChallengeQuestion question,
    required StudySessionRecord session,
    required bool challengeMode,
  }) async {
    await _store.writeString(
      _activeChallengeKey(ownerScopeKey, alarmId, localDate),
      jsonEncode(<String, dynamic>{
        'question': question.toJson(),
        'session': session.toJson(),
        'challengeMode': challengeMode,
      }),
    );
  }

  Future<({ChallengeQuestion question, StudySessionRecord session, bool challengeMode})?>
      loadActiveChallenge({
    required String ownerScopeKey,
    required String alarmId,
    required String localDate,
  }) async {
    final String? raw = await _store.readString(
      _activeChallengeKey(ownerScopeKey, alarmId, localDate),
    );
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final Object? qMap = decoded['question'];
      final Object? sMap = decoded['session'];
      if (qMap is! Map<String, dynamic> || sMap is! Map<String, dynamic>) {
        return null;
      }
      final ChallengeQuestion question = ChallengeQuestion.fromJson(qMap);
      final StudySessionRecord session = StudySessionRecord(
        sessionId: sMap['sessionId'] as String? ?? '',
        localSessionId: sMap['localSessionId'] as String? ?? '',
        state: sMap['state'] as String? ?? 'active',
        version: (sMap['version'] as num?)?.toInt() ?? 1,
        isOfflineLocal: sMap['isOfflineLocal'] as bool? ?? false,
      );
      if (session.sessionId.isEmpty || question.prompt.isEmpty) return null;
      return (
        question: question,
        session: session,
        challengeMode: decoded['challengeMode'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveChallenge({
    required String ownerScopeKey,
    required String alarmId,
    required String localDate,
  }) async {
    await _store.remove(_activeChallengeKey(ownerScopeKey, alarmId, localDate));
  }
}
