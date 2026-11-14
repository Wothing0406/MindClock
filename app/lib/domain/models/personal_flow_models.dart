import 'dart:typed_data';

enum GradingVerdict {
  correct,
  incorrect,
  uncertain;

  static GradingVerdict fromWire(String? value) {
    switch (value) {
      case 'correct':
        return GradingVerdict.correct;
      case 'incorrect':
        return GradingVerdict.incorrect;
      default:
        return GradingVerdict.uncertain;
    }
  }
}

/// Đề bài nhận từ `GET /v1/challenges/next` (tuyệt đối không chứa đáp án/rubric).
class ChallengeQuestion {
  const ChallengeQuestion({
    required this.questionId,
    required this.questionRevision,
    required this.validForDate,
    required this.subjectCode,
    required this.topicId,
    required this.difficulty,
    required this.prompt,
    required this.reasoningPromptVi,
    required this.offlinePolicy,
    required this.estimatedSeconds,
    this.fallback = false,
    this.isDebugFixture = false,
  });

  final String questionId;
  final int questionRevision;
  final String validForDate;
  final String subjectCode;
  final String topicId;
  final int difficulty;
  final String prompt;
  final String reasoningPromptVi;
  final String offlinePolicy;
  final int estimatedSeconds;
  final bool fallback;
  final bool isDebugFixture;

  factory ChallengeQuestion.fromJson(
    Map<String, dynamic> json, {
    bool isDebugFixture = false,
  }) {
    return ChallengeQuestion(
      questionId: json['questionId'] as String? ?? 'unknown-question',
      questionRevision: (json['questionRevision'] as num?)?.toInt() ?? 1,
      validForDate: json['validForDate'] as String? ?? '',
      subjectCode: json['subject'] as String? ?? 'math',
      topicId: json['topicId'] as String? ?? 'general',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      prompt: json['prompt'] as String? ?? '',
      reasoningPromptVi: json['reasoningPromptVi'] as String? ??
          'Viết ngắn gọn bước làm hoặc lý do bạn chọn đáp án.',
      offlinePolicy: json['offlinePolicy'] as String? ?? 'ungraded_only',
      estimatedSeconds: (json['estimatedSeconds'] as num?)?.toInt() ?? 75,
      fallback: json['fallback'] as bool? ?? false,
      isDebugFixture: isDebugFixture,
    );
  }
}

class StudySessionRecord {
  const StudySessionRecord({
    required this.sessionId,
    required this.localSessionId,
    required this.state,
    required this.version,
    this.isOfflineLocal = false,
  });

  final String sessionId;
  final String localSessionId;
  final String state;
  final int version;
  final bool isOfflineLocal;

  factory StudySessionRecord.fromJson(
    Map<String, dynamic> json, {
    required String localSessionId,
  }) {
    return StudySessionRecord(
      sessionId: json['sessionId'] as String? ?? localSessionId,
      localSessionId: localSessionId,
      state: json['state'] as String? ?? 'active',
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  StudySessionRecord copyWith({String? state, int? version}) {
    return StudySessionRecord(
      sessionId: sessionId,
      localSessionId: localSessionId,
      state: state ?? this.state,
      version: version ?? this.version,
      isOfflineLocal: isOfflineLocal,
    );
  }
}

class GradingResult {
  const GradingResult({
    required this.attemptId,
    required this.verdict,
    required this.observedSteps,
    required this.firstIssue,
    required this.feedbackVi,
    required this.hintVi,
    required this.nextActions,
    required this.xpAwarded,
    required this.modelVersion,
    required this.rubricRevision,
    required this.isServerAuthoritative,
    this.isDebugFixture = false,
  });

  final String attemptId;
  final GradingVerdict verdict;
  final List<String> observedSteps;
  final String? firstIssue;
  final String feedbackVi;
  final String? hintVi;
  final List<String> nextActions;
  final int xpAwarded;
  final String modelVersion;
  final int rubricRevision;
  final bool isServerAuthoritative;
  final bool isDebugFixture;

  int get authoritativeXpAwarded =>
      (isServerAuthoritative && !isDebugFixture) ? xpAwarded : 0;

  factory GradingResult.fromJson(
    Map<String, dynamic> json, {
    bool isServerAuthoritative = true,
    bool isDebugFixture = false,
  }) {
    final List<dynamic> rawSteps =
        json['observedSteps'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> rawActions =
        json['nextActions'] as List<dynamic>? ?? const <dynamic>[];
    return GradingResult(
      attemptId: json['attemptId'] as String? ?? '',
      verdict: GradingVerdict.fromWire(json['result'] as String?),
      observedSteps: rawSteps.whereType<String>().toList(growable: false),
      firstIssue: json['firstIssue'] as String?,
      feedbackVi: json['feedback'] as String? ??
          'Đã nhận phản hồi từ hệ thống chấm.',
      hintVi: json['hint'] as String?,
      nextActions: rawActions.whereType<String>().toList(growable: false),
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      modelVersion: json['modelVersion'] as String? ?? '',
      rubricRevision: (json['rubricRevision'] as num?)?.toInt() ?? 0,
      isServerAuthoritative: isServerAuthoritative,
      isDebugFixture: isDebugFixture,
    );
  }
}

/// Bản nháp bài chữ offline tự chọn (tuyệt đối không lưu ảnh, TTL tối đa 24 giờ).
class OfflineTextDraft {
  const OfflineTextDraft({
    required this.ownerKey,
    required this.questionId,
    required this.questionRevision,
    required this.promptSnapshot,
    required this.answerValue,
    required this.reasoningText,
    required this.clientAttemptId,
    required this.idempotencyKey,
    required this.savedAtEpochMillis,
    required this.expiresAtEpochMillis,
  });

  static const Duration maxRetention = Duration(hours: 24);

  final String ownerKey;
  final String questionId;
  final int questionRevision;
  final String promptSnapshot;
  final String answerValue;
  final String reasoningText;
  final String clientAttemptId;
  final String idempotencyKey;
  final int savedAtEpochMillis;
  final int expiresAtEpochMillis;

  bool isExpiredAt(int nowEpochMillis) => nowEpochMillis >= expiresAtEpochMillis;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ownerKey': ownerKey,
        'questionId': questionId,
        'questionRevision': questionRevision,
        'promptSnapshot': promptSnapshot,
        'answerValue': answerValue,
        'reasoningText': reasoningText,
        'clientAttemptId': clientAttemptId,
        'idempotencyKey': idempotencyKey,
        'savedAtEpochMillis': savedAtEpochMillis,
        'expiresAtEpochMillis': expiresAtEpochMillis,
      };

  factory OfflineTextDraft.fromJson(Map<String, dynamic> json) {
    return OfflineTextDraft(
      ownerKey: json['ownerKey'] as String? ?? 'guest',
      questionId: json['questionId'] as String? ?? '',
      questionRevision: (json['questionRevision'] as num?)?.toInt() ?? 1,
      promptSnapshot: json['promptSnapshot'] as String? ?? '',
      answerValue: json['answerValue'] as String? ?? '',
      reasoningText: json['reasoningText'] as String? ?? '',
      clientAttemptId: json['clientAttemptId'] as String? ?? '',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      savedAtEpochMillis:
          (json['savedAtEpochMillis'] as num?)?.toInt() ?? 0,
      expiresAtEpochMillis:
          (json['expiresAtEpochMillis'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProgressSummary {
  const ProgressSummary({
    required this.xp,
    required this.streak,
    required this.completedSessions,
    required this.topicsToReview,
    required this.isServerAuthoritative,
    this.isDebugFixture = false,
  });

  const ProgressSummary.unauthenticated()
      : xp = 0,
        streak = 0,
        completedSessions = 0,
        topicsToReview = const <String>[],
        isServerAuthoritative = false,
        isDebugFixture = false;

  final int xp;
  final int streak;
  final int completedSessions;
  final List<String> topicsToReview;
  final bool isServerAuthoritative;
  final bool isDebugFixture;

  factory ProgressSummary.fromJson(
    Map<String, dynamic> json, {
    bool isServerAuthoritative = true,
    bool isDebugFixture = false,
  }) {
    final List<dynamic> rawTopics =
        json['topicsToReview'] as List<dynamic>? ?? const <dynamic>[];
    return ProgressSummary(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      completedSessions: (json['completedSessions'] as num?)?.toInt() ?? 0,
      topicsToReview: rawTopics.whereType<String>().toList(growable: false),
      isServerAuthoritative: isServerAuthoritative,
      isDebugFixture: isDebugFixture,
    );
  }
}

class SessionHistoryItem {
  const SessionHistoryItem({
    required this.sessionId,
    required this.localDate,
    required this.subjectCode,
    required this.state,
  });

  final String sessionId;
  final String localDate;
  final String subjectCode;
  final String state;

  factory SessionHistoryItem.fromJson(Map<String, dynamic> json) {
    return SessionHistoryItem(
      sessionId: json['sessionId'] as String? ?? '',
      localDate: json['localDate'] as String? ?? '',
      subjectCode: json['subject'] as String? ?? 'math',
      state: json['state'] as String? ?? 'completed',
    );
  }
}

class FeedbackReportResult {
  const FeedbackReportResult({
    required this.feedbackId,
    required this.status,
  });

  final String feedbackId;
  final String status;

  factory FeedbackReportResult.fromJson(Map<String, dynamic> json) {
    return FeedbackReportResult(
      feedbackId: json['feedbackId'] as String? ?? '',
      status: json['status'] as String? ?? 'received',
    );
  }
}

class PhotoAttemptUpload {
  const PhotoAttemptUpload({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
}

class PersonalApiException implements Exception {
  const PersonalApiException({
    required this.code,
    required this.messageVi,
    this.httpStatus,
    this.retryable = false,
    this.isTimeout = false,
    this.isNetworkError = false,
  });

  final String code;
  final String messageVi;
  final int? httpStatus;
  final bool retryable;
  final bool isTimeout;
  final bool isNetworkError;

  bool get isAuthExpired => httpStatus == 401;
  bool get isForbidden => httpStatus == 403;
  bool get isConflict => httpStatus == 409;

  @override
  String toString() => 'PersonalApiException($code, status=$httpStatus)';
}
