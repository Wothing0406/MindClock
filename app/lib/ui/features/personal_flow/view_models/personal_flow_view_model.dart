import 'package:flutter/foundation.dart';

import '../../../../data/services/local_id_generator.dart';
import '../../../../data/services/offline_text_draft_store.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../../domain/game/solo_training_question_bank.dart';
import '../../../../domain/models/auth_session.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/xp_history.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/services/auth_session_gateway.dart';
import '../../../../domain/services/camera_capture_gateway.dart';
import '../../../../domain/services/personal_flow_repository.dart';

/// ViewModel điều phối luồng học tập cá nhân online/offline (`docs/07, 17, 18, 24, 25, 39`).
///
/// Tách biệt hoàn toàn khỏi `AlarmSchedulerService` để lỗi mạng hoặc hết hạn token
/// tuyệt đối không làm hỏng báo thức local hoặc Dừng khẩn cấp.
class PersonalFlowViewModel extends ChangeNotifier {
  PersonalFlowViewModel({
    required AuthSessionGateway authGateway,
    required PersonalFlowRepository repository,
    required CameraCaptureGateway cameraGateway,
    required OfflineTextDraftStore draftStore,
    DateTime Function()? nowProvider,
  })  : _authGateway = authGateway,
        _repository = repository,
        _cameraGateway = cameraGateway,
        _draftStore = draftStore,
        _nowProvider = nowProvider ?? DateTime.now;

  final AuthSessionGateway _authGateway;
  final PersonalFlowRepository _repository;
  final CameraCaptureGateway _cameraGateway;
  final OfflineTextDraftStore _draftStore;
  final DateTime Function() _nowProvider;

  AuthSession _authSession = const AuthSession.guest();
  ChallengeQuestion? _currentQuestion;
  StudySessionRecord? _activeSession;
  GradingResult? _lastResult;
  ProgressSummary _progressSummary = const ProgressSummary.unauthenticated();
  List<SessionHistoryItem> _sessionHistory = const <SessionHistoryItem>[];
  List<XpHistoryEntry> _xpHistory = const [];
  int? _xpNextOffset;
  bool _xpHistoryLoaded = false;
  bool _xpHistoryBusy = false;
  String? _xpHistoryError;
  DateTime? _progressSyncedAt;
  String? _progressError;
  int _progressEpoch = 0;
  int _historyEpoch = 0;

  List<XpHistoryEntry> get xpHistory => List.unmodifiable(_xpHistory);
  bool get xpHistoryHasMore => _xpNextOffset != null;
  bool get xpHistoryLoaded => _xpHistoryLoaded;
  bool get xpHistoryBusy => _xpHistoryBusy;
  String? get xpHistoryError => _xpHistoryError;
  DateTime? get progressSyncedAt => _progressSyncedAt;
  String? get progressError => _progressError;
  OfflineTextDraft? _savedDraft;
  PhotoAttemptUpload? _pendingPhotoPreview;
  FeedbackReportResult? _lastFeedbackReport;

  bool _isBusy = false;
  bool _challengeModeSession = false;
  bool _morningHookCompletedOrSkipped = false;
  int _clearWrongCount = 0;
  int _offlineRotationOffset = 0;
  String? _postAttemptRevealVi;
  String? _bannerMessageVi;
  String? _errorMessageVi;

  // Giữ khóa idempotency ổn định xuyên suốt các lần retry cùng nội dung
  String? _pendingClientAttemptId;
  String? _pendingIdempotencyKey;
  String _preparedAnswerSnapshot = '';
  String _preparedReasoningSnapshot = '';
  bool _hasRetryableTextFailure = false;
  bool _hasRetryablePhotoFailure = false;

  bool get isDebugFixture =>
      _repository.isDebugFixture || _authGateway.isDebugFixture;
  AuthSession get authSession => _authSession;
  ChallengeQuestion? get currentQuestion => _currentQuestion;
  StudySessionRecord? get activeSession => _activeSession;
  GradingResult? get lastResult => _lastResult;
  ProgressSummary get progressSummary => _progressSummary;
  List<SessionHistoryItem> get sessionHistory => _sessionHistory;
  OfflineTextDraft? get savedDraft => _savedDraft;
  PhotoAttemptUpload? get pendingPhotoPreview => _pendingPhotoPreview;
  FeedbackReportResult? get lastFeedbackReport => _lastFeedbackReport;

  bool get isBusy => _isBusy;
  bool get isChallengeModeSession => _challengeModeSession;
  bool get isMorningHookVisible =>
      _currentQuestion?.morningCard != null && !_morningHookCompletedOrSkipped;
  int get clearWrongCount => _clearWrongCount;
  String? get postAttemptRevealVi =>
      _postAttemptRevealVi ?? _lastResult?.revealVi;
  bool get canAbandonCurrentSession =>
      _clearWrongCount >= 5 || (_lastResult?.canAbandon ?? false);
  String? get bannerMessageVi => _bannerMessageVi;
  String? get errorMessageVi => _errorMessageVi;
  bool get hasRetryableTextFailure => _hasRetryableTextFailure;
  bool get hasRetryablePhotoFailure => _hasRetryablePhotoFailure;
  String? get activeIdempotencyKey => _pendingIdempotencyKey;
  String? get activeClientAttemptId => _pendingClientAttemptId;

  /// Bỏ qua đoạn mở màn (6–12 giây) để vào thẳng câu hỏi của cùng lượt học (`MORNING-01`).
  void skipOrFinishMorningHook() {
    if (_morningHookCompletedOrSkipped) return;
    _morningHookCompletedOrSkipped = true;
    notifyListeners();
  }

  /// Theo `docs/31` & `docs/07 §6`: chế độ thử thách chỉ hiện gợi ý phương pháp từ lần sai rõ thứ 3.
  bool get canRevealMethodHint {
    final GradingResult? result = _lastResult;
    if (result == null || result.hintVi == null || result.hintVi!.isEmpty) {
      return false;
    }
    if (!_challengeModeSession) return true;
    return _clearWrongCount >= 3;
  }

  Future<void> initialize() async {
    _authSession = await _authGateway.loadSavedSession();
    _savedDraft = await _draftStore.loadDraft(_authSession.ownerScopeKey);
    if (_authSession.isAuthenticated) {
      await _loadOnlineProgressQuietly();
    } else {
      _progressSummary = const ProgressSummary.unauthenticated();
      _sessionHistory = const <SessionHistoryItem>[];
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _runAuthOperation(
      () => _authGateway.signInWithEmail(email: email, password: password),
      successMessage: 'Đã đăng nhập tài khoản học tập.',
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    return _runAuthOperation(
      () => _authGateway.signUpWithEmail(email: email, password: password),
      successMessage: 'Đã tạo tài khoản và đăng nhập thành công.',
    );
  }

  Future<bool> _runAuthOperation(
    Future<AuthSession> Function() operation, {
    required String successMessage,
  }) async {
    _isBusy = true;
    _errorMessageVi = null;
    _bannerMessageVi = null;
    notifyListeners();

    try {
      final String previousOwner = _authSession.ownerScopeKey;
      final AuthSession next = await operation();
      if (next.ownerScopeKey != previousOwner) {
        _resetAccountScopedMemory();
      }
      _authSession = next;
      _savedDraft = await _draftStore.loadDraft(_authSession.ownerScopeKey);
      _bannerMessageVi = isDebugFixture
          ? '$successMessage (Chế độ cục bộ trên máy).'
          : successMessage;
      await _loadOnlineProgressQuietly();
      return true;
    } on AuthException catch (e) {
      _errorMessageVi = e.messageVi;
      return false;
    } on Exception catch (e) {
      _errorMessageVi =
          'Không thể hoàn tất xác thực lúc này (${e.runtimeType}). Báo thức trên máy vẫn chạy bình thường.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<StudyProfile?> fetchRemoteProfileIfSignedIn() async {
    if (!_authSession.isAuthenticated) return null;
    try {
      return await _repository.fetchProfileSnapshot();
    } on Exception {
      return null;
    }
  }

  Future<void> signOut() async {
    await _authGateway.signOut();
    _authSession = const AuthSession.guest();
    _resetAccountScopedMemory();
    _savedDraft = await _draftStore.loadDraft(_authSession.ownerScopeKey);
    _bannerMessageVi =
        'Đã đăng xuất và xóa dữ liệu phiên khỏi bộ nhớ hiển thị. Báo thức local trên máy vẫn được giữ nguyên.';
    notifyListeners();
  }

  void _resetAccountScopedMemory() {
    _progressEpoch++;
    _historyEpoch++;
    _xpHistory = const [];
    _xpNextOffset = null;
    _xpHistoryLoaded = false;
    _xpHistoryBusy = false;
    _xpHistoryError = null;
    _progressSyncedAt = null;
    _progressError = null;
    _currentQuestion = null;
    _activeSession = null;
    _lastResult = null;
    _progressSummary = const ProgressSummary.unauthenticated();
    _sessionHistory = const <SessionHistoryItem>[];
    _pendingPhotoPreview = null;
    _lastFeedbackReport = null;
    _morningHookCompletedOrSkipped = false;
    _postAttemptRevealVi = null;
    _clearWrongCount = 0;
    _clearSubmissionKeys();
  }

  Future<void> _loadOnlineProgressQuietly() async {
    if (!_authSession.isAuthenticated) {
      _progressSummary = const ProgressSummary.unauthenticated();
      _sessionHistory = const <SessionHistoryItem>[];
      return;
    }
    final epoch = ++_progressEpoch;
    final owner = _authSession.ownerScopeKey;
    bool current() =>
        epoch == _progressEpoch &&
        _authSession.isAuthenticated &&
        owner == _authSession.ownerScopeKey;
    try {
      final summary = await _repository.fetchProgressSummary();
      if (!current()) return;
      _progressSummary = summary;
      _progressSyncedAt = _nowProvider();
      _progressError = null;
      final history = await _repository.fetchSessionHistory(limit: 10);
      if (current()) _sessionHistory = history;
    } on PersonalApiException catch (e) {
      if (!current()) return;
      _progressError = e.messageVi;
      await _handleApiError(e, preservePendingSubmission: true);
    }
  }

  Future<void> refreshProgressAndHistory() async {
    if (!_authSession.isAuthenticated) {
      _progressSummary = const ProgressSummary.unauthenticated();
      _sessionHistory = const <SessionHistoryItem>[];
      _bannerMessageVi =
          'Đăng nhập để xem XP và lịch sử phiên đồng bộ từ server.';
      notifyListeners();
      return;
    }
    _isBusy = true;
    _errorMessageVi = null;
    notifyListeners();
    try {
      await _loadOnlineProgressQuietly();
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadXpHistory({bool refresh = false}) async {
    if (!_authSession.isAuthenticated || isDebugFixture) return;
    if (_xpHistoryBusy && !refresh) return;
    if (!refresh && _xpHistoryLoaded && _xpNextOffset == null) return;
    final owner = _authSession.ownerScopeKey;
    final epoch = ++_historyEpoch;
    bool current() =>
        epoch == _historyEpoch &&
        _authSession.isAuthenticated &&
        owner == _authSession.ownerScopeKey;
    final offset = refresh ? 0 : _xpNextOffset ?? 0;
    _xpHistoryBusy = true;
    _xpHistoryError = null;
    notifyListeners();
    try {
      final page = await _repository.fetchXpHistory(offset: offset);
      if (!current()) return;
      final byId = <String, XpHistoryEntry>{
        if (!refresh)
          for (final entry in _xpHistory) entry.id: entry,
        for (final entry in page.items) entry.id: entry,
      };
      _xpHistory = List.unmodifiable(byId.values);
      _xpNextOffset = page.nextOffset;
      _xpHistoryLoaded = true;
    } on PersonalApiException catch (e) {
      if (!current()) return;
      _xpHistoryError = e.messageVi;
      await _handleApiError(e, preservePendingSubmission: true);
    } finally {
      if (epoch == _historyEpoch) {
        _xpHistoryBusy = false;
        notifyListeners();
      }
    }
  }

  /// Tải câu hỏi từ `/v1/challenges/next` (hoặc lấy câu hỏi + đáp án có sẵn trong kho cục bộ khi offline/mất mạng).
  Future<void> startSession({
    String alarmId = 'practice_manual',
    String? subjectCode,
    String? gradeLevel,
    bool challengeMode = false,
    bool preferAiRegen = false,
  }) async {
    _isBusy = true;
    _errorMessageVi = null;
    _bannerMessageVi = null;
    _lastResult = null;
    _lastFeedbackReport = null;
    _pendingPhotoPreview = null;
    _challengeModeSession = challengeMode;
    _morningHookCompletedOrSkipped = false;
    _postAttemptRevealVi = null;
    _clearWrongCount = 0;
    _clearSubmissionKeys();
    notifyListeners();

    final DateTime now = _nowProvider();
    final String localDate = _formatYmd(now);
    final String localSessionId = LocalIdGenerator.nextUuidV4();

    if (!_authSession.isAuthenticated) {
      _currentQuestion = _offlineBankChallengeQuestion(
        localDate: localDate,
        subjectCode: subjectCode,
        gradeLevel: gradeLevel,
      );
      _activeSession = StudySessionRecord(
        sessionId: 'local_$localSessionId',
        localSessionId: localSessionId,
        state: 'offline_ungraded',
        version: 1,
        isOfflineLocal: true,
      );
      _bannerMessageVi =
          'Đang dùng bộ câu hỏi & đáp án có sẵn trên máy (luyện tập ngoại tuyến, không cộng XP server).';
      _isBusy = false;
      notifyListeners();
      return;
    }

    try {
      final ChallengeQuestion question = await _repository.fetchNextChallenge(
        localDate: localDate,
        subjectCode: subjectCode,
        mode: preferAiRegen ? 'ai_regen' : 'bank',
      );
      final StudySessionRecord session = await _repository.createOrSyncSession(
        alarmId: alarmId,
        localSessionId: localSessionId,
        localDate: localDate,
        questionId: question.questionId,
        questionRevision: question.questionRevision,
        startedAtUtc: now.toUtc(),
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
      );
      _currentQuestion = question;
      _activeSession = session;
      if (isDebugFixture) {
        _bannerMessageVi =
            'Chế độ cục bộ trên máy · Không phải AI/XP từ máy chủ.';
      } else if (preferAiRegen) {
        _bannerMessageVi =
            'Đã nạp câu mới tạo từ đề gốc vào phiên học hiện tại.';
      }
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: false);
      _currentQuestion = _offlineBankChallengeQuestion(
        localDate: localDate,
        subjectCode: subjectCode,
        gradeLevel: gradeLevel,
      );
      _activeSession = StudySessionRecord(
        sessionId: 'local_$localSessionId',
        localSessionId: localSessionId,
        state: 'offline_ungraded',
        version: 1,
        isOfflineLocal: true,
      );
      _bannerMessageVi =
          'Mất kết nối máy chủ: đã chuyển sang bộ câu hỏi & đáp án có sẵn trên máy.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  bool get hasOfflineAnswerKey =>
      _currentQuestion != null &&
      SoloTrainingQuestionBank.findById(_currentQuestion!.questionId) != null;

  /// Đối chiếu trực tiếp với đáp án & lời giải có sẵn trên máy khi mất mạng (luôn giữ 0 XP server).
  GradingResult? checkOfflineBankAnswer({
    required String answerValue,
    required String reasoningText,
  }) {
    final ChallengeQuestion? question = _currentQuestion;
    if (question == null) {
      _errorMessageVi = 'Hãy mở câu hỏi trước khi kiểm tra đáp án.';
      notifyListeners();
      return null;
    }
    final String cleanAnswer = answerValue.trim();
    final String cleanReasoning = reasoningText.trim();
    if (cleanAnswer.isEmpty || cleanReasoning.isEmpty) {
      _errorMessageVi =
          'Vui lòng nhập đáp án và ít nhất một bước làm để đối chiếu.';
      notifyListeners();
      return null;
    }
    final SoloApprovedQuestion? offlineQ =
        SoloTrainingQuestionBank.findById(question.questionId);
    if (offlineQ == null) {
      _errorMessageVi =
          'Câu này chưa có bộ đáp án lưu cục bộ. Bạn có thể lưu bản nháp 24 giờ để gửi máy chủ khi có mạng.';
      notifyListeners();
      return null;
    }
    final SoloGradingFeedback localGrade = gradeSoloTrainingSubmission(
      question: offlineQ,
      answerText: cleanAnswer,
      reasoningText: cleanReasoning,
    );
    final GradingVerdict mappedVerdict = switch (localGrade.status) {
      SoloGradeStatus.correct => GradingVerdict.correct,
      SoloGradeStatus.incorrect => GradingVerdict.incorrect,
      SoloGradeStatus.uncertain => GradingVerdict.uncertain,
    };
    final int nextWrongCount = mappedVerdict == GradingVerdict.incorrect
        ? _clearWrongCount + 1
        : (mappedVerdict == GradingVerdict.correct ? 0 : _clearWrongCount);
    final GradingResult offlineResult = GradingResult(
      attemptId: 'offline_${LocalIdGenerator.nextUuidV4()}',
      verdict: mappedVerdict,
      observedSteps: <String>[cleanReasoning],
      firstIssue: mappedVerdict == GradingVerdict.incorrect
          ? 'Kiểm tra lại bước biến đổi và đáp số đối chiếu.'
          : null,
      feedbackVi:
          '${localGrade.feedbackVi} (Đối chiếu bộ đáp án có sẵn · 0 XP server).',
      hintVi: offlineQ.oneStepHintVi,
      nextActions: mappedVerdict == GradingVerdict.correct
          ? const <String>['finish']
          : <String>[
              'retry',
              if (nextWrongCount >= 5) 'abandon',
              'finish_ungraded',
              'emergency_stop',
            ],
      xpAwarded: 0,
      modelVersion: 'offline-bank-validator',
      rubricRevision: offlineQ.rubricRevision,
      isServerAuthoritative: false,
      confirmedIncorrectCount: nextWrongCount,
      canAbandon:
          mappedVerdict != GradingVerdict.correct && nextWrongCount >= 5,
      revealVi: mappedVerdict == GradingVerdict.correct
          ? '${offlineQ.gradingRubricStepsVi.join(" ")} Đáp án: ${offlineQ.explanationAfterRevealVi}'
          : null,
    );
    _applyGradingResult(offlineResult);
    _errorMessageVi = null;
    notifyListeners();
    return offlineResult;
  }

  /// Bảo toàn cặp `clientAttemptId` + `idempotencyKey` giữa các lần retry cùng nội dung;
  /// chỉ cấp key mới khi người dùng thay đổi bài làm.
  void ensureSubmissionKeys({
    required String answerValue,
    required String reasoningText,
  }) {
    final String a = answerValue.trim();
    final String r = reasoningText.trim();
    final bool samePayload =
        a == _preparedAnswerSnapshot && r == _preparedReasoningSnapshot;

    if (!samePayload ||
        _pendingClientAttemptId == null ||
        _pendingIdempotencyKey == null) {
      _preparedAnswerSnapshot = a;
      _preparedReasoningSnapshot = r;
      _pendingClientAttemptId = LocalIdGenerator.nextUuidV4();
      _pendingIdempotencyKey = LocalIdGenerator.nextUuidV4();
      _hasRetryableTextFailure = false;
      _hasRetryablePhotoFailure = false;
    }
  }

  void _clearSubmissionKeys() {
    _preparedAnswerSnapshot = '';
    _preparedReasoningSnapshot = '';
    _pendingClientAttemptId = null;
    _pendingIdempotencyKey = null;
    _hasRetryableTextFailure = false;
    _hasRetryablePhotoFailure = false;
  }

  Future<GradingResult?> submitTextAnswer({
    required String answerValue,
    required String reasoningText,
  }) async {
    final String cleanAnswer = answerValue.trim();
    final String cleanReasoning = reasoningText.trim();
    if (cleanAnswer.isEmpty || cleanReasoning.isEmpty) {
      _errorMessageVi =
          'Vui lòng nhập cả đáp án và ít nhất một bước giải thích trước khi gửi.';
      notifyListeners();
      return null;
    }

    final ChallengeQuestion? question = _currentQuestion;
    final StudySessionRecord? session = _activeSession;
    if (question == null || session == null) {
      _errorMessageVi = 'Hãy bắt đầu câu hỏi trước khi nộp bài.';
      notifyListeners();
      return null;
    }

    ensureSubmissionKeys(
      answerValue: cleanAnswer,
      reasoningText: cleanReasoning,
    );

    if (!_authSession.isAuthenticated || session.isOfflineLocal) {
      _errorMessageVi =
          'Chưa thể gửi chấm máy chủ khi ngoại tuyến hoặc chưa đăng nhập. Bạn có thể bấm "Kiểm tra đáp án có sẵn (ngoại tuyến)" hoặc lưu bản nháp chữ (tối đa 24 giờ).';
      _lastResult = null;
      notifyListeners();
      return null;
    }

    _isBusy = true;
    _errorMessageVi = null;
    _bannerMessageVi = null;
    notifyListeners();

    try {
      final GradingResult result = await _repository.submitTextAnswer(
        sessionId: session.sessionId,
        answerValue: cleanAnswer,
        reasoningText: cleanReasoning,
        clientAttemptId: _pendingClientAttemptId!,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      _applyGradingResult(result);
      _clearSubmissionKeys();
      await _loadOnlineProgressQuietly();
      return result;
    } on PersonalApiException catch (e) {
      _hasRetryableTextFailure = e.retryable || e.isTimeout || e.isNetworkError;
      if (e.isConflict) {
        _clearSubmissionKeys();
      }
      await _handleApiError(e, preservePendingSubmission: true);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Xin quyền camera đúng lúc người dùng bấm chụp và đưa sang màn xem lại trước upload.
  Future<void> capturePhotoForReview() async {
    _errorMessageVi = null;
    _bannerMessageVi = null;
    final CameraCaptureOutcome outcome =
        await _cameraGateway.captureHandwrittenPhoto();

    switch (outcome.status) {
      case CameraCaptureStatus.captured:
        if (outcome.bytes != null && outcome.mimeType != null) {
          _pendingPhotoPreview = PhotoAttemptUpload(
            bytes: outcome.bytes!,
            mimeType: outcome.mimeType!,
            fileName: outcome.fileName ?? 'handwritten_attempt.jpg',
          );
          _pendingClientAttemptId = LocalIdGenerator.nextUuidV4();
          _pendingIdempotencyKey = LocalIdGenerator.nextUuidV4();
          _hasRetryablePhotoFailure = false;
          _bannerMessageVi =
              'Vui lòng kiểm tra lại ảnh vừa chụp và bấm Xác nhận gửi ảnh.';
        }
      case CameraCaptureStatus.permissionDenied:
      case CameraCaptureStatus.unavailable:
      case CameraCaptureStatus.fileTooLarge:
      case CameraCaptureStatus.unsupportedMime:
        _errorMessageVi = outcome.messageVi;
      case CameraCaptureStatus.cancelled:
        _bannerMessageVi = outcome.messageVi ?? 'Đã hủy chụp ảnh.';
    }
    notifyListeners();
  }

  void cancelPhotoPreview() {
    _pendingPhotoPreview = null;
    _hasRetryablePhotoFailure = false;
    _clearSubmissionKeys();
    _bannerMessageVi =
        'Đã hủy ảnh vừa chụp (không lưu ảnh trên máy và không gửi lên server).';
    notifyListeners();
  }

  Future<GradingResult?> confirmAndUploadPhotoAttempt({
    required String answerValue,
  }) async {
    final PhotoAttemptUpload? photo = _pendingPhotoPreview;
    if (photo == null) {
      _errorMessageVi = 'Chưa có ảnh bài làm để gửi.';
      notifyListeners();
      return null;
    }
    final String cleanAnswer = answerValue.trim();
    if (cleanAnswer.isEmpty) {
      _errorMessageVi =
          'Vui lòng nhập đáp án cuối cùng trước khi xác nhận gửi ảnh.';
      notifyListeners();
      return null;
    }

    final ChallengeQuestion? question = _currentQuestion;
    final StudySessionRecord? session = _activeSession;
    if (question == null ||
        session == null ||
        !_authSession.isAuthenticated ||
        session.isOfflineLocal) {
      _errorMessageVi =
          'Chưa thể chấm ảnh khi ngoại tuyến hoặc chưa đăng nhập. Ảnh không tự xếp hàng gửi ngầm; bạn có thể nhập chữ hoặc hủy ảnh.';
      notifyListeners();
      return null;
    }

    _pendingClientAttemptId ??= LocalIdGenerator.nextUuidV4();
    _pendingIdempotencyKey ??= LocalIdGenerator.nextUuidV4();

    _isBusy = true;
    _errorMessageVi = null;
    _bannerMessageVi = null;
    notifyListeners();

    try {
      final GradingResult result = await _repository.submitPhotoAttempt(
        sessionId: session.sessionId,
        questionId: question.questionId,
        answerValue: cleanAnswer,
        photo: photo,
        clientAttemptId: _pendingClientAttemptId!,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      // Xóa ảnh tạm trong RAM ngay sau khi hoàn tất request
      _pendingPhotoPreview = null;
      _hasRetryablePhotoFailure = false;
      _applyGradingResult(result);
      _clearSubmissionKeys();
      await _loadOnlineProgressQuietly();
      return result;
    } on PersonalApiException catch (e) {
      _hasRetryablePhotoFailure =
          e.retryable || e.isTimeout || e.isNetworkError;
      if (e.isConflict) {
        _clearSubmissionKeys();
      }
      await _handleApiError(e, preservePendingSubmission: true);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _applyGradingResult(GradingResult result) {
    _lastResult = result;
    _morningHookCompletedOrSkipped = true;
    switch (result.verdict) {
      case GradingVerdict.correct:
        _clearWrongCount = 0;
        _postAttemptRevealVi = result.revealVi;
      case GradingVerdict.incorrect:
        _clearWrongCount = result.confirmedIncorrectCount > 0
            ? result.confirmedIncorrectCount
            : (_clearWrongCount + 1);
      case GradingVerdict.uncertain:
        // Không cộng lượt sai rõ khi AI chưa chắc chắn (`docs/31`, `docs/39`).
        break;
    }
  }

  /// Bỏ lượt sau khi đã thử và sai rõ từ 5 lần (`MORNING-02`, `MORNING-03`):
  /// kết thúc phiên với `0 EXP`, không cộng ngày chuỗi, không trừ điểm đã có và hiển thị lời giải chuẩn.
  Future<SessionAbandonResult?> abandonActiveSession() async {
    final StudySessionRecord? session = _activeSession;
    if (session == null) return null;
    if (!canAbandonCurrentSession) {
      _errorMessageVi =
          'Chỉ mở Bỏ lượt sau khi đã thử và sai rõ từ 5 lần. Dừng khẩn cấp luôn có sẵn.';
      notifyListeners();
      return null;
    }
    if (!_authSession.isAuthenticated || session.isOfflineLocal) {
      _activeSession = session.copyWith(state: 'abandoned');
      _bannerMessageVi =
          'Đã bỏ lượt câu này trên máy (0 EXP, không trừ điểm đã có).';
      notifyListeners();
      return SessionAbandonResult(
        sessionId: session.sessionId,
        state: 'abandoned',
        version: session.version + 1,
        confirmedIncorrectCount: _clearWrongCount,
        xpAwarded: 0,
        streakDayAwarded: false,
        messageVi: _bannerMessageVi!,
      );
    }

    _isBusy = true;
    _errorMessageVi = null;
    notifyListeners();
    try {
      final SessionAbandonResult res = await _repository.abandonSession(
        sessionId: session.sessionId,
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
      );
      _activeSession = session.copyWith(
        state: res.state,
        version: res.version,
      );
      _postAttemptRevealVi = res.revealVi;
      _bannerMessageVi = res.messageVi;
      await _loadOnlineProgressQuietly();
      return res;
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> completeSessionUngraded() async {
    final StudySessionRecord? session = _activeSession;
    if (session != null &&
        _authSession.isAuthenticated &&
        !session.isOfflineLocal) {
      try {
        _activeSession = await _repository.postSessionEvent(
          sessionId: session.sessionId,
          eventType: 'complete_ungraded',
          occurredAtUtc: _nowProvider().toUtc(),
          version: session.version,
          idempotencyKey: LocalIdGenerator.nextUuidV4(),
        );
        await _loadOnlineProgressQuietly();
      } on PersonalApiException catch (e) {
        await _handleApiError(e, preservePendingSubmission: false);
      }
    }
    _pendingPhotoPreview = null;
    _bannerMessageVi =
        'Đã hoàn thành không chấm. Tiến độ/XP chỉ ghi nhận trên server khi đủ điều kiện.';
    notifyListeners();
  }

  Future<void> saveOfflineTextDraft({
    required String answerValue,
    required String reasoningText,
  }) async {
    final ChallengeQuestion? question = _currentQuestion;
    final String cleanAnswer = answerValue.trim();
    final String cleanReasoning = reasoningText.trim();
    if (question == null || cleanAnswer.isEmpty || cleanReasoning.isEmpty) {
      _errorMessageVi =
          'Nhập đủ đáp án và cách làm chữ để lưu bản nháp cục bộ.';
      notifyListeners();
      return;
    }
    ensureSubmissionKeys(
      answerValue: cleanAnswer,
      reasoningText: cleanReasoning,
    );
    _savedDraft = await _draftStore.saveDraft(
      ownerScopeKey: _authSession.ownerScopeKey,
      questionId: question.questionId,
      questionRevision: question.questionRevision,
      promptSnapshot: question.prompt,
      answerValue: cleanAnswer,
      reasoningText: cleanReasoning,
      clientAttemptId: _pendingClientAttemptId!,
      idempotencyKey: _pendingIdempotencyKey!,
    );
    _bannerMessageVi =
        'Đã lưu bản nháp chữ trên máy (hiệu lực tối đa 24 giờ, chỉ gửi khi bạn xác nhận).';
    _errorMessageVi = null;
    notifyListeners();
  }

  Future<GradingResult?> confirmAndUploadSavedDraft() async {
    final OfflineTextDraft? draft =
        await _draftStore.loadDraft(_authSession.ownerScopeKey);
    _savedDraft = draft;
    if (draft == null) {
      _errorMessageVi = 'Không còn bản nháp hợp lệ trong 24 giờ qua.';
      notifyListeners();
      return null;
    }
    if (!_authSession.isAuthenticated) {
      _errorMessageVi = 'Vui lòng đăng nhập để gửi bản nháp nhận nhận xét.';
      notifyListeners();
      return null;
    }

    _isBusy = true;
    _errorMessageVi = null;
    _bannerMessageVi = null;
    notifyListeners();

    try {
      final DateTime now = _nowProvider();
      final StudySessionRecord session = await _repository.createOrSyncSession(
        alarmId: 'offline_draft_sync',
        localSessionId: LocalIdGenerator.nextUuidV4(),
        localDate: _formatYmd(now),
        questionId: draft.questionId,
        questionRevision: draft.questionRevision,
        startedAtUtc: DateTime.fromMillisecondsSinceEpoch(
            draft.savedAtEpochMillis,
            isUtc: true),
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
      );

      final GradingResult result = await _repository.submitTextAnswer(
        sessionId: session.sessionId,
        answerValue: draft.answerValue,
        reasoningText: draft.reasoningText,
        clientAttemptId: draft.clientAttemptId,
        idempotencyKey: draft.idempotencyKey,
      );

      await _draftStore.clearDraft(_authSession.ownerScopeKey);
      _savedDraft = null;
      _activeSession = session;
      _applyGradingResult(result);
      await _loadOnlineProgressQuietly();
      _bannerMessageVi = 'Đã gửi bản nháp và nhận phản hồi từ máy chủ.';
      return result;
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> discardSavedDraft() async {
    await _draftStore.clearDraft(_authSession.ownerScopeKey);
    _savedDraft = null;
    _bannerMessageVi = 'Đã xóa bản nháp chữ khỏi thiết bị.';
    notifyListeners();
  }

  Future<FeedbackReportResult?> reportGradingWrong({
    String category = 'incorrect_verdict',
    String? comment,
  }) async {
    final StudySessionRecord? session = _activeSession;
    final GradingResult? result = _lastResult;
    if (session == null ||
        result == null ||
        !_authSession.isAuthenticated ||
        session.isOfflineLocal) {
      _errorMessageVi = 'Chỉ báo chấm sai được cho lượt chấm trên server.';
      notifyListeners();
      return null;
    }

    _isBusy = true;
    _errorMessageVi = null;
    notifyListeners();
    try {
      final FeedbackReportResult report =
          await _repository.reportGradingFeedback(
        sessionId: session.sessionId,
        attemptId: result.attemptId,
        category: category,
        comment: comment,
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
      );
      _lastFeedbackReport = report;
      _bannerMessageVi = 'Đã gửi phản hồi báo chấm sai tới hệ thống rà soát.';
      return report;
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _handleApiError(
    PersonalApiException e, {
    required bool preservePendingSubmission,
  }) async {
    _errorMessageVi = e.messageVi;
    if (e.isAuthExpired) {
      _progressSummary = const ProgressSummary.unauthenticated();
      _sessionHistory = const [];
      _xpHistory = const [];
      _xpHistoryLoaded = false;
      _xpNextOffset = null;
      _progressSyncedAt = null;
      _authSession = await _authGateway.loadSavedSession();
      if (_authSession.status != AuthStatus.reauthRequired) {
        _authSession = await _authGateway.markSessionExpired(
          messageVi:
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại (chuông báo thức trên máy vẫn giữ nguyên).',
        );
      }
    }
    if (!preservePendingSubmission) {
      _clearSubmissionKeys();
    }
  }

  Future<List<Map<String, dynamic>>> parseTimetableImage({
    required String imageBase64,
    String mimeType = 'image/jpeg',
  }) {
    return _repository.parseTimetableImage(
      imageBase64: imageBase64,
      mimeType: mimeType,
    );
  }

  /// Đồng bộ hồ sơ THPT (`PATCH /v1/me`) khi đã đăng nhập; lỗi mạng không làm mất lưu local.
  Future<bool> syncProfileToServer(StudyProfile profile) async {
    if (!_authSession.isAuthenticated) return false;
    try {
      await _repository.syncProfile(profile: profile);
      return true;
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Ghi nhận đồng ý điều khoản/dữ liệu (`POST /v1/me/consent`) trên server.
  Future<bool> recordConsent({
    required String scope,
    required String version,
    required bool granted,
  }) async {
    if (!_authSession.isAuthenticated) return false;
    try {
      await _repository.recordConsent(
        scope: scope,
        version: version,
        granted: granted,
      );
      return true;
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Đồng bộ thời khóa biểu 7 ngày (`PUT /v1/timetable`) khi đã đăng nhập; lỗi mạng giữ an toàn dữ liệu local.
  Future<bool> syncTimetableToServer(WeeklyTimetable timetable) async {
    if (!_authSession.isAuthenticated) return false;
    try {
      await _repository.syncTimetable(timetable: timetable);
      return true;
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Xóa tài khoản & dữ liệu trực tuyến (`DELETE /v1/me`), đăng xuất tại chỗ; không chạm báo thức local.
  Future<bool> deleteAccount() async {
    if (!_authSession.isAuthenticated) return false;
    final String deletingScope = _authSession.ownerScopeKey;
    _isBusy = true;
    _errorMessageVi = null;
    _bannerMessageVi = null;
    notifyListeners();
    try {
      await _repository.deleteAccount();
      await _draftStore.clearDraft(deletingScope);
      await _authGateway.signOut();
      _authSession = const AuthSession.guest();
      _resetAccountScopedMemory();
      _savedDraft = null;
      _bannerMessageVi =
          'Đã xóa tài khoản và dữ liệu trực tuyến. Báo thức local trên máy vẫn được giữ nguyên.';
      return true;
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
      return false;
    } catch (_) {
      _errorMessageVi =
          'Không thể xóa tài khoản lúc này. Vui lòng thử lại khi có mạng.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  static String _formatYmd(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  ChallengeQuestion _offlineBankChallengeQuestion({
    required String localDate,
    String? subjectCode,
    String? gradeLevel,
  }) {
    final SoloApprovedQuestion picked =
        SoloTrainingQuestionBank.pickOfflineQuestion(
      subjectCode: subjectCode,
      gradeLevel: gradeLevel,
      excludeQuestionId: _currentQuestion?.questionId,
      rotationOffset: _offlineRotationOffset++,
    );
    return ChallengeQuestion(
      questionId: picked.id,
      questionRevision: picked.revision,
      validForDate: localDate,
      subjectCode: picked.subjectCode,
      topicId: '${picked.subjectCode}_offline',
      difficulty: 1,
      prompt: picked.prompt,
      reasoningPromptVi: picked.reasoningPromptVi,
      offlinePolicy: 'offline_approved_bank',
      estimatedSeconds: 60,
      fallback: true,
      isDebugFixture: false,
    );
  }
}
