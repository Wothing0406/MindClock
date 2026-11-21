import 'dart:convert';
import 'dart:typed_data';

import '../../domain/services/study_reply_voice_source.dart';
import '../../domain/models/personal_flow_models.dart';
import '../services/local_id_generator.dart';
import '../../domain/models/study_ai_models.dart';
import '../../domain/models/study_focus_models.dart';
import '../../domain/services/study_ai_gateway.dart';
import '../services/personal_api_client.dart';

/// Gateway thật gọi backend `/v1/study/*` qua `PersonalApiClient`.
///
/// Theo `docs/45 §5`:
/// - KHÔNG gửi `left_at`, danh sách app, khung hình camera hay XP từ client.
/// - `POST /v1/study/help` chỉ gửi tối đa 3 lượt hội thoại gần nhất cùng `subject`, `grade`, `task`.
class RemoteStudyAiGateway implements StudyAiGateway, StudyReplyVoiceSource {
  const RemoteStudyAiGateway({required PersonalApiClient apiClient})
      : _apiClient = apiClient;

  final PersonalApiClient _apiClient;

  @override
  bool get isDebugFixture => false;

  @override
  Future<Uint8List> synthesizeReply(
      {required String sessionId, required String text}) async {
    final data = await _apiClient.postJson('/study/sessions/$sessionId/speech',
        body: {'text': text, 'consentGranted': true},
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
        timeout: const Duration(seconds: 50));
    final encoded = data['audioBase64'];
    if (data['mimeType'] != 'audio/wav' ||
        encoded is! String ||
        encoded.length > 5592416) {
      throw const PersonalApiException(
          code: 'INVALID_VOICE', messageVi: 'Âm thanh AI không hợp lệ.');
    }
    final bytes = base64Decode(encoded);
    if (bytes.length < 45 ||
        bytes.length > 4194304 ||
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != 'WAVE') {
      throw const PersonalApiException(
          code: 'INVALID_VOICE', messageVi: 'Âm thanh AI không hợp lệ.');
    }
    return bytes;
  }

  @override
  Future<RemoteStudySessionResult> createStudySession({
    required StudyFocusSessionSnapshot snapshot,
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/study/sessions',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'clientSessionId': snapshot.sessionId,
        'taskTitle': snapshot.taskTitle,
        'subjectCode': snapshot.subjectCode,
        'targetMinutes': snapshot.durationMinutes,
        'focusLevel': snapshot.level.wireValue,
        'roomMode': snapshot.roomMode.wireValue,
        'cadence': snapshot.cadence.wireValue,
        'startedAt': DateTime.fromMillisecondsSinceEpoch(
          snapshot.startedAtEpochMs,
        ).toUtc().toIso8601String(),
      },
    );
    return RemoteStudySessionResult.fromJson(
      json,
      fallbackClientSessionId: snapshot.sessionId,
      isDebugFixture: false,
    );
  }

  @override
  Future<RemoteStudySessionResult> finishStudySession({
    required StudyFocusRecord record,
    required String idempotencyKey,
  }) async {
    final String pathSessionId =
        (record.remoteSessionId != null && record.remoteSessionId!.isNotEmpty)
            ? record.remoteSessionId!
            : record.sessionId;
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/study/sessions/$pathSessionId/finish',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'clientSessionId': record.sessionId,
        'finalStatus': record.finalStatus.wireValue,
        'elapsedWallSeconds': record.elapsedWallSeconds,
        'inAppFocusSeconds': record.inAppFocusSeconds,
        'endedAt': DateTime.fromMillisecondsSinceEpoch(
          record.endedAtEpochMs,
        ).toUtc().toIso8601String(),
        'notesDone': record.notesDone,
        'notesStuck': record.notesStuck,
      },
    );
    return RemoteStudySessionResult.fromJson(
      json,
      fallbackClientSessionId: record.sessionId,
      isDebugFixture: false,
    );
  }

  @override
  Future<StudyHelpResponse> requestHelp({
    required String sessionId,
    required String taskTitle,
    String? subjectCode,
    String? gradeLevel,
    required String questionText,
    required List<StudyHelpTurn> recentTurns,
    required String idempotencyKey,
  }) async {
    final List<StudyHelpTurn> clipped = recentTurns.length <= 3
        ? recentTurns
        : recentTurns.sublist(recentTurns.length - 3);
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/study/help',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'clientSessionId': sessionId,
        'subject': subjectCode ?? 'general',
        'grade': gradeLevel,
        'task': taskTitle,
        'questionText': questionText.trim(),
        'recentTurns': clipped
            .map((StudyHelpTurn t) => t.toApiJson())
            .toList(growable: false),
      },
    );
    return StudyHelpResponse.fromJson(json, isDebugFixture: false);
  }

  @override
  Future<PersonalizedPracticeQuestion> generatePersonalizedQuestion({
    required String subjectCode,
    String? gradeLevel,
    String? topicHint,
    int difficulty = 1,
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/questions/personalized',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'subjectCode': subjectCode.trim().toUpperCase(),
        if (gradeLevel != null && gradeLevel.trim().isNotEmpty)
          'gradeLevel': gradeLevel.trim(),
        if (topicHint != null && topicHint.trim().isNotEmpty)
          'topicHint': topicHint.trim(),
        'difficulty': difficulty.clamp(1, 3),
        'saveToBank': true,
      },
    );
    return PersonalizedPracticeQuestion.fromJson(json, isDebugFixture: false);
  }

  @override
  Future<GeminiLiveSessionToken> requestLiveToken({
    String? sessionId,
    required String subjectCode,
    String? gradeLevel,
    required String taskTitle,
    String responseModality = 'AUDIO',
    required bool consentGranted,
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/study/live-token',
      idempotencyKey:
          'live_${sessionId ?? "standalone"}_${DateTime.now().millisecondsSinceEpoch}',
      body: <String, dynamic>{
        if (sessionId != null && sessionId.trim().isNotEmpty)
          'sessionId': sessionId.trim(),
        'subjectCode': subjectCode.trim().toUpperCase(),
        if (gradeLevel != null && gradeLevel.trim().isNotEmpty)
          'gradeLevel': gradeLevel.trim(),
        'taskTitle':
            taskTitle.trim().isEmpty ? 'Ôn tập cá nhân' : taskTitle.trim(),
        'responseModality': responseModality,
        'consentGranted': consentGranted,
      },
    );
    return GeminiLiveSessionToken.fromJson(json, isDebugFixture: false);
  }

  @override
  Future<void> syncLearningProfile({
    String? alias,
    String? gradeLevel,
    List<String>? selectedSubjects,
    bool? liveConsentGranted,
  }) async {
    await _apiClient.patchJson(
      '/me',
      body: <String, dynamic>{
        if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        if (gradeLevel != null && gradeLevel.trim().isNotEmpty)
          'gradeLevel': gradeLevel.trim(),
        if (selectedSubjects != null) 'selectedSubjects': selectedSubjects,
        if (liveConsentGranted != null)
          'liveConsentGranted': liveConsentGranted,
      },
    );
  }
}
