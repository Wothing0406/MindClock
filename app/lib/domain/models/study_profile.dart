import 'subject_catalog.dart';

enum PriorityLevel {
  high,
  medium,
}

class PrioritySubject {
  const PrioritySubject({
    required this.subjectCode,
    required this.level,
  });

  final String subjectCode;
  final PriorityLevel level;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subjectCode': subjectCode,
        'level': level.name,
      };

  factory PrioritySubject.fromJson(Map<String, dynamic> json) {
    final String rawLevel = json['level'] as String? ?? 'high';
    final PriorityLevel level = PriorityLevel.values.firstWhere(
      (PriorityLevel e) => e.name == rawLevel,
      orElse: () => PriorityLevel.high,
    );
    return PrioritySubject(
      subjectCode: json['subjectCode'] as String? ?? '',
      level: level,
    );
  }
}

/// Hồ sơ học tập cá nhân của khách theo `docs/32 §1`.
class StudyProfile {
  const StudyProfile({
    this.gradeLevel,
    this.selectedSubjectCodes = const <String>[],
    this.prioritySubjects = const <PrioritySubject>[],
    this.goalLabel = '',
    this.alarmOnlyMode = false,
  });

  static const int maxPrioritySubjects = 5;

  final String? gradeLevel;
  final List<String> selectedSubjectCodes;
  final List<PrioritySubject> prioritySubjects;
  final String goalLabel;
  final bool alarmOnlyMode;

  bool hasAnyApprovedSubject() {
    for (final String code in selectedSubjectCodes) {
      if (SubjectCatalog.isApproved(code)) return true;
    }
    return false;
  }

  PriorityLevel? priorityOf(String subjectCode) {
    for (final PrioritySubject item in prioritySubjects) {
      if (item.subjectCode == subjectCode) return item.level;
    }
    return null;
  }

  StudyProfile copyWith({
    String? gradeLevel,
    bool clearGradeLevel = false,
    List<String>? selectedSubjectCodes,
    List<PrioritySubject>? prioritySubjects,
    String? goalLabel,
    bool? alarmOnlyMode,
  }) {
    return StudyProfile(
      gradeLevel: clearGradeLevel ? null : (gradeLevel ?? this.gradeLevel),
      selectedSubjectCodes: selectedSubjectCodes ?? this.selectedSubjectCodes,
      prioritySubjects: prioritySubjects ?? this.prioritySubjects,
      goalLabel: goalLabel ?? this.goalLabel,
      alarmOnlyMode: alarmOnlyMode ?? this.alarmOnlyMode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'gradeLevel': gradeLevel,
        'selectedSubjectCodes': selectedSubjectCodes,
        'prioritySubjects':
            prioritySubjects.map((PrioritySubject e) => e.toJson()).toList(),
        'goalLabel': goalLabel,
        'alarmOnlyMode': alarmOnlyMode,
      };

  factory StudyProfile.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSubjects =
        json['selectedSubjectCodes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawPriorities =
        json['prioritySubjects'] as List<dynamic>? ?? <dynamic>[];
    return StudyProfile(
      gradeLevel: json['gradeLevel'] as String?,
      selectedSubjectCodes:
          rawSubjects.whereType<String>().toList(growable: false),
      prioritySubjects: rawPriorities
          .whereType<Map<String, dynamic>>()
          .map(PrioritySubject.fromJson)
          .toList(growable: false),
      goalLabel: json['goalLabel'] as String? ?? '',
      alarmOnlyMode: json['alarmOnlyMode'] as bool? ?? false,
    );
  }
}
