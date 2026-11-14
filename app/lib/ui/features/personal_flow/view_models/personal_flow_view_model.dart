import 'package:flutter/foundation.dart';

import '../../../../data/services/local_id_generator.dart';
import '../../../../data/services/offline_text_draft_store.dart';
import '../../../../domain/models/auth_session.dart';
import '../../../../domain/models/personal_flow_models.dart';
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
  OfflineTextDraft? _savedDraft;
  PhotoAttemptUpload? _pendingPhotoPreview;
  FeedbackReportResult? _lastFeedbackReport;

  bool _isBusy = false;
  bool _challengeModeSession = false;
  int _clearWrongCount = 0;
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
  int get clearWrongCount => _clearWrongCount;
  String? get bannerMessageVi => _bannerMessageVi;
  String? get errorMessageVi => _errorMessageVi;
  bool get hasRetryableTextFailure => _hasRetryableTextFailure;
  bool get hasRetryablePhotoFailure => _hasRetryablePhotoFailure;
  String? get activeIdempotencyKey => _pendingIdempotencyKey;
  String? get activeClientAttemptId => _pendingClientAttemptId;

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
          ? '$successMessage (Đang dùng Fixture debug — không phải tài khoản thật).'
          : successMessage;
      await _loadOnlineProgressQuietly();
      return true;
    } on AuthException catch (e) {
      _errorMessageVi = e.messageVi;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
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
    _currentQuestion = null;
    _activeSession = null;
    _lastResult = null;
    _progressSummary = const ProgressSummary.unauthenticated();
    _sessionHistory = const <SessionHistoryItem>[];
    _pendingPhotoPreview = null;
    _lastFeedbackReport = null;
    _clearWrongCount = 0;
    _clearSubmissionKeys();
  }

  Future<void> _loadOnlineProgressQuietly() async {
    if (!_authSession.isAuthenticated) {
      _progressSummary = const ProgressSummary.unauthenticated();
      _sessionHistory = const <SessionHistoryItem>[];
      return;
    }
    try {
      _progressSummary = await _repository.fetchProgressSummary();
      _sessionHistory = await _repository.fetchSessionHistory(limit: 10);
    } on PersonalApiException catch (e) {
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
      _progressSummary = await _repository.fetchProgressSummary();
      _sessionHistory = await _repository.fetchSessionHistory(limit: 10);
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: true);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Tải câu hỏi từ `/v1/challenges/next` (hoặc chuyển sang câu dự phòng local khi offline/chưa đăng nhập).
  Future<void> startSession({
    String alarmId = 'practice_manual',
    String? subjectCode,
    bool challengeMode = false,
  }) async {
    _isBusy = true;
    _errorMessageVi = null;
    _bannerMessageVi = null;
    _lastResult = null;
    _lastFeedbackReport = null;
    _pendingPhotoPreview = null;
    _challengeModeSession = challengeMode;
    _clearWrongCount = 0;
    _clearSubmissionKeys();
    notifyListeners();

    final DateTime now = _nowProvider();
    final String localDate = _formatYmd(now);
    final String localSessionId = LocalIdGenerator.nextUuidV4();

    if (!_authSession.isAuthenticated) {
      _currentQuestion = _bundledFallbackQuestion(
        localDate: localDate,
        subjectCode: subjectCode,
      );
      _activeSession = StudySessionRecord(
        sessionId: 'local_$localSessionId',
        localSessionId: localSessionId,
        state: 'offline_ungraded',
        version: 1,
        isOfflineLocal: true,
      );
      _bannerMessageVi =
          'Chưa đăng nhập: bạn vẫn làm câu dự phòng trên máy (hoàn thành không chấm, không tự cộng XP).';
      _isBusy = false;
      notifyListeners();
      return;
    }

    try {
      final ChallengeQuestion question = await _repository.fetchNextChallenge(
        localDate: localDate,
        subjectCode: subjectCode,
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
            'Đang dùng Fixture debug · Không phải AI thật hay XP server.';
      }
    } on PersonalApiException catch (e) {
      await _handleApiError(e, preservePendingSubmission: false);
      _currentQuestion = _bundledFallbackQuestion(
        localDate: localDate,
        subjectCode: subjectCode,
      );
      _activeSession = StudySessionRecord(
        sessionId: 'local_$localSessionId',
        localSessionId: localSessionId,
        state: 'offline_ungraded',
        version: 1,
        isOfflineLocal: true,
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
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
          'Chưa thể chấm khi ngoại tuyến hoặc chưa đăng nhập. Bạn có thể hoàn thành không chấm hoặc lưu nháp chữ (tối đa 24 giờ).';
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
      _errorMessageVi = 'Vui lòng nhập đáp án cuối cùng trước khi xác nhận gửi ảnh.';
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
      _hasRetryablePhotoFailure = e.retryable || e.isTimeout || e.isNetworkError;
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
    switch (result.verdict) {
      case GradingVerdict.correct:
        _clearWrongCount = 0;
      case GradingVerdict.incorrect:
        _clearWrongCount += 1;
      case GradingVerdict.uncertain:
        // Không cộng lượt sai rõ khi AI chưa chắc chắn (`docs/31`, `docs/39`).
        break;
    }
  }

  Future<void> completeSessionUngraded() async {
    final StudySessionRecord? session = _activeSession;
    if (session != null && _authSession.isAuthenticated && !session.isOfflineLocal) {
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
        startedAtUtc:
            DateTime.fromMillisecondsSinceEpoch(draft.savedAtEpochMillis, isUtc: true),
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
      final FeedbackReportResult report = await _repository.reportGradingFeedback(
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

  static String _formatYmd(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static ChallengeQuestion _bundledFallbackQuestion({
    required String localDate,
    String? subjectCode,
  }) {
    return ChallengeQuestion(
      questionId: 'bundled-offline-math-001',
      questionRevision: 1,
      validForDate: localDate,
      subjectCode: subjectCode ?? 'TOAN',
      topicId: 'linear_equation_1var',
      difficulty: 1,
      prompt: 'Tìm x biết 2x + 4 = 12 (câu dự phòng offline).',
      reasoningPromptVi: 'Viết một bước biến đổi chính của bạn.',
      offlinePolicy: 'ungraded_only',
      estimatedSeconds: 60,
      fallback: true,
      isDebugFixture: false,
    );
  }
}
