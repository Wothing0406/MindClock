/// Một tiết học trong thời khóa biểu 7 ngày.
class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.subjectCode,
    required this.startMinutes,
    this.note = '',
  });

  final String id;
  final String subjectCode;
  final int startMinutes;
  final String note;

  int get hour => (startMinutes ~/ 60) % 24;
  int get minute => startMinutes % 60;

  String get formattedStartTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  TimetableEntry copyWith({
    String? id,
    String? subjectCode,
    int? startMinutes,
    String? note,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      subjectCode: subjectCode ?? this.subjectCode,
      startMinutes: startMinutes ?? this.startMinutes,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'subjectCode': subjectCode,
        'startMinutes': startMinutes,
        'note': note,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? 'math',
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 420,
      note: json['note'] as String? ?? '',
    );
  }
}

/// Lịch của một ngày trong tuần (`weekday`: 1 = Thứ 2 .. 7 = Chủ nhật).
class DaySchedule {
  const DaySchedule({
    required this.weekday,
    this.isRestDay = false,
    this.entries = const <TimetableEntry>[],
  });

  final int weekday;
  final bool isRestDay;
  final List<TimetableEntry> entries;

  List<TimetableEntry> get sortedEntries {
    final List<TimetableEntry> copy = List<TimetableEntry>.from(entries);
    copy.sort((TimetableEntry a, TimetableEntry b) =>
        a.startMinutes.compareTo(b.startMinutes));
    return copy;
  }

  DaySchedule copyWith({
    int? weekday,
    bool? isRestDay,
    List<TimetableEntry>? entries,
  }) {
    return DaySchedule(
      weekday: weekday ?? this.weekday,
      isRestDay: isRestDay ?? this.isRestDay,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'weekday': weekday,
        'isRestDay': isRestDay,
        'entries': entries.map((TimetableEntry e) => e.toJson()).toList(),
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawEntries =
        json['entries'] as List<dynamic>? ?? <dynamic>[];
    return DaySchedule(
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      isRestDay: json['isRestDay'] as bool? ?? false,
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(TimetableEntry.fromJson)
          .toList(growable: false),
    );
  }
}

/// Thời khóa biểu 7 ngày đầy đủ.
class WeeklyTimetable {
  WeeklyTimetable({
    List<DaySchedule>? days,
    this.revision = 1,
  }) : days = days ?? _defaultWeek();

  final List<DaySchedule> days;
  final int revision;

  static List<DaySchedule> _defaultWeek() {
    return List<DaySchedule>.generate(
      7,
      (int index) => DaySchedule(
        weekday: index + 1,
        isRestDay: index == 6, // Chủ nhật mặc định là ngày nghỉ, người dùng sửa được
      ),
      growable: false,
    );
  }

  static String weekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
      default:
        return 'Chủ nhật';
    }
  }

  static String shortWeekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
      default:
        return 'CN';
    }
  }

  DaySchedule dayFor(int weekday) {
    for (final DaySchedule day in days) {
      if (day.weekday == weekday) return day;
    }
    return DaySchedule(weekday: weekday);
  }

  TimetableEntry? earliestEntryFor(int weekday) {
    final DaySchedule day = dayFor(weekday);
    if (day.isRestDay || day.entries.isEmpty) return null;
    return day.sortedEntries.first;
  }

  WeeklyTimetable updateDay(DaySchedule updated) {
    final List<DaySchedule> nextDays = days
        .map((DaySchedule d) => d.weekday == updated.weekday ? updated : d)
        .toList(growable: false);
    return WeeklyTimetable(days: nextDays, revision: revision + 1);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'revision': revision,
        'days': days.map((DaySchedule d) => d.toJson()).toList(),
      };

  factory WeeklyTimetable.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDays = json['days'] as List<dynamic>? ?? <dynamic>[];
    final Map<int, DaySchedule> byWeekday = <int, DaySchedule>{};
    for (final Map<String, dynamic> item
        in rawDays.whereType<Map<String, dynamic>>()) {
      final DaySchedule parsed = DaySchedule.fromJson(item);
      if (parsed.weekday >= 1 && parsed.weekday <= 7) {
        byWeekday[parsed.weekday] = parsed;
      }
    }
    final List<DaySchedule> completeDays = List<DaySchedule>.generate(
      7,
      (int idx) =>
          byWeekday[idx + 1] ??
          DaySchedule(weekday: idx + 1, isRestDay: idx == 6),
      growable: false,
    );
    return WeeklyTimetable(
      days: completeDays,
      revision: (json['revision'] as num?)?.toInt() ?? 1,
    );
  }
}
