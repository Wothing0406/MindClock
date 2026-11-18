import 'daily_study_plan.dart';
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

/// Hồ sơ học tập cá nhân của học sinh theo `docs/07` và `docs/32 §1`.
class StudyProfile {
  const StudyProfile({
    this.alias = '',
    this.avatarId = 'sunrise',
    this.gradeLevel,
    this.selectedSubjectCodes = const <String>[],
    this.prioritySubjects = const <PrioritySubject>[],
    this.selfAssessments = const <String, SubjectSelfAssessment>{},
    this.confirmedPlan,
    this.goalLabel = '',
    this.alarmOnlyMode = false,
  });

  static const int maxPrioritySubjects = 5;

  final String alias;
  final String avatarId;
  final String? gradeLevel;
  final List<String> selectedSubjectCodes;
  final List<PrioritySubject> prioritySubjects;
  final Map<String, SubjectSelfAssessment> selfAssessments;
  final DailyStudyPlan? confirmedPlan;
  final String goalLabel;
  final bool alarmOnlyMode;

  List<String> get prioritySubjectCodes => prioritySubjects
      .map((PrioritySubject item) => item.subjectCode)
      .toList(growable: false);

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
    String? alias,
    String? avatarId,
    String? gradeLevel,
    bool clearGradeLevel = false,
    List<String>? selectedSubjectCodes,
    List<PrioritySubject>? prioritySubjects,
    Map<String, SubjectSelfAssessment>? selfAssessments,
    DailyStudyPlan? confirmedPlan,
    bool clearConfirmedPlan = false,
    String? goalLabel,
    bool? alarmOnlyMode,
  }) {
    return StudyProfile(
      alias: alias ?? this.alias,
      avatarId: avatarId ?? this.avatarId,
      gradeLevel: clearGradeLevel ? null : (gradeLevel ?? this.gradeLevel),
      selectedSubjectCodes: selectedSubjectCodes ?? this.selectedSubjectCodes,
      prioritySubjects: prioritySubjects ?? this.prioritySubjects,
      selfAssessments: selfAssessments ?? this.selfAssessments,
      confirmedPlan:
          clearConfirmedPlan ? null : (confirmedPlan ?? this.confirmedPlan),
      goalLabel: goalLabel ?? this.goalLabel,
      alarmOnlyMode: alarmOnlyMode ?? this.alarmOnlyMode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'alias': alias,
        'avatarId': avatarId,
        'gradeLevel': gradeLevel,
        'selectedSubjectCodes': selectedSubjectCodes,
        'prioritySubjects':
            prioritySubjects.map((PrioritySubject e) => e.toJson()).toList(),
        'selfAssessments': selfAssessments.map(
          (String key, SubjectSelfAssessment value) =>
              MapEntry<String, String>(key, value.code),
        ),
        'confirmedPlan': confirmedPlan?.toJson(),
        'goalLabel': goalLabel,
        'alarmOnlyMode': alarmOnlyMode,
      };

  factory StudyProfile.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSubjects =
        json['selectedSubjectCodes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawPriorities =
        json['prioritySubjects'] as List<dynamic>? ?? <dynamic>[];
    final Object? rawAssessments = json['selfAssessments'];
    final Map<String, SubjectSelfAssessment> parsedAssessments =
        <String, SubjectSelfAssessment>{};
    if (rawAssessments is Map<String, dynamic>) {
      rawAssessments.forEach((String key, dynamic value) {
        parsedAssessments[key] =
            SubjectSelfAssessment.fromCode(value as String?);
      });
    }
    final Object? rawPlan = json['confirmedPlan'];
    return StudyProfile(
      alias: json['alias'] as String? ?? '',
      avatarId: json['avatarId'] as String? ?? 'sunrise',
      gradeLevel: json['gradeLevel'] as String?,
      selectedSubjectCodes:
          rawSubjects.whereType<String>().toList(growable: false),
      prioritySubjects: rawPriorities
          .whereType<Map<String, dynamic>>()
          .map(PrioritySubject.fromJson)
          .toList(growable: false),
      selfAssessments: parsedAssessments,
      confirmedPlan: rawPlan is Map<String, dynamic>
          ? DailyStudyPlan.fromJson(rawPlan)
          : null,
      goalLabel: json['goalLabel'] as String? ?? '',
      alarmOnlyMode: json['alarmOnlyMode'] as bool? ?? false,
    );
  }
}
