import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindclock_app/app.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';

void main() {
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'TC-RTC-01: TodayScreen hiển thị đồng hồ thời gian thực và đếm ngược báo thức kế tiếp',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      await tester.pumpWidget(
        MindClockApp(
          repository: GuestWorkspaceRepository(store: store),
          personalRepository: DebugFixturePersonalFlowRepository(),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          enableStudyTicker: false,
        ),
      );
      await tester.pumpAndSettle();

      // Bỏ qua onboarding để vào thẳng màn Hôm nay
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('guest-skip-later')),
      );

      // Kiểm tra widget đồng hồ thời gian thực xuất hiện
      expect(find.byKey(const ValueKey<String>('today-realtime-clock-hm')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('today-realtime-clock-sec')), findsOneWidget);
      expect(find.text('Thời gian thực'), findsOneWidget);

      // Tích tắc thời gian
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey<String>('today-realtime-clock-sec')), findsOneWidget);
    },
  );

  testWidgets(
    'TC-OCR-01: TimetableProfileScreen có nút quét ảnh AI và áp dụng bản nháp TKB',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      await tester.pumpWidget(
        MindClockApp(
          repository: GuestWorkspaceRepository(store: store),
          personalRepository: DebugFixturePersonalFlowRepository(),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          enableStudyTicker: false,
        ),
      );
      await tester.pumpAndSettle();

      // Bỏ qua onboarding để vào màn Hôm nay
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('guest-skip-later')),
      );

      // Mở màn Sửa thời khóa biểu & hồ sơ
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('today-edit-timetable-profile')),
      );

      // Tìm nút quét ảnh AI
      final Finder scanBtn = find.byKey(const ValueKey<String>('scan-timetable-photo-ai'));
      expect(scanBtn, findsOneWidget);

      // Bấm nút quét ảnh AI
      await scrollAndTap(tester, scanBtn);

      // Bản nháp AI nhận diện xuất hiện
      expect(find.byKey(const ValueKey<String>('apply-ai-timetable-draft')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('cancel-ai-timetable-draft')), findsOneWidget);

      // Bấm xác nhận lưu bản nháp TKB
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('apply-ai-timetable-draft')),
      );

      // Đã cập nhật thành công
      expect(find.textContaining('Đã cập nhật thời khóa biểu từ AI thành công'), findsOneWidget);
    },
  );
}
