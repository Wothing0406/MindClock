import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/models/timetable.dart';
import 'package:mindclock_app/domain/services/morning_question_selector.dart';

void main() {
  group('MorningQuestionSelector Tests', () {
    const StudyProfile mockProfile = StudyProfile(
      alias: 'Minh',
      gradeLevel: 'Lớp 12',
      selectedSubjectCodes: <String>['math', 'english', 'biology'],
      prioritySubjects: <PrioritySubject>[
        PrioritySubject(subjectCode: 'math', level: PriorityLevel.high),
        PrioritySubject(subjectCode: 'english', level: PriorityLevel.medium),
      ],
    );

    final WeeklyTimetable mockTimetable = WeeklyTimetable(
      days: <DaySchedule>[
        const DaySchedule(
          weekday: 1, // Thứ 2
          entries: <TimetableEntry>[
            TimetableEntry(id: 't2-1', subjectCode: 'english', startMinutes: 420),
            TimetableEntry(id: 't2-2', subjectCode: 'math', startMinutes: 470),
          ],
        ),
        const DaySchedule(
          weekday: 2, // Thứ 3
          entries: <TimetableEntry>[
            TimetableEntry(id: 't3-1', subjectCode: 'physics', startMinutes: 420),
          ],
        ),
        const DaySchedule(
          weekday: 7, // Chủ nhật
          isRestDay: true,
          entries: <TimetableEntry>[],
        ),
      ],
    );

    test('TC-MQS-01: Rule none returns alarm only proposal with 0 minutes', () {
      const AlarmConfig alarm = AlarmConfig(
        id: 'alarm_1',
        hour: 6,
        minute: 0,
        subjectRule: AlarmSubjectRule.none,
      );

      final MorningQuestionProposal proposal = MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: mockProfile,
        timetable: mockTimetable,
        weekday: 1,
      );

      expect(proposal.ruleApplied, AlarmSubjectRule.none);
      expect(proposal.hasApprovedQuestions, isFalse);
      expect(proposal.estimatedMinutes, 0);
      expect(proposal.topicNameVi, 'Chỉ báo thức');
    });

    test('TC-MQS-02: Rule todaySchedule selects earliest period subject of that day', () {
      const AlarmConfig alarm = AlarmConfig(
        id: 'alarm_1',
        hour: 6,
        minute: 0,
        subjectRule: AlarmSubjectRule.todaySchedule,
      );

      final MorningQuestionProposal proposal = MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: mockProfile,
        timetable: mockTimetable,
        weekday: 1, // Thứ 2: Tiết 1 là English
      );

      expect(proposal.ruleApplied, AlarmSubjectRule.todaySchedule);
      expect(proposal.subjectCode, 'english');
      expect(proposal.hasApprovedQuestions, isTrue);
      expect(proposal.explanationVi, contains('Theo lịch học Thứ 2'));
      expect(proposal.explanationVi, contains('Tiết đầu lúc 07:00 là môn Tiếng Anh'));
    });

    test('TC-MQS-03: Rule todaySchedule on rest day falls back to priority subject with explanation', () {
      const AlarmConfig alarm = AlarmConfig(
        id: 'alarm_1',
        hour: 6,
        minute: 0,
        subjectRule: AlarmSubjectRule.todaySchedule,
      );

      final MorningQuestionProposal proposal = MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: mockProfile,
        timetable: mockTimetable,
        weekday: 7, // Chủ nhật: Ngày nghỉ
      );

      expect(proposal.ruleApplied, AlarmSubjectRule.todaySchedule);
      expect(proposal.subjectCode, 'math');
      expect(proposal.hasApprovedQuestions, isTrue);
      expect(proposal.explanationVi, contains('Chủ nhật không có tiết'));
      expect(proposal.explanationVi, contains('Tự động ôn môn ưu tiên trong hồ sơ (Toán)'));
    });

    test('TC-MQS-04: Rule priorityWeak selects top priority subject from profile', () {
      const AlarmConfig alarm = AlarmConfig(
        id: 'alarm_1',
        hour: 6,
        minute: 0,
        subjectRule: AlarmSubjectRule.priorityWeak,
      );

      final MorningQuestionProposal proposal = MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: mockProfile,
        timetable: mockTimetable,
        weekday: 2,
      );

      expect(proposal.ruleApplied, AlarmSubjectRule.priorityWeak);
      expect(proposal.subjectCode, 'math');
      expect(proposal.hasApprovedQuestions, isTrue);
      expect(proposal.topicId, 'function_monotonicity');
      expect(proposal.explanationVi, contains('Ưu tiên môn trọng tâm trong hồ sơ'));
    });

    test('TC-MQS-05: Unapproved subject produces transparent explanation and suggested fallback', () {
      const AlarmConfig alarm = AlarmConfig(
        id: 'alarm_1',
        hour: 6,
        minute: 0,
        subjectRule: AlarmSubjectRule.fixedSubject,
        subjectCode: 'physics', // Vật lí: hasApprovedQuestions == false
      );

      final MorningQuestionProposal proposal = MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: mockProfile,
        timetable: mockTimetable,
        weekday: 1,
      );

      expect(proposal.hasApprovedQuestions, isFalse);
      expect(proposal.subjectCode, 'physics');
      expect(proposal.explanationVi, contains('chưa có bộ câu hỏi được kiểm duyệt trong ngân hàng'));
      expect(proposal.suggestedApprovedSubjectCode, 'math');
    });

    test('TC-MQS-06: Avoid repeating yesterday question ID for grade 12 math', () {
      const AlarmConfig alarm = AlarmConfig(
        id: 'alarm_1',
        hour: 6,
        minute: 0,
        subjectRule: AlarmSubjectRule.fixedSubject,
        subjectCode: 'math',
      );

      final MorningQuestionProposal proposal1 = MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: mockProfile,
        timetable: mockTimetable,
        weekday: 1,
        lastCompletedQuestionId: null,
      );

      final MorningQuestionProposal proposal2 = MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: mockProfile,
        timetable: mockTimetable,
        weekday: 1,
        lastCompletedQuestionId: 'mc-math-12-001',
      );

      expect(proposal1.questionId, 'mc-math-12-001');
      expect(proposal2.questionId, 'mc-math-12-002');
      expect(proposal1.topicId, isNot(equals(proposal2.topicId)));
    });
  });
}
