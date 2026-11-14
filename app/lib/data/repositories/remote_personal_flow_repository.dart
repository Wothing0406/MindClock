import '../../domain/models/personal_flow_models.dart';
import '../../domain/services/personal_flow_repository.dart';
import '../services/personal_api_client.dart';

/// Repository thật gọi FastAPI `/v1` theo đúng hợp đồng `docs/07`.
class RemotePersonalFlowRepository implements PersonalFlowRepository {
  const RemotePersonalFlowRepository({required PersonalApiClient apiClient})
      : _apiClient = apiClient;

  final PersonalApiClient _apiClient;

  @override
  bool get isDebugFixture => false;

  @override
  Future<ChallengeQuestion> fetchNextChallenge({
    required String localDate,
    String? subjectCode,
  }) async {
    final Map<String, String> query = <String, String>{'date': localDate};
    if (subjectCode != null && subjectCode.trim().isNotEmpty) {
      query['subject'] = subjectCode.trim();
    }
    final Map<String, dynamic> json = await _apiClient.getJson(
      '/challenges/next',
      queryParameters: query,
    );
    return ChallengeQuestion.fromJson(json, isDebugFixture: false);
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
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/sessions',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'alarmId': alarmId,
        'localSessionId': localSessionId,
        'localDate': localDate,
        'questionId': questionId,
        'questionRevision': questionRevision,
        'startedAt': startedAtUtc.toUtc().toIso8601String(),
      },
    );
    return StudySessionRecord.fromJson(json, localSessionId: localSessionId);
  }

  @override
  Future<StudySessionRecord> postSessionEvent({
    required String sessionId,
    required String eventType,
    required DateTime occurredAtUtc,
    required int version,
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/sessions/$sessionId/events',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'eventType': eventType,
        'occurredAt': occurredAtUtc.toUtc().toIso8601String(),
        'version': version,
      },
    );
    return StudySessionRecord.fromJson(json, localSessionId: sessionId);
  }

  @override
  Future<GradingResult> submitTextAnswer({
    required String sessionId,
    required String answerValue,
    required String reasoningText,
    required String clientAttemptId,
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/sessions/$sessionId/answers',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'answerValue': answerValue,
        'reasoningText': reasoningText,
        'clientAttemptId': clientAttemptId,
      },
    );
    return GradingResult.fromJson(
      json,
      isServerAuthoritative: true,
      isDebugFixture: false,
    );
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
    final Map<String, dynamic> json = await _apiClient.postMultipartAttempt(
      path: '/sessions/$sessionId/attempts',
      idempotencyKey: idempotencyKey,
      fields: <String, String>{
        'answerValue': answerValue,
        'questionId': questionId,
        'submissionKind': 'handwritten',
        'clientAttemptId': clientAttemptId,
      },
      photo: photo,
    );
    return GradingResult.fromJson(
      json,
      isServerAuthoritative: true,
      isDebugFixture: false,
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
    final Map<String, dynamic> body = <String, dynamic>{
      'attemptId': attemptId,
      'category': category,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    };
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/sessions/$sessionId/feedback',
      idempotencyKey: idempotencyKey,
      body: body,
    );
    return FeedbackReportResult.fromJson(json);
  }

  @override
  Future<ProgressSummary> fetchProgressSummary() async {
    final Map<String, dynamic> json =
        await _apiClient.getJson('/progress/summary');
    return ProgressSummary.fromJson(
      json,
      isServerAuthoritative: true,
      isDebugFixture: false,
    );
  }

  @override
  Future<List<SessionHistoryItem>> fetchSessionHistory({
    int limit = 20,
    String? cursor,
  }) async {
    final Map<String, String> query = <String, String>{
      'limit': limit.clamp(1, 50).toString(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final Map<String, dynamic> json = await _apiClient.getJson(
      '/sessions',
      queryParameters: query,
    );
    final List<dynamic> items =
        json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SessionHistoryItem.fromJson)
        .toList(growable: false);
  }
}
