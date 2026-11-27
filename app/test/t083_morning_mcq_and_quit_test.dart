import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';
import 'package:mindclock_app/ui/features/personal_flow/views/practice_session_screen.dart';

class _T083AuthGateway extends DebugFixtureAuthGateway {
  @override
  bool get isDebugFixture => false;
}

class _T083CameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async =>
      const CameraCaptureOutcome(status: CameraCaptureStatus.unavailable);
}

class _T083FakeRepo extends DebugFixturePersonalFlowRepository {
  @override
  bool get isDebugFixture => false;

  bool abandonedImmediateCalled = false;
  int? submittedMcqIndex;

  @override
  Future<ChallengeQuestion> fetchNextChallenge({
    required String localDate,
    String? subjectCode,
    String mode = 'bank',
    String? difficulty,
  }) async {
    return ChallengeQuestion(
      questionId: 'q_t083_mcq',
      questionRevision: 1,
      validForDate: localDate,
      subjectCode: 'TIENG_ANH',
      topicId: 'Unit 3 · Tuần 12',
      difficulty: 1,
      prompt: 'Chọn nghĩa đúng của từ "resilient":',
      reasoningPromptVi: 'Chạm 1 đáp án đúng bên dưới.',
      offlinePolicy: 'ungraded_only',
      estimatedSeconds: 25,
      questionFormat: 'mcq',
      options: const <String>[
        'Kiên cường, mau phục hồi',
        'Dễ vỡ',
        'Thờ ơ',
        'Chần chừ',
      ],
      sourceScheduleReasonVi: 'Đọc từ TKB Thứ 6 hôm nay',
      schoolWeek: 12,
      currentChapter: 'Unit 3–4',
    );
  }

  @override
  Future<GradingResult> submitTextAnswer({
    required String sessionId,
    required String answerValue,
    required String reasoningText,
    required String clientAttemptId,
    required String idempotencyKey,
    int? selectedIndex,
    List<int>? quizAnswers,
  }) async {
    submittedMcqIndex = selectedIndex;
    return const GradingResult(
      attemptId: 'att_mcq_1',
      verdict: GradingVerdict.correct,
      observedSteps: <String>[],
      firstIssue: null,
      feedbackVi: 'Chính xác! Ghi nhận +10 XP.',
      hintVi: null,
      nextActions: <String>['finish'],
      xpAwarded: 10,
      modelVersion: 'mcq-grader',
      rubricRevision: 1,
      isServerAuthoritative: true,
      scorePercent: 100,
      masteryScore: 56,
    );
  }

  @override
  Future<SessionAbandonResult> abandonSession({
    required String sessionId,
    required String idempotencyKey,
    bool immediate = false,
  }) async {
    abandonedImmediateCalled = immediate;
    return const SessionAbandonResult(
      sessionId: 'sess_1',
      state: 'abandoned',
      version: 2,
      confirmedIncorrectCount: 0,
      xpAwarded: 0,
      streakDayAwarded: false,
      messageVi: 'Đã bỏ cuộc câu này (0 EXP).',
      revealVi: 'Đáp án đúng là A.',
    );
  }
}

void main() {
  testWidgets(
    'T083: PracticeSessionScreen hiển thị nguồn TKB, 4 nút ABCD 1 chạm, nút Bỏ cuộc và bỏ bước chụp ảnh ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();

      final _T083FakeRepo repo = _T083FakeRepo();
      final PersonalFlowViewModel pvm = PersonalFlowViewModel(
        repository: repo,
        authGateway: _T083AuthGateway(),
        cameraGateway: _T083CameraGateway(),
        draftStore: OfflineTextDraftStore(store: store),
      );
      addTearDown(pvm.dispose);
      await pvm.signIn(email: 't083@mindclock.vn', password: 'Password@123');

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: PracticeSessionScreen(
                guestViewModel: guestVm,
                personalViewModel: pvm,
                onOpenProfileSetup: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('practice-start-challenge')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('practice-start-challenge')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('practice-schedule-reason')),
        findsOneWidget,
      );
      expect(find.text('Đọc từ TKB Thứ 6 hôm nay'), findsOneWidget);
      expect(find.text('Tuần 12'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('practice-mcq-option-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('practice-capture-photo')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('practice-quit-challenge')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('practice-quit-challenge')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('practice-quit-challenge')),
      );
      await tester.pumpAndSettle();
      expect(repo.abandonedImmediateCalled, isTrue);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('practice-start-challenge')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('practice-start-challenge')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('practice-mcq-option-0')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('practice-mcq-option-0')),
      );
      await tester.pumpAndSettle();

      expect(repo.submittedMcqIndex, 0);
      expect(find.text('Kết quả: Đúng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
