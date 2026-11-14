import '../../domain/models/study_ai_models.dart';
import '../../domain/models/study_focus_models.dart';
import '../../domain/services/study_ai_gateway.dart';
import '../services/personal_api_client.dart';

/// Gateway thật gọi backend `/v1/study/*` qua `PersonalApiClient`.
///
/// Theo `docs/45 §5`:
/// - KHÔNG gửi `left_at`, danh sách app, khung hình camera hay XP từ client.
/// - `POST /v1/study/help` chỉ gửi tối đa 3 lượt hội thoại gần nhất cùng `subject`, `grade`, `task`.
class RemoteStudyAiGateway implements StudyAiGateway {
  const RemoteStudyAiGateway({required PersonalApiClient apiClient})
      : _apiClient = apiClient;

  final PersonalApiClient _apiClient;

  @override
  bool get isDebugFixture => false;

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
}
