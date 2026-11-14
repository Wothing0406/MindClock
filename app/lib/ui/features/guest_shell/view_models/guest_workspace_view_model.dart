import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/guest_workspace_repository.dart';
import '../../../../data/services/local_id_generator.dart';
import '../../../../data/services/pending_alarm_event_store.dart';
import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/guest_workspace.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/models/wake_suggestion.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../../domain/services/alarm_sync_gateway.dart';
import '../../../core/strings/app_strings.dart';

class GuestWorkspaceViewModel extends ChangeNotifier {
  GuestWorkspaceViewModel({
    required GuestWorkspaceRepository repository,
    required AlarmSchedulerService alarmScheduler,
    AlarmSyncGateway? alarmSyncGateway,
    PendingAlarmEventStore? pendingAlarmEventStore,
    DateTime Function()? nowProvider,
  })  : _repository = repository,
        _alarmScheduler = alarmScheduler,
        _alarmSyncGateway = alarmSyncGateway,
        _pendingAlarmEventStore = pendingAlarmEventStore,
        _nowProvider = nowProvider ?? DateTime.now;

  final GuestWorkspaceRepository _repository;
  final AlarmSchedulerService _alarmScheduler;
  final AlarmSyncGateway? _alarmSyncGateway;
  final PendingAlarmEventStore? _pendingAlarmEventStore;
  final DateTime Function() _nowProvider;

  GuestWorkspace _workspace = GuestWorkspace.initial();
  AlarmServiceCapabilities? _capabilities;
  AlarmPermissionSnapshot _permissionSnapshot =
      const AlarmPermissionSnapshot.unbound();
  AlarmRingPayload? _activeRingPayload;
  String _lastSchedulerMessage = AppStrings.alarmOsUnboundExplain;
  bool _isLoaded = false;
  bool _scheduleChangedSinceAlarmSave = false;

  String _ownerScopeKey = 'guest';
  bool _isAuthenticated = false;
  int _pendingEventCount = 0;
  String? _serverSyncMessageVi;
  Future<void>? _pendingServerSync;

  GuestWorkspace get workspace => _workspace;
  StudyProfile get profile => _workspace.profile;
  WeeklyTimetable get timetable => _workspace.timetable;
  List<AlarmConfig> get alarms => _workspace.alarms;
  AlarmConfig? get primaryAlarm => _workspace.primaryAlarm;
  WakeSuggestionInput get wakePreferences => _workspace.wakePreferences;
  AlarmServiceCapabilities? get capabilities => _capabilities;
  AlarmPermissionSnapshot get permissionSnapshot => _permissionSnapshot;
  AlarmRingPayload? get activeRingPayload => _activeRingPayload;
  String get lastSchedulerMessage => _lastSchedulerMessage;
  bool get isLoaded => _isLoaded;
  bool get isOsBridgeConnected => _alarmScheduler.isOsBridgeConnected;
  bool get scheduleChangedSinceAlarmSave => _scheduleChangedSinceAlarmSave;
  String get ownerScopeKey => _ownerScopeKey;
  bool get isAuthenticated => _isAuthenticated;
  int get pendingEventCount => _pendingEventCount;
  String? get serverSyncMessageVi => _serverSyncMessageVi;
  bool get isAlarmSyncDebugFixture => _alarmSyncGateway?.isDebugFixture ?? false;

  List<AlarmPermissionAction> get missingPermissionActions =>
      _permissionSnapshot.missingActions();

  bool get needsOsPermissions =>
      isOsBridgeConnected && !_permissionSnapshot.allGranted;

  Future<void> initialize() async {
    _workspace = await _repository.load();
    await refreshOsStatus();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> waitForPendingServerSync() async {
    await _pendingServerSync;
  }

  /// Cập nhật ngữ cảnh tài khoản cho đồng bộ server mà KHÔNG xóa báo thức local trên máy.
  Future<void> setAccountContext({
    required String ownerScopeKey,
    required bool isAuthenticated,
  }) async {
    final String normalizedScope =
        ownerScopeKey.trim().isEmpty ? 'guest' : ownerScopeKey.trim();
    final bool scopeChanged = normalizedScope != _ownerScopeKey;
    final bool authChanged = isAuthenticated != _isAuthenticated;
    if (!scopeChanged && !authChanged) return;

    _ownerScopeKey = normalizedScope;
    _isAuthenticated = isAuthenticated;
    _serverSyncMessageVi = null;

    if (scopeChanged && _workspace.alarms.isNotEmpty) {
      bool updatedAny = false;
      final List<AlarmConfig> resetSync = _workspace.alarms.map((AlarmConfig a) {
        if (a.serverSyncedOwnerScope != null &&
            a.serverSyncedOwnerScope != normalizedScope) {
          updatedAny = true;
          return a.copyWith(
            serverSyncStatus: AlarmServerSyncStatus.localOnly,
            clearServerAlarmId: true,
            clearServerRevision: true,
            clearServerSyncedOwnerScope: true,
            clearLastServerSyncError: true,
          );
        }
        return a;
      }).toList(growable: false);
      if (updatedAny) {
        _workspace = _workspace.copyWith(alarms: resetSync);
        _workspace = await _repository.save(_workspace);
      }
    }

    await _refreshPendingEventCount();
    notifyListeners();

    if (_isAuthenticated && _alarmSyncGateway != null && _isLoaded) {
      _trackSync(syncAllAlarmsAndEvents());
    }
  }

  Future<void> _refreshPendingEventCount() async {
    final PendingAlarmEventStore? store = _pendingAlarmEventStore;
    if (store == null) {
      _pendingEventCount = 0;
      return;
    }
    final List<PendingAlarmServerEvent> pending =
        await store.loadEvents(_ownerScopeKey);
    _pendingEventCount = pending.length;
  }

  void _trackSync(Future<void> work) {
    _pendingServerSync = work;
  }

  String serverStatusLabelForAlarm(AlarmConfig alarm) {
    switch (alarm.serverSyncStatus) {
      case AlarmServerSyncStatus.synced:
        return isAlarmSyncDebugFixture
            ? 'Đồng bộ mẫu (debug)'
            : 'Đã đồng bộ server';
      case AlarmServerSyncStatus.syncing:
        return 'Đang đồng bộ server';
      case AlarmServerSyncStatus.syncFailed:
        return 'Chưa đồng bộ server (lỗi/offline)';
      case AlarmServerSyncStatus.localOnly:
        return 'Chưa đồng bộ server';
    }
  }

  /// Đồng bộ lại năng lực bridge, quyền OS và trạng thái chuông vừa mở từ màn khóa.
  Future<void> refreshOsStatus() async {
    _capabilities = await _alarmScheduler.checkCapabilities();
    _permissionSnapshot = await _alarmScheduler.getPermissionStatus();
    final AlarmRingPayload? pendingRing =
        await _alarmScheduler.consumePendingRingLaunch();
    if (pendingRing != null) {
      _activeRingPayload = pendingRing;
    }

    if (isOsBridgeConnected && !_permissionSnapshot.allGranted) {
      _lastSchedulerMessage = AppStrings.alarmPermissionMissingExplain;
      await _downgradeStaleReadyAlarmsIfMissingPermissions();
    } else if (_capabilities != null) {
      _lastSchedulerMessage = _capabilities!.statusSummaryVi;
    }
    notifyListeners();
  }

  Future<void> _downgradeStaleReadyAlarmsIfMissingPermissions() async {
    bool changed = false;
    final List<AlarmConfig> updated = _workspace.alarms.map((AlarmConfig a) {
      if (a.enabled && a.syncStatus == AlarmSyncStatus.scheduledReady) {
        changed = true;
        return a.copyWith(syncStatus: AlarmSyncStatus.osPermissionMissing);
      }
      return a;
    }).toList(growable: false);

    if (changed) {
      _workspace = _workspace.copyWith(alarms: updated);
      _workspace = await _repository.save(_workspace);
    }
  }

  /// Trạng thái hiển thị chuẩn cho mỗi báo thức.
  ///
  /// CHỈ báo `Đã sẵn sàng` khi bridge nối thành công, tất cả quyền OS đã cấp,
  /// và Android OS xác nhận đặt lịch thành công (`scheduledReady`).
  String statusLabelForAlarm(AlarmConfig alarm) {
    if (!isOsBridgeConnected) {
      return AppStrings.alarmSavedConfigOnly;
    }
    if (!alarm.enabled) {
      return AppStrings.alarmSavedConfigOnly;
    }
    switch (alarm.syncStatus) {
      case AlarmSyncStatus.scheduledReady:
        if (!_permissionSnapshot.allGranted) {
          return AppStrings.alarmPermissionMissingLabel;
        }
        return AppStrings.alarmReadyOs;
      case AlarmSyncStatus.pendingOsSync:
        return 'Đang đồng bộ hệ thống';
      case AlarmSyncStatus.osPermissionMissing:
        return AppStrings.alarmPermissionMissingLabel;
      case AlarmSyncStatus.osFailed:
        return 'Chưa đặt được trên OS';
      case AlarmSyncStatus.savedConfigOnly:
        return AppStrings.alarmSavedConfigOnly;
    }
  }

  String explainAlarmModeAndSubject(AlarmConfig alarm) {
    final StringBuffer buffer = StringBuffer();
    if (alarm.mode == AlarmMode.challenge) {
      buffer.write(AppStrings.challengeModeNotice);
    } else {
      buffer.write('${AppStrings.normalModeTitle}: ${AppStrings.normalModeDesc}');
    }
    final String? subjectCode = alarm.subjectCode;
    if (subjectCode != null && !SubjectCatalog.isApproved(subjectCode)) {
      buffer.write(
        ' ${SubjectCatalog.nameFor(subjectCode)}: chưa có câu ôn được duyệt; '
        'báo thức vẫn được lưu và hoạt động bình thường.',
      );
    }
    return buffer.toString();
  }

  String labelForPermissionAction(AlarmPermissionAction action) {
    switch (action) {
      case AlarmPermissionAction.exactAlarmSettings:
        return 'Cấp quyền Báo thức chính xác';
      case AlarmPermissionAction.notificationSettings:
        return 'Bật quyền Thông báo';
      case AlarmPermissionAction.fullScreenIntentSettings:
        return 'Cho phép hiện trên màn khóa';
      case AlarmPermissionAction.batteryOptimizationSettings:
        return 'Kiểm tra Tiết kiệm pin';
    }
  }

  Future<bool> openPermissionSettings(AlarmPermissionAction action) {
    return _alarmScheduler.openPermissionSettings(action);
  }

  /// Dừng âm và rung NGAY TRÊN MÁY; ghi nhận sự kiện server thực hiện sau và
  /// tuyệt đối không đặt lịch lại hay phát lại chuông.
  Future<AlarmScheduleResult> triggerEmergencyStop({
    String? alarmId,
    String? activeSessionId,
  }) async {
    final String targetAlarmId =
        alarmId ?? _activeRingPayload?.alarmId ?? 'primary_morning';
    final AlarmScheduleResult result =
        await _alarmScheduler.triggerEmergencyStop(targetAlarmId);
    _activeRingPayload = null;
    _permissionSnapshot = result.permissionSnapshot;
    _lastSchedulerMessage = result.messageVi;
    notifyListeners();

    if (activeSessionId != null && activeSessionId.isNotEmpty) {
      final DateTime now = _nowProvider();
      final PendingAlarmServerEvent event = PendingAlarmServerEvent(
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
        ownerScopeKey: _ownerScopeKey,
        sessionId: activeSessionId,
        alarmId: targetAlarmId,
        eventType: 'dismiss',
        version: 1,
        occurredAtUtcIso: now.toUtc().toIso8601String(),
        createdAtEpochMs: now.millisecondsSinceEpoch,
      );
      _trackSync(_dispatchOrQueueEmergencyEvent(event));
    }
    return result;
  }

  Future<void> _dispatchOrQueueEmergencyEvent(
    PendingAlarmServerEvent event,
  ) async {
    final AlarmSyncGateway? gateway = _alarmSyncGateway;
    final PendingAlarmEventStore? eventStore = _pendingAlarmEventStore;
    if (eventStore != null) {
      await eventStore.enqueue(event);
      await _refreshPendingEventCount();
      notifyListeners();
    }

    if (!_isAuthenticated || gateway == null) return;

    try {
      await gateway.sendSessionLifecycleEvent(event);
      if (eventStore != null) {
        await eventStore.removeByIdempotencyKey(
          ownerScopeKey: event.ownerScopeKey,
          idempotencyKey: event.idempotencyKey,
        );
        await _refreshPendingEventCount();
      }
      _serverSyncMessageVi = 'Đã ghi nhận Dừng khẩn cấp lên server (không phát lại chuông).';
      notifyListeners();
    } catch (_) {
      // Lỗi mạng/token/server không ảnh hưởng đến việc chuông đã tắt an toàn trên máy.
      _serverSyncMessageVi =
          'Chuông đã tắt trên máy; sự kiện sẽ đồng bộ lại sau khi đăng nhập và có mạng.';
      notifyListeners();
    }
  }

  Future<AlarmScheduleResult> snoozeActiveAlarm({int minutes = 5}) async {
    final AlarmRingPayload? ring = _activeRingPayload;
    final AlarmConfig target = _findAlarmForRing(ring);
    final AlarmScheduleResult result =
        await _alarmScheduler.snoozeAlarm(target, minutes: minutes);
    _permissionSnapshot = result.permissionSnapshot;
    _lastSchedulerMessage = result.messageVi;
    if (result.errorCode == AlarmBridgeErrorCode.ok) {
      _activeRingPayload = null;
    }
    notifyListeners();
    return result;
  }

  void dismissActiveRingUi() {
    _activeRingPayload = null;
    notifyListeners();
  }

  AlarmConfig _findAlarmForRing(AlarmRingPayload? ring) {
    if (ring != null) {
      for (final AlarmConfig alarm in _workspace.alarms) {
        if (alarm.id == ring.alarmId) {
          return alarm;
        }
      }
      final List<String> parts = ring.formattedTime.split(':');
      final int hour = parts.length == 2 ? (int.tryParse(parts[0]) ?? 6) : 6;
      final int minute = parts.length == 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return AlarmConfig(
        id: ring.alarmId,
        hour: hour,
        minute: minute,
        mode: ring.mode,
        subjectCode: ring.subjectCode,
        label: ring.label,
      );
    }
    return _workspace.primaryAlarm ??
        const AlarmConfig(id: 'primary_morning', hour: 6, minute: 0);
  }

  Future<void> completeOnboardingAsLater({required bool alarmOnly}) async {
    _workspace = _workspace.copyWith(
      onboardingCompleted: true,
      profile: _workspace.profile.copyWith(alarmOnlyMode: alarmOnly),
    );
    _workspace = await _repository.save(_workspace);
    notifyListeners();
  }

  Future<void> saveStudyProfile(StudyProfile nextProfile) async {
    final Set<String> selectedSet = nextProfile.selectedSubjectCodes.toSet();
    final List<PrioritySubject> cleanPriorities = nextProfile.prioritySubjects
        .where((PrioritySubject p) => selectedSet.contains(p.subjectCode))
        .take(StudyProfile.maxPrioritySubjects)
        .toList(growable: false);

    final StudyProfile normalized = nextProfile.copyWith(
      prioritySubjects: cleanPriorities,
      goalLabel: nextProfile.goalLabel.trim(),
    );

    _workspace = _workspace.copyWith(
      onboardingCompleted: true,
      profile: normalized,
    );
    _workspace = await _repository.save(_workspace);
    notifyListeners();
  }

  Future<void> toggleRestDay(int weekday, bool isRestDay) async {
    final DaySchedule current = _workspace.timetable.dayFor(weekday);
    final WeeklyTimetable nextTimetable = _workspace.timetable.updateDay(
      current.copyWith(isRestDay: isRestDay),
    );
    await _commitTimetable(nextTimetable);
  }

  Future<void> addTimetableEntry({
    required int weekday,
    required String subjectCode,
    required int startMinutes,
    String note = '',
  }) async {
    final DaySchedule day = _workspace.timetable.dayFor(weekday);
    final String id =
        'w${weekday}_${DateTime.now().microsecondsSinceEpoch}_${day.entries.length}';
    final TimetableEntry entry = TimetableEntry(
      id: id,
      subjectCode: subjectCode,
      startMinutes: startMinutes,
      note: note.trim(),
    );
    final List<TimetableEntry> nextEntries = <TimetableEntry>[
      ...day.entries,
      entry,
    ];
    final WeeklyTimetable nextTimetable = _workspace.timetable.updateDay(
      day.copyWith(isRestDay: false, entries: nextEntries),
    );
    await _commitTimetable(nextTimetable);
  }

  Future<void> updateTimetableEntry({
    required int weekday,
    required TimetableEntry updated,
  }) async {
    final DaySchedule day = _workspace.timetable.dayFor(weekday);
    final List<TimetableEntry> nextEntries = day.entries
        .map((TimetableEntry e) => e.id == updated.id ? updated : e)
        .toList(growable: false);
    final WeeklyTimetable nextTimetable = _workspace.timetable.updateDay(
      day.copyWith(entries: nextEntries),
    );
    await _commitTimetable(nextTimetable);
  }

  Future<void> deleteTimetableEntry({
    required int weekday,
    required String entryId,
  }) async {
    final DaySchedule day = _workspace.timetable.dayFor(weekday);
    final List<TimetableEntry> nextEntries = day.entries
        .where((TimetableEntry e) => e.id != entryId)
        .toList(growable: false);
    final WeeklyTimetable nextTimetable = _workspace.timetable.updateDay(
      day.copyWith(entries: nextEntries),
    );
    await _commitTimetable(nextTimetable);
  }

  /// Lưu thời khóa biểu mới nhưng TUYỆT ĐỐI không tự thay đổi giờ báo thức đã chọn.
  Future<void> _commitTimetable(WeeklyTimetable nextTimetable) async {
    _workspace = _workspace.copyWith(timetable: nextTimetable);
    if (_workspace.alarms.isNotEmpty) {
      _scheduleChangedSinceAlarmSave = true;
    }
    _workspace = await _repository.save(_workspace);
    notifyListeners();
  }

  WakeSuggestionResult previewWakeSuggestion(WakeSuggestionInput input) {
    return WakeSuggestionCalculator.calculate(input);
  }

  Future<void> updateWakePreferences(WakeSuggestionInput input) async {
    _workspace = _workspace.copyWith(wakePreferences: input);
    _workspace = await _repository.save(_workspace);
    notifyListeners();
  }

  Future<AlarmScheduleResult> saveAlarm(
    AlarmConfig draft, {
    WakeSuggestionInput? usedWakePreferences,
  }) async {
    // 1. Lưu và lập lịch local TRƯỚC, tuyệt đối không chờ backend.
    final AlarmScheduleResult result =
        await _alarmScheduler.scheduleAlarm(draft);
    _permissionSnapshot = result.permissionSnapshot;
    _lastSchedulerMessage = result.messageVi;

    final bool shouldSyncServer =
        _isAuthenticated && _alarmSyncGateway != null;
    final AlarmConfig persistedAlarm = draft.copyWith(
      syncStatus: result.status,
      serverSyncStatus: shouldSyncServer
          ? AlarmServerSyncStatus.syncing
          : AlarmServerSyncStatus.localOnly,
      clearLastServerSyncError: true,
    );

    final int existingIndex =
        _workspace.alarms.indexWhere((AlarmConfig a) => a.id == draft.id);
    final List<AlarmConfig> nextAlarms = List<AlarmConfig>.from(_workspace.alarms);
    if (existingIndex >= 0) {
      nextAlarms[existingIndex] = persistedAlarm;
    } else {
      nextAlarms.add(persistedAlarm);
    }

    _workspace = _workspace.copyWith(
      onboardingCompleted: true,
      alarms: nextAlarms,
      wakePreferences: usedWakePreferences ?? _workspace.wakePreferences,
    );
    _scheduleChangedSinceAlarmSave = false;
    _workspace = await _repository.save(_workspace);
    notifyListeners();

    if (shouldSyncServer) {
      _trackSync(_syncSingleAlarmToServer(persistedAlarm.id));
    }
    return result;
  }

  Future<void> toggleAlarmEnabled(String alarmId, bool enabled) async {
    final int idx =
        _workspace.alarms.indexWhere((AlarmConfig a) => a.id == alarmId);
    if (idx < 0) return;

    final AlarmConfig updated = _workspace.alarms[idx].copyWith(enabled: enabled);
    final AlarmScheduleResult result = enabled
        ? await _alarmScheduler.scheduleAlarm(updated)
        : await _alarmScheduler.cancelAlarm(alarmId);

    _permissionSnapshot = result.permissionSnapshot;
    _lastSchedulerMessage = result.messageVi;

    final bool shouldSyncServer =
        _isAuthenticated && _alarmSyncGateway != null;
    final List<AlarmConfig> nextAlarms = List<AlarmConfig>.from(_workspace.alarms);
    nextAlarms[idx] = updated.copyWith(
      syncStatus: result.status,
      serverSyncStatus: shouldSyncServer
          ? AlarmServerSyncStatus.syncing
          : AlarmServerSyncStatus.localOnly,
      clearLastServerSyncError: true,
    );
    _workspace = _workspace.copyWith(alarms: nextAlarms);
    _workspace = await _repository.save(_workspace);
    notifyListeners();

    if (shouldSyncServer) {
      _trackSync(_syncSingleAlarmToServer(alarmId));
    }
  }

  Future<void> deleteAlarm(String alarmId) async {
    final int idx =
        _workspace.alarms.indexWhere((AlarmConfig a) => a.id == alarmId);
    final String? serverIdToDelete =
        idx >= 0 ? _workspace.alarms[idx].serverAlarmId : null;
    final String? syncedScope =
        idx >= 0 ? _workspace.alarms[idx].serverSyncedOwnerScope : null;

    await _alarmScheduler.cancelAlarm(alarmId);
    final List<AlarmConfig> nextAlarms = _workspace.alarms
        .where((AlarmConfig a) => a.id != alarmId)
        .toList(growable: false);
    _workspace = _workspace.copyWith(alarms: nextAlarms);
    _workspace = await _repository.save(_workspace);
    notifyListeners();

    final AlarmSyncGateway? gateway = _alarmSyncGateway;
    if (_isAuthenticated &&
        gateway != null &&
        serverIdToDelete != null &&
        serverIdToDelete.isNotEmpty &&
        syncedScope == _ownerScopeKey) {
      _trackSync(_deleteRemoteAlarmBestEffort(gateway, serverIdToDelete));
    }
  }

  Future<void> _deleteRemoteAlarmBestEffort(
    AlarmSyncGateway gateway,
    String serverAlarmId,
  ) async {
    try {
      await gateway.deleteRemoteAlarm(serverAlarmId: serverAlarmId);
    } catch (_) {
      // Lỗi xóa trên server không khôi phục chuông đã tắt/xóa cục bộ.
    }
  }

  Future<void> syncAllAlarmsAndEvents() async {
    if (!_isAuthenticated || _alarmSyncGateway == null) return;
    for (final AlarmConfig alarm in List<AlarmConfig>.from(_workspace.alarms)) {
      if (alarm.serverSyncStatus != AlarmServerSyncStatus.synced ||
          alarm.serverSyncedOwnerScope != _ownerScopeKey) {
        await _syncSingleAlarmToServer(alarm.id);
      }
    }
    await _flushPendingAlarmEvents();
  }

  Future<void> _flushPendingAlarmEvents() async {
    final AlarmSyncGateway? gateway = _alarmSyncGateway;
    final PendingAlarmEventStore? eventStore = _pendingAlarmEventStore;
    if (!_isAuthenticated || gateway == null || eventStore == null) return;

    final List<PendingAlarmServerEvent> pending =
        await eventStore.loadEvents(_ownerScopeKey);
    for (final PendingAlarmServerEvent event in pending) {
      try {
        await gateway.sendSessionLifecycleEvent(event);
        await eventStore.removeByIdempotencyKey(
          ownerScopeKey: event.ownerScopeKey,
          idempotencyKey: event.idempotencyKey,
        );
      } catch (_) {
        // Dừng flush khi server chưa sẵn sàng, giữ nguyên hàng đợi.
        break;
      }
    }
    await _refreshPendingEventCount();
    notifyListeners();
  }

  Future<void> _syncSingleAlarmToServer(String alarmId) async {
    final AlarmSyncGateway? gateway = _alarmSyncGateway;
    if (!_isAuthenticated || gateway == null) return;

    final int idx =
        _workspace.alarms.indexWhere((AlarmConfig a) => a.id == alarmId);
    if (idx < 0) return;

    final AlarmConfig target = _workspace.alarms[idx];
    final String scopeAtStart = _ownerScopeKey;
    try {
      final RemoteAlarmRecord remote = await gateway.upsertRemoteAlarm(
        localAlarm: target,
        timeZone: 'Asia/Ho_Chi_Minh',
        idempotencyKey: LocalIdGenerator.nextUuidV4(),
      );
      if (_ownerScopeKey != scopeAtStart) return;
      final int currentIdx =
          _workspace.alarms.indexWhere((AlarmConfig a) => a.id == alarmId);
      if (currentIdx < 0) return;
      final List<AlarmConfig> next = List<AlarmConfig>.from(_workspace.alarms);
      // Tuyệt đối giữ nguyên local syncStatus (OS) khi cập nhật server metadata.
      next[currentIdx] = next[currentIdx].copyWith(
        serverSyncStatus: AlarmServerSyncStatus.synced,
        serverAlarmId: remote.serverAlarmId,
        serverRevision: remote.revision,
        serverSyncedOwnerScope: scopeAtStart,
        clearLastServerSyncError: true,
      );
      _workspace = _workspace.copyWith(alarms: next);
      _workspace = await _repository.save(_workspace);
      _serverSyncMessageVi = gateway.isDebugFixture
          ? 'Đã đồng bộ cấu hình báo thức (mẫu debug).'
          : 'Đã đồng bộ cấu hình báo thức lên server.';
      notifyListeners();
    } on PersonalApiException catch (error) {
      if (_ownerScopeKey != scopeAtStart) return;
      await _markAlarmSyncFailed(alarmId, error.messageVi);
    } catch (_) {
      if (_ownerScopeKey != scopeAtStart) return;
      await _markAlarmSyncFailed(
        alarmId,
        'Không thể đồng bộ server lúc này. Chuông local vẫn hoạt động bình thường.',
      );
    }
  }

  Future<void> _markAlarmSyncFailed(String alarmId, String messageVi) async {
    final int currentIdx =
        _workspace.alarms.indexWhere((AlarmConfig a) => a.id == alarmId);
    if (currentIdx < 0) return;
    final List<AlarmConfig> next = List<AlarmConfig>.from(_workspace.alarms);
    next[currentIdx] = next[currentIdx].copyWith(
      serverSyncStatus: AlarmServerSyncStatus.syncFailed,
      lastServerSyncErrorVi: messageVi,
    );
    _workspace = _workspace.copyWith(alarms: next);
    _workspace = await _repository.save(_workspace);
    _serverSyncMessageVi = messageVi;
    notifyListeners();
  }

  Future<void> resetLocalWorkspace() async {
    await _repository.clear();
    _workspace = GuestWorkspace.initial();
    _activeRingPayload = null;
    _scheduleChangedSinceAlarmSave = false;
    await refreshOsStatus();
  }
}
