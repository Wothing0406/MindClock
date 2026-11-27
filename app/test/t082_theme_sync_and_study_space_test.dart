import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/community/views/commitment_group_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/alarm_config_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/today_screen.dart';

void main() {
  testWidgets(
    'T082 TC-01: TodayScreen, AlarmConfigScreen & CommitmentGroupScreen đồng bộ nền sáng surface/paper (không còn mảng đen lạc tông) ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await vm.initialize();

      final DebugFixtureCommunityRepository commRepo =
          DebugFixtureCommunityRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: TodayScreen(
                viewModel: vm,
                communityRepository: commRepo,
                onCreateAlarm: () {},
                onEditAlarm: (_) {},
                onOpenTimetableAndProfile: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra không có Container tô nền tối mc.night trong TodayScreen
      final Iterable<Container> todayContainers =
          tester.widgetList<Container>(find.byType(Container));
      for (final Container c in todayContainers) {
        final Decoration? dec = c.decoration;
        if (dec is BoxDecoration) {
          expect(dec.color, isNot(equals(MindClockTheme.light.night)));
        }
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: AlarmConfigScreen(
              viewModel: vm,
              onSaved: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Iterable<Container> alarmContainers =
          tester.widgetList<Container>(find.byType(Container));
      for (final Container c in alarmContainers) {
        final Decoration? dec = c.decoration;
        if (dec is BoxDecoration) {
          expect(dec.color, isNot(equals(MindClockTheme.light.night)));
        }
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: CommitmentGroupScreen(repository: commRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Iterable<Container> groupContainers =
          tester.widgetList<Container>(find.byType(Container));
      for (final Container c in groupContainers) {
        final Decoration? dec = c.decoration;
        if (dec is BoxDecoration) {
          expect(dec.color, isNot(equals(MindClockTheme.light.night)));
        }
      }

      expect(tester.takeException(), isNull);
    },
  );
}
