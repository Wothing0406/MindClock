import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/local_study_focus_repository.dart';
import '../../../../data/services/local_id_generator.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/study_ai_models.dart';
import '../../../../domain/models/study_focus_models.dart';
import '../../../../domain/services/study_ai_gateway.dart';
import '../../../../domain/services/study_focus_bridge.dart';

/// ViewModel điều phối Không gian học local & đồng bộ AI qua backend (`docs/45 §§1–6`).
///
/// - Mọi số giây còn lại và tập trung được tính từ mốc thời gian thiết bị (`DateTime`),
///   tuyệt đối không cộng thời gian ảo khi kill app hay suy ra xao nhãng khi rời app.
/// - Tách biệt theo `ownerScopeKey` (`guest` hoặc `user:<uid>`) để không lộ phiên
///   khi đăng xuất/đổi tài khoản, đồng thời không chạm vào báo thức local.
/// - Mọi lỗi mạng/timeout/429/401 của API không bao giờ chặn timer hoặc giữ kẹt màn học.
class StudyFocusViewModel extends ChangeNotifier {
  StudyFocusViewModel({
    required LocalStudyFocusRepository repository,
    required StudyFocusBridge bridge,
    StudyAiGateway? aiGateway,
    DateTime Function()? nowProvider,
    bool enablePeriodicTicker = true,
  })  : _repository = repository,
        _bridge = bridge,
        _aiGateway = aiGateway,
        _nowProvider = nowProvider ?? DateTime.now,
        _enablePeriodicTicker = enablePeriodicTicker;

  final LocalStudyFocusRepository _repository;
  final StudyFocusBridge _bridge;
  final StudyAiGateway? _aiGateway;
  final DateTime Function() _nowProvider;
  final bool _enablePeriodicTicker;

  String _ownerScopeKey = 'guest';
  bool _isAuthenticated = false;
  String? _gradeLevel;
  bool _isLoaded = false;
  bool _isBackgrounded = false;
  bool _hasPlayedEndCueForSession = false;

  // Cấu hình draft cho phiên kế tiếp
  String _draftTaskTitle = '';
  String? _draftSubjectCode;
  int _draftDurationMinutes = 25;
  StudyFocusLevel _draftLevel = StudyFocusLevel.standard;
  bool _draftEndSoundEnabled = true;
  bool _draftNotifyOutsideApp = false;
  bool _reduceMotionStaticMode = false;

  StudyFocusSessionSnapshot? _activeSnapshot;
  List<StudyFocusRecord> _history = const <StudyFocusRecord>[];
  StudyNotificationPermission _notificationPermission =
      StudyNotificationPermission.unknown;
  String? _wellbeingFeedbackVi;
  String? _statusBannerVi;
  Timer? _ticker;

  // Trạng thái AI Socratic & đồng bộ `/v1/study/*`
  List<StudyHelpTurn> _aiTurns = const <StudyHelpTurn>[];
  StudyAiRequestStatus _aiStatus = StudyAiRequestStatus.idle;
  String? _aiErrorVi;
  String? _pendingHelpQuestion;
  String? _pendingHelpIdempotencyKey;
  String? _remoteSessionErrorVi;
  Future<void>? _pendingRemoteCreate;
  Future<void>? _pendingRemoteFinish;

  // Trạng thái câu hỏi cá nhân hóa & Gemini Live opt-in
  PersonalizedPracticeQuestion? _personalizedQuestion;
  StudyAiRequestStatus _personalizedStatus = StudyAiRequestStatus.idle;
  String? _personalizedErrorVi;
  bool _liveConsentGranted = false;
  GeminiLiveSessionToken? _liveToken;
  StudyAiRequestStatus _liveTokenStatus = StudyAiRequestStatus.idle;
  String? _liveTokenErrorVi;

  String get ownerScopeKey => _ownerScopeKey;
  bool get isAuthenticated => _isAuthenticated;
  String? get gradeLevel => _gradeLevel;
  bool get hasAiGateway => _aiGateway != null;
  bool get isAiDebugFixture => _aiGateway?.isDebugFixture ?? false;
  bool get isLoaded => _isLoaded;
  String get draftTaskTitle => _draftTaskTitle;
  String? get draftSubjectCode => _draftSubjectCode;
  int get draftDurationMinutes => _draftDurationMinutes;
  StudyFocusLevel get draftLevel => _draftLevel;
  bool get draftEndSoundEnabled => _draftEndSoundEnabled;
  bool get draftNotifyOutsideApp => _draftNotifyOutsideApp;
  bool get reduceMotionStaticMode => _reduceMotionStaticMode;

  StudyFocusSessionSnapshot? get activeSnapshot => _activeSnapshot;
  List<StudyFocusRecord> get history => _history;
  StudyNotificationPermission get notificationPermission =>
      _notificationPermission;
  String? get wellbeingFeedbackVi => _wellbeingFeedbackVi;
  String? get statusBannerVi => _statusBannerVi;
  List<StudyHelpTurn> get aiTurns => _aiTurns;
  StudyAiRequestStatus get aiStatus => _aiStatus;
  String? get aiErrorVi => _aiErrorVi;
  String? get pendingHelpQuestion => _pendingHelpQuestion;
  String? get remoteSessionErrorVi => _remoteSessionErrorVi;
  PersonalizedPracticeQuestion? get personalizedQuestion => _personalizedQuestion;
  StudyAiRequestStatus get personalizedStatus => _personalizedStatus;
  String? get personalizedErrorVi => _personalizedErrorVi;
  bool get liveConsentGranted => _liveConsentGranted;
  GeminiLiveSessionToken? get liveToken => _liveToken;
  StudyAiRequestStatus get liveTokenStatus => _liveTokenStatus;
  String? get liveTokenErrorVi => _liveTokenErrorVi;

  Future<void> waitForPendingRemoteWork() async {
    await _pendingRemoteCreate;
    await _pendingRemoteFinish;
  }

  DateTime get currentTime => _nowProvider();

  bool get hasOngoingSession => _activeSnapshot?.status.isOngoing ?? false;
  bool get hasUnfinishedOrSummarySession => _activeSnapshot != null;

  int get remainingSeconds {
    final StudyFocusSessionSnapshot? s = _activeSnapshot;
    if (s == null) return _draftDurationMinutes * 60;
    return s.remainingSecondsAt(_nowProvider());
  }

  int get elapsedWallSeconds {
    final StudyFocusSessionSnapshot? s = _activeSnapshot;
    if (s == null) return 0;
    return s.elapsedWallSecondsAt(_nowProvider());
  }

  int get inAppFocusSeconds {
    final StudyFocusSessionSnapshot? s = _activeSnapshot;
    if (s == null) return 0;
    return s.inAppFocusSecondsAt(_nowProvider());
  }

  double get progressFraction {
    final StudyFocusSessionSnapshot? s = _activeSnapshot;
    if (s == null || s.targetDurationSeconds <= 0) return 0;
    final int done = s.countdownElapsedSecondsAt(_nowProvider());
    return (done / s.targetDurationSeconds).clamp(0.0, 1.0);
  }

  Future<void> initialize({String ownerScopeKey = 'guest'}) async {
    _ownerScopeKey = _normalizeScope(ownerScopeKey);
    await _reloadScopeState();
    _notificationPermission = await _bridge.getNotificationPermissionStatus();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setAccountAuthenticated(
    bool isAuthenticated, {
    String? gradeLevel,
  }) async {
    final bool changed =
        isAuthenticated != _isAuthenticated || gradeLevel != _gradeLevel;
    _isAuthenticated = isAuthenticated;
    _gradeLevel = gradeLevel;
    if (changed) {
      notifyListeners();
    }
    // Không tự gửi câu hỏi/bản nháp AI khi chỉ đổi kết nối/trạng thái đăng nhập.
  }

  Future<void> setOwnerScope(String nextOwnerScopeKey) async {
    final String normalized = _normalizeScope(nextOwnerScopeKey);
    if (normalized == _ownerScopeKey && _isLoaded) return;
    _stopTicker();
    _isBackgrounded = false;
    _hasPlayedEndCueForSession = false;
    _statusBannerVi = null;
    _wellbeingFeedbackVi = null;
    _clearAiConversationState();
    await _bridge.cancelStudyReminder();
    _ownerScopeKey = normalized;
    await _reloadScopeState();
    _isLoaded = true;
    notifyListeners();
  }

  void _clearAiConversationState() {
    _aiTurns = const <StudyHelpTurn>[];
    _aiStatus = StudyAiRequestStatus.idle;
    _aiErrorVi = null;
    _pendingHelpQuestion = null;
    _pendingHelpIdempotencyKey = null;
    _remoteSessionErrorVi = null;
    _personalizedQuestion = null;
    _personalizedStatus = StudyAiRequestStatus.idle;
    _personalizedErrorVi = null;
    _liveToken = null;
    _liveTokenStatus = StudyAiRequestStatus.idle;
    _liveTokenErrorVi = null;
  }

  String _normalizeScope(String scope) {
    final String clean = scope.trim();
    return clean.isEmpty ? 'guest' : clean;
  }

  Future<void> _reloadScopeState() async {
    _history = await _repository.loadHistory(_ownerScopeKey);
    final StudyFocusSessionSnapshot? stored =
        await _repository.loadSnapshot(_ownerScopeKey);
    if (stored == null) {
      _activeSnapshot = null;
      return;
    }

    // Khôi phục sau khi app bị kill/reboot (`docs/45 §2`, `F02`):
    // mọi phiên `running` hoặc `paused` khi mở lại lạnh chuyển về `interrupted`
    // tại mốc sống cuối cùng để không cộng thời gian ảo trong lúc app đã đóng.
    if (stored.status == StudyFocusStatus.running ||
        stored.status == StudyFocusStatus.paused) {
      final int nowMs = _nowProvider().millisecondsSinceEpoch;
      final int candidateFreezeMs =
          stored.pausedAtEpochMs ?? stored.leftAtEpochMs ?? stored.updatedAtEpochMs;
      final int frozenAtMs = math.min(
        nowMs,
        math.max(stored.startedAtEpochMs, candidateFreezeMs),
      );
      _activeSnapshot = stored.copyWith(
        status: StudyFocusStatus.interrupted,
        pausedAtEpochMs: frozenAtMs,
        clearLeftAt: true,
        commitmentAwaitingResume: false,
        updatedAtEpochMs: nowMs,
        lastReturnNoticeVi:
            'Phiên đã gián đoạn do app đóng hoặc máy khởi động lại. Không cộng thời gian ảo; chọn Tiếp tục học hoặc Kết thúc.',
      );
      await _repository.saveSnapshot(_activeSnapshot!);
    } else {
      _activeSnapshot = stored;
    }
  }

  void applyTaskSuggestion(StudyTaskChoice choice) {
    _draftTaskTitle = choice.title;
    _draftSubjectCode = choice.subjectCode;
    notifyListeners();
  }

  void setCustomTaskTitle(String title) {
    _draftTaskTitle = title;
    notifyListeners();
  }

  void setDurationMinutes(int minutes) {
    _draftDurationMinutes = minutes.clamp(
      StudyFocusSessionSnapshot.minDurationMinutes,
      StudyFocusSessionSnapshot.maxDurationMinutes,
    );
    notifyListeners();
  }

  void setFocusLevel(StudyFocusLevel level) {
    _draftLevel = level;
    notifyListeners();
  }

  void setEndSoundEnabled(bool enabled) {
    _draftEndSoundEnabled = enabled;
    notifyListeners();
  }

  void setReduceMotionStaticMode(bool enabled) {
    _reduceMotionStaticMode = enabled;
    notifyListeners();
  }

  Future<void> setNotifyOutsideApp(bool enabled) async {
    if (!enabled) {
      _draftNotifyOutsideApp = false;
      _statusBannerVi = null;
      notifyListeners();
      return;
    }

    final StudyNotificationPermission perm =
        await _bridge.requestNotificationPermission();
    _notificationPermission = perm;
    if (perm == StudyNotificationPermission.granted) {
      _draftNotifyOutsideApp = true;
      _statusBannerVi =
          'Đã bật 1 nhắc cục bộ khi rời phiên Tập trung thường quá 30 giây.';
    } else {
      _draftNotifyOutsideApp = false;
      _statusBannerVi =
          'Chưa có quyền thông báo OS. MindClock vẫn nhắc nhẹ ngay trong màn hình khi bạn quay lại.';
    }
    notifyListeners();
  }

  Future<void> startSession({
    String? overrideTaskTitle,
    String? overrideSubjectCode,
  }) async {
    final DateTime now = _nowProvider();
    final int nowMs = now.millisecondsSinceEpoch;
    final String rawTitle = (overrideTaskTitle ?? _draftTaskTitle).trim();
    final String resolvedTitle =
        rawTitle.isEmpty ? StudyTaskChoice.freeStudy.title : rawTitle;
    final String? resolvedSubject = rawTitle.isEmpty
        ? null
        : (overrideSubjectCode ?? _draftSubjectCode);

    final int plannedEndMs =
        nowMs + Duration(minutes: _draftDurationMinutes).inMilliseconds;

    _hasPlayedEndCueForSession = false;
    _isBackgrounded = false;
    _statusBannerVi = null;
    _clearAiConversationState();

    final StudyFocusSessionSnapshot snapshot = StudyFocusSessionSnapshot(
      sessionId: LocalIdGenerator.nextUuidV4(),
      ownerScopeKey: _ownerScopeKey,
      taskTitle: resolvedTitle,
      subjectCode: resolvedSubject,
      durationMinutes: _draftDurationMinutes,
      level: _draftLevel,
      status: StudyFocusStatus.running,
      endSoundEnabled: _draftEndSoundEnabled,
      notifyOutsideApp: _draftNotifyOutsideApp,
      startedAtEpochMs: nowMs,
      plannedEndAtEpochMs: plannedEndMs,
      updatedAtEpochMs: nowMs,
      createIdempotencyKey: LocalIdGenerator.nextUuidV4(),
      finishIdempotencyKey: LocalIdGenerator.nextUuidV4(),
    );
    _activeSnapshot = snapshot;

    // Timer & dữ liệu phiên luôn lưu local trước, không chờ backend.
    await _repository.saveSnapshot(_activeSnapshot!);
    _startTickerIfRunning();
    notifyListeners();

    if (_isAuthenticated && _aiGateway != null) {
      _pendingRemoteCreate = _syncRemoteSessionCreation(snapshot.sessionId);
    }
  }

  Future<bool> retryCreateRemoteSession() async {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null) return false;
    final Future<bool> work = _syncRemoteSessionCreation(current.sessionId);
    _pendingRemoteCreate = work;
    return work;
  }

  Future<bool> _syncRemoteSessionCreation(String localSessionId) async {
    final StudyAiGateway? gateway = _aiGateway;
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (!_isAuthenticated || gateway == null || current == null) {
      return false;
    }
    if (current.sessionId != localSessionId) return false;
    if (current.remoteSessionSynced &&
        current.remoteSessionId != null &&
        current.remoteSessionId!.isNotEmpty) {
      return true;
    }

    final String idempotencyKey = current.createIdempotencyKey.isNotEmpty
        ? current.createIdempotencyKey
        : LocalIdGenerator.nextUuidV4();
    if (current.createIdempotencyKey.isEmpty) {
      _activeSnapshot = current.copyWith(createIdempotencyKey: idempotencyKey);
      await _repository.saveSnapshot(_activeSnapshot!);
    }

    final String scopeAtStart = _ownerScopeKey;
    try {
      final RemoteStudySessionResult remote = await gateway.createStudySession(
        snapshot: _activeSnapshot!,
        idempotencyKey: idempotencyKey,
      );
      final StudyFocusSessionSnapshot? latest = _activeSnapshot;
      if (_ownerScopeKey != scopeAtStart ||
          latest == null ||
          latest.sessionId != localSessionId) {
        return false;
      }
      _activeSnapshot = latest.copyWith(
        remoteSessionId: remote.remoteSessionId,
        remoteSessionSynced: true,
      );
      _remoteSessionErrorVi = null;
      await _repository.saveSnapshot(_activeSnapshot!);
      notifyListeners();
      return true;
    } on PersonalApiException catch (error) {
      if (_ownerScopeKey != scopeAtStart) return false;
      _remoteSessionErrorVi = error.messageVi;
      notifyListeners();
      return false;
    } catch (_) {
      if (_ownerScopeKey != scopeAtStart) return false;
      _remoteSessionErrorVi =
          'Chưa tạo được phiên trên server. Bộ đếm local vẫn chạy bình thường.';
      notifyListeners();
      return false;
    }
  }

  /// Hỏi trợ lý học tập Socratic qua backend `POST /v1/study/help` (`docs/45 §5`).
  ///
  /// Trả `true` chỉ khi thành công để UI xóa ô nhập; khi lỗi trả `false` và GIỮ NGUYÊN
  /// câu hỏi người dùng vừa gõ (`_pendingHelpQuestion`) cùng `Idempotency-Key` để bấm Thử lại.
  Future<bool> requestAiHelp({
    required String questionText,
    String? gradeLevel,
  }) async {
    final String cleanQuestion = questionText.trim();
    if (cleanQuestion.isEmpty) return false;
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null) return false;

    final bool isSamePendingQuestion = _pendingHelpQuestion == cleanQuestion &&
        _pendingHelpIdempotencyKey != null;
    _pendingHelpQuestion = cleanQuestion;
    if (!isSamePendingQuestion) {
      _pendingHelpIdempotencyKey = LocalIdGenerator.nextUuidV4();
    }

    if (!_isAuthenticated) {
      _aiStatus = StudyAiRequestStatus.authExpired;
      _aiErrorVi =
          'Đăng nhập để hỏi AI qua backend. Bạn vẫn giữ câu hỏi vừa nhập và học offline bình thường.';
      notifyListeners();
      return false;
    }

    final StudyAiGateway? gateway = _aiGateway;
    if (gateway == null) {
      _aiStatus = StudyAiRequestStatus.offline;
      _aiErrorVi =
          'Chưa kết nối backend AI. ${StudyHelpResponse.offlineFallbackMessageVi}';
      notifyListeners();
      return false;
    }

    final String scopeAtStart = _ownerScopeKey;
    final String sessionIdAtStart = current.sessionId;
    _aiStatus = StudyAiRequestStatus.loading;
    _aiErrorVi = null;
    notifyListeners();

    if (!current.remoteSessionSynced) {
      await _syncRemoteSessionCreation(current.sessionId);
    }

    final StudyFocusSessionSnapshot? refreshed = _activeSnapshot;
    if (_ownerScopeKey != scopeAtStart ||
        refreshed == null ||
        refreshed.sessionId != sessionIdAtStart) {
      return false;
    }

    final String targetSessionId =
        (refreshed.remoteSessionId != null && refreshed.remoteSessionId!.isNotEmpty)
            ? refreshed.remoteSessionId!
            : refreshed.sessionId;

    try {
      final List<StudyHelpTurn> clippedTurns = _aiTurns.length <= 3
          ? List<StudyHelpTurn>.from(_aiTurns)
          : _aiTurns.sublist(_aiTurns.length - 3);
      final StudyHelpResponse response = await gateway.requestHelp(
        sessionId: targetSessionId,
        taskTitle: refreshed.taskTitle,
        subjectCode: refreshed.subjectCode,
        gradeLevel: gradeLevel ?? _gradeLevel,
        questionText: cleanQuestion,
        recentTurns: clippedTurns,
        idempotencyKey: _pendingHelpIdempotencyKey!,
      );
      if (_ownerScopeKey != scopeAtStart ||
          _activeSnapshot?.sessionId != sessionIdAtStart) {
        return false;
      }

      _aiTurns = <StudyHelpTurn>[
        ..._aiTurns,
        StudyHelpTurn(role: 'user', contentVi: cleanQuestion),
        StudyHelpTurn(
          role: 'assistant',
          contentVi: response.messageVi,
          nextQuestionVi: response.nextQuestionVi,
          helpLevel: response.helpLevel,
          safetyStatus: response.safetyStatus,
        ),
      ];
      _aiStatus = StudyAiRequestStatus.ready;
      _aiErrorVi = null;
      _pendingHelpQuestion = null;
      _pendingHelpIdempotencyKey = null;
      notifyListeners();
      return true;
    } on PersonalApiException catch (error) {
      if (_ownerScopeKey != scopeAtStart) return false;
      _aiStatus = _mapApiExceptionToStatus(error);
      _aiErrorVi = _formatAiErrorVi(error);
      notifyListeners();
      return false;
    } catch (_) {
      if (_ownerScopeKey != scopeAtStart) return false;
      _aiStatus = StudyAiRequestStatus.error;
      _aiErrorVi =
          'Không gọi được AI lúc này. ${StudyHelpResponse.offlineFallbackMessageVi}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> retryLastAiHelp({String? gradeLevel}) async {
    final String? pending = _pendingHelpQuestion;
    if (pending == null || pending.trim().isEmpty) return false;
    return requestAiHelp(questionText: pending, gradeLevel: gradeLevel);
  }

  StudyAiRequestStatus _mapApiExceptionToStatus(PersonalApiException error) {
    if (error.isAuthExpired) return StudyAiRequestStatus.authExpired;
    if (error.httpStatus == 429) return StudyAiRequestStatus.rateLimited;
    if (error.isTimeout) return StudyAiRequestStatus.timeout;
    if (error.isNetworkError) return StudyAiRequestStatus.offline;
    return StudyAiRequestStatus.error;
  }

  String _formatAiErrorVi(PersonalApiException error) {
    if (error.httpStatus == 429) {
      return 'Bạn đang hỏi hơi nhanh (vượt giới hạn lượt). Chờ một lát rồi bấm Thử lại.';
    }
    if (error.isTimeout) {
      return 'Máy chủ AI phản hồi quá 15 giây. Câu hỏi của bạn vẫn được giữ nguyên để thử lại.';
    }
    if (error.isNetworkError) {
      return 'Mất mạng nên chưa hỏi được AI. ${StudyHelpResponse.offlineFallbackMessageVi}';
    }
    if (error.isAuthExpired) {
      return 'Phiên đăng nhập đã hết hạn. Đăng nhập lại ở tab Cá nhân rồi bấm Thử lại.';
    }
    return '${error.messageVi} (${StudyHelpResponse.offlineFallbackMessageVi})';
  }

  /// Sinh 1 câu hỏi ôn tập cá nhân hóa (`POST /v1/questions/personalized`, 0 XP).
  Future<PersonalizedPracticeQuestion?> generatePersonalizedQuestion({
    required String subjectCode,
    String? gradeLevel,
    String? topicHint,
    int difficulty = 1,
  }) async {
    final StudyAiGateway? gateway = _aiGateway;
    if (gateway == null) {
      _personalizedStatus = StudyAiRequestStatus.offline;
      _personalizedErrorVi = 'Chưa nối backend AI để tạo câu hỏi cá nhân hóa.';
      notifyListeners();
      return null;
    }
    if (!_isAuthenticated && !gateway.isDebugFixture) {
      _personalizedStatus = StudyAiRequestStatus.authExpired;
      _personalizedErrorVi = 'Đăng nhập ở tab Cá nhân để tạo câu hỏi cá nhân hóa.';
      notifyListeners();
      return null;
    }

    final String scopeAtStart = _ownerScopeKey;
    _personalizedStatus = StudyAiRequestStatus.loading;
    _personalizedErrorVi = null;
    notifyListeners();

    try {
      final PersonalizedPracticeQuestion q =
          await gateway.generatePersonalizedQuestion(
        subjectCode: subjectCode,
        gradeLevel: gradeLevel ?? _gradeLevel,
        topicHint: topicHint,
        difficulty: difficulty,
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
      );
      if (_ownerScopeKey != scopeAtStart) return null;
      _personalizedQuestion = q;
      _personalizedStatus = StudyAiRequestStatus.ready;
      _personalizedErrorVi = null;
      notifyListeners();
      return q;
    } on PersonalApiException catch (error) {
      if (_ownerScopeKey != scopeAtStart) return null;
      _personalizedStatus = _mapApiExceptionToStatus(error);
      _personalizedErrorVi = error.messageVi;
      notifyListeners();
      return null;
    } catch (_) {
      if (_ownerScopeKey != scopeAtStart) return null;
      _personalizedStatus = StudyAiRequestStatus.error;
      _personalizedErrorVi = 'Không thể tạo câu hỏi cá nhân hóa lúc này.';
      notifyListeners();
      return null;
    }
  }

  void setLiveConsentGranted(bool granted) {
    if (_liveConsentGranted == granted) return;
    _liveConsentGranted = granted;
    if (!granted) {
      _liveToken = null;
      _liveTokenStatus = StudyAiRequestStatus.idle;
      _liveTokenErrorVi = null;
    }
    notifyListeners();
  }

  /// Xin ephemeral token Gemini Live (`POST /v1/study/live-token`) khi đã đồng ý rõ ràng.
  Future<GeminiLiveSessionToken?> requestGeminiLiveToken({
    required String subjectCode,
    String? gradeLevel,
    String? taskTitle,
    String responseModality = 'AUDIO',
  }) async {
    if (!_liveConsentGranted) {
      _liveTokenStatus = StudyAiRequestStatus.error;
      _liveTokenErrorVi =
          'Bạn cần bật đồng ý dùng trợ lý giọng nói Gemini Live trước.';
      notifyListeners();
      return null;
    }
    final StudyAiGateway? gateway = _aiGateway;
    if (gateway == null) {
      _liveTokenStatus = StudyAiRequestStatus.offline;
      _liveTokenErrorVi = 'Chưa nối backend để cấp phiên Gemini Live.';
      notifyListeners();
      return null;
    }
    if (!_isAuthenticated && !gateway.isDebugFixture) {
      _liveTokenStatus = StudyAiRequestStatus.authExpired;
      _liveTokenErrorVi = 'Đăng nhập ở tab Cá nhân trước khi mở Gemini Live.';
      notifyListeners();
      return null;
    }

    final String scopeAtStart = _ownerScopeKey;
    _liveTokenStatus = StudyAiRequestStatus.loading;
    _liveTokenErrorVi = null;
    notifyListeners();

    try {
      final String? sessionId =
          _activeSnapshot?.remoteSessionId ?? _activeSnapshot?.sessionId;
      final String effectiveTask = (taskTitle != null && taskTitle.trim().isNotEmpty)
          ? taskTitle.trim()
          : (_activeSnapshot?.taskTitle ??
              (_draftTaskTitle.trim().isEmpty
                  ? 'Ôn tập cá nhân'
                  : _draftTaskTitle.trim()));
      final GeminiLiveSessionToken tok = await gateway.requestLiveToken(
        sessionId: sessionId,
        subjectCode: subjectCode,
        gradeLevel: gradeLevel ?? _gradeLevel,
        taskTitle: effectiveTask,
        responseModality: responseModality,
        consentGranted: _liveConsentGranted,
      );
      if (_ownerScopeKey != scopeAtStart) return null;
      _liveToken = tok;
      _liveTokenStatus = StudyAiRequestStatus.ready;
      _liveTokenErrorVi = null;
      notifyListeners();
      return tok;
    } on PersonalApiException catch (error) {
      if (_ownerScopeKey != scopeAtStart) return null;
      _liveTokenStatus = _mapApiExceptionToStatus(error);
      _liveTokenErrorVi = error.messageVi;
      notifyListeners();
      return null;
    } catch (_) {
      if (_ownerScopeKey != scopeAtStart) return null;
      _liveTokenStatus = StudyAiRequestStatus.error;
      _liveTokenErrorVi = 'Không xin được phiên Gemini Live lúc này.';
      notifyListeners();
      return null;
    }
  }

  Future<void> syncLearningProfile({
    String? alias,
    String? gradeLevel,
    List<String>? selectedSubjects,
  }) async {
    final StudyAiGateway? gateway = _aiGateway;
    if (gateway == null || !_isAuthenticated) return;
    try {
      await gateway.syncLearningProfile(
        alias: alias,
        gradeLevel: gradeLevel,
        selectedSubjects: selectedSubjects,
      );
    } catch (_) {
      // Đồng bộ hồ sơ là best-effort; lỗi mạng không chặn thao tác local.
    }
  }

  Future<void> pauseSession() async {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null || current.status != StudyFocusStatus.running) return;
    final int nowMs = _nowProvider().millisecondsSinceEpoch;
    _stopTicker();
    await _bridge.cancelStudyReminder();

    _activeSnapshot = current.copyWith(
      status: StudyFocusStatus.paused,
      pausedAtEpochMs: current.pausedAtEpochMs ?? nowMs,
      commitmentAwaitingResume: false,
      clearLeftAt: true,
      updatedAtEpochMs: nowMs,
    );
    await _repository.saveSnapshot(_activeSnapshot!);
    notifyListeners();
  }

  Future<void> resumeSession() async {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null) return;
    final bool canResume = current.status == StudyFocusStatus.paused ||
        current.status == StudyFocusStatus.interrupted ||
        (current.status == StudyFocusStatus.running &&
            current.commitmentAwaitingResume);
    if (!canResume) return;

    final int nowMs = _nowProvider().millisecondsSinceEpoch;
    final int pauseStartedMs = current.pausedAtEpochMs ?? nowMs;
    final int pauseDeltaMs = math.max(0, nowMs - pauseStartedMs);

    _activeSnapshot = current.copyWith(
      status: StudyFocusStatus.running,
      accumulatedPausedMs: current.accumulatedPausedMs + pauseDeltaMs,
      plannedEndAtEpochMs: current.plannedEndAtEpochMs + pauseDeltaMs,
      clearPausedAt: true,
      commitmentAwaitingResume: false,
      clearLastReturnNotice: true,
      updatedAtEpochMs: nowMs,
    );

    await _bridge.cancelStudyReminder();
    await _repository.saveSnapshot(_activeSnapshot!);
    _checkTargetReached(nowMs);
    _startTickerIfRunning();
    notifyListeners();
  }

  /// Được gọi khi `MindClockShellScreen` nhận `AppLifecycleState.paused`/`hidden`.
  Future<void> onAppBackgrounded() async {
    if (_isBackgrounded) return;
    _isBackgrounded = true;
    _stopTicker();

    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null ||
        current.status != StudyFocusStatus.running ||
        current.commitmentAwaitingResume) {
      return;
    }

    final int nowMs = _nowProvider().millisecondsSinceEpoch;
    _activeSnapshot = current.copyWith(
      leftAtEpochMs: current.leftAtEpochMs ?? nowMs,
      updatedAtEpochMs: nowMs,
    );
    await _repository.saveSnapshot(_activeSnapshot!);
  }

  /// Được gọi khi `MindClockShellScreen` nhận `AppLifecycleState.resumed`.
  Future<void> onAppResumed() async {
    _isBackgrounded = false;
    await _bridge.cancelStudyReminder();

    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null) return;

    if (current.status != StudyFocusStatus.running ||
        current.leftAtEpochMs == null) {
      _startTickerIfRunning();
      notifyListeners();
      return;
    }

    final DateTime now = _nowProvider();
    final int nowMs = now.millisecondsSinceEpoch;
    final int awayMs = math.max(0, nowMs - current.leftAtEpochMs!);
    final int awaySeconds = awayMs ~/ 1000;
    final int nextAccumulatedAwayMs = current.accumulatedAwayMs + awayMs;

    StudyFocusSessionSnapshot next = current.copyWith(
      clearLeftAt: true,
      accumulatedAwayMs: nextAccumulatedAwayMs,
      lastAwaySeconds: awaySeconds,
      updatedAtEpochMs: nowMs,
    );

    switch (current.level) {
      case StudyFocusLevel.flexible:
        next = next.copyWith(
          lastReturnNoticeVi: awaySeconds > 0
              ? 'Bạn vừa rời MindClock ${formatVietnameseAwayDuration(awaySeconds)}. Đồng hồ vẫn tiếp tục.'
              : null,
          clearLastReturnNotice: awaySeconds == 0,
        );
      case StudyFocusLevel.standard:
        if (awaySeconds > StudyFocusSnapshot.standardReminderThresholdSeconds) {
          final String msg =
              'Bạn vừa ra khỏi MindClock ${formatVietnameseAwayDuration(awaySeconds)}. Tiếp tục việc đang làm?';
          next = next.copyWith(lastReturnNoticeVi: msg);
          if (current.notifyOutsideApp &&
              _notificationPermission == StudyNotificationPermission.granted) {
            await _bridge.showSingleStudyReminder(
              sessionId: current.sessionId,
              titleVi: 'Quay lại việc đang học',
              bodyVi: msg,
            );
          }
        }
      case StudyFocusLevel.commitment:
        if (awaySeconds > StudyFocusSnapshot.commitmentThresholdSeconds) {
          next = next.copyWith(
            commitmentFrozenAwayMs: current.commitmentFrozenAwayMs + awayMs,
            plannedEndAtEpochMs: current.plannedEndAtEpochMs + awayMs,
            commitmentAwaitingResume: true,
            pausedAtEpochMs: nowMs,
            lastReturnNoticeVi:
                'Đã rời phiên ${formatVietnameseAwayDuration(awaySeconds)} · Bấm Tiếp tục học để tính tiếp thời gian tập trung trong app.',
          );
        }
    }

    _activeSnapshot = next;
    _checkTargetReached(nowMs);
    await _repository.saveSnapshot(_activeSnapshot!);
    _startTickerIfRunning();
    notifyListeners();
  }

  /// Được gọi khi hết giờ ở màn kết thúc nhưng người dùng chọn `Cần thêm thời gian`.
  Future<void> addExtraMinutes(int extraMinutes) async {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null || extraMinutes <= 0) return;
    final int nowMs = _nowProvider().millisecondsSinceEpoch;
    final int updatedMinutes = math.min(
      StudyFocusSessionSnapshot.maxDurationMinutes,
      current.durationMinutes + extraMinutes,
    );

    // Nếu trước đó đã ở trạng thái `completed`, chuyển về `running` để tiếp tục.
    final int closedDoneDeltaMs =
        current.status == StudyFocusStatus.completed &&
                current.endedAtEpochMs != null
            ? math.max(0, nowMs - current.endedAtEpochMs!)
            : 0;

    _hasPlayedEndCueForSession = false;
    _activeSnapshot = current.copyWith(
      durationMinutes: updatedMinutes,
      status: StudyFocusStatus.running,
      accumulatedPausedMs: current.accumulatedPausedMs + closedDoneDeltaMs,
      plannedEndAtEpochMs:
          current.plannedEndAtEpochMs + extraMinutes * 60 * 1000 + closedDoneDeltaMs,
      clearEndedAt: true,
      clearPausedAt: true,
      commitmentAwaitingResume: false,
      updatedAtEpochMs: nowMs,
      lastReturnNoticeVi: 'Đã thêm $extraMinutes phút cho phiên học hiện tại.',
    );
    await _repository.saveSnapshot(_activeSnapshot!);
    _startTickerIfRunning();
    notifyListeners();
  }

  Future<void> finishSession({required bool early}) async {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null) return;
    if (current.status.isTerminal) return;

    final int nowMs = _nowProvider().millisecondsSinceEpoch;
    _stopTicker();
    await _bridge.cancelStudyReminder();

    int extraPausedMs = current.accumulatedPausedMs;
    if (current.pausedAtEpochMs != null &&
        (current.status == StudyFocusStatus.paused ||
            current.status == StudyFocusStatus.interrupted ||
            current.commitmentAwaitingResume)) {
      extraPausedMs += math.max(0, nowMs - current.pausedAtEpochMs!);
    }

    int extraAwayMs = current.accumulatedAwayMs;
    int extraCommitmentAwayMs = current.commitmentFrozenAwayMs;
    if (current.leftAtEpochMs != null) {
      final int tailAway = math.max(0, nowMs - current.leftAtEpochMs!);
      extraAwayMs += tailAway;
      if (current.level == StudyFocusLevel.commitment &&
          tailAway > StudyFocusSnapshot.commitmentThresholdSeconds * 1000) {
        extraCommitmentAwayMs += tailAway;
      }
    }

    _activeSnapshot = current.copyWith(
      status: early ? StudyFocusStatus.endedEarly : StudyFocusStatus.completed,
      endedAtEpochMs: nowMs,
      accumulatedPausedMs: extraPausedMs,
      accumulatedAwayMs: extraAwayMs,
      commitmentFrozenAwayMs: extraCommitmentAwayMs,
      clearPausedAt: true,
      clearLeftAt: true,
      commitmentAwaitingResume: false,
      updatedAtEpochMs: nowMs,
    );

    if (!early && current.endSoundEnabled && !_hasPlayedEndCueForSession) {
      _hasPlayedEndCueForSession = true;
      await _bridge.playSessionEndCue();
    }

    await _repository.saveSnapshot(_activeSnapshot!);
    notifyListeners();
  }

  void updateReflectionNotes({String? done, String? stuck}) {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null) return;
    _activeSnapshot = current.copyWith(
      notesDone: done ?? current.notesDone,
      notesStuck: stuck ?? current.notesStuck,
      updatedAtEpochMs: _nowProvider().millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  /// Lưu bản ghi phiên đã kết thúc với tính chất idempotent theo `sessionId` (`F07`).
  ///
  /// Luôn hoàn tất lưu cục bộ và xóa phiên đang mở TRƯỚC khi gọi `/v1/study/sessions/{id}/finish`
  /// để API lỗi/timeout tuyệt đối không giữ kẹt người dùng ở màn học.
  Future<StudyFocusRecord?> saveFinishedSession({
    String? notesDone,
    String? notesStuck,
  }) async {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null || !current.status.isTerminal) return null;

    final DateTime endAt = DateTime.fromMillisecondsSinceEpoch(
      current.endedAtEpochMs ?? _nowProvider().millisecondsSinceEpoch,
    );
    final String finishKey = current.finishIdempotencyKey.isNotEmpty
        ? current.finishIdempotencyKey
        : LocalIdGenerator.nextUuidV4();
    final StudyFocusRecord record = StudyFocusRecord(
      sessionId: current.sessionId,
      ownerScopeKey: current.ownerScopeKey,
      taskTitle: current.taskTitle,
      subjectCode: current.subjectCode,
      targetMinutes: current.durationMinutes,
      level: current.level,
      finalStatus: current.status,
      elapsedWallSeconds: current.elapsedWallSecondsAt(endAt),
      inAppFocusSeconds: current.inAppFocusSecondsAt(endAt),
      startedAtEpochMs: current.startedAtEpochMs,
      endedAtEpochMs: endAt.millisecondsSinceEpoch,
      notesDone: (notesDone ?? current.notesDone).trim(),
      notesStuck: (notesStuck ?? current.notesStuck).trim(),
      remoteSessionId: current.remoteSessionId,
      finishIdempotencyKey: finishKey,
      remoteFinishSynced: false,
    );

    _history = await _repository.saveRecordIdempotent(record);
    await _repository.clearSnapshot(current.ownerScopeKey);
    _activeSnapshot = null;
    _clearAiConversationState();
    _statusBannerVi = _isAuthenticated && _aiGateway != null
        ? 'Đã lưu phiên học cục bộ (0 XP từ đồng hồ) và đang đồng bộ server...'
        : 'Đã lưu phiên học cục bộ trên máy (0 XP từ đồng hồ).';
    notifyListeners();

    if (_isAuthenticated && _aiGateway != null) {
      _pendingRemoteFinish = _syncFinishRecord(
        record,
        createSnapshot: current,
      );
    }
    return record;
  }

  Future<bool> retryFinishRecordSync(String sessionId) async {
    final int idx = _history.indexWhere((StudyFocusRecord r) => r.sessionId == sessionId);
    if (idx < 0) return false;
    final Future<bool> work = _syncFinishRecord(_history[idx]);
    _pendingRemoteFinish = work;
    return work;
  }

  Future<bool> _syncFinishRecord(
    StudyFocusRecord record, {
    StudyFocusSessionSnapshot? createSnapshot,
  }) async {
    final StudyAiGateway? gateway = _aiGateway;
    if (!_isAuthenticated || gateway == null) return false;

    final String scopeAtStart = _ownerScopeKey;
    StudyFocusRecord working = record;
    if (working.finishIdempotencyKey.isEmpty) {
      working = working.copyWith(finishIdempotencyKey: LocalIdGenerator.nextUuidV4());
      _history = await _repository.saveRecordIdempotent(working);
    }

    try {
      // Nếu lúc bắt đầu phiên bị offline nên chưa có remoteSessionId, tạo lại idempotent trước khi finish.
      if (working.remoteSessionId == null || working.remoteSessionId!.isEmpty) {
        final StudyFocusSessionSnapshot fallbackSnapshot = createSnapshot ??
            StudyFocusSessionSnapshot(
              sessionId: working.sessionId,
              ownerScopeKey: working.ownerScopeKey,
              taskTitle: working.taskTitle,
              subjectCode: working.subjectCode,
              durationMinutes: working.targetMinutes,
              level: working.level,
              status: working.finalStatus,
              endSoundEnabled: false,
              notifyOutsideApp: false,
              startedAtEpochMs: working.startedAtEpochMs,
              plannedEndAtEpochMs: working.endedAtEpochMs,
              updatedAtEpochMs: working.endedAtEpochMs,
            );
        final String createKey =
            (createSnapshot != null && createSnapshot.createIdempotencyKey.isNotEmpty)
                ? createSnapshot.createIdempotencyKey
                : LocalIdGenerator.nextUuidV4();
        final RemoteStudySessionResult created = await gateway.createStudySession(
          snapshot: fallbackSnapshot,
          idempotencyKey: createKey,
        );
        working = working.copyWith(remoteSessionId: created.remoteSessionId);
        _history = await _repository.saveRecordIdempotent(working);
      }

      final RemoteStudySessionResult finished = await gateway.finishStudySession(
        record: working,
        idempotencyKey: working.finishIdempotencyKey,
      );
      if (_ownerScopeKey != scopeAtStart) return false;
      final StudyFocusRecord synced = working.copyWith(
        remoteSessionId: finished.remoteSessionId,
        remoteFinishSynced: true,
        clearRemoteSyncError: true,
      );
      _history = await _repository.saveRecordIdempotent(synced);
      _statusBannerVi = gateway.isDebugFixture
          ? 'Đã đồng bộ phiên học kết thúc (mẫu debug, 0 XP).'
          : 'Đã đồng bộ phiên học kết thúc lên server (0 XP).';
      notifyListeners();
      return true;
    } on PersonalApiException catch (error) {
      if (_ownerScopeKey != scopeAtStart) return false;
      final StudyFocusRecord failed = working.copyWith(
        remoteFinishSynced: false,
        remoteSyncErrorVi: error.messageVi,
      );
      _history = await _repository.saveRecordIdempotent(failed);
      _statusBannerVi =
          'Phiên đã lưu trên máy; đồng bộ server lỗi (${error.messageVi}).';
      notifyListeners();
      return false;
    } catch (_) {
      if (_ownerScopeKey != scopeAtStart) return false;
      final StudyFocusRecord failed = working.copyWith(
        remoteFinishSynced: false,
        remoteSyncErrorVi: 'Không thể đồng bộ kết thúc phiên lên server lúc này.',
      );
      _history = await _repository.saveRecordIdempotent(failed);
      _statusBannerVi =
          'Phiên đã lưu trên máy; chưa đồng bộ được server. Bạn vẫn thoát màn học bình thường.';
      notifyListeners();
      return false;
    }
  }

  Future<void> discardActiveSession() async {
    _stopTicker();
    await _bridge.cancelStudyReminder();
    await _repository.clearSnapshot(_ownerScopeKey);
    _activeSnapshot = null;
    _statusBannerVi = null;
    _clearAiConversationState();
    notifyListeners();
  }

  Future<void> openDigitalWellbeingFocusSettings() async {
    final DigitalWellbeingOpenResult result =
        await _bridge.openDigitalWellbeingFocusSettings();
    _wellbeingFeedbackVi = result.messageVi;
    notifyListeners();
  }

  void clearStatusBanner() {
    _statusBannerVi = null;
    notifyListeners();
  }

  /// Kiểm tra mốc hết giờ mỗi tick hoặc khi resume để chuyển sang `completed`.
  void checkClockTick() {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null || current.status != StudyFocusStatus.running) return;
    final int nowMs = _nowProvider().millisecondsSinceEpoch;
    final bool finished = _checkTargetReached(nowMs);
    if (finished) {
      unawaited(_repository.saveSnapshot(_activeSnapshot!));
      if (current.endSoundEnabled && !_hasPlayedEndCueForSession) {
        _hasPlayedEndCueForSession = true;
        unawaited(_bridge.playSessionEndCue());
      }
      _stopTicker();
    }
    notifyListeners();
  }

  bool _checkTargetReached(int nowMs) {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null || current.status != StudyFocusStatus.running) {
      return false;
    }
    if (current.commitmentAwaitingResume) return false;
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(nowMs);
    if (!current.isTargetReachedAt(now)) return false;

    _stopTicker();
    _activeSnapshot = current.copyWith(
      status: StudyFocusStatus.completed,
      endedAtEpochMs: nowMs,
      updatedAtEpochMs: nowMs,
      clearLeftAt: true,
    );
    return true;
  }

  void _startTickerIfRunning() {
    _stopTicker();
    if (!_enablePeriodicTicker) return;
    final StudyFocusSessionSnapshot? s = _activeSnapshot;
    if (s == null ||
        s.status != StudyFocusStatus.running ||
        s.commitmentAwaitingResume) {
      return;
    }
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => checkClockTick(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
