import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/app.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/strings/app_strings.dart';
import 'package:mindclock_app/ui/core/widgets/mindclock_brand_mark.dart';

void main() {
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    required InMemoryKeyValueStore store,
    Size surfaceSize = const Size(360, 780),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MindClockApp(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          enableStudyTicker: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'AC-01..AC-07: luồng khách, sửa lịch giữ nguyên giờ chuông, khôi phục khi mở lại app và hiển thị Đã lưu cấu hình',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      await pumpApp(tester, store: store);

      // Màn S01 Chào mừng: không ép đăng nhập, có Để sau và Chỉ báo thức
      expect(find.text(AppStrings.tryGuestCta), findsOneWidget);
      expect(find.text(AppStrings.setupLaterCta), findsOneWidget);
      expect(find.text(AppStrings.alarmOnlyCta), findsOneWidget);
      expect(find.text('Đấu trường'), findsNothing);

      // Bắt đầu thiết lập học tập khách
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('guest-start-setup')),
      );

      await scrollAndTap(tester, find.byKey(const ValueKey<String>('grade-Lớp 9')));
      await scrollAndTap(tester, find.byKey(const ValueKey<String>('subject-math')));
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('subject-informatics')),
      );
      await scrollAndTap(tester, find.byKey(const ValueKey<String>('priority-math')));
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('onboarding-goal-input')),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('onboarding-goal-input')),
        'Đạt điểm 9 Toán',
      );
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('onboarding-save')),
      );

      // Vào màn Hôm nay: đủ 4 tab chính (gồm Đấu trường G1 Luyện đơn cục bộ, không có Ranked)
      expect(find.byKey(const ValueKey<String>('nav-today')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-practice')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-arena')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-me')), findsOneWidget);
      expect(find.text('Đấu hạng'), findsNothing);

      // Đặt báo thức đầu tiên + xem phép tính gợi ý 07:00 - 25 - 30 - 10 = 05:55
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('today-add-first-alarm')),
      );

      expect(
        find.byKey(const ValueKey<String>('wake-formula-text')),
        findsOneWidget,
      );
      expect(find.textContaining('05:55'), findsWidgets);

      // Trước khi bấm Dùng giờ này: giờ mặc định vẫn là 06:00
      expect(find.text('06:00'), findsWidgets);

      // Bấm Dùng giờ này -> giờ chuyển thành 05:55
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('apply-wake-suggestion')),
      );
      expect(find.text('05:55'), findsWidgets);

      // Màn đặt chuông tinh gọn: KHÔNG còn chọn môn thủ công hay chọn chế độ thường; auto Thử thách theo hồ sơ & TKB
      expect(
        find.byKey(const ValueKey<String>('alarm-subject-informatics')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('alarm-mode-normal')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('alarm-auto-challenge-card')),
        findsOneWidget,
      );
      expect(find.textContaining('Không có nút Hoãn'), findsWidgets);

      // Lưu cấu hình báo thức -> tự động lưu chế độ Thử thách theo hồ sơ & TKB sáng
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('save-alarm-config')),
      );

      // Ở Hôm nay: thấy giờ 05:55 và badge Đã lưu cấu hình, KHÔNG thấy Đã sẵn sàng
      expect(find.text('05:55'), findsOneWidget);
      expect(find.text(AppStrings.alarmSavedConfigOnly), findsOneWidget);
      expect(find.text('Đã sẵn sàng'), findsNothing);

      // Mở Thời khóa biểu 7 ngày và thêm tiết -> giờ chuông 05:55 vẫn giữ nguyên
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('today-edit-timetable-profile')),
      );
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('add-timetable-entry')),
      );
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('save-period-btn')),
      );
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('timetable-close')),
      );

      expect(find.text('05:55'), findsOneWidget);
      expect(
        find.text(AppStrings.wakeScheduleChangedNotice),
        findsOneWidget,
      );

      // Giả lập đóng và mở lại app với widget tree hoàn toàn mới trên cùng local store
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await pumpApp(tester, store: store);

      expect(find.byKey(const ValueKey<String>('nav-today')), findsOneWidget);
      expect(find.text('05:55'), findsOneWidget);
      expect(find.text(AppStrings.alarmSavedConfigOnly), findsOneWidget);
      expect(find.textContaining('Đạt điểm 9 Toán'), findsOneWidget);
    },
  );

  testWidgets(
    'AC-08: Không tràn layout tại chiều rộng 320 dp và cỡ chữ 200%',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      await pumpApp(
        tester,
        store: store,
        surfaceSize: const Size(320, 640),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('guest-skip-later')),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Boot loading screen hiển thị MindClockBrandMark và không tràn ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      // Tạo app chưa pump xong future initialize -> pump 1 frame ngay lập tức để bắt màn boot loading
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2.0),
            disableAnimations: true,
          ),
          child: MindClockApp(
            repository: GuestWorkspaceRepository(store: store),
            alarmScheduler: const UnboundAlarmSchedulerService(),
            enableStudyTicker: false,
          ),
        ),
      );

      expect(find.byKey(const ValueKey<String>('app-boot-loading')), findsOneWidget);
      expect(find.byType(MindClockBrandMark), findsOneWidget);
      expect(find.text('MindClock'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('app-boot-loading')), findsNothing);
    },
  );
}
