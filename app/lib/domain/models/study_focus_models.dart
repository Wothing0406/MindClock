import 'dart:math' as math;

import 'study_profile.dart';
import 'subject_catalog.dart';
import 'timetable.dart';

/// Mức tập trung trong Không gian học (`docs/45 §1`).
enum StudyFocusLevel {
  flexible,
  standard,
  commitment;

  String get wireValue => name;

  String get labelVi {
    switch (this) {
      case StudyFocusLevel.flexible:
        return 'Linh hoạt';
      case StudyFocusLevel.standard:
        return 'Tập trung thường';
      case StudyFocusLevel.commitment:
        return 'Cam kết';
    }
  }

  String get shortBehaviorVi {
    switch (this) {
      case StudyFocusLevel.flexible:
        return 'Đồng hồ tiếp tục khi rời app; khi trở lại cho biết thời gian rời, không nhắc.';
      case StudyFocusLevel.standard:
        return 'Rời app quá 30 giây sẽ hiện 1 nhắc cục bộ khi quay lại; không chồng thông báo.';
      case StudyFocusLevel.commitment:
        return 'Rời app quá 10 giây sẽ dừng phút tập trung trong app và cần bấm Tiếp tục học khi quay lại.';
    }
  }

  static StudyFocusLevel fromWire(String? value) {
    for (final StudyFocusLevel level in values) {
      if (level.wireValue == value) return level;
    }
    return StudyFocusLevel.standard;
  }
}

/// Máy trạng thái phiên học cục bộ (`docs/45 §2`).
enum StudyFocusStatus {
  draft,
  running,
  paused,
  interrupted,
  completed,
  endedEarly;

  String get wireValue => name;

  bool get isOngoing =>
      this == StudyFocusStatus.running ||
      this == StudyFocusStatus.paused ||
      this == StudyFocusStatus.interrupted;

  bool get isTerminal =>
      this == StudyFocusStatus.completed || this == StudyFocusStatus.endedEarly;

  static StudyFocusStatus fromWire(String? value) {
    for (final StudyFocusStatus status in values) {
      if (status.wireValue == value) return status;
    }
    return StudyFocusStatus.draft;
  }
}

/// Việc học gợi ý cho màn `Hôm nay` và màn thiết lập phiên (`docs/45 §2`).
class StudyTaskChoice {
  const StudyTaskChoice({
    required this.title,
    this.subjectCode,
    this.isSuggestedFromSchedule = false,
  });

  final String title;
  final String? subjectCode;
  final bool isSuggestedFromSchedule;

  static const StudyTaskChoice freeStudy = StudyTaskChoice(
    title: 'Học tự do',
    subjectCode: null,
    isSuggestedFromSchedule: false,
  );

  static List<StudyTaskChoice> buildSuggestions({
    required StudyProfile profile,
    required WeeklyTimetable timetable,
    required DateTime now,
  }) {
    final List<StudyTaskChoice> suggestions = <StudyTaskChoice>[];
    final Set<String> seenTitles = <String>{};

    void addChoice(String title, String? subjectCode, bool fromSchedule) {
      final String clean = title.trim();
      if (clean.isEmpty || seenTitles.contains(clean)) return;
      seenTitles.add(clean);
      suggestions.add(
        StudyTaskChoice(
          title: clean,
          subjectCode: subjectCode,
          isSuggestedFromSchedule: fromSchedule,
        ),
      );
    }

    final DaySchedule today = timetable.dayFor(now.weekday);
    if (!today.isRestDay) {
      for (final TimetableEntry entry in today.sortedEntries) {
        final String subjectName = SubjectCatalog.nameFor(entry.subjectCode);
        addChoice(
          'Ôn $subjectName (${entry.formattedStartTime})',
          entry.subjectCode,
          true,
        );
      }
    }

    for (final String code in profile.prioritySubjectCodes) {
      addChoice(
        'Làm bài tập ${SubjectCatalog.nameFor(code)}',
        code,
        false,
      );
    }

    for (final String code in profile.selectedSubjectCodes) {
      addChoice(
        'Ôn tập ${SubjectCatalog.nameFor(code)}',
        code,
        false,
      );
    }

    addChoice(freeStudy.title, null, false);
    return suggestions;
  }
}

/// Snapshot phiên học cục bộ tính theo mốc thời gian (`docs/45 §§1–2`).
class StudyFocusSessionSnapshot {
  const StudyFocusSessionSnapshot({
    required this.sessionId,
    required this.ownerScopeKey,
    required this.taskTitle,
    required this.durationMinutes,
    required this.level,
    required this.status,
    required this.endSoundEnabled,
    required this.notifyOutsideApp,
    required this.startedAtEpochMs,
    required this.plannedEndAtEpochMs,
    required this.updatedAtEpochMs,
    this.subjectCode,
    this.pausedAtEpochMs,
    this.leftAtEpochMs,
    this.endedAtEpochMs,
    this.accumulatedPausedMs = 0,
    this.accumulatedAwayMs = 0,
    this.commitmentFrozenAwayMs = 0,
    this.commitmentAwaitingResume = false,
    this.lastAwaySeconds,
    this.lastReturnNoticeVi,
    this.notesDone = '',
    this.notesStuck = '',
    this.createIdempotencyKey = '',
    this.finishIdempotencyKey = '',
    this.remoteSessionId,
    this.remoteSessionSynced = false,
  });

  static const int minDurationMinutes = 5;
  static const int maxDurationMinutes = 120;
  static const List<int> presetMinutes = <int>[10, 25, 45];
  static const int standardReminderThresholdSeconds = 30;
  static const int commitmentThresholdSeconds = 10;

  final String sessionId;
  final String ownerScopeKey;
  final String taskTitle;
  final String? subjectCode;
  final int durationMinutes;
  final StudyFocusLevel level;
  final StudyFocusStatus status;
  final bool endSoundEnabled;
  final bool notifyOutsideApp;

  final int startedAtEpochMs;
  final int plannedEndAtEpochMs;
  final int updatedAtEpochMs;
  final int? pausedAtEpochMs;
  final int? leftAtEpochMs;
  final int? endedAtEpochMs;

  final int accumulatedPausedMs;
  final int accumulatedAwayMs;
  final int commitmentFrozenAwayMs;
  final bool commitmentAwaitingResume;

  final int? lastAwaySeconds;
  final String? lastReturnNoticeVi;
  final String notesDone;
  final String notesStuck;
  final String createIdempotencyKey;
  final String finishIdempotencyKey;
  final String? remoteSessionId;
  final bool remoteSessionSynced;

  int get targetDurationSeconds => durationMinutes * 60;

  /// Tổng thời gian trôi qua trên đồng hồ thực tế từ lúc bắt đầu (`elapsed_wall_seconds`).
  int elapsedWallSecondsAt(DateTime now) {
    final int endMs = endedAtEpochMs ?? now.millisecondsSinceEpoch;
    return math.max(0, (endMs - startedAtEpochMs) ~/ 1000);
  }

  int _openPauseDeltaMs(int effectiveNowMs) {
    if (pausedAtEpochMs == null) return 0;
    if (status == StudyFocusStatus.paused ||
        status == StudyFocusStatus.interrupted ||
        commitmentAwaitingResume) {
      return math.max(0, effectiveNowMs - pausedAtEpochMs!);
    }
    return 0;
  }

  /// Thời gian đã trôi qua cho bộ đếm ngược mục tiêu (`Linh hoạt`/`Tập trung thường` tiếp tục khi rời app).
  int countdownElapsedSecondsAt(DateTime now) {
    final int endMs = endedAtEpochMs ?? now.millisecondsSinceEpoch;
    final int livePauseMs = _openPauseDeltaMs(endMs);
    final int openAwayMsForCommitment = (level == StudyFocusLevel.commitment &&
            leftAtEpochMs != null &&
            math.max(0, endMs - leftAtEpochMs!) > commitmentThresholdSeconds * 1000)
        ? math.max(0, endMs - leftAtEpochMs!)
        : 0;

    final int nonCountdownMs = accumulatedPausedMs +
        livePauseMs +
        (level == StudyFocusLevel.commitment
            ? commitmentFrozenAwayMs + openAwayMsForCommitment
            : 0);

    return math.max(0, (endMs - startedAtEpochMs - nonCountdownMs) ~/ 1000);
  }

  int remainingSecondsAt(DateTime now) {
    return math.max(0, targetDurationSeconds - countdownElapsedSecondsAt(now));
  }

  bool isTargetReachedAt(DateTime now) => remainingSecondsAt(now) == 0;

  /// Thời gian tập trung ở trong app (`in_app_focus_seconds`, tách khỏi `elapsed_wall_seconds`).
  int inAppFocusSecondsAt(DateTime now) {
    final int endMs = endedAtEpochMs ?? now.millisecondsSinceEpoch;
    final int livePauseMs = _openPauseDeltaMs(endMs);
    final int liveAwayMs =
        leftAtEpochMs != null ? math.max(0, endMs - leftAtEpochMs!) : 0;

    // Tránh trừ hai lần nếu lúc tạm nghỉ đồng thời có leftAt trước đó: dùng giá trị loại trừ tích lũy chuẩn.
    final int excludedMs =
        accumulatedPausedMs + accumulatedAwayMs + livePauseMs + liveAwayMs;
    return math.max(0, (endMs - startedAtEpochMs - excludedMs) ~/ 1000);
  }

  StudyFocusSessionSnapshot copyWith({
    String? sessionId,
    String? ownerScopeKey,
    String? taskTitle,
    String? subjectCode,
    bool clearSubjectCode = false,
    int? durationMinutes,
    StudyFocusLevel? level,
    StudyFocusStatus? status,
    bool? endSoundEnabled,
    bool? notifyOutsideApp,
    int? startedAtEpochMs,
    int? plannedEndAtEpochMs,
    int? updatedAtEpochMs,
    int? pausedAtEpochMs,
    bool clearPausedAt = false,
    int? leftAtEpochMs,
    bool clearLeftAt = false,
    int? endedAtEpochMs,
    bool clearEndedAt = false,
    int? accumulatedPausedMs,
    int? accumulatedAwayMs,
    int? commitmentFrozenAwayMs,
    bool? commitmentAwaitingResume,
    int? lastAwaySeconds,
    bool clearLastAwaySeconds = false,
    String? lastReturnNoticeVi,
    bool clearLastReturnNotice = false,
    String? notesDone,
    String? notesStuck,
    String? createIdempotencyKey,
    String? finishIdempotencyKey,
    String? remoteSessionId,
    bool clearRemoteSessionId = false,
    bool? remoteSessionSynced,
  }) {
    return StudyFocusSessionSnapshot(
      sessionId: sessionId ?? this.sessionId,
      ownerScopeKey: ownerScopeKey ?? this.ownerScopeKey,
      taskTitle: taskTitle ?? this.taskTitle,
      subjectCode: clearSubjectCode ? null : (subjectCode ?? this.subjectCode),
      durationMinutes: durationMinutes ?? this.durationMinutes,
      level: level ?? this.level,
      status: status ?? this.status,
      endSoundEnabled: endSoundEnabled ?? this.endSoundEnabled,
      notifyOutsideApp: notifyOutsideApp ?? this.notifyOutsideApp,
      startedAtEpochMs: startedAtEpochMs ?? this.startedAtEpochMs,
      plannedEndAtEpochMs: plannedEndAtEpochMs ?? this.plannedEndAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      pausedAtEpochMs:
          clearPausedAt ? null : (pausedAtEpochMs ?? this.pausedAtEpochMs),
      leftAtEpochMs: clearLeftAt ? null : (leftAtEpochMs ?? this.leftAtEpochMs),
      endedAtEpochMs:
          clearEndedAt ? null : (endedAtEpochMs ?? this.endedAtEpochMs),
      accumulatedPausedMs: accumulatedPausedMs ?? this.accumulatedPausedMs,
      accumulatedAwayMs: accumulatedAwayMs ?? this.accumulatedAwayMs,
      commitmentFrozenAwayMs:
          commitmentFrozenAwayMs ?? this.commitmentFrozenAwayMs,
      commitmentAwaitingResume:
          commitmentAwaitingResume ?? this.commitmentAwaitingResume,
      lastAwaySeconds:
          clearLastAwaySeconds ? null : (lastAwaySeconds ?? this.lastAwaySeconds),
      lastReturnNoticeVi: clearLastReturnNotice
          ? null
          : (lastReturnNoticeVi ?? this.lastReturnNoticeVi),
      notesDone: notesDone ?? this.notesDone,
      notesStuck: notesStuck ?? this.notesStuck,
      createIdempotencyKey: createIdempotencyKey ?? this.createIdempotencyKey,
      finishIdempotencyKey: finishIdempotencyKey ?? this.finishIdempotencyKey,
      remoteSessionId: clearRemoteSessionId
          ? null
          : (remoteSessionId ?? this.remoteSessionId),
      remoteSessionSynced: remoteSessionSynced ?? this.remoteSessionSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'ownerScopeKey': ownerScopeKey,
      'taskTitle': taskTitle,
      'subjectCode': subjectCode,
      'durationMinutes': durationMinutes,
      'level': level.wireValue,
      'status': status.wireValue,
      'endSoundEnabled': endSoundEnabled,
      'notifyOutsideApp': notifyOutsideApp,
      'startedAtEpochMs': startedAtEpochMs,
      'plannedEndAtEpochMs': plannedEndAtEpochMs,
      'updatedAtEpochMs': updatedAtEpochMs,
      'pausedAtEpochMs': pausedAtEpochMs,
      'leftAtEpochMs': leftAtEpochMs,
      'endedAtEpochMs': endedAtEpochMs,
      'accumulatedPausedMs': accumulatedPausedMs,
      'accumulatedAwayMs': accumulatedAwayMs,
      'commitmentFrozenAwayMs': commitmentFrozenAwayMs,
      'commitmentAwaitingResume': commitmentAwaitingResume,
      'lastAwaySeconds': lastAwaySeconds,
      'lastReturnNoticeVi': lastReturnNoticeVi,
      'notesDone': notesDone,
      'notesStuck': notesStuck,
      'createIdempotencyKey': createIdempotencyKey,
      'finishIdempotencyKey': finishIdempotencyKey,
      'remoteSessionId': remoteSessionId,
      'remoteSessionSynced': remoteSessionSynced,
    };
  }

  factory StudyFocusSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final String sid = json['sessionId'] as String? ?? '';
    return StudyFocusSessionSnapshot(
      sessionId: sid,
      ownerScopeKey: json['ownerScopeKey'] as String? ?? 'guest',
      taskTitle: json['taskTitle'] as String? ?? StudyTaskChoice.freeStudy.title,
      subjectCode: json['subjectCode'] as String?,
      durationMinutes: ((json['durationMinutes'] as num?)?.toInt() ?? 25)
          .clamp(minDurationMinutes, maxDurationMinutes),
      level: StudyFocusLevel.fromWire(json['level'] as String?),
      status: StudyFocusStatus.fromWire(json['status'] as String?),
      endSoundEnabled: json['endSoundEnabled'] as bool? ?? true,
      notifyOutsideApp: json['notifyOutsideApp'] as bool? ?? false,
      startedAtEpochMs: (json['startedAtEpochMs'] as num?)?.toInt() ?? 0,
      plannedEndAtEpochMs: (json['plannedEndAtEpochMs'] as num?)?.toInt() ?? 0,
      updatedAtEpochMs: (json['updatedAtEpochMs'] as num?)?.toInt() ?? 0,
      pausedAtEpochMs: (json['pausedAtEpochMs'] as num?)?.toInt(),
      leftAtEpochMs: (json['leftAtEpochMs'] as num?)?.toInt(),
      endedAtEpochMs: (json['endedAtEpochMs'] as num?)?.toInt(),
      accumulatedPausedMs: (json['accumulatedPausedMs'] as num?)?.toInt() ?? 0,
      accumulatedAwayMs: (json['accumulatedAwayMs'] as num?)?.toInt() ?? 0,
      commitmentFrozenAwayMs:
          (json['commitmentFrozenAwayMs'] as num?)?.toInt() ?? 0,
      commitmentAwaitingResume:
          json['commitmentAwaitingResume'] as bool? ?? false,
      lastAwaySeconds: (json['lastAwaySeconds'] as num?)?.toInt(),
      lastReturnNoticeVi: json['lastReturnNoticeVi'] as String?,
      notesDone: json['notesDone'] as String? ?? '',
      notesStuck: json['notesStuck'] as String? ?? '',
      createIdempotencyKey:
          json['createIdempotencyKey'] as String? ?? 'study_create_$sid',
      finishIdempotencyKey:
          json['finishIdempotencyKey'] as String? ?? 'study_finish_$sid',
      remoteSessionId: json['remoteSessionId'] as String?,
      remoteSessionSynced: json['remoteSessionSynced'] as bool? ?? false,
    );
  }
}

/// Bản ghi phiên học đã hoàn tất lưu cục bộ (`idempotent` theo `sessionId`).
class StudyFocusRecord {
  const StudyFocusRecord({
    required this.sessionId,
    required this.ownerScopeKey,
    required this.taskTitle,
    required this.targetMinutes,
    required this.level,
    required this.finalStatus,
    required this.elapsedWallSeconds,
    required this.inAppFocusSeconds,
    required this.startedAtEpochMs,
    required this.endedAtEpochMs,
    this.subjectCode,
    this.notesDone = '',
    this.notesStuck = '',
    this.remoteSessionId,
    this.finishIdempotencyKey = '',
    this.remoteFinishSynced = false,
    this.remoteSyncErrorVi,
  });

  final String sessionId;
  final String ownerScopeKey;
  final String taskTitle;
  final String? subjectCode;
  final int targetMinutes;
  final StudyFocusLevel level;
  final StudyFocusStatus finalStatus;
  final int elapsedWallSeconds;
  final int inAppFocusSeconds;
  final int startedAtEpochMs;
  final int endedAtEpochMs;
  final String notesDone;
  final String notesStuck;
  final String? remoteSessionId;
  final String finishIdempotencyKey;
  final bool remoteFinishSynced;
  final String? remoteSyncErrorVi;

  /// Theo `docs/45 §§1, 5`: không tự cấp XP chỉ vì thời gian hay camera.
  int get xpAwardedByTimer => 0;

  StudyFocusRecord copyWith({
    String? remoteSessionId,
    String? finishIdempotencyKey,
    bool? remoteFinishSynced,
    String? remoteSyncErrorVi,
    bool clearRemoteSyncError = false,
  }) {
    return StudyFocusRecord(
      sessionId: sessionId,
      ownerScopeKey: ownerScopeKey,
      taskTitle: taskTitle,
      subjectCode: subjectCode,
      targetMinutes: targetMinutes,
      level: level,
      finalStatus: finalStatus,
      elapsedWallSeconds: elapsedWallSeconds,
      inAppFocusSeconds: inAppFocusSeconds,
      startedAtEpochMs: startedAtEpochMs,
      endedAtEpochMs: endedAtEpochMs,
      notesDone: notesDone,
      notesStuck: notesStuck,
      remoteSessionId: remoteSessionId ?? this.remoteSessionId,
      finishIdempotencyKey: finishIdempotencyKey ?? this.finishIdempotencyKey,
      remoteFinishSynced: remoteFinishSynced ?? this.remoteFinishSynced,
      remoteSyncErrorVi: clearRemoteSyncError
          ? null
          : (remoteSyncErrorVi ?? this.remoteSyncErrorVi),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'ownerScopeKey': ownerScopeKey,
      'taskTitle': taskTitle,
      'subjectCode': subjectCode,
      'targetMinutes': targetMinutes,
      'level': level.wireValue,
      'finalStatus': finalStatus.wireValue,
      'elapsedWallSeconds': elapsedWallSeconds,
      'inAppFocusSeconds': inAppFocusSeconds,
      'startedAtEpochMs': startedAtEpochMs,
      'endedAtEpochMs': endedAtEpochMs,
      'notesDone': notesDone,
      'notesStuck': notesStuck,
      'remoteSessionId': remoteSessionId,
      'finishIdempotencyKey': finishIdempotencyKey,
      'remoteFinishSynced': remoteFinishSynced,
      'remoteSyncErrorVi': remoteSyncErrorVi,
    };
  }

  factory StudyFocusRecord.fromJson(Map<String, dynamic> json) {
    final String sid = json['sessionId'] as String? ?? '';
    return StudyFocusRecord(
      sessionId: sid,
      ownerScopeKey: json['ownerScopeKey'] as String? ?? 'guest',
      taskTitle: json['taskTitle'] as String? ?? StudyTaskChoice.freeStudy.title,
      subjectCode: json['subjectCode'] as String?,
      targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 25,
      level: StudyFocusLevel.fromWire(json['level'] as String?),
      finalStatus: StudyFocusStatus.fromWire(json['finalStatus'] as String?),
      elapsedWallSeconds: (json['elapsedWallSeconds'] as num?)?.toInt() ?? 0,
      inAppFocusSeconds: (json['inAppFocusSeconds'] as num?)?.toInt() ?? 0,
      startedAtEpochMs: (json['startedAtEpochMs'] as num?)?.toInt() ?? 0,
      endedAtEpochMs: (json['endedAtEpochMs'] as num?)?.toInt() ?? 0,
      notesDone: json['notesDone'] as String? ?? '',
      notesStuck: json['notesStuck'] as String? ?? '',
      remoteSessionId: json['remoteSessionId'] as String?,
      finishIdempotencyKey:
          json['finishIdempotencyKey'] as String? ?? 'study_finish_$sid',
      remoteFinishSynced: json['remoteFinishSynced'] as bool? ?? false,
      remoteSyncErrorVi: json['remoteSyncErrorVi'] as String?,
    );
  }
}

/// Định dạng giây thành `MM:SS` hoặc `HH:MM:SS` rõ ràng, không dùng emoji.
String formatDurationClock(int totalSeconds) {
  final int safe = math.max(0, totalSeconds);
  final int hours = safe ~/ 3600;
  final int minutes = (safe % 3600) ~/ 60;
  final int seconds = safe % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  if (hours > 0) {
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}

/// Định dạng thời lượng rời app tự nhiên bằng tiếng Việt (`giây` / `phút`).
String formatVietnameseAwayDuration(int totalSeconds) {
  final int safe = math.max(0, totalSeconds);
  if (safe < 60) {
    return '$safe giây';
  }
  final int minutes = safe ~/ 60;
  final int remSeconds = safe % 60;
  if (remSeconds == 0) {
    return '$minutes phút';
  }
  return '$minutes phút $remSeconds giây';
}
