import '../models/alarm_config.dart';
import '../models/study_profile.dart';
import '../models/subject_catalog.dart';
import '../models/timetable.dart';

/// Đề xuất câu hỏi ôn tập buổi sáng với lý do minh bạch theo chuẩn Bộ GD&ĐT.
class MorningQuestionProposal {
  const MorningQuestionProposal({
    required this.subjectCode,
    required this.subjectNameVi,
    required this.topicId,
    required this.topicNameVi,
    required this.hasApprovedQuestions,
    required this.difficultyBand,
    required this.estimatedMinutes,
    required this.learningOutcomeVi,
    required this.ruleApplied,
    required this.explanationVi,
    this.suggestedApprovedSubjectCode,
    this.sampleQuestionPrompt,
    this.questionId,
  });

  final String subjectCode;
  final String subjectNameVi;
  final String topicId;
  final String topicNameVi;
  final bool hasApprovedQuestions;
  final int difficultyBand; // 1: Nhận biết, 2: Thông hiểu, 3: Vận dụng
  final int estimatedMinutes; // 1..3 phút
  final String learningOutcomeVi;
  final AlarmSubjectRule ruleApplied;
  final String explanationVi;
  final String? suggestedApprovedSubjectCode;
  final String? sampleQuestionPrompt;
  final String? questionId;

  String get difficultyLabelVi {
    switch (difficultyBand) {
      case 1:
        return 'Nhận biết (1-2 phút)';
      case 2:
        return 'Thông hiểu (2 phút)';
      case 3:
      default:
        return 'Vận dụng (2-3 phút)';
    }
  }
}

/// Dịch vụ phân giải câu hỏi ôn sáng theo thứ tự ưu tiên minh bạch:
/// 1. Khối lớp THPT (10, 11, 12).
/// 2. Quy tắc môn [AlarmSubjectRule] (Lịch học hôm nay, Ưu tiên môn yếu, Môn cố định).
/// 3. Chủ đề cần cải thiện trong hồ sơ học sinh.
/// 4. Ngân hàng câu hỏi đã duyệt ([SubjectCatalog.isApproved]).
/// 5. Tránh lặp câu hỏi vừa hoàn thành ở phiên gần nhất.
class MorningQuestionSelector {
  const MorningQuestionSelector._();

  static MorningQuestionProposal resolveForAlarm({
    required AlarmConfig alarm,
    required StudyProfile profile,
    required WeeklyTimetable timetable,
    required int weekday, // 1 = T2 ... 7 = CN
    String? lastCompletedQuestionId,
  }) {
    if (alarm.subjectRule == AlarmSubjectRule.none) {
      return const MorningQuestionProposal(
        subjectCode: '',
        subjectNameVi: 'Không kèm câu hỏi',
        topicId: 'none',
        topicNameVi: 'Chỉ báo thức',
        hasApprovedQuestions: false,
        difficultyBand: 1,
        estimatedMinutes: 0,
        learningOutcomeVi: 'Báo thức âm thanh / rung thuần túy, không có câu hỏi mở màn.',
        ruleApplied: AlarmSubjectRule.none,
        explanationVi: 'Chế độ chỉ báo thức: Chuông reo bình thường, không yêu cầu làm câu hỏi.',
      );
    }

    String resolvedSubject = 'math';
    String explanation = '';

    switch (alarm.subjectRule) {
      case AlarmSubjectRule.todaySchedule:
        final DaySchedule? day = timetable.days.cast<DaySchedule?>().firstWhere(
              (DaySchedule? d) => d?.weekday == weekday,
              orElse: () => null,
            );
        final List<TimetableEntry> entries = day?.sortedEntries ?? <TimetableEntry>[];
        if (entries.isNotEmpty) {
          final TimetableEntry firstEntry = entries.first;
          resolvedSubject = firstEntry.subjectCode;
          final String dayLabel = _weekdayLabel(weekday);
          explanation =
              'Theo lịch học $dayLabel: Tiết đầu lúc ${firstEntry.formattedStartTime} là môn ${SubjectCatalog.nameFor(resolvedSubject)}.';
        } else {
          resolvedSubject = _findTopPrioritySubject(profile);
          final String dayLabel = _weekdayLabel(weekday);
          explanation =
              '$dayLabel không có tiết trên TKB: Tự động ôn môn ưu tiên trong hồ sơ (${SubjectCatalog.nameFor(resolvedSubject)}).';
        }
        break;

      case AlarmSubjectRule.priorityWeak:
        resolvedSubject = _findTopPrioritySubject(profile);
        explanation =
            'Ưu tiên môn trọng tâm trong hồ sơ ôn thi (${SubjectCatalog.nameFor(resolvedSubject)}).';
        break;

      case AlarmSubjectRule.fixedSubject:
        resolvedSubject = alarm.subjectCode?.trim().isNotEmpty == true
            ? alarm.subjectCode!
            : 'math';
        explanation =
            'Môn cố định do bạn chọn (${SubjectCatalog.nameFor(resolvedSubject)}).';
        break;

      case AlarmSubjectRule.none:
        break;
    }

    final bool isApproved = SubjectCatalog.isApproved(resolvedSubject);
    final String subjectName = SubjectCatalog.nameFor(resolvedSubject);

    if (!isApproved) {
      final String fallbackApproved = _findApprovedFallback(profile);
      return MorningQuestionProposal(
        subjectCode: resolvedSubject,
        subjectNameVi: subjectName,
        topicId: 'unapproved_subject',
        topicNameVi: 'Chưa có câu hỏi duyệt',
        hasApprovedQuestions: false,
        difficultyBand: 1,
        estimatedMinutes: 1,
        learningOutcomeVi: 'Ngân hàng đề đang cập nhật chuẩn Bộ GD&ĐT cho môn $subjectName.',
        ruleApplied: alarm.subjectRule,
        explanationVi:
            'Môn $subjectName chưa có bộ câu hỏi được kiểm duyệt trong ngân hàng. App sẽ báo thức chuông bình thường hoặc bạn có thể đổi sang ôn ${SubjectCatalog.nameFor(fallbackApproved)}.',
        suggestedApprovedSubjectCode: fallbackApproved,
      );
    }

    return _buildApprovedProposal(
      subjectCode: resolvedSubject,
      gradeLevel: profile.gradeLevel ?? 'Lớp 10',
      ruleApplied: alarm.subjectRule,
      explanationVi: explanation,
      lastQuestionId: lastCompletedQuestionId,
    );
  }

  static String _findTopPrioritySubject(StudyProfile profile) {
    if (profile.prioritySubjects.isNotEmpty) {
      return profile.prioritySubjects.first.subjectCode;
    }
    if (profile.selectedSubjectCodes.isNotEmpty) {
      return profile.selectedSubjectCodes.first;
    }
    return 'math';
  }

  static String _findApprovedFallback(StudyProfile profile) {
    for (final PrioritySubject ps in profile.prioritySubjects) {
      if (SubjectCatalog.isApproved(ps.subjectCode)) return ps.subjectCode;
    }
    for (final String code in profile.selectedSubjectCodes) {
      if (SubjectCatalog.isApproved(code)) return code;
    }
    return 'math';
  }

  static String _weekdayLabel(int weekday) {
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
        return 'Chủ nhật';
      default:
        return 'Thứ $weekday';
    }
  }

  static MorningQuestionProposal _buildApprovedProposal({
    required String subjectCode,
    required String gradeLevel,
    required AlarmSubjectRule ruleApplied,
    required String explanationVi,
    String? lastQuestionId,
  }) {
    final String subjectName = SubjectCatalog.nameFor(subjectCode);

    if (subjectCode == 'math') {
      if (gradeLevel.contains('12')) {
        final bool pickSecond = lastQuestionId == 'mc-math-12-001';
        return MorningQuestionProposal(
          subjectCode: 'math',
          subjectNameVi: subjectName,
          topicId: pickSecond ? 'anti_derivative_integral' : 'function_monotonicity',
          topicNameVi: pickSecond ? 'Nguyên hàm & Tích phân' : 'Tính đơn điệu của hàm số',
          hasApprovedQuestions: true,
          difficultyBand: 2,
          estimatedMinutes: 2,
          learningOutcomeVi: pickSecond
              ? 'Áp dụng bảng nguyên hàm cơ bản để tính tích phân đơn giản'
              : 'Xác định khoảng đồng biến/nghịch biến qua dấu của đạo hàm y\'',
          ruleApplied: ruleApplied,
          explanationVi: explanationVi,
          questionId: pickSecond ? 'mc-math-12-002' : 'mc-math-12-001',
          sampleQuestionPrompt: pickSecond
              ? 'Tính nguyên hàm của hàm số f(x) = 3x^2 + 2x.'
              : 'Cho hàm số y = x^3 - 3x. Tìm khoảng đồng biến của hàm số.',
        );
      } else if (gradeLevel.contains('11')) {
        return MorningQuestionProposal(
          subjectCode: 'math',
          subjectNameVi: subjectName,
          topicId: 'trig_equations',
          topicNameVi: 'Phương trình lượng giác cơ bản',
          hasApprovedQuestions: true,
          difficultyBand: 2,
          estimatedMinutes: 2,
          learningOutcomeVi: 'Nghiệm của phương trình sin(x) = a và cos(x) = b trên đường tròn',
          ruleApplied: ruleApplied,
          explanationVi: explanationVi,
          questionId: 'mc-math-11-001',
          sampleQuestionPrompt: 'Giải phương trình sin(x) = 1/2 trên đoạn [0; pi].',
        );
      } else {
        return MorningQuestionProposal(
          subjectCode: 'math',
          subjectNameVi: subjectName,
          topicId: 'quadratic_function',
          topicNameVi: 'Hàm số bậc hai & Đỉnh parabol',
          hasApprovedQuestions: true,
          difficultyBand: 1,
          estimatedMinutes: 1,
          learningOutcomeVi: 'Nhận biết toạ độ đỉnh I(-b/2a; -delta/4a) và trục đối xứng',
          ruleApplied: ruleApplied,
          explanationVi: explanationVi,
          questionId: 'mc-math-10-001',
          sampleQuestionPrompt: 'Tìm toạ độ đỉnh của parabol y = x^2 - 4x + 3.',
        );
      }
    }

    if (subjectCode == 'english') {
      return MorningQuestionProposal(
        subjectCode: 'english',
        subjectNameVi: subjectName,
        topicId: 'conditional_sentences',
        topicNameVi: 'Câu điều kiện loại 1 & 2',
        hasApprovedQuestions: true,
        difficultyBand: 1,
        estimatedMinutes: 1,
        learningOutcomeVi: 'Phân biệt cấu trúc điều kiện có thực và giả định ở hiện tại',
        ruleApplied: ruleApplied,
        explanationVi: explanationVi,
        questionId: 'mc-eng-10-001',
        sampleQuestionPrompt: 'If it (rain) ______ tomorrow, we will postpone the study session.',
      );
    }

    if (subjectCode == 'biology') {
      return MorningQuestionProposal(
        subjectCode: 'biology',
        subjectNameVi: subjectName,
        topicId: 'cellular_respiration',
        topicNameVi: 'Hô hấp tế bào & Ty thể',
        hasApprovedQuestions: true,
        difficultyBand: 2,
        estimatedMinutes: 2,
        learningOutcomeVi: 'Xác định các giai đoạn đường phân, chu trình Krebs và chuỗi truyền e-',
        ruleApplied: ruleApplied,
        explanationVi: explanationVi,
        questionId: 'mc-bio-10-001',
        sampleQuestionPrompt: 'Giai đoạn nào trong hô hấp tế bào giải phóng nhiều phân tử ATP nhất?',
      );
    }

    return MorningQuestionProposal(
      subjectCode: subjectCode,
      subjectNameVi: subjectName,
      topicId: 'core_review',
      topicNameVi: 'Ôn tập kiến thức trọng tâm',
      hasApprovedQuestions: true,
      difficultyBand: 1,
      estimatedMinutes: 2,
      learningOutcomeVi: 'Củng cố định nghĩa và kỹ năng giải toán cơ bản',
      ruleApplied: ruleApplied,
      explanationVi: explanationVi,
      questionId: 'mc-$subjectCode-default',
      sampleQuestionPrompt: 'Câu hỏi ôn tập buổi sáng 1-2 phút cho môn $subjectName.',
    );
  }
}
