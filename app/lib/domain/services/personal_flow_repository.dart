import '../models/personal_flow_models.dart';

/// Hợp đồng tầng Repository cho luồng cá nhân (`docs/07`, `docs/18`, `docs/39`).
///
/// Bản thật (`RemotePersonalFlowRepository`) và bản fixture debug
/// (`DebugFixturePersonalFlowRepository`) được tách riêng hoàn toàn qua interface này.
abstract interface class PersonalFlowRepository {
  bool get isDebugFixture;

  Future<ChallengeQuestion> fetchNextChallenge({
    required String localDate,
    String? subjectCode,
  });

  Future<StudySessionRecord> createOrSyncSession({
    required String alarmId,
    required String localSessionId,
    required String localDate,
    required String questionId,
    required int questionRevision,
    required DateTime startedAtUtc,
    required String idempotencyKey,
  });

  Future<StudySessionRecord> postSessionEvent({
    required String sessionId,
    required String eventType,
    required DateTime occurredAtUtc,
    required int version,
    required String idempotencyKey,
  });

  Future<GradingResult> submitTextAnswer({
    required String sessionId,
    required String answerValue,
    required String reasoningText,
    required String clientAttemptId,
    required String idempotencyKey,
  });

  Future<GradingResult> submitPhotoAttempt({
    required String sessionId,
    required String questionId,
    required String answerValue,
    required PhotoAttemptUpload photo,
    required String clientAttemptId,
    required String idempotencyKey,
  });

  Future<FeedbackReportResult> reportGradingFeedback({
    required String sessionId,
    required String attemptId,
    required String category,
    required String idempotencyKey,
    String? comment,
  });

  Future<ProgressSummary> fetchProgressSummary();

  Future<List<SessionHistoryItem>> fetchSessionHistory({
    int limit = 20,
    String? cursor,
  });
}
