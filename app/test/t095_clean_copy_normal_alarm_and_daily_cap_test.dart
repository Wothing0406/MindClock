import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/alarm_occurrence.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/alarm_config_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/alarm_ring_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/onboarding_setup_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/welcome_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/widgets/circular_sleep_clock_picker.dart';

ThemeData _testTheme() {
  return ThemeData.light().copyWith(
    extensions: const <ThemeExtension<dynamic>>[MindClockTheme.light],
  );
}

void main() {
  group('T095 Clean Product Copy, Normal Alarm & Single Daily Cap', () {
    testWidgets(
      'TC-01: WelcomeScreen và OnboardingSetupScreen không còn chế độ khách/không cần đăng nhập',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: _testTheme(),
            home: Scaffold(
              body: WelcomeScreen(onStartAuth: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey<String>('welcome-auth-start')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('guest-alarm-only')), findsNothing);
        expect(find.textContaining('cục bộ'), findsNothing);
        expect(find.textContaining('offline'), findsNothing);

        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await vm.initialize();

        await tester.pumpWidget(
          MaterialApp(
            theme: _testTheme(),
            home: Scaffold(
              body: OnboardingSetupScreen(
                initialProfile: vm.profile,
                onSaveProfile: (_) async {},
                onSkipLater: () async {},
                onAlarmOnly: () async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey<String>('onboarding-later')), findsNothing);
        expect(find.byKey(const ValueKey<String>('onboarding-alarm-only')), findsNothing);
      },
    );

    testWidgets(
      'TC-02: AlarmConfigScreen hỗ trợ Hẹn giờ thường (ẩn vòng ngủ & câu hỏi) và lưu AlarmMode.normal',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await vm.initialize();

        bool savedCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: _testTheme(),
            home: Scaffold(
              body: AlarmConfigScreen(
                viewModel: vm,
                onSaved: (_) {
                  savedCalled = true;
                },
                onCancel: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mặc định là Báo thức dậy học (challenge) -> có vòng ngủ và thẻ câu sáng
        expect(find.byType(CircularSleepClockPicker), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('alarm-auto-challenge-card')), findsOneWidget);

        // Chuyển sang Hẹn giờ thường -> ẩn vòng ngủ & thẻ câu sáng
        await tester.tap(find.byKey(const ValueKey<String>('alarm-mode-normal')));
        await tester.pumpAndSettle();

        expect(find.byType(CircularSleepClockPicker), findsNothing);
        expect(find.byKey(const ValueKey<String>('alarm-auto-challenge-card')), findsNothing);

        await tester.ensureVisible(find.byKey(const ValueKey<String>('save-alarm-config')));
        await tester.tap(find.byKey(const ValueKey<String>('save-alarm-config')));
        await tester.pumpAndSettle();

        expect(savedCalled, isTrue);
        expect(vm.alarms, isNotEmpty);
        expect(vm.alarms.last.mode, AlarmMode.normal);
      },
    );

    testWidgets(
      'TC-03: Mỗi ngày chỉ tính tối đa 1 báo thức hoàn thành; chuông thứ 2 cho tắt trực tiếp',
      (WidgetTester tester) async {
        final DateTime fixedNow = DateTime(2026, 11, 28, 6, 30);
        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          nowProvider: () => fixedNow,
        );
        await vm.initialize();

        expect(vm.hasCompletedAlarmToday, isFalse);
        expect(vm.completedAlarmCountToday, 0);

        await vm.markAlarmQuestionOpened(alarmId: 'alarm-1', subjectCode: 'math');
        await vm.markAlarmOccurrenceCompleted(alarmId: 'alarm-1', sessionId: 's1');

        expect(vm.hasCompletedAlarmToday, isTrue);
        expect(vm.completedAlarmCountToday, 1);

        // Chuông thứ 2 trong cùng ngày không được tính thêm completed
        await vm.markAlarmQuestionOpened(alarmId: 'alarm-2', subjectCode: 'english');
        await vm.markAlarmOccurrenceCompleted(alarmId: 'alarm-2', sessionId: 's2');

        expect(vm.completedAlarmCountToday, 1);
        expect(
          vm.occurrenceForToday('alarm-2')?.state,
          AlarmOccurrenceState.dismissed,
        );

        // Màn chuông khi đã hoàn thành hôm nay chỉ hiện Tắt chuông, không ép Mở câu hỏi
        await tester.pumpWidget(
          MaterialApp(
            theme: _testTheme(),
            home: Scaffold(
              body: AlarmRingScreen(
                payload: const AlarmRingPayload(
                  alarmId: 'alarm-2',
                  formattedTime: '07:00',
                  mode: AlarmMode.challenge,
                  label: 'Báo thức 2',
                ),
                alreadyCompletedToday: vm.hasCompletedAlarmToday,
                onOpenQuestion: () {},
                onEmergencyStop: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey<String>('ring-open-question')), findsNothing);
        expect(find.byKey(const ValueKey<String>('ring-dismiss-alarm')), findsOneWidget);
      },
    );
  });
}
