import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/alarm_config_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/widgets/circular_sleep_clock_picker.dart';

void main() {
  test(
    'T080 TC-01: sleepDurationMinutes và formatHm tính chính xác qua nửa đêm',
    () {
      expect(
        CircularSleepClockPicker.sleepDurationMinutes(22 * 60 + 30, 6 * 60),
        7 * 60 + 30,
      );
      expect(
        CircularSleepClockPicker.sleepDurationMinutes(23 * 60 + 15, 6 * 60),
        6 * 60 + 45,
      );
      expect(CircularSleepClockPicker.formatHm(6 * 60 + 5), '06:05');
    },
  );

  testWidgets(
    'T080 TC-02: AlarmConfigScreen hiển thị đồng hồ xoay 24h, kéo wake handle cập nhật giờ & thời gian ngủ ở 320dp 200%',
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

      expect(
        find.byKey(const ValueKey<String>('circular-sleep-clock')),
        findsOneWidget,
      );
      expect(find.text('7 giờ 30 phút'), findsOneWidget);
      expect(find.text('Thời gian ngủ'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('alarm-selected-time-text')),
        findsOneWidget,
      );
      expect(find.text('06:00'), findsOneWidget);

      // Kéo wake handle từ 06:00 (phải) xuống dưới (về phía 12:00)
      final Finder wakeHandle =
          find.byKey(const ValueKey<String>('circular-wake-handle'));
      await tester.ensureVisible(wakeHandle);
      await tester.drag(wakeHandle, const Offset(-40, 80));
      await tester.pumpAndSettle();

      // Sau khi kéo, giờ báo thức không còn giữ nguyên 06:00
      expect(find.text('06:00'), findsNothing);

      // Nút tinh chỉnh nhanh vẫn hoạt động bình thường
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('alarm-hour-plus')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('alarm-hour-plus')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
