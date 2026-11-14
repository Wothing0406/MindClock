import '../../domain/models/personal_flow_models.dart';
import '../../domain/services/personal_flow_repository.dart';

/// Fixture debug tách riêng cho demo/test UI khi chưa bật backend thật `T016`.
///
/// Tuân thủ `docs/18 §4`: luôn trả `isDebugFixture = true` và không đánh dấu
/// `isServerAuthoritative = true` để UI không giả lập đây là AI/XP thật.
class DebugFixturePersonalFlowRepository implements PersonalFlowRepository {
  DebugFixturePersonalFlowRepository();

  int _wrongStreakInChallenge = 0;
  final Map<String, GradingResult> _idempotentResults = <String, GradingResult>{};

  @override
  bool get isDebugFixture => true;

  @override
  Future<ChallengeQuestion> fetchNextChallenge({
    required String localDate,
    String? subjectCode,
  }) async {
    return ChallengeQuestion(
      questionId: 'fixture-math9-linear-001',
      questionRevision: 3,
      validForDate: localDate,
      subjectCode: subjectCode ?? 'TOAN',
      topicId: 'linear_equation_1var',
      difficulty: 1,
      prompt: 'Giải phương trình 2(x − 3) = 10.',
      reasoningPromptVi: 'Viết 1–2 bước biến đổi bạn đã làm.',
      offlinePolicy: 'ungraded_only',
      estimatedSeconds: 75,
      fallback: false,
      isDebugFixture: true,
    );
  }

  @override
  Future<StudySessionRecord> createOrSyncSession({
    required String alarmId,
    required String localSessionId,
    required String localDate,
    required String questionId,
    required int questionRevision,
    required DateTime startedAtUtc,
    required String idempotencyKey,
  }) async {
    return StudySessionRecord(
      sessionId: 'debug_sess_$localSessionId',
      localSessionId: localSessionId,
      state: 'active',
      version: 1,
    );
  }

  @override
  Future<StudySessionRecord> postSessionEvent({
    required String sessionId,
    required String eventType,
    required DateTime occurredAtUtc,
    required int version,
    required String idempotencyKey,
  }) async {
    return StudySessionRecord(
      sessionId: sessionId,
      localSessionId: sessionId,
      state: eventType == 'dismiss' ? 'dismissed' : 'active',
      version: version + 1,
    );
  }

  @override
  Future<GradingResult> submitTextAnswer({
    required String sessionId,
    required String answerValue,
    required String reasoningText,
    required String clientAttemptId,
    required String idempotencyKey,
  }) async {
    final GradingResult? cached = _idempotentResults[idempotencyKey];
    if (cached != null) return cached;

    final String cleanAnswer = answerValue.trim().toLowerCase();
    final String cleanReason = reasoningText.trim();
    late final GradingResult outcome;

    if (cleanReason.length < 4) {
      outcome = GradingResult(
        attemptId: 'debug_att_$clientAttemptId',
        verdict: GradingVerdict.uncertain,
        observedSteps: const <String>[],
        firstIssue: null,
        feedbackVi:
            '[Fixture debug] Chưa đủ rõ bước làm. Bạn có thể bổ sung cách nghĩ.',
        hintVi: null,
        nextActions: const <String>['retry', 'finish_ungraded'],
        xpAwarded: 0,
        modelVersion: 'debug-fixture-v1',
        rubricRevision: 3,
        isServerAuthoritative: false,
        isDebugFixture: true,
      );
    } else if (cleanAnswer == '8' || cleanAnswer == 'x=8' || cleanAnswer == 'x = 8') {
      _wrongStreakInChallenge = 0;
      outcome = GradingResult(
        attemptId: 'debug_att_$clientAttemptId',
        verdict: GradingVerdict.correct,
        observedSteps: <String>[cleanReason],
        firstIssue: null,
        feedbackVi:
            '[Fixture debug] Khớp đáp án mẫu x = 8 (XP chỉ được cấp khi nối backend thật).',
        hintVi: null,
        nextActions: const <String>['finish'],
        xpAwarded: 0,
        modelVersion: 'debug-fixture-v1',
        rubricRevision: 3,
        isServerAuthoritative: false,
        isDebugFixture: true,
      );
    } else {
      _wrongStreakInChallenge += 1;
      final bool allowHint = _wrongStreakInChallenge >= 3;
      outcome = GradingResult(
        attemptId: 'debug_att_$clientAttemptId',
        verdict: GradingVerdict.incorrect,
        observedSteps: allowHint ? <String>[cleanReason] : const <String>[],
        firstIssue: allowHint ? 'Kiểm tra bước nhân phân phối 2(x − 3).' : null,
        feedbackVi: allowHint
            ? '[Fixture debug] Chưa đúng lần $_wrongStreakInChallenge.'
            : '[Fixture debug] Bài này chưa đúng. Bạn có thể thử lại.',
        hintVi: allowHint
            ? 'Nhân số 2 vào cả hai số hạng trong ngoặc trước khi chuyển vế.'
            : null,
        nextActions: const <String>['retry', 'finish_ungraded', 'emergency_stop'],
        xpAwarded: 0,
        modelVersion: 'debug-fixture-v1',
        rubricRevision: 3,
        isServerAuthoritative: false,
        isDebugFixture: true,
      );
    }

    _idempotentResults[idempotencyKey] = outcome;
    return outcome;
  }

  @override
  Future<GradingResult> submitPhotoAttempt({
    required String sessionId,
    required String questionId,
    required String answerValue,
    required PhotoAttemptUpload photo,
    required String clientAttemptId,
    required String idempotencyKey,
  }) async {
    return submitTextAnswer(
      sessionId: sessionId,
      answerValue: answerValue,
      reasoningText: 'Ảnh giấy viết tay (${photo.bytes.lengthInBytes} bytes)',
      clientAttemptId: clientAttemptId,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<FeedbackReportResult> reportGradingFeedback({
    required String sessionId,
    required String attemptId,
    required String category,
    required String idempotencyKey,
    String? comment,
  }) async {
    return FeedbackReportResult(
      feedbackId: 'debug_fb_$attemptId',
      status: 'received_debug',
    );
  }

  @override
  Future<ProgressSummary> fetchProgressSummary() async {
    return const ProgressSummary(
      xp: 0,
      streak: 0,
      completedSessions: 0,
      topicsToReview: <String>['Phương trình bậc nhất (Fixture debug)'],
      isServerAuthoritative: false,
      isDebugFixture: true,
    );
  }

  @override
  Future<List<SessionHistoryItem>> fetchSessionHistory({
    int limit = 20,
    String? cursor,
  }) async {
    return const <SessionHistoryItem>[];
  }
}
