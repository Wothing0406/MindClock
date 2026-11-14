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

  @override
  Future<PersonalizedPracticeQuestion> generatePersonalizedQuestion({
    required String subjectCode,
    String? gradeLevel,
    String? topicHint,
    int difficulty = 1,
    required String idempotencyKey,
  }) async {
    final String grade = (gradeLevel == null || gradeLevel.trim().isEmpty)
        ? 'Lớp 9'
        : gradeLevel.trim();
    final String topic =
        (topicHint == null || topicHint.trim().isEmpty) ? 'trọng tâm' : topicHint.trim();
    return PersonalizedPracticeQuestion(
      questionId: 'debug_${subjectCode.toLowerCase()}_001',
      subjectCode: subjectCode.toUpperCase(),
      gradeBand: grade,
      topicId: 'debug_topic',
      difficulty: difficulty,
      prompt: 'Mẫu debug ($subjectCode · $grade): Ôn ngắn về $topic.',
      reasoningPromptVi: 'Viết 1–2 bước giải thích cách làm của bạn.',
      steps: const <String>[
        'Đọc kỹ dữ kiện chính của bài.',
        'Áp dụng công thức hoặc quy tắc trọng tâm.',
      ],
      hintVi: 'Bắt đầu từ dữ kiện đã cho trong đề.',
      status: 'draft',
      sourceType: 'debug_fixture',
      modelVersion: 'debug-fixture',
      xpAwarded: 0,
      fallbackUsed: false,
      isDebugFixture: true,
    );
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
    if (!consentGranted) {
      throw const PersonalApiException(
        code: 'CONSENT_REQUIRED',
        messageVi: 'Cần bật đồng ý rõ ràng trước khi mở Gemini Live.',
        httpStatus: 403,
      );
    }
    return GeminiLiveSessionToken(
      tokenName: 'auth_tokens/debug_live_001',
      wsUrl:
          'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=auth_tokens/debug_live_001',
      model: 'gemini-3.8-live',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)).toIso8601String(),
      expiresInSeconds: 600,
      responseModalities: <String>[responseModality],
      contextSummary: '$subjectCode · ${gradeLevel ?? "Lớp 9"}',
      isMock: true,
      isDebugFixture: true,
    );
  }

  @override
  Future<void> syncLearningProfile({
    String? alias,
    String? gradeLevel,
    List<String>? selectedSubjects,
    bool? liveConsentGranted,
  }) async {}
}
