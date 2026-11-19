import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/method_channel_schedule_widget_bridge.dart';
import 'package:mindclock_app/domain/models/daily_todo_task.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/media_picker_gateway.dart';
import 'package:mindclock_app/domain/services/schedule_widget_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/day_schedule_timeline_card.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/timetable_profile_screen.dart';

class _SpyScheduleWidgetBridge extends ScheduleWidgetBridge {
  final List<ScheduleWidgetSnapshot> snapshots = <ScheduleWidgetSnapshot>[];
  final List<DailyTodoTask> scheduledReminders = <DailyTodoTask>[];
  final List<String> cancelledReminders = <String>[];

  @override
  bool get isPlatformConnected => true;

  @override
  Future<void> syncWidgetSnapshot(ScheduleWidgetSnapshot snapshot) async {
    snapshots.add(snapshot);
  }

  @override
  Future<void> scheduleTaskReminder(DailyTodoTask task) async {
    scheduledReminders.add(task);
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    cancelledReminders.add(taskId);
  }
}

class _CancelledPhotoPicker implements MediaPickerGateway {
  @override
  Future<MediaPickResult> pickAlarmAudio() async =>
      const MediaPickResult.cancelled();

  @override
  Future<MediaPickResult> pickAvatarImage() async =>
      const MediaPickResult.cancelled();

  @override
  Future<bool> previewAudio({
    required String soundOption,
    String? customSoundPath,
    bool loop = false,
  }) async =>
      false;

  @override
  Future<void> stopAudioPreview() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T057 Clock To-do, Calendar Timeline & Schedule Widget', () {
    test(
      'AC-01 & AC-04: Lưu bền DailyTodoTask, gộp với TKB, tick Done hủy nhắc & đồng bộ Widget snapshot',
      () async {
        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final _SpyScheduleWidgetBridge spyBridge = _SpyScheduleWidgetBridge();
        final DateTime fixedNow = DateTime(2026, 11, 19, 8, 30);

        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          scheduleWidgetBridge: spyBridge,
          nowProvider: () => fixedNow,
        );
        await vm.initialize();
        await vm.addTimetableEntry(
          weekday: fixedNow.weekday,
          subjectCode: 'math',
          startMinutes: 7 * 60,
        );
        await vm.addDailyTodoTask(
          title: 'Học thêm Vật lí thầy Hùng',
          date: fixedNow,
          startMinutes: 19 * 60 + 30,
          durationMinutes: 90,
          subjectCode: 'physics',
          category: DailyTodoCategory.extraClass,
          remindOnTime: true,
        );

        expect(spyBridge.scheduledReminders.length, 1);
        final List<DayScheduleBlock> blocks = vm.timelineForDate(fixedNow);
        expect(blocks.length, 2);
        expect(blocks[0].isFromTimetable, isTrue);
        expect(blocks[0].title, 'Toán');
        expect(blocks[1].isFromTimetable, isFalse);
        expect(blocks[1].title, 'Học thêm Vật lí thầy Hùng');
        expect(blocks[1].formattedTimeRange, '19:30 - 21:00');

        // Tick Done task học thêm -> hủy nhắc việc & cập nhật snapshot
        await vm.toggleBlockDone(blocks[1], fixedNow);
        expect(spyBridge.cancelledReminders, contains(blocks[1].id));
        expect(spyBridge.snapshots.last.doneCount, 1);
        expect(spyBridge.snapshots.last.totalCount, 2);

        // Reload lại ViewModel từ cùng store -> dữ liệu vẫn giữ nguyên
        final GuestWorkspaceViewModel vm2 = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          nowProvider: () => fixedNow,
        );
        await vm2.initialize();
        final List<DayScheduleBlock> reloaded = vm2.timelineForDate(fixedNow);
        expect(reloaded.length, 2);
        expect(reloaded[1].isDone, isTrue);
      },
    );

    testWidgets(
      'AC-02: DayScheduleTimelineCard thêm việc, tick Done, mở Calendar trục giờ không tràn ở 320dp 200%',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final DateTime fixedNow = DateTime(2026, 11, 19, 10, 0);
        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          nowProvider: () => fixedNow,
        );
        await vm.initialize();
        await vm.saveStudyProfile(
          const StudyProfile(
            gradeLevel: 'Lớp 11',
            selectedSubjectCodes: <String>['math', 'physics'],
          ),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AnimatedBuilder(
                    animation: vm,
                    builder: (_, __) => DayScheduleTimelineCard(
                      viewModel: vm,
                      selectedDate: fixedNow,
                      now: fixedNow,
                      onSelectWeekday: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mở sheet thêm việc mới
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('todo-add-btn')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('todo-add-btn')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey<String>('todo-title-input')),
          'Làm đề Toán 45 phút',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('todo-save-btn')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('todo-save-btn')));
        await tester.pumpAndSettle();

        expect(find.text('Làm đề Toán 45 phút'), findsOneWidget);
        expect(find.text('0/1 việc xong'), findsOneWidget);

        // Tick Done
        final String taskId = vm.dailyTasks.first.id;
        await tester.ensureVisible(
          find.byKey(ValueKey<String>('todo-toggle-$taskId')),
        );
        await tester.tap(
          find.byKey(ValueKey<String>('todo-toggle-$taskId')),
        );
        await tester.pumpAndSettle();
        expect(find.text('1/1 việc xong'), findsOneWidget);

        // Mở Calendar Timeline theo giờ
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('todo-open-calendar-timeline')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('todo-open-calendar-timeline')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('calendar-day-timeline-sheet')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AC-03: TimetableProfileScreen hủy chọn ảnh TKB qua MediaPickerGateway không crash',
      (WidgetTester tester) async {
        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await vm.initialize();

        await tester.pumpWidget(
          MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: TimetableProfileScreen(
              viewModel: vm,
              mediaPickerGateway: _CancelledPhotoPicker(),
              onClose: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('scan-timetable-photo-ai')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('scan-timetable-photo-ai')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Đã hủy chọn ảnh thời khóa biểu.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    test('MethodChannelScheduleWidgetBridge serializes wire calls', () async {
      final List<MethodCall> calls = <MethodCall>[];
      const MethodChannel channel =
          MethodChannel(MethodChannelScheduleWidgetBridge.channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      const MethodChannelScheduleWidgetBridge bridge =
          MethodChannelScheduleWidgetBridge(channel: channel);
      await bridge.syncWidgetSnapshot(
        const ScheduleWidgetSnapshot(
          dateIso: '2026-11-19',
          weekdayShortVi: 'TH 5',
          dayNumberLabel: '19',
          monthLabelVi: '19/11',
          doneCount: 1,
          totalCount: 2,
          nextAlarmLabelVi: 'Chuông 06:00',
          items: <ScheduleWidgetItem>[
            ScheduleWidgetItem(
              timeLabel: '07:00',
              title: 'Toán',
              categoryLabelVi: 'Chính khóa',
              isDone: true,
            ),
          ],
        ),
      );
      expect(calls.length, 1);
      expect(calls.first.method, 'syncWidgetSnapshot');
      final Map<String, dynamic> decoded = jsonDecode(
        (calls.first.arguments as Map<dynamic, dynamic>)['snapshotJson']
            as String,
      ) as Map<String, dynamic>;
      expect(decoded['doneCount'], 1);
      expect(decoded['totalCount'], 2);

      // Avoid unused dart:io analyzer warning if not referenced directly
      expect(Directory.current.path.isNotEmpty, isTrue);
    });
  });
}
