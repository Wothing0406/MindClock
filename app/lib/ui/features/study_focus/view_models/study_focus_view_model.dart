import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/local_study_focus_repository.dart';
import '../../../../data/services/local_id_generator.dart';
import '../../../../domain/models/study_focus_models.dart';
import '../../../../domain/services/study_focus_bridge.dart';

/// ViewModel điều phối Không gian học local (`docs/45 §§1–6`, nhiệm vụ 6A).
///
/// - Mọi số giây còn lại và tập trung được tính từ mốc thời gian thiết bị (`DateTime`),
///   tuyệt đối không cộng thời gian ảo khi kill app hay suy ra xao nhãng khi rời app.
/// - Tách biệt theo `ownerScopeKey` (`guest` hoặc `user:<uid>`) để không lộ phiên
///   khi đăng xuất/đổi tài khoản, đồng thời không chạm vào báo thức local.
class StudyFocusViewModel extends ChangeNotifier {
  StudyFocusViewModel({
    required LocalStudyFocusRepository repository,
    required StudyFocusBridge bridge,
    DateTime Function()? nowProvider,
    bool enablePeriodicTicker = true,
  })  : _repository = repository,
        _bridge = bridge,
        _nowProvider = nowProvider ?? DateTime.now,
        _enablePeriodicTicker = enablePeriodicTicker;

  final LocalStudyFocusRepository _repository;
  final StudyFocusBridge _bridge;
  final DateTime Function() _nowProvider;
  final bool _enablePeriodicTicker;

  String _ownerScopeKey = 'guest';
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

  String get ownerScopeKey => _ownerScopeKey;
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

  Future<void> setOwnerScope(String nextOwnerScopeKey) async {
    final String normalized = _normalizeScope(nextOwnerScopeKey);
    if (normalized == _ownerScopeKey && _isLoaded) return;
    _stopTicker();
    _isBackgrounded = false;
    _hasPlayedEndCueForSession = false;
    _statusBannerVi = null;
    _wellbeingFeedbackVi = null;
    await _bridge.cancelStudyReminder();
    _ownerScopeKey = normalized;
    await _reloadScopeState();
    _isLoaded = true;
    notifyListeners();
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

    _activeSnapshot = StudyFocusSessionSnapshot(
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
    );

    await _repository.saveSnapshot(_activeSnapshot!);
    _startTickerIfRunning();
    notifyListeners();
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
  Future<StudyFocusRecord?> saveFinishedSession({
    String? notesDone,
    String? notesStuck,
  }) async {
    final StudyFocusSessionSnapshot? current = _activeSnapshot;
    if (current == null || !current.status.isTerminal) return null;

    final DateTime endAt = DateTime.fromMillisecondsSinceEpoch(
      current.endedAtEpochMs ?? _nowProvider().millisecondsSinceEpoch,
    );
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
    );

    _history = await _repository.saveRecordIdempotent(record);
    await _repository.clearSnapshot(current.ownerScopeKey);
    _activeSnapshot = null;
    _statusBannerVi = 'Đã lưu phiên học cục bộ trên máy (0 XP từ đồng hồ).';
    notifyListeners();
    return record;
  }

  Future<void> discardActiveSession() async {
    _stopTicker();
    await _bridge.cancelStudyReminder();
    await _repository.clearSnapshot(_ownerScopeKey);
    _activeSnapshot = null;
    _statusBannerVi = null;
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
