import 'alarm_config.dart';
import 'daily_todo_task.dart';
import 'study_profile.dart';
import 'timetable.dart';
import 'wake_suggestion.dart';

/// Toàn bộ trạng thái cục bộ của người dùng khách.
class GuestWorkspace {
  const GuestWorkspace({
    this.onboardingCompleted = false,
    this.profile = const StudyProfile(),
    required this.timetable,
    this.alarms = const <AlarmConfig>[],
    this.wakePreferences = const WakeSuggestionInput(
      classStartMinutes: 420,
      commuteMinutes: 25,
      prepMinutes: 30,
      bufferMinutes: 10,
    ),
    this.dailyTasks = const <DailyTodoTask>[],
    this.doneScheduleKeys = const <String>[],
    this.lastSavedIso,
  });

  factory GuestWorkspace.initial() => GuestWorkspace(
        onboardingCompleted: false,
        profile: const StudyProfile(),
        timetable: WeeklyTimetable(),
        alarms: const <AlarmConfig>[],
        dailyTasks: const <DailyTodoTask>[],
        doneScheduleKeys: const <String>[],
      );

  final bool onboardingCompleted;
  final StudyProfile profile;
  final WeeklyTimetable timetable;
  final List<AlarmConfig> alarms;
  final WakeSuggestionInput wakePreferences;
  final List<DailyTodoTask> dailyTasks;
  final List<String> doneScheduleKeys;
  final String? lastSavedIso;

  AlarmConfig? get primaryAlarm => alarms.isEmpty ? null : alarms.first;

  GuestWorkspace copyWith({
    bool? onboardingCompleted,
    StudyProfile? profile,
    WeeklyTimetable? timetable,
    List<AlarmConfig>? alarms,
    WakeSuggestionInput? wakePreferences,
    List<DailyTodoTask>? dailyTasks,
    List<String>? doneScheduleKeys,
    String? lastSavedIso,
  }) {
    return GuestWorkspace(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profile: profile ?? this.profile,
      timetable: timetable ?? this.timetable,
      alarms: alarms ?? this.alarms,
      wakePreferences: wakePreferences ?? this.wakePreferences,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      doneScheduleKeys: doneScheduleKeys ?? this.doneScheduleKeys,
      lastSavedIso: lastSavedIso ?? this.lastSavedIso,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': 2,
        'onboardingCompleted': onboardingCompleted,
        'profile': profile.toJson(),
        'timetable': timetable.toJson(),
        'alarms': alarms.map((AlarmConfig a) => a.toJson()).toList(),
        'wakePreferences': wakePreferences.toJson(),
        'dailyTasks': dailyTasks.map((DailyTodoTask t) => t.toJson()).toList(),
        'doneScheduleKeys': doneScheduleKeys,
        'lastSavedIso': lastSavedIso,
      };

  factory GuestWorkspace.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawAlarms =
        json['alarms'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawTasks =
        json['dailyTasks'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawDoneKeys =
        json['doneScheduleKeys'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic>? rawProfile =
        json['profile'] as Map<String, dynamic>?;
    final Map<String, dynamic>? rawTimetable =
        json['timetable'] as Map<String, dynamic>?;
    final Map<String, dynamic>? rawWakePrefs =
        json['wakePreferences'] as Map<String, dynamic>?;

    return GuestWorkspace(
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      profile: rawProfile != null
          ? StudyProfile.fromJson(rawProfile)
          : const StudyProfile(),
      timetable: rawTimetable != null
          ? WeeklyTimetable.fromJson(rawTimetable)
          : WeeklyTimetable(),
      alarms: rawAlarms
          .whereType<Map<String, dynamic>>()
          .map(AlarmConfig.fromJson)
          .toList(growable: false),
      wakePreferences: rawWakePrefs != null
          ? WakeSuggestionInput.fromJson(rawWakePrefs)
          : const WakeSuggestionInput(
              classStartMinutes: 420,
              commuteMinutes: 25,
              prepMinutes: 30,
              bufferMinutes: 10,
            ),
      dailyTasks: rawTasks
          .whereType<Map<String, dynamic>>()
          .map(DailyTodoTask.fromJson)
          .toList(growable: false),
      doneScheduleKeys: rawDoneKeys
          .whereType<String>()
          .toList(growable: false),
      lastSavedIso: json['lastSavedIso'] as String?,
    );
  }
}
