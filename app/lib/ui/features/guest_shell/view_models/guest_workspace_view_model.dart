import 'package:flutter/foundation.dart';

import '../../../../data/repositories/guest_workspace_repository.dart';
import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/guest_workspace.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/models/wake_suggestion.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../core/strings/app_strings.dart';

class GuestWorkspaceViewModel extends ChangeNotifier {
  GuestWorkspaceViewModel({
    required GuestWorkspaceRepository repository,
    required AlarmSchedulerService alarmScheduler,
  })  : _repository = repository,
        _alarmScheduler = alarmScheduler;

  final GuestWorkspaceRepository _repository;
  final AlarmSchedulerService _alarmScheduler;

  GuestWorkspace _workspace = GuestWorkspace.initial();
  AlarmServiceCapabilities? _capabilities;
  AlarmPermissionSnapshot _permissionSnapshot =
      const AlarmPermissionSnapshot.unbound();
  String _lastSchedulerMessage = AppStrings.alarmOsUnboundExplain;
  bool _isLoaded = false;
  bool _scheduleChangedSinceAlarmSave = false;

  GuestWorkspace get workspace => _workspace;
  StudyProfile get profile => _workspace.profile;
  WeeklyTimetable get timetable => _workspace.timetable;
  List<AlarmConfig> get alarms => _workspace.alarms;
  AlarmConfig? get primaryAlarm => _workspace.primaryAlarm;
  WakeSuggestionInput get wakePreferences => _workspace.wakePreferences;
  AlarmServiceCapabilities? get capabilities => _capabilities;
  AlarmPermissionSnapshot get permissionSnapshot => _permissionSnapshot;
  String get lastSchedulerMessage => _lastSchedulerMessage;
  bool get isLoaded => _isLoaded;
  bool get isOsBridgeConnected => _alarmScheduler.isOsBridgeConnected;
  bool get scheduleChangedSinceAlarmSave => _scheduleChangedSinceAlarmSave;

  Future<void> initialize() async {
    _workspace = await _repository.load();
    _capabilities = await _alarmScheduler.checkCapabilities();
    _permissionSnapshot = await _alarmScheduler.getPermissionStatus();
    if (_capabilities != null) {
      _lastSchedulerMessage = _capabilities!.statusSummaryVi;
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Trạng thái hiển thị chuẩn cho mỗi báo thức.
  ///
  /// Khi chưa nối tầng native Android OS, luôn trả `Đã lưu cấu hình`.
  String statusLabelForAlarm(AlarmConfig alarm) {
    if (!isOsBridgeConnected) {
      return AppStrings.alarmSavedConfigOnly;
    }
    switch (alarm.syncStatus) {
      case AlarmSyncStatus.scheduledReady:
        return 'Đã sẵn sàng';
      case AlarmSyncStatus.pendingOsSync:
        return 'Đang đồng bộ hệ thống';
      case AlarmSyncStatus.osPermissionMissing:
        return 'Thiếu quyền báo thức OS';
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
    final AlarmScheduleResult result =
        await _alarmScheduler.scheduleAlarm(draft);
    _permissionSnapshot = result.permissionSnapshot;
    _lastSchedulerMessage = result.messageVi;

    final AlarmConfig persistedAlarm = draft.copyWith(
      syncStatus: result.status,
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

    final List<AlarmConfig> nextAlarms = List<AlarmConfig>.from(_workspace.alarms);
    nextAlarms[idx] = updated.copyWith(syncStatus: result.status);
    _workspace = _workspace.copyWith(alarms: nextAlarms);
    _workspace = await _repository.save(_workspace);
    notifyListeners();
  }

  Future<void> deleteAlarm(String alarmId) async {
    await _alarmScheduler.cancelAlarm(alarmId);
    final List<AlarmConfig> nextAlarms = _workspace.alarms
        .where((AlarmConfig a) => a.id != alarmId)
        .toList(growable: false);
    _workspace = _workspace.copyWith(alarms: nextAlarms);
    _workspace = await _repository.save(_workspace);
    notifyListeners();
  }

  Future<void> resetLocalWorkspace() async {
    await _repository.clear();
    _workspace = GuestWorkspace.initial();
    _scheduleChangedSinceAlarmSave = false;
    _capabilities = await _alarmScheduler.checkCapabilities();
    _permissionSnapshot = await _alarmScheduler.getPermissionStatus();
    notifyListeners();
  }
}
