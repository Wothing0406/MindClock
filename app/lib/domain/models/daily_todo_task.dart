import 'subject_catalog.dart';
import 'timetable.dart';

/// Phân loại công việc / lịch học trong ngày trên trục thời gian MindClock.
enum DailyTodoCategory {
  schoolClass('school', 'Chính khóa'),
  extraClass('extra', 'Học thêm'),
  selfStudy('self_study', 'Tự học / Bài tập');

  const DailyTodoCategory(this.id, this.labelVi);
  final String id;
  final String labelVi;

  static DailyTodoCategory fromId(String? id) {
    for (final DailyTodoCategory c in values) {
      if (c.id == id || c.name == id) return c;
    }
    return DailyTodoCategory.selfStudy;
  }
}

/// Chuẩn hóa chuỗi ngày `YYYY-MM-DD` theo giờ địa phương.
String formatDateIso(DateTime date) {
  final String y = date.year.toString().padLeft(4, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatMinutesClock(int totalMinutes) {
  final int safe = ((totalMinutes % 1440) + 1440) % 1440;
  final String h = (safe ~/ 60).toString().padLeft(2, '0');
  final String m = (safe % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Một công việc / lịch học thêm / nhiệm vụ To-do trong ngày.
class DailyTodoTask {
  const DailyTodoTask({
    required this.id,
    required this.title,
    required this.dateIso,
    required this.startMinutes,
    this.durationMinutes = 45,
    this.subjectCode,
    this.category = DailyTodoCategory.selfStudy,
    this.isDone = false,
    this.doneAtIso,
    this.remindOnTime = true,
    this.note = '',
  });

  final String id;
  final String title;
  final String dateIso;
  final int startMinutes;
  final int durationMinutes;
  final String? subjectCode;
  final DailyTodoCategory category;
  final bool isDone;
  final String? doneAtIso;
  final bool remindOnTime;
  final String note;

  int get endMinutes => (startMinutes + durationMinutes).clamp(0, 1440);

  String get formattedStart => formatMinutesClock(startMinutes);

  String get formattedTimeRange =>
      '${formatMinutesClock(startMinutes)} - ${formatMinutesClock(endMinutes)}';

  DailyTodoTask copyWith({
    String? id,
    String? title,
    String? dateIso,
    int? startMinutes,
    int? durationMinutes,
    String? subjectCode,
    bool clearSubjectCode = false,
    DailyTodoCategory? category,
    bool? isDone,
    String? doneAtIso,
    bool clearDoneAt = false,
    bool? remindOnTime,
    String? note,
  }) {
    return DailyTodoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      dateIso: dateIso ?? this.dateIso,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      subjectCode: clearSubjectCode ? null : (subjectCode ?? this.subjectCode),
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      doneAtIso: clearDoneAt ? null : (doneAtIso ?? this.doneAtIso),
      remindOnTime: remindOnTime ?? this.remindOnTime,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'dateIso': dateIso,
        'startMinutes': startMinutes,
        'durationMinutes': durationMinutes,
        'subjectCode': subjectCode,
        'category': category.id,
        'isDone': isDone,
        'doneAtIso': doneAtIso,
        'remindOnTime': remindOnTime,
        'note': note,
      };

  factory DailyTodoTask.fromJson(Map<String, dynamic> json) {
    return DailyTodoTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      dateIso: json['dateIso'] as String? ?? formatDateIso(DateTime.now()),
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 480,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      subjectCode: json['subjectCode'] as String?,
      category: DailyTodoCategory.fromId(json['category'] as String?),
      isDone: json['isDone'] as bool? ?? false,
      doneAtIso: json['doneAtIso'] as String?,
      remindOnTime: json['remindOnTime'] as bool? ?? true,
      note: json['note'] as String? ?? '',
    );
  }
}

enum ScheduleBlockStatus {
  done,
  ongoing,
  overdue,
  upcoming,
}

/// Khối lịch thống nhất trên Calendar ngày (gộp tiết TKB chính khóa + To-do / Học thêm).
class DayScheduleBlock {
  const DayScheduleBlock({
    required this.id,
    required this.isFromTimetable,
    required this.title,
    required this.category,
    required this.startMinutes,
    required this.durationMinutes,
    required this.isDone,
    required this.remindOnTime,
    this.subjectCode,
    this.note = '',
    this.timetableDoneKey,
    this.sourceTask,
  });

  final String id;
  final bool isFromTimetable;
  final String title;
  final DailyTodoCategory category;
  final int startMinutes;
  final int durationMinutes;
  final bool isDone;
  final bool remindOnTime;
  final String? subjectCode;
  final String note;
  final String? timetableDoneKey;
  final DailyTodoTask? sourceTask;

  int get endMinutes => (startMinutes + durationMinutes).clamp(0, 1440);

  String get formattedStart => formatMinutesClock(startMinutes);

  String get formattedTimeRange =>
      '${formatMinutesClock(startMinutes)} - ${formatMinutesClock(endMinutes)}';

  ScheduleBlockStatus statusAt(DateTime now, DateTime viewingDate) {
    if (isDone) return ScheduleBlockStatus.done;
    final String nowIso = formatDateIso(now);
    final String viewIso = formatDateIso(viewingDate);
    if (viewIso.compareTo(nowIso) < 0) {
      return ScheduleBlockStatus.overdue;
    }
    if (viewIso.compareTo(nowIso) > 0) {
      return ScheduleBlockStatus.upcoming;
    }
    final int nowMins = now.hour * 60 + now.minute;
    if (nowMins >= startMinutes && nowMins < endMinutes) {
      return ScheduleBlockStatus.ongoing;
    }
    if (nowMins >= endMinutes) {
      return ScheduleBlockStatus.overdue;
    }
    return ScheduleBlockStatus.upcoming;
  }

  static List<DayScheduleBlock> buildForDate({
    required DateTime date,
    required WeeklyTimetable timetable,
    required List<DailyTodoTask> tasks,
    required Set<String> doneScheduleKeys,
  }) {
    final String dateIso = formatDateIso(date);
    final List<DayScheduleBlock> blocks = <DayScheduleBlock>[];

    final DaySchedule daySchedule = timetable.dayFor(date.weekday);
    if (!daySchedule.isRestDay) {
      for (final TimetableEntry entry in daySchedule.sortedEntries) {
        final String key = '$dateIso|${entry.id}';
        final String subjectName = SubjectCatalog.nameFor(entry.subjectCode);
        blocks.add(
          DayScheduleBlock(
            id: 'tt_${entry.id}',
            isFromTimetable: true,
            title: subjectName,
            category: DailyTodoCategory.schoolClass,
            startMinutes: entry.startMinutes,
            durationMinutes: 45,
            isDone: doneScheduleKeys.contains(key),
            remindOnTime: false,
            subjectCode: entry.subjectCode,
            note: entry.note,
            timetableDoneKey: key,
          ),
        );
      }
    }

    for (final DailyTodoTask task in tasks) {
      if (task.dateIso != dateIso) continue;
      blocks.add(
        DayScheduleBlock(
          id: task.id,
          isFromTimetable: false,
          title: task.title,
          category: task.category,
          startMinutes: task.startMinutes,
          durationMinutes: task.durationMinutes,
          isDone: task.isDone,
          remindOnTime: task.remindOnTime,
          subjectCode: task.subjectCode,
          note: task.note,
          sourceTask: task,
        ),
      );
    }

    blocks.sort((DayScheduleBlock a, DayScheduleBlock b) {
      final int cmp = a.startMinutes.compareTo(b.startMinutes);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return blocks;
  }
}

/// Snapshot JSON gửi sang Android Home Screen Widget (`AppWidgetProvider`).
class ScheduleWidgetSnapshot {
  const ScheduleWidgetSnapshot({
    required this.dateIso,
    required this.weekdayShortVi,
    required this.dayNumberLabel,
    required this.monthLabelVi,
    required this.doneCount,
    required this.totalCount,
    required this.nextAlarmLabelVi,
    required this.items,
  });

  final String dateIso;
  final String weekdayShortVi;
  final String dayNumberLabel;
  final String monthLabelVi;
  final int doneCount;
  final int totalCount;
  final String nextAlarmLabelVi;
  final List<ScheduleWidgetItem> items;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dateIso': dateIso,
        'weekdayShortVi': weekdayShortVi,
        'dayNumberLabel': dayNumberLabel,
        'monthLabelVi': monthLabelVi,
        'doneCount': doneCount,
        'totalCount': totalCount,
        'nextAlarmLabelVi': nextAlarmLabelVi,
        'items': items.map((ScheduleWidgetItem i) => i.toJson()).toList(),
      };
}

class ScheduleWidgetItem {
  const ScheduleWidgetItem({
    required this.timeLabel,
    required this.title,
    required this.categoryLabelVi,
    required this.isDone,
  });

  final String timeLabel;
  final String title;
  final String categoryLabelVi;
  final bool isDone;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timeLabel': timeLabel,
        'title': title,
        'categoryLabelVi': categoryLabelVi,
        'isDone': isDone,
      };
}
