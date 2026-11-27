import '../../domain/models/personal_flow_models.dart';
import '../../domain/models/xp_history.dart';
import '../../domain/models/study_profile.dart';
import '../../domain/models/timetable.dart';
import '../../domain/services/answer_normalizer.dart';
import '../../domain/services/personal_flow_repository.dart';

/// Fixture debug tách riêng cho demo/test UI khi chưa bật backend thật `T016`.
///
/// Tuân thủ `docs/18 §4`: luôn trả `isDebugFixture = true` và không đánh dấu
/// `isServerAuthoritative = true` để UI không giả lập đây là AI/XP thật.
class DebugFixturePersonalFlowRepository implements PersonalFlowRepository {
  DebugFixturePersonalFlowRepository();

  int _wrongStreakInChallenge = 0;
  final Map<String, GradingResult> _idempotentResults =
      <String, GradingResult>{};

  @override
  bool get isDebugFixture => true;

  @override
  Future<void> syncProfile({required StudyProfile profile}) async {}

  @override
  Future<StudyProfile?> fetchProfileSnapshot() async => null;

  @override
  Future<void> recordConsent({
    required String scope,
    required String version,
    required bool granted,
  }) async {}

  @override
  Future<void> syncTimetable({required WeeklyTimetable timetable}) async {}

  @override
  Future<WeeklyTimetable?> fetchTimetableSnapshot() async => null;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<ChallengeQuestion> fetchNextChallenge({
    required String localDate,
    String? subjectCode,
    String mode = 'bank',
    String? difficulty,
  }) async {
    final bool aiRegen = mode.trim().toLowerCase() == 'ai_regen';
    return ChallengeQuestion(
      questionId: aiRegen ? 'fixture-ai-regen-002' : 'fixture-math9-linear-001',
      questionRevision: aiRegen ? 1 : 3,
      validForDate: localDate,
      subjectCode: subjectCode ?? 'TOAN',
      topicId: 'linear_equation_1var',
      difficulty: aiRegen ? 2 : 1,
      prompt: aiRegen
          ? 'Giải phương trình 3(x - 2) = 15 (tái tạo từ đề gốc).'
          : 'Giải phương trình 2(x − 3) = 10.',
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
  Future<SessionAbandonResult> abandonSession({
    required String sessionId,
    required String idempotencyKey,
    bool immediate = false,
  }) async {
    return SessionAbandonResult(
      sessionId: sessionId,
      state: 'abandoned',
      version: 2,
      confirmedIncorrectCount: _wrongStreakInChallenge,
      xpAwarded: 0,
      streakDayAwarded: false,
      messageVi: '[Fixture debug] Đã bỏ lượt câu này (0 EXP).',
      revealVi:
          '[Fixture debug] Chia hai vế của 2(x − 3) = 10 cho 2 được x − 3 = 5, suy ra x = 8.',
    );
  }

  @override
  Future<GradingResult> submitTextAnswer({
    required String sessionId,
    required String answerValue,
    required String reasoningText,
    required String clientAttemptId,
    required String idempotencyKey,
    int? selectedIndex,
    List<int>? quizAnswers,
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
    } else if (isAnswerAccepted(
        cleanAnswer, const <String>['8', 'x=8', 'x = 8'])) {
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
      final bool allowAbandon = _wrongStreakInChallenge >= 5;
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
        nextActions: allowAbandon
            ? const <String>[
                'retry',
                'abandon',
                'finish_ungraded',
                'emergency_stop'
              ]
            : const <String>['retry', 'finish_ungraded', 'emergency_stop'],
        xpAwarded: 0,
        modelVersion: 'debug-fixture-v1',
        rubricRevision: 3,
        isServerAuthoritative: false,
        confirmedIncorrectCount: _wrongStreakInChallenge,
        canAbandon: allowAbandon,
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
    return ProgressSummary(
      xp: 0,
      streak: _debugReports.isNotEmpty ? 1 : 0,
      bestStreak: _debugReports.isNotEmpty ? 1 : 0,
      totalActiveDays: _debugReports.length,
      todayCompleted: _debugReports.isNotEmpty,
      todayReportSubmitted: _debugReports.isNotEmpty,
      todaySources: _debugReports.isNotEmpty
          ? const <String>['daily_report']
          : const <String>[],
      completedSessions: 0,
      topicsToReview: const <String>['Phương trình bậc nhất (Fixture debug)'],
      isServerAuthoritative: false,
      isDebugFixture: true,
    );
  }

  final List<DailyReportRecord> _debugReports = <DailyReportRecord>[];

  @override
  Future<DailyReportSubmitResult> submitDailyReport({
    required int tasksCompleted,
    required String feeling,
    required String reflectionNote,
    required String idempotencyKey,
  }) async {
    final DateTime now = DateTime.now();
    final String ymd =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final bool already =
        _debugReports.any((DailyReportRecord r) => r.localDate == ymd);
    final DailyReportRecord report = DailyReportRecord(
      reportId: 'debug_report_$ymd',
      localDate: ymd,
      studyMinutes: 0,
      tasksCompleted: tasksCompleted,
      challengeCompleted: false,
      feeling: feeling,
      reflectionNote: reflectionNote.trim(),
      xpAwarded: 0,
      createdAt: now,
    );
    _debugReports.removeWhere((DailyReportRecord r) => r.localDate == ymd);
    _debugReports.insert(0, report);
    final ProgressSummary updatedSummary = await fetchProgressSummary();
    return DailyReportSubmitResult(
      report: report,
      alreadyReportedToday: already,
      xpAwarded: 0,
      streakAwardedToday: !already,
      summary: updatedSummary,
    );
  }

  @override
  Future<List<DailyReportRecord>> fetchDailyReports({int limit = 14}) async {
    return List<DailyReportRecord>.unmodifiable(_debugReports.take(limit));
  }

  @override
  Future<XpHistoryPage> fetchXpHistory(
          {int limit = 20, int offset = 0}) async =>
      const XpHistoryPage(items: []);

  @override
  Future<List<SessionHistoryItem>> fetchSessionHistory({
    int limit = 20,
    String? cursor,
  }) async {
    return const <SessionHistoryItem>[];
  }

  @override
  Future<List<Map<String, dynamic>>> parseTimetableImage({
    required String imageBase64,
    String mimeType = 'image/jpeg',
  }) async {
    return const <Map<String, dynamic>>[
      <String, dynamic>{'weekday': 1, 'position': 1, 'subjectCode': 'math'},
      <String, dynamic>{
        'weekday': 1,
        'position': 2,
        'subjectCode': 'literature'
      },
      <String, dynamic>{'weekday': 2, 'position': 1, 'subjectCode': 'physics'},
      <String, dynamic>{
        'weekday': 3,
        'position': 1,
        'subjectCode': 'chemistry'
      },
      <String, dynamic>{'weekday': 4, 'position': 1, 'subjectCode': 'english'},
      <String, dynamic>{'weekday': 5, 'position': 1, 'subjectCode': 'history'},
    ];
  }

  @override
  Future<ProfileShowcase> fetchProfileShowcase() async {
    return const ProfileShowcase(
      userId: 'debug_student',
      alias: 'Học sinh MindClock',
      avatarId: 'avatar_sunrise',
      gradeLevel: 'Lớp 11',
      xp: 340,
      level: 2,
      streak: 5,
      bestStreak: 7,
      seasonRank: ProfileSeasonRank(
        seasonCode: '2026-S4',
        tier: 'vang',
        labelVi: 'Vàng · Bình minh',
        frameColorHex: '#D9932B',
        minXp: 300,
        nextMinXp: 700,
      ),
      equippedTitleVi: 'Dậy sớm chủ động',
      earlyBirdDaysThisWeek: 4,
      topSubject: ProfileTopSubject(
        subjectCode: 'TOAN',
        subjectNameVi: 'Toán',
        masteryScore: 76,
        attemptsCount: 8,
        correctCount: 7,
        accuracyPct: 88,
        currentWeek: 12,
        currentChapter: 'Dãy số & Cấp số',
      ),
      stamps: <ProfileStamp>[
        ProfileStamp(
          id: 'streak',
          titleVi: 'Chuỗi bền bỉ',
          valueVi: '5 ngày',
          subtitleVi: 'Kỷ lục 7 ngày',
          kind: 'flame',
        ),
        ProfileStamp(
          id: 'early_bird',
          titleVi: 'Dậy sớm tuần',
          valueVi: '4/7 ngày',
          subtitleVi: 'Hoàn thành thử thách sáng',
          kind: 'sunrise',
        ),
        ProfileStamp(
          id: 'top_subject',
          titleVi: 'Sở trường',
          valueVi: 'Môn Toán',
          subtitleVi: '76% · Tuần 12',
          kind: 'book',
        ),
      ],
      groups: <ProfileShowcaseGroupItem>[
        ProfileShowcaseGroupItem(
          id: 'debug_group_1',
          name: 'Nhóm 6h sáng',
          groupCode: 'MAM600',
          streakDays: 5,
          memberCount: 3,
          maxMembers: 8,
          petName: 'Mầm Xanh',
        ),
      ],
      leaderboardOptIn: true,
    );
  }

  @override
  Future<WeeklySubjectLeaderboard> fetchWeeklySubjectLeaderboard({
    String subjectCode = 'TOAN',
    int limit = 20,
  }) async {
    return WeeklySubjectLeaderboard(
      subjectCode: subjectCode,
      subjectNameVi: subjectCode == 'TIENG_ANH' ? 'Tiếng Anh' : 'Toán',
      weekWindowVi: '7 ngày gần nhất',
      currentUserOptedIn: true,
      entries: <WeeklyLeaderboardEntry>[
        WeeklyLeaderboardEntry(
          rank: 1,
          userId: 'debug_student',
          alias: 'Học sinh MindClock',
          avatarId: 'avatar_sunrise',
          gradeLevel: 'Lớp 11',
          seasonRank: const ProfileSeasonRank(
            seasonCode: '2026-S4',
            tier: 'vang',
            labelVi: 'Vàng · Bình minh',
            frameColorHex: '#D9932B',
            minXp: 300,
            nextMinXp: 700,
          ),
          equippedTitleVi: 'Dậy sớm chủ động',
          subjectCode: subjectCode,
          subjectNameVi: subjectCode == 'TIENG_ANH' ? 'Tiếng Anh' : 'Toán',
          weeklyScore: 185,
          accuracyPct: 88,
          attemptsCount: 8,
          earlyBirdDaysThisWeek: 4,
          isCurrentUser: true,
        ),
      ],
    );
  }
}
