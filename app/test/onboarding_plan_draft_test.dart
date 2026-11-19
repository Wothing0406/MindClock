import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/domain/models/daily_study_plan.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/domain/services/rule_based_plan_generator.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _NoopCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(
      status: CameraCaptureStatus.unavailable,
      messageVi: 'Chưa dùng camera',
    );
  }
}

Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.4,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('T049 RuleBasedPlanGenerator & StudyProfile JSON (ON-04, ON-05)', () {
    test('TC-01: Tối đa 3 việc/ngày, 10–25 phút, tôn trọng môn chưa duyệt & ưu tiên mức tự đánh giá', () {
      final DailyStudyPlan plan = RuleBasedPlanGenerator.generateDraft(
        gradeLevel: 'Lớp 12',
        selectedSubjectCodes: const <String>[
          'literature',
          'math',
          'physics',
          'history',
          'english',
        ],
        selfAssessments: const <String, SubjectSelfAssessment>{
          'literature': SubjectSelfAssessment.examPrep,
          'english': SubjectSelfAssessment.beginner,
          'math': SubjectSelfAssessment.basic,
          'history': SubjectSelfAssessment.basic,
          'physics': SubjectSelfAssessment.challenge,
        },
        prioritySubjects: const <PrioritySubject>[],
      );

      expect(plan.plannerRuleVersion, DailyStudyPlan.currentRuleVersion);
      expect(plan.catalogVersion, DailyStudyPlan.currentCatalogVersion);
      expect(plan.source, 'rule_based');
      expect(plan.sourceLabelVi, contains('Chưa có gợi ý AI'));
      expect(plan.items.length, 3);
      for (final DailyPlanItem item in plan.items) {
        expect(item.durationMinutes, inInclusiveRange(10, 25));
      }

      // Ngữ văn (examPrep) đứng đầu nhưng ghi rõ chưa có câu ôn được duyệt
      expect(plan.items.first.subjectCode, 'literature');
      expect(plan.items.first.hasApprovedQuestions, isFalse);
      expect(plan.items.first.reasonVi, contains('Chưa có câu ôn được duyệt'));

      // Tiếng Anh (beginner) có câu duyệt trong SubjectCatalog
      expect(plan.items[1].subjectCode, 'english');
      expect(plan.items[1].hasApprovedQuestions, isTrue);
    });

    test('TC-05a: StudyProfile.fromJson tương thích ngược JSON cũ và lưu/đọc confirmedPlan đầy đủ', () {
      // JSON cũ không có selfAssessments & confirmedPlan
      final StudyProfile legacy = StudyProfile.fromJson(<String, dynamic>{
        'alias': 'Minh',
        'gradeLevel': 'Lớp 11',
        'selectedSubjectCodes': <String>['math'],
      });
      expect(legacy.alias, 'Minh');
      expect(legacy.selfAssessments, isEmpty);
      expect(legacy.confirmedPlan, isNull);

      // Round-trip JSON mới có confirmedPlan
      final DailyStudyPlan confirmed = RuleBasedPlanGenerator.generateDraft(
        gradeLevel: 'Lớp 11',
        selectedSubjectCodes: const <String>['math', 'literature'],
        selfAssessments: const <String, SubjectSelfAssessment>{
          'math': SubjectSelfAssessment.examPrep,
        },
        prioritySubjects: const <PrioritySubject>[],
      ).markConfirmed(DateTime(2026, 11, 18, 7, 0));

      final StudyProfile modern = StudyProfile(
        alias: 'An',
        gradeLevel: 'Lớp 11',
        selectedSubjectCodes: const <String>['math', 'literature'],
        selfAssessments: const <String, SubjectSelfAssessment>{
          'math': SubjectSelfAssessment.examPrep,
        },
        confirmedPlan: confirmed,
      );
      final StudyProfile restored = StudyProfile.fromJson(modern.toJson());
      expect(restored.confirmedPlan, isNotNull);
      expect(restored.confirmedPlan!.isConfirmed, isTrue);
      expect(restored.confirmedPlan!.items.length, 2);
      expect(restored.selfAssessments['math'], SubjectSelfAssessment.examPrep);
    });
  });

  group('T049 Onboarding Draft Plan -> Today Dashboard Widget Flow (ON-04, ON-05)', () {
    testWidgets(
      'TC-02 & TC-03: Xem trước bản kế hoạch nháp (không Báo thức tự động) -> Xác nhận -> hiện trên Hôm nay và không tự tạo báo thức',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
          authGateway: DebugFixtureAuthGateway(),
          repository: DebugFixturePersonalFlowRepository(),
          draftStore: OfflineTextDraftStore(store: store),
          cameraGateway: _NoopCameraGateway(),
        );
        await personalVm.initialize();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('welcome-auth-start')),
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('auth-email-input')),
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-email-input')),
          'plan1@mindclock.vn',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('auth-password-input')),
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-password-input')),
          'MindClock@2026',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('auth-confirm-password-input')),
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-confirm-password-input')),
          'MindClock@2026',
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-terms')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-age')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );

        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('grade-Lớp 12')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('subject-math')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('subject-literature')),
        );

        // Chạm mức tự đánh giá Toán (Cơ bản -> Đang ôn thi)
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('priority-math')),
        );

        expect(
          find.byKey(const ValueKey<String>('onboarding-plan-draft-card')),
          findsOneWidget,
        );
        expect(find.textContaining('Chưa có gợi ý AI'), findsOneWidget);
        expect(find.textContaining('Báo thức tự động'), findsNothing);

        // Xác nhận kế hoạch -> vào Dashboard Hôm nay
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('onboarding-save')),
        );

        expect(guestVm.profile.confirmedPlan, isNotNull);
        expect(guestVm.profile.confirmedPlan!.isConfirmed, isTrue);
        expect(guestVm.alarms, isEmpty);
        expect(
          find.byKey(const ValueKey<String>('today-confirmed-plan-card')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TC-04: Bỏ qua kế hoạch từ Onboarding -> vào Hôm nay không có thẻ kế hoạch ép buộc và không tự tạo báo thức',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
          authGateway: DebugFixtureAuthGateway(),
          repository: DebugFixturePersonalFlowRepository(),
          draftStore: OfflineTextDraftStore(store: store),
          cameraGateway: _NoopCameraGateway(),
        );
        await personalVm.initialize();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('welcome-auth-start')),
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('auth-email-input')),
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-email-input')),
          'plan1@mindclock.vn',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('auth-password-input')),
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-password-input')),
          'MindClock@2026',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('auth-confirm-password-input')),
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-confirm-password-input')),
          'MindClock@2026',
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-terms')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-age')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('onboarding-skip-plan')),
        );

        expect(guestVm.profile.confirmedPlan, isNull);
        expect(guestVm.alarms, isEmpty);
        expect(
          find.byKey(const ValueKey<String>('today-confirmed-plan-card')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey<String>('nav-today')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
