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

/// Thẻ mở màn ngắn 6–12 giây gắn trực tiếp với câu hỏi (`docs/01-product/09-giac-ngu-va-bao-thuc.md`, `11-eduskills-vn-tich-hop.md`).
class MorningHookCard {
  const MorningHookCard({
    required this.cardId,
    required this.questionId,
    required this.questionRevision,
    required this.learningOutcome,
    required this.durationTargetSeconds,
    required this.setupVi,
    required this.cliffVi,
    required this.staticFallbackVi,
    this.assetId = '',
    this.skipAllowed = true,
  });

  final String cardId;
  final String questionId;
  final int questionRevision;
  final String learningOutcome;
  final int durationTargetSeconds;
  final String setupVi;
  final String cliffVi;
  final String staticFallbackVi;
  final String assetId;
  final bool skipAllowed;

  factory MorningHookCard.fromJson(Map<String, dynamic> json) {
    return MorningHookCard(
      cardId: json['cardId'] as String? ?? 'mc_default',
      questionId: json['questionId'] as String? ?? '',
      questionRevision: (json['questionRevision'] as num?)?.toInt() ?? 1,
      learningOutcome: json['learningOutcome'] as String? ?? '',
      durationTargetSeconds:
          ((json['durationTargetSeconds'] as num?)?.toInt() ?? 8).clamp(6, 12),
      setupVi: json['setupVi'] as String? ?? '',
      cliffVi: json['cliffVi'] as String? ?? '',
      staticFallbackVi: json['staticFallbackVi'] as String? ?? '',
      assetId: json['assetId'] as String? ?? '',
      skipAllowed: json['skipAllowed'] as bool? ?? true,
    );
  }
}

class ChallengeSubQuestion {
  const ChallengeSubQuestion({
    required this.index,
    required this.prompt,
    required this.options,
  });

  final int index;
  final String prompt;
  final List<String> options;

  factory ChallengeSubQuestion.fromJson(Map<String, dynamic> json) {
    return ChallengeSubQuestion(
      index: (json['index'] as num?)?.toInt() ?? 0,
      prompt: json['prompt'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(growable: false),
    );
  }
}

/// Đề bài nhận từ `GET /v1/challenges/next` (tuyệt đối không chứa đáp án/rubric/reveal trước khi kết thúc).
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
    this.morningCard,
    this.fallback = false,
    this.isDebugFixture = false,
    this.questionFormat = 'short_text',
    this.difficultyMode = 'basic',
    this.options = const <String>[],
    this.subQuestions = const <ChallengeSubQuestion>[],
    this.passThreshold = 1.0,
    this.sourceScheduleReasonVi,
    this.schoolWeek,
    this.currentChapter,
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
  final MorningHookCard? morningCard;
  final bool fallback;
  final bool isDebugFixture;
  final String questionFormat;
  final String difficultyMode;
  final List<String> options;
  final List<ChallengeSubQuestion> subQuestions;
  final double passThreshold;
  final String? sourceScheduleReasonVi;
  final int? schoolWeek;
  final String? currentChapter;

  factory ChallengeQuestion.fromJson(
    Map<String, dynamic> json, {
    bool isDebugFixture = false,
  }) {
    final Object? rawCard = json['morningCard'];
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
      morningCard: rawCard is Map<String, dynamic>
          ? MorningHookCard.fromJson(rawCard)
          : null,
      fallback: json['fallback'] as bool? ?? false,
      isDebugFixture: isDebugFixture,
      questionFormat: json['questionFormat'] as String? ?? 'short_text',
      difficultyMode: json['difficultyMode'] as String? ?? 'basic',
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(growable: false),
      subQuestions:
          (json['subQuestions'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(ChallengeSubQuestion.fromJson)
              .toList(growable: false),
      passThreshold: (json['passThreshold'] as num?)?.toDouble() ?? 1.0,
      sourceScheduleReasonVi: json['sourceScheduleReasonVi'] as String?,
      schoolWeek: (json['schoolWeek'] as num?)?.toInt(),
      currentChapter: json['currentChapter'] as String?,
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
    this.confirmedIncorrectCount = 0,
    this.canAbandon = false,
    this.revealVi,
    this.isDebugFixture = false,
    this.scorePercent,
    this.masteryScore,
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
  final int confirmedIncorrectCount;
  final bool canAbandon;
  final String? revealVi;
  final bool isDebugFixture;
  final int? scorePercent;
  final int? masteryScore;

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
    final List<String> parsedActions =
        rawActions.whereType<String>().toList(growable: false);
    final int wrongCount =
        (json['confirmedIncorrectCount'] as num?)?.toInt() ?? 0;
    final bool canAbandon = (json['canAbandon'] as bool?) ??
        parsedActions.contains('abandon') || wrongCount >= 5;
    return GradingResult(
      attemptId: json['attemptId'] as String? ?? '',
      verdict: GradingVerdict.fromWire(json['result'] as String?),
      observedSteps: rawSteps.whereType<String>().toList(growable: false),
      firstIssue: json['firstIssue'] as String?,
      feedbackVi:
          json['feedback'] as String? ?? 'Đã nhận phản hồi từ hệ thống chấm.',
      hintVi: json['hint'] as String?,
      nextActions: parsedActions,
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      modelVersion: json['modelVersion'] as String? ?? '',
      rubricRevision: (json['rubricRevision'] as num?)?.toInt() ?? 0,
      isServerAuthoritative: isServerAuthoritative,
      confirmedIncorrectCount: wrongCount,
      canAbandon: canAbandon,
      revealVi: json['revealVi'] as String?,
      isDebugFixture: isDebugFixture,
      scorePercent: (json['scorePercent'] as num?)?.toInt(),
      masteryScore: (json['masteryScore'] as num?)?.toInt(),
    );
  }
}

class SessionAbandonResult {
  const SessionAbandonResult({
    required this.sessionId,
    required this.state,
    required this.version,
    required this.confirmedIncorrectCount,
    required this.xpAwarded,
    required this.streakDayAwarded,
    required this.messageVi,
    this.revealVi,
  });

  final String sessionId;
  final String state;
  final int version;
  final int confirmedIncorrectCount;
  final int xpAwarded;
  final bool streakDayAwarded;
  final String messageVi;
  final String? revealVi;

  factory SessionAbandonResult.fromJson(Map<String, dynamic> json) {
    return SessionAbandonResult(
      sessionId: json['sessionId'] as String? ?? '',
      state: json['state'] as String? ?? 'abandoned',
      version: (json['version'] as num?)?.toInt() ?? 1,
      confirmedIncorrectCount:
          (json['confirmedIncorrectCount'] as num?)?.toInt() ?? 5,
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      streakDayAwarded: json['streakDayAwarded'] as bool? ?? false,
      messageVi: json['messageVi'] as String? ??
          'Đã bỏ lượt câu này (0 EXP, không trừ điểm đã có).',
      revealVi: json['revealVi'] as String?,
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

  bool isExpiredAt(int nowEpochMillis) =>
      nowEpochMillis >= expiresAtEpochMillis;

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
      savedAtEpochMillis: (json['savedAtEpochMillis'] as num?)?.toInt() ?? 0,
      expiresAtEpochMillis:
          (json['expiresAtEpochMillis'] as num?)?.toInt() ?? 0,
    );
  }
}

class StreakDayActivity {
  const StreakDayActivity({
    required this.date,
    required this.weekdayLabel,
    required this.isToday,
    required this.completed,
    required this.hasDailyReport,
    required this.hasStudy,
    required this.hasChallenge,
    required this.xpEarned,
  });

  final String date;
  final String weekdayLabel;
  final bool isToday;
  final bool completed;
  final bool hasDailyReport;
  final bool hasStudy;
  final bool hasChallenge;
  final int xpEarned;

  factory StreakDayActivity.fromJson(Map<String, dynamic> json) {
    return StreakDayActivity(
      date: json['date'] as String? ?? '',
      weekdayLabel: json['weekdayLabel'] as String? ?? '',
      isToday: json['isToday'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      hasDailyReport: json['hasDailyReport'] as bool? ?? false,
      hasStudy: json['hasStudy'] as bool? ?? false,
      hasChallenge: json['hasChallenge'] as bool? ?? false,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyReportRecord {
  const DailyReportRecord({
    required this.reportId,
    required this.localDate,
    required this.studyMinutes,
    required this.tasksCompleted,
    required this.challengeCompleted,
    required this.feeling,
    required this.reflectionNote,
    required this.xpAwarded,
    required this.createdAt,
  });

  final String reportId;
  final String localDate;
  final int studyMinutes;
  final int tasksCompleted;
  final bool challengeCompleted;
  final String feeling;
  final String reflectionNote;
  final int xpAwarded;
  final DateTime? createdAt;

  String get feelingLabelVi => switch (feeling) {
        'focused' => 'Tập trung tốt',
        'tired' => 'Hơi mệt nhưng vẫn cố',
        _ => 'Ổn định · Đều nhịp',
      };

  factory DailyReportRecord.fromJson(Map<String, dynamic> json) {
    final String? rawCreatedAt = json['createdAt'] as String?;
    return DailyReportRecord(
      reportId: json['reportId'] as String? ?? '',
      localDate: json['localDate'] as String? ?? '',
      studyMinutes: (json['studyMinutes'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
      challengeCompleted: json['challengeCompleted'] as bool? ?? false,
      feeling: json['feeling'] as String? ?? 'steady',
      reflectionNote: json['reflectionNote'] as String? ?? '',
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      createdAt:
          rawCreatedAt == null ? null : DateTime.tryParse(rawCreatedAt),
    );
  }
}

class DailyReportSubmitResult {
  const DailyReportSubmitResult({
    required this.report,
    required this.alreadyReportedToday,
    required this.xpAwarded,
    required this.streakAwardedToday,
    required this.summary,
  });

  final DailyReportRecord report;
  final bool alreadyReportedToday;
  final int xpAwarded;
  final bool streakAwardedToday;
  final ProgressSummary summary;

  factory DailyReportSubmitResult.fromJson(
    Map<String, dynamic> json, {
    bool isServerAuthoritative = true,
    bool isDebugFixture = false,
  }) {
    return DailyReportSubmitResult(
      report: DailyReportRecord.fromJson(
        json['report'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      alreadyReportedToday: json['alreadyReportedToday'] as bool? ?? false,
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      streakAwardedToday: json['streakAwardedToday'] as bool? ?? false,
      summary: ProgressSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        isServerAuthoritative: isServerAuthoritative,
        isDebugFixture: isDebugFixture,
      ),
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
    this.level,
    this.xpToNextLevel,
    this.levelStartXp,
    this.nextLevelXp,
    this.bestStreak = 0,
    this.totalActiveDays = 0,
    this.todayCompleted = false,
    this.todayReportSubmitted = false,
    this.todaySources = const <String>[],
    this.recentDays = const <StreakDayActivity>[],
    this.streakPolicyVersion,
  });

  const ProgressSummary.unauthenticated()
      : xp = 0,
        streak = 0,
        completedSessions = 0,
        topicsToReview = const <String>[],
        isServerAuthoritative = false,
        level = null,
        xpToNextLevel = null,
        levelStartXp = null,
        nextLevelXp = null,
        isDebugFixture = false,
        bestStreak = 0,
        totalActiveDays = 0,
        todayCompleted = false,
        todayReportSubmitted = false,
        todaySources = const <String>[],
        recentDays = const <StreakDayActivity>[],
        streakPolicyVersion = null;

  final int xp;
  final int? level;
  final int? xpToNextLevel;
  final int? levelStartXp;
  final int? nextLevelXp;

  double? get levelFraction {
    final start = levelStartXp;
    final end = nextLevelXp;
    if (start == null || end == null || end <= start) return null;
    return ((xp - start) / (end - start)).clamp(0.0, 1.0);
  }

  final int streak;
  final int bestStreak;
  final int totalActiveDays;
  final bool todayCompleted;
  final bool todayReportSubmitted;
  final List<String> todaySources;
  final List<StreakDayActivity> recentDays;
  final String? streakPolicyVersion;
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
    final List<dynamic> rawSources =
        json['todaySources'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> rawDays =
        json['recentDays'] as List<dynamic>? ?? const <dynamic>[];
    return ProgressSummary(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt(),
      xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt(),
      levelStartXp: (json['levelStartXp'] as num?)?.toInt(),
      nextLevelXp: (json['nextLevelXp'] as num?)?.toInt(),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      totalActiveDays: (json['totalActiveDays'] as num?)?.toInt() ?? 0,
      todayCompleted: json['todayCompleted'] as bool? ?? false,
      todayReportSubmitted: json['todayReportSubmitted'] as bool? ?? false,
      todaySources: rawSources.whereType<String>().toList(growable: false),
      recentDays: rawDays
          .whereType<Map<String, dynamic>>()
          .map(StreakDayActivity.fromJson)
          .toList(growable: false),
      streakPolicyVersion: json['streakPolicyVersion'] as String?,
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

/// Khung bậc mùa & huy hiệu thành tích (T085 - không dùng giờ dậy để xếp hạng).
class ProfileSeasonRank {
  const ProfileSeasonRank({
    required this.seasonCode,
    required this.tier,
    required this.labelVi,
    required this.frameColorHex,
    required this.minXp,
    this.nextMinXp,
  });

  final String seasonCode;
  final String tier;
  final String labelVi;
  final String frameColorHex;
  final int minXp;
  final int? nextMinXp;

  factory ProfileSeasonRank.fromJson(Map<String, dynamic> json) {
    return ProfileSeasonRank(
      seasonCode: json['seasonCode'] as String? ?? '2026-S4',
      tier: json['tier'] as String? ?? 'dong',
      labelVi: json['labelVi'] as String? ?? 'Đồng · Khởi hành',
      frameColorHex: json['frameColor'] as String? ?? '#A67C52',
      minXp: (json['minXp'] as num?)?.toInt() ?? 0,
      nextMinXp: (json['nextMinXp'] as num?)?.toInt(),
    );
  }
}

class ProfileStamp {
  const ProfileStamp({
    required this.id,
    required this.titleVi,
    required this.valueVi,
    required this.subtitleVi,
    required this.kind,
  });

  final String id;
  final String titleVi;
  final String valueVi;
  final String subtitleVi;
  final String kind;

  factory ProfileStamp.fromJson(Map<String, dynamic> json) {
    return ProfileStamp(
      id: json['id'] as String? ?? '',
      titleVi: json['titleVi'] as String? ?? '',
      valueVi: json['valueVi'] as String? ?? '',
      subtitleVi: json['subtitleVi'] as String? ?? '',
      kind: json['kind'] as String? ?? 'flame',
    );
  }
}

class ProfileTopSubject {
  const ProfileTopSubject({
    required this.subjectCode,
    required this.subjectNameVi,
    required this.masteryScore,
    required this.attemptsCount,
    required this.correctCount,
    required this.accuracyPct,
    required this.currentWeek,
    this.currentChapter = '',
  });

  final String subjectCode;
  final String subjectNameVi;
  final int masteryScore;
  final int attemptsCount;
  final int correctCount;
  final int accuracyPct;
  final int currentWeek;
  final String currentChapter;

  factory ProfileTopSubject.fromJson(Map<String, dynamic> json) {
    return ProfileTopSubject(
      subjectCode: json['subjectCode'] as String? ?? 'TOAN',
      subjectNameVi: json['subjectNameVi'] as String? ?? 'Toán',
      masteryScore: (json['masteryScore'] as num?)?.toInt() ?? 50,
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      accuracyPct: (json['accuracyPct'] as num?)?.toInt() ?? 0,
      currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 12,
      currentChapter: json['currentChapter'] as String? ?? '',
    );
  }
}

class ProfileShowcaseGroupItem {
  const ProfileShowcaseGroupItem({
    required this.id,
    required this.name,
    required this.groupCode,
    required this.streakDays,
    required this.memberCount,
    required this.maxMembers,
    required this.petName,
  });

  final String id;
  final String name;
  final String groupCode;
  final int streakDays;
  final int memberCount;
  final int maxMembers;
  final String petName;

  factory ProfileShowcaseGroupItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> pet =
        json['pet'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return ProfileShowcaseGroupItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Nhóm cam kết',
      groupCode: json['groupCode'] as String? ?? '',
      streakDays: (pet['currentStreakDays'] as num?)?.toInt() ??
          (json['groupStreak'] as num?)?.toInt() ??
          0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 1,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 8,
      petName: pet['name'] as String? ?? 'Mầm',
    );
  }
}

class ProfileShowcase {
  const ProfileShowcase({
    required this.userId,
    required this.alias,
    required this.avatarId,
    required this.gradeLevel,
    required this.xp,
    required this.level,
    required this.streak,
    required this.bestStreak,
    required this.seasonRank,
    required this.equippedTitleVi,
    required this.earlyBirdDaysThisWeek,
    required this.topSubject,
    required this.stamps,
    required this.groups,
    required this.leaderboardOptIn,
  });

  final String userId;
  final String alias;
  final String avatarId;
  final String gradeLevel;
  final int xp;
  final int level;
  final int streak;
  final int bestStreak;
  final ProfileSeasonRank seasonRank;
  final String equippedTitleVi;
  final int earlyBirdDaysThisWeek;
  final ProfileTopSubject topSubject;
  final List<ProfileStamp> stamps;
  final List<ProfileShowcaseGroupItem> groups;
  final bool leaderboardOptIn;

  factory ProfileShowcase.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rankJson =
        json['seasonRank'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final Map<String, dynamic> topJson =
        json['topSubject'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final List<dynamic> rawStamps =
        json['stamps'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> rawGroups =
        json['groups'] as List<dynamic>? ?? const <dynamic>[];
    return ProfileShowcase(
      userId: json['userId'] as String? ?? '',
      alias: json['alias'] as String? ?? 'Học sinh MindClock',
      avatarId: json['avatarId'] as String? ?? 'sunrise',
      gradeLevel: json['gradeLevel'] as String? ?? 'Lớp 11',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      seasonRank: ProfileSeasonRank.fromJson(rankJson),
      equippedTitleVi:
          json['equippedTitleVi'] as String? ?? 'Bạn đồng hành MindClock',
      earlyBirdDaysThisWeek:
          (json['earlyBirdDaysThisWeek'] as num?)?.toInt() ?? 0,
      topSubject: ProfileTopSubject.fromJson(topJson),
      stamps: rawStamps
          .whereType<Map<String, dynamic>>()
          .map(ProfileStamp.fromJson)
          .toList(growable: false),
      groups: rawGroups
          .whereType<Map<String, dynamic>>()
          .map(ProfileShowcaseGroupItem.fromJson)
          .toList(growable: false),
      leaderboardOptIn: json['leaderboardOptIn'] as bool? ?? false,
    );
  }
}

class WeeklyLeaderboardEntry {
  const WeeklyLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.alias,
    required this.avatarId,
    required this.gradeLevel,
    required this.seasonRank,
    required this.equippedTitleVi,
    required this.subjectCode,
    required this.subjectNameVi,
    required this.weeklyScore,
    required this.accuracyPct,
    required this.attemptsCount,
    required this.earlyBirdDaysThisWeek,
    required this.isCurrentUser,
  });

  final int rank;
  final String userId;
  final String alias;
  final String avatarId;
  final String gradeLevel;
  final ProfileSeasonRank seasonRank;
  final String equippedTitleVi;
  final String subjectCode;
  final String subjectNameVi;
  final int weeklyScore;
  final int accuracyPct;
  final int attemptsCount;
  final int earlyBirdDaysThisWeek;
  final bool isCurrentUser;

  factory WeeklyLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return WeeklyLeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      userId: json['userId'] as String? ?? '',
      alias: json['alias'] as String? ?? 'Bạn học',
      avatarId: json['avatarId'] as String? ?? 'sunrise',
      gradeLevel: json['gradeLevel'] as String? ?? 'Lớp 11',
      seasonRank: ProfileSeasonRank.fromJson(
        json['seasonRank'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      equippedTitleVi:
          json['equippedTitleVi'] as String? ?? 'Bạn đồng hành MindClock',
      subjectCode: json['subjectCode'] as String? ?? 'TOAN',
      subjectNameVi: json['subjectNameVi'] as String? ?? 'Toán',
      weeklyScore: (json['weeklyScore'] as num?)?.toInt() ?? 0,
      accuracyPct: (json['accuracyPct'] as num?)?.toInt() ?? 0,
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
      earlyBirdDaysThisWeek:
          (json['earlyBirdDaysThisWeek'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}

class WeeklySubjectLeaderboard {
  const WeeklySubjectLeaderboard({
    required this.subjectCode,
    required this.subjectNameVi,
    required this.weekWindowVi,
    required this.currentUserOptedIn,
    required this.entries,
  });

  final String subjectCode;
  final String subjectNameVi;
  final String weekWindowVi;
  final bool currentUserOptedIn;
  final List<WeeklyLeaderboardEntry> entries;

  factory WeeklySubjectLeaderboard.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawEntries =
        json['entries'] as List<dynamic>? ?? const <dynamic>[];
    return WeeklySubjectLeaderboard(
      subjectCode: json['subjectCode'] as String? ?? 'TOAN',
      subjectNameVi: json['subjectNameVi'] as String? ?? 'Toán',
      weekWindowVi: json['weekWindowVi'] as String? ?? '7 ngày gần nhất',
      currentUserOptedIn: json['currentUserOptedIn'] as bool? ?? false,
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(WeeklyLeaderboardEntry.fromJson)
          .toList(growable: false),
    );
  }
}
