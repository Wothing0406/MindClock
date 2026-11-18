/// Mức tự đánh giá ban đầu theo từng môn (`docs/01-product/07`).
///
/// Đây chỉ là điểm khởi đầu do học sinh tự chọn, KHÔNG phải chẩn đoán năng lực.
enum SubjectSelfAssessment {
  beginner('beginner', 'Mới bắt đầu', 15),
  basic('basic', 'Cơ bản', 15),
  examPrep('exam_prep', 'Đang ôn thi', 25),
  challenge('challenge', 'Muốn thử thách', 20);

  const SubjectSelfAssessment(
    this.code,
    this.labelVi,
    this.suggestedMinutes,
  );

  final String code;
  final String labelVi;
  final int suggestedMinutes;

  SubjectSelfAssessment get next {
    final int idx = SubjectSelfAssessment.values.indexOf(this);
    return SubjectSelfAssessment
        .values[(idx + 1) % SubjectSelfAssessment.values.length];
  }

  static SubjectSelfAssessment fromCode(String? raw) {
    for (final SubjectSelfAssessment value in SubjectSelfAssessment.values) {
      if (value.code == raw || value.name == raw) return value;
    }
    return SubjectSelfAssessment.basic;
  }
}

/// Một mục việc cụ thể trong bản kế hoạch học hôm nay (tối đa 3 việc/ngày, 10–25 phút).
class DailyPlanItem {
  const DailyPlanItem({
    required this.subjectCode,
    required this.subjectNameVi,
    required this.titleVi,
    required this.durationMinutes,
    required this.reasonVi,
    required this.hasApprovedQuestions,
    this.assessment = SubjectSelfAssessment.basic,
  });

  final String subjectCode;
  final String subjectNameVi;
  final String titleVi;
  final int durationMinutes;
  final String reasonVi;
  final bool hasApprovedQuestions;
  final SubjectSelfAssessment assessment;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subjectCode': subjectCode,
        'subjectNameVi': subjectNameVi,
        'titleVi': titleVi,
        'durationMinutes': durationMinutes,
        'reasonVi': reasonVi,
        'hasApprovedQuestions': hasApprovedQuestions,
        'assessment': assessment.code,
      };

  factory DailyPlanItem.fromJson(Map<String, dynamic> json) {
    final int rawDuration = (json['durationMinutes'] as num?)?.toInt() ?? 15;
    final int clampedDuration = rawDuration.clamp(10, 25);
    return DailyPlanItem(
      subjectCode: json['subjectCode'] as String? ?? 'math',
      subjectNameVi: json['subjectNameVi'] as String? ?? 'Toán',
      titleVi: json['titleVi'] as String? ?? 'Ôn tập trọng tâm',
      durationMinutes: clampedDuration,
      reasonVi: json['reasonVi'] as String? ?? '',
      hasApprovedQuestions: json['hasApprovedQuestions'] as bool? ?? false,
      assessment: SubjectSelfAssessment.fromCode(json['assessment'] as String?),
    );
  }
}

/// Bản kế hoạch ngày có nguồn rõ ràng (`rule_based` hoặc `ai_assisted`), cần người dùng xác nhận.
class DailyStudyPlan {
  const DailyStudyPlan({
    required this.plannerRuleVersion,
    required this.catalogVersion,
    required this.source,
    required this.sourceLabelVi,
    required this.gradeLevel,
    required this.items,
    required this.confirmedAtIso,
  });

  static const String currentRuleVersion = 'rule-plan-v0.1';
  static const String currentCatalogVersion = 'gdpt-2018-v1';

  final String plannerRuleVersion;
  final String catalogVersion;
  final String source; // 'rule_based' | 'ai_assisted'
  final String sourceLabelVi;
  final String gradeLevel;
  final List<DailyPlanItem> items;
  final String? confirmedAtIso;

  bool get isConfirmed => confirmedAtIso != null && confirmedAtIso!.isNotEmpty;

  DailyStudyPlan markConfirmed(DateTime now) {
    return DailyStudyPlan(
      plannerRuleVersion: plannerRuleVersion,
      catalogVersion: catalogVersion,
      source: source,
      sourceLabelVi: sourceLabelVi,
      gradeLevel: gradeLevel,
      items: items,
      confirmedAtIso: now.toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'plannerRuleVersion': plannerRuleVersion,
        'catalogVersion': catalogVersion,
        'source': source,
        'sourceLabelVi': sourceLabelVi,
        'gradeLevel': gradeLevel,
        'items': items.map((DailyPlanItem e) => e.toJson()).toList(),
        'confirmedAtIso': confirmedAtIso,
      };

  factory DailyStudyPlan.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? <dynamic>[];
    return DailyStudyPlan(
      plannerRuleVersion:
          json['plannerRuleVersion'] as String? ?? currentRuleVersion,
      catalogVersion:
          json['catalogVersion'] as String? ?? currentCatalogVersion,
      source: json['source'] as String? ?? 'rule_based',
      sourceLabelVi: json['sourceLabelVi'] as String? ??
          'Kế hoạch cơ bản · Chưa có gợi ý AI',
      gradeLevel: json['gradeLevel'] as String? ?? 'Lớp 10',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(DailyPlanItem.fromJson)
          .take(3)
          .toList(growable: false),
      confirmedAtIso: json['confirmedAtIso'] as String?,
    );
  }
}
