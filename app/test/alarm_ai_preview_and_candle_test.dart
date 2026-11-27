import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_study_ai_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/study_ai_models.dart';
import 'package:mindclock_app/domain/models/study_focus_models.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/models/timetable.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/alarm_config_screen.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _TestClock {
  _TestClock(this.now);
  DateTime now;
}

class _TrackingAiGateway extends DebugFixtureStudyAiGateway {
  _TrackingAiGateway({this.shouldThrow = false});

  final bool shouldThrow;
  final List<String> requestedSubjects = <String>[];
  final List<String?> requestedGrades = <String?>[];
  int callCount = 0;

  @override
  Future<PersonalizedPracticeQuestion> generatePersonalizedQuestion({
    required String subjectCode,
    String? gradeLevel,
    String? topicHint,
    int difficulty = 1,
    required String idempotencyKey,
  }) async {
    callCount += 1;
    requestedSubjects.add(subjectCode);
    requestedGrades.add(gradeLevel);
    if (shouldThrow) {
      throw StateError('offline');
    }
    return PersonalizedPracticeQuestion(
      questionId: 'ai_prev_$callCount',
      subjectCode: subjectCode,
      gradeBand: gradeLevel ?? 'Lớp 12',
      topicId: 'topic_$subjectCode',
      difficulty: difficulty,
      prompt:
          'Câu AI #$callCount ($subjectCode · ${gradeLevel ?? "THPT"}): Con lắc lò xo dao động với f = 2 Hz, tính chu kỳ T (s).',
      reasoningPromptVi: 'Nêu công thức T = 1/f rồi thay số.',
      steps: const <String>['Bước 1: T = 1 / f', 'Bước 2: T = 0,5 s'],
      hintVi: 'Chu kỳ là nghịch đảo tần số.',
      status: 'draft',
      sourceType: 'ai_personalized_preview',
      modelVersion: 'gemini-test',
      xpAwarded: 0,
      fallbackUsed: false,
    );
  }
}

void main() {
  testWidgets(
    'T059 TC-01 & TC-02: Study Space lọc đúng môn Profile và Đốt nến đếm giờ tự do vượt 120 phút ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _TestClock clock = _TestClock(DateTime(2026, 11, 20, 8, 0));
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      await guestVm.saveStudyProfile(
        const StudyProfile(
          alias: 'Bảo Ngọc',
          gradeLevel: 'Lớp 12',
          selectedSubjectCodes: <String>['math', 'physics', 'english'],
          prioritySubjects: <PrioritySubject>[
            PrioritySubject(subjectCode: 'physics', level: PriorityLevel.high),
          ],
          goalLabel: 'Ôn thi đại học',
        ),
      );

      final StudyFocusViewModel studyVm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        nowProvider: () => clock.now,
        enablePeriodicTicker: false,
      );
      await studyVm.initialize(ownerScopeKey: 'user_ngoc');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2.0),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: StudySpaceScreen(
              guestViewModel: guestVm,
              studyViewModel: studyVm,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // AC-01: Chỉ hiện đúng 3 môn trong StudyProfile, không hiện môn ngoài hồ sơ
      expect(
        find.byKey(const ValueKey<String>('study-profile-subject-math')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('study-profile-subject-physics')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('study-profile-subject-english')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('study-profile-subject-chemistry')),
        findsNothing,
      );

      // Có mốc > 120 phút (150 phút) cho Đếm ngược
      expect(
        find.byKey(const ValueKey<String>('study-duration-150')),
        findsOneWidget,
      );

      // AC-02: Chọn Đốt nến · Đếm giờ tự do và bắt đầu phiên
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('study-timing-candle')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('study-timing-candle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('study-candle-mode-info')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('study-start-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('study-start-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('study-candle-timer')),
        findsOneWidget,
      );

      // Tiến thời gian lên 150 phút (vượt 120p) -> KHÔNG tự cắt phiên!
      clock.now = clock.now.add(const Duration(minutes: 150));
      studyVm.checkClockTick();
      await tester.pumpAndSettle();

      expect(studyVm.activeSnapshot!.status, StudyFocusStatus.running);
      expect(studyVm.displayClockSeconds, 150 * 60);
      expect(
        find.byKey(const ValueKey<String>('study-long-session-rest-banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('study-candle-over-120-pill')),
        findsOneWidget,
      );
      expect(find.text('02:30:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'T059 TC-03: AlarmConfigScreen tự tạo câu thử thách AI theo TKB + Profile & fallback offline',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      await guestVm.saveStudyProfile(
        const StudyProfile(
          alias: 'Gia Huy',
          gradeLevel: 'Lớp 12',
          selectedSubjectCodes: <String>['math', 'physics'],
          prioritySubjects: <PrioritySubject>[
            PrioritySubject(subjectCode: 'math', level: PriorityLevel.high),
          ],
          goalLabel: 'Mục tiêu Bách Khoa',
        ),
      );

      final WeeklyTimetable baseTkb = WeeklyTimetable();
      final WeeklyTimetable updatedTkb = WeeklyTimetable(
        days: baseTkb.days.map((DaySchedule d) {
          if (d.weekday == 1) {
            return d.copyWith(
              isRestDay: false,
              entries: const <TimetableEntry>[
                TimetableEntry(
                  id: 't1',
                  subjectCode: 'physics',
                  startMinutes: 7 * 60,
                ),
              ],
            );
          }
          return d.copyWith(isRestDay: true, entries: const <TimetableEntry>[]);
        }).toList(growable: false),
      );
      await guestVm.replaceEntireTimetable(updatedTkb);

      // Bắt đầu trên 1 ngày cụ thể hoặc chỉnh weekday lặp về Thứ 2
      final _TrackingAiGateway onlineGateway = _TrackingAiGateway();

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: AlarmConfigScreen(
            viewModel: guestVm,
            studyAiGateway: onlineGateway,
            onSaved: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tắt hết T3..T5, giữ đúng Thứ 2 (weekday 1) có Vật lí trên TKB
      for (final int d in <int>[2, 3, 4, 5]) {
        await tester.ensureVisible(
          find.byKey(ValueKey<String>('repeat-day-$d')),
        );
        await tester.tap(find.byKey(ValueKey<String>('repeat-day-$d')));
        await tester.pumpAndSettle();
      }

      expect(
        find.byKey(const ValueKey<String>('alarm-ai-challenge-preview')),
        findsOneWidget,
      );
      expect(onlineGateway.requestedSubjects.last, 'physics');
      expect(onlineGateway.requestedGrades.last, 'Lớp 12');
      // T089: Không lộ đề bài trước khi chuông reo trên AlarmConfigScreen
      expect(find.textContaining('Con lắc lò xo dao động'), findsNothing);
      expect(find.text('Đã chuẩn bị sẵn đề'), findsOneWidget);

      // Tạo lại câu AI mẫu bằng nút
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('alarm-regenerate-challenge')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('alarm-regenerate-challenge')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Câu AI #'), findsNothing);
      expect(find.text('Đã chuẩn bị sẵn đề'), findsOneWidget);

      // Kiểm tra fallback offline khi AI lỗi mạng
      final _TrackingAiGateway offlineGateway =
          _TrackingAiGateway(shouldThrow: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: AlarmConfigScreen(
            key: const ValueKey<String>('alarm-config-offline'),
            viewModel: guestVm,
            studyAiGateway: offlineGateway,
            onSaved: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('alarm-ai-challenge-preview')),
        findsOneWidget,
      );
      expect(find.textContaining('Ẩn đề tới khi reo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
