import '../../domain/models/study_ai_models.dart';
import '../../domain/models/study_focus_models.dart';
import '../../domain/services/study_ai_gateway.dart';

/// Fixture mẫu chỉ dùng ở debug khi `MINDCLOCK_DEBUG_FIXTURE=true`.
class DebugFixtureStudyAiGateway implements StudyAiGateway {
  @override
  bool get isDebugFixture => true;

  @override
  Future<RemoteStudySessionResult> createStudySession({
    required StudyFocusSessionSnapshot snapshot,
    required String idempotencyKey,
  }) async {
    return RemoteStudySessionResult(
      remoteSessionId: 'debug_${snapshot.sessionId}',
      clientSessionId: snapshot.sessionId,
      state: 'running',
      isDebugFixture: true,
    );
  }

  @override
  Future<RemoteStudySessionResult> finishStudySession({
    required StudyFocusRecord record,
    required String idempotencyKey,
  }) async {
    return RemoteStudySessionResult(
      remoteSessionId: record.remoteSessionId ?? 'debug_${record.sessionId}',
      clientSessionId: record.sessionId,
      state: record.finalStatus.wireValue,
      isDebugFixture: true,
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
    return const StudyHelpResponse(
      messageVi:
          'Mẫu debug (không phải AI thật): Mình chỉ gợi ý bước tiếp theo cho việc này.',
      nextQuestionVi: 'Bạn đã thử bước biến đổi đầu tiên chưa?',
      helpLevel: 'socratic',
      safetyStatus: 'safe',
      isDebugFixture: true,
    );
  }
}
