import '../models/daily_study_plan.dart';
import '../models/study_profile.dart';
import '../models/subject_catalog.dart';

/// Máy lập kế hoạch nháp rule-based (`docs/01-product/07`, `docs/02-engineering/10`).
///
/// Bất biến:
/// - Tối đa 3 việc mỗi ngày, mỗi việc 10–25 phút.
/// - Không tự đặt báo thức, không tự bật thông báo.
/// - Môn chưa có ngân hàng câu hỏi duyệt ghi rõ `hasApprovedQuestions = false`.
/// - Luôn hoạt động khi offline hoặc khi AI lỗi/không có quota.
class RuleBasedPlanGenerator {
  const RuleBasedPlanGenerator._();

  static const int maxItemsPerDay = 3;

  static DailyStudyPlan generateDraft({
    required String? gradeLevel,
    required List<String> selectedSubjectCodes,
    required Map<String, SubjectSelfAssessment> selfAssessments,
    required List<PrioritySubject> prioritySubjects,
    String goalLabel = '',
  }) {
    final String effectiveGrade =
        (gradeLevel != null && gradeLevel.trim().isNotEmpty)
            ? gradeLevel.trim()
            : 'Lớp 10';

    if (selectedSubjectCodes.isEmpty) {
      return DailyStudyPlan(
        plannerRuleVersion: DailyStudyPlan.currentRuleVersion,
        catalogVersion: DailyStudyPlan.currentCatalogVersion,
        source: 'rule_based',
        sourceLabelVi: 'Kế hoạch cơ bản · Chưa có gợi ý AI',
        gradeLevel: effectiveGrade,
        items: const <DailyPlanItem>[
          DailyPlanItem(
            subjectCode: 'math',
            subjectNameVi: 'Toán',
            titleVi: 'Ôn 1 bài ngắn làm quen (15 phút)',
            durationMinutes: 15,
            reasonVi:
                'Chưa chọn môn cụ thể — gợi ý 1 lượt ôn cơ bản để bạn dễ bắt đầu và có thể đổi môn bất kỳ lúc nào.',
            hasApprovedQuestions: true,
            assessment: SubjectSelfAssessment.basic,
          ),
        ],
        confirmedAtIso: null,
      );
    }

    final Map<String, PriorityLevel> priorityMap = <String, PriorityLevel>{
      for (final PrioritySubject p in prioritySubjects) p.subjectCode: p.level,
    };

    // Sắp xếp ưu tiên xác định: Đang ôn thi > Mới bắt đầu > ưu tiên cao > có câu duyệt > thứ tự chọn
    final List<String> rankedCodes = List<String>.from(selectedSubjectCodes);
    rankedCodes.sort((String a, String b) {
      final int scoreB = _rankScore(b, selfAssessments[b], priorityMap[b]);
      final int scoreA = _rankScore(a, selfAssessments[a], priorityMap[a]);
      if (scoreB != scoreA) return scoreB.compareTo(scoreA);
      return selectedSubjectCodes
          .indexOf(a)
          .compareTo(selectedSubjectCodes.indexOf(b));
    });

    final List<DailyPlanItem> items = <DailyPlanItem>[];
    for (final String code in rankedCodes.take(maxItemsPerDay)) {
      final String name = SubjectCatalog.nameFor(code);
      final bool approved = SubjectCatalog.isApproved(code);
      final SubjectSelfAssessment assessment =
          selfAssessments[code] ?? _fallbackAssessment(priorityMap[code]);
      final int minutes = assessment.suggestedMinutes.clamp(10, 25);

      final String titleVi = approved
          ? 'Ôn trọng tâm $name ($effectiveGrade · $minutes phút)'
          : 'Tự đọc/ghi chú $name ($effectiveGrade · $minutes phút)';

      final String reasonVi = approved
          ? 'Mức tự đánh giá: ${assessment.labelVi}. Có câu ôn đã duyệt để khởi động nhẹ trước khi vào bài.'
          : 'Mức tự đánh giá: ${assessment.labelVi}. Chưa có câu ôn được duyệt — dùng cho nhắc học & tự ôn, không chấm điểm tự động.';

      items.add(
        DailyPlanItem(
          subjectCode: code,
          subjectNameVi: name,
          titleVi: titleVi,
          durationMinutes: minutes,
          reasonVi: reasonVi,
          hasApprovedQuestions: approved,
          assessment: assessment,
        ),
      );
    }

    return DailyStudyPlan(
      plannerRuleVersion: DailyStudyPlan.currentRuleVersion,
      catalogVersion: DailyStudyPlan.currentCatalogVersion,
      source: 'rule_based',
      sourceLabelVi: 'Kế hoạch cơ bản · Chưa có gợi ý AI',
      gradeLevel: effectiveGrade,
      items: List<DailyPlanItem>.unmodifiable(items),
      confirmedAtIso: null,
    );
  }

  static int _rankScore(
    String subjectCode,
    SubjectSelfAssessment? assessment,
    PriorityLevel? priority,
  ) {
    int score = 0;
    switch (assessment) {
      case SubjectSelfAssessment.examPrep:
        score += 40;
        break;
      case SubjectSelfAssessment.beginner:
        score += 30;
        break;
      case SubjectSelfAssessment.challenge:
        score += 20;
        break;
      case SubjectSelfAssessment.basic:
      case null:
        score += 10;
        break;
    }
    if (priority == PriorityLevel.high) {
      score += 15;
    } else if (priority == PriorityLevel.medium) {
      score += 5;
    }
    if (SubjectCatalog.isApproved(subjectCode)) {
      score += 8;
    }
    return score;
  }

  static SubjectSelfAssessment _fallbackAssessment(PriorityLevel? priority) {
    if (priority == PriorityLevel.high) return SubjectSelfAssessment.examPrep;
    if (priority == PriorityLevel.medium) return SubjectSelfAssessment.basic;
    return SubjectSelfAssessment.basic;
  }
}
