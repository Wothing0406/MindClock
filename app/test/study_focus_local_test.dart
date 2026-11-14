import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/app.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/method_channel_study_focus_bridge.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/study_focus_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/strings/app_strings.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _FakeClock {
  _FakeClock(this.now);
  DateTime now;

  void advance(Duration delta) {
    now = now.add(delta);
  }
}

class _FakeStudyFocusBridge implements StudyFocusBridge {
  DigitalWellbeingOpenResult nextWellbeingResult =
      const DigitalWellbeingOpenResult(
    opened: false,
    target: DigitalWellbeingTarget.unavailable,
    messageVi:
        'Thiết bị không có Digital Wellbeing chuẩn để mở thẳng. MindClock không khóa app khác.',
  );

  StudyNotificationPermission permissionState =
      StudyNotificationPermission.granted;

  final List<String> shownReminderBodies = <String>[];
  int cancelCalls = 0;
  int endCueCalls = 0;
  int openWellbeingCalls = 0;

  @override
  bool get isPlatformConnected => true;

  @override
  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings() async {
    openWellbeingCalls += 1;
    return nextWellbeingResult;
  }

  @override
  Future<StudyNotificationPermission> getNotificationPermissionStatus() async {
    return permissionState;
  }

  @override
  Future<StudyNotificationPermission> requestNotificationPermission() async {
    return permissionState;
  }

  @override
  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  }) async {
    shownReminderBodies.add(bodyVi);
  }

  @override
  Future<void> cancelStudyReminder() async {
    cancelCalls += 1;
  }

  @override
  Future<void> playSessionEndCue() async {
    endCueCalls += 1;
  }
}

class _StubAlarmScheduler implements AlarmSchedulerService {
  AlarmRingPayload? pendingRing;
  bool emergencyStopCalled = false;

  @override
  bool get isOsBridgeConnected => true;

  @override
  Future<AlarmServiceCapabilities> checkCapabilities() async {
    return const AlarmServiceCapabilities(
      isOsBridgeConnected: true,
      supportsExactAlarm: true,
      supportsFullScreenIntent: true,
      statusSummaryVi: 'Đã nối dịch vụ báo thức local Android.',
    );
  }

  @override
  Future<AlarmPermissionSnapshot> getPermissionStatus() async {
    return const AlarmPermissionSnapshot(
      isOsBridgeConnected: true,
      exactAlarm: OsPermissionState.granted,
      notifications: OsPermissionState.granted,
      fullScreenIntent: OsPermissionState.granted,
    );
  }

  @override
  Future<AlarmScheduleResult> scheduleAlarm(AlarmConfig config) async {
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.scheduledReady,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã sẵn sàng',
    );
  }

  @override
  Future<AlarmScheduleResult> cancelAlarm(String alarmId) async {
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã hủy',
    );
  }

  @override
  Future<AlarmScheduleResult> snoozeAlarm(
    AlarmConfig config, {
    int minutes = 5,
  }) async {
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.scheduledReady,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã hoãn',
    );
  }

  @override
  Future<AlarmScheduleResult> triggerEmergencyStop({String? alarmId}) async {
    emergencyStopCalled = true;
    pendingRing = null;
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã dừng khẩn cấp',
    );
  }

  @override
  Future<bool> openPermissionSettings(AlarmPermissionAction action) async =>
      true;

  @override
  Future<AlarmRingPayload?> consumePendingRingLaunch() async {
    final AlarmRingPayload? out = pendingRing;
    pendingRing = null;
    return out;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Không gian học local (6A / docs/45)', () {
    test(
      'SF-TC-01 (F01): tính timer theo mốc thời gian, fallback Học tự do, không cộng thời gian ảo khi rời app ở mức Linh hoạt',
      () async {
        final _FakeClock clock =
            _FakeClock(DateTime(2026, 11, 14, 9, 0, 0));
        final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
        final LocalStudyFocusRepository repo =
            LocalStudyFocusRepository(store: kv);
        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();

        final StudyFocusViewModel vm = StudyFocusViewModel(
          repository: repo,
          bridge: bridge,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
        );
        await vm.initialize();

        expect(vm.draftLevel, StudyFocusLevel.standard);
        expect(vm.draftDurationMinutes, 25);

        // Chặn clamp 5..120 phút
        vm.setDurationMinutes(2);
        expect(vm.draftDurationMinutes, 5);
        vm.setDurationMinutes(180);
        expect(vm.draftDurationMinutes, 120);
        vm.setDurationMinutes(25);

        vm.setFocusLevel(StudyFocusLevel.flexible);
        // Để trống tên việc -> dùng Học tự do
        await vm.startSession(overrideTaskTitle: '   ');
        expect(vm.activeSnapshot!.taskTitle, 'Học tự do');
        expect(vm.remainingSeconds, 1500);

        // Học 60 giây trong app
        clock.advance(const Duration(seconds: 60));
        expect(vm.remainingSeconds, 1440);
        expect(vm.elapsedWallSeconds, 60);
        expect(vm.inAppFocusSeconds, 60);

        // Khóa màn / chuyển app 120 giây rồi quay lại
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 120));
        await vm.onAppResumed();

        // Đồng hồ đếm ngược tiếp tục (1440 - 120 = 1320s),
        // thời gian thực tế = 180s, nhưng trong app KHÔNG cộng ảo 120s lúc rời app (= 60s).
        expect(vm.remainingSeconds, 1320);
        expect(vm.elapsedWallSeconds, 180);
        expect(vm.inAppFocusSeconds, 60);
        expect(vm.activeSnapshot!.commitmentAwaitingResume, isFalse);
        expect(vm.activeSnapshot!.lastReturnNoticeVi, contains('2 phút'));
        expect(vm.activeSnapshot!.lastReturnNoticeVi, isNot(contains('xao nhãng')));
      },
    );

    test(
      'SF-TC-02 (F02): kill app/reboot chuyển phiên dở sang interrupted không cộng giờ ảo, vẫn cho Tiếp tục/Kết thúc và không ảnh hưởng báo thức local',
      () async {
        final _FakeClock clock =
            _FakeClock(DateTime(2026, 11, 14, 19, 0, 0));
        final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
        final _StubAlarmScheduler alarmScheduler = _StubAlarmScheduler();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: kv),
          alarmScheduler: alarmScheduler,
        );
        await guestVm.initialize();
        await guestVm.saveAlarm(
          const AlarmConfig(
            id: 'a1',
            hour: 6,
            minute: 0,
            repeatWeekdays: <int>[1, 2, 3, 4, 5],
            mode: AlarmMode.challenge,
            soundOption: AlarmSoundOption.gentleDawn,
            vibrateEnabled: true,
            enabled: true,
            subjectCode: 'math',
            syncStatus: AlarmSyncStatus.scheduledReady,
          ),
        );

        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();
        final StudyFocusViewModel vm1 = StudyFocusViewModel(
          repository: LocalStudyFocusRepository(store: kv),
          bridge: bridge,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
        );
        await vm1.initialize();
        vm1.setDurationMinutes(25);
        await vm1.startSession(overrideTaskTitle: 'Giải 3 câu hàm số');

        // Học 3 phút -> pause hoặc background -> bị kill app 10 phút
        clock.advance(const Duration(minutes: 3));
        await vm1.pauseSession();
        vm1.dispose();

        // Giả lập máy tắt/mất 10 phút rồi mở lại từ lạnh
        clock.advance(const Duration(minutes: 10));
        final StudyFocusViewModel vm2 = StudyFocusViewModel(
          repository: LocalStudyFocusRepository(store: kv),
          bridge: bridge,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
        );
        await vm2.initialize();

        expect(vm2.activeSnapshot, isNotNull);
        expect(vm2.activeSnapshot!.status, StudyFocusStatus.interrupted);
        expect(vm2.inAppFocusSeconds, 180);
        expect(vm2.remainingSeconds, 1320);

        // Tiếp tục thêm 2 phút rồi kết thúc sớm
        await vm2.resumeSession();
        expect(vm2.activeSnapshot!.status, StudyFocusStatus.running);
        clock.advance(const Duration(minutes: 2));
        expect(vm2.inAppFocusSeconds, 300);
        expect(vm2.remainingSeconds, 1200);

        await vm2.finishSession(early: true);
        final StudyFocusRecord? saved = await vm2.saveFinishedSession();
        expect(saved, isNotNull);
        expect(saved!.finalStatus, StudyFocusStatus.endedEarly);
        expect(saved.inAppFocusSeconds, 300);

        // Báo thức độc lập vẫn còn nguyên và Dừng khẩn cấp hoạt động
        expect(guestVm.alarms, hasLength(1));
        await guestVm.triggerEmergencyStop(alarmId: 'a1');
        expect(alarmScheduler.emergencyStopCalled, isTrue);
      },
    );

    test(
      'SF-TC-03 (F03): kiểm tra đúng ngưỡng rời app 5s, 11s, 31s và rời nhiều lần cho cả 3 mức',
      () async {
        // 1) Tập trung thường: 5s và 11s không nhắc; 31s nhắc đúng 1 lần; rời lần 2 vẫn không chồng notification
        final _FakeClock clock =
            _FakeClock(DateTime(2026, 11, 14, 14, 0, 0));
        final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();
        final StudyFocusViewModel vm = StudyFocusViewModel(
          repository: LocalStudyFocusRepository(store: kv),
          bridge: bridge,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
        );
        await vm.initialize();
        await vm.setNotifyOutsideApp(true);
        vm.setFocusLevel(StudyFocusLevel.standard);
        await vm.startSession(overrideTaskTitle: 'Đọc SGK Lý');

        // 5 giây (<= 30s)
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 5));
        await vm.onAppResumed();
        expect(vm.activeSnapshot!.lastReturnNoticeVi, isNull);
        expect(bridge.shownReminderBodies, isEmpty);

        // 11 giây (<= 30s)
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 11));
        await vm.onAppResumed();
        expect(vm.activeSnapshot!.lastReturnNoticeVi, isNull);
        expect(bridge.shownReminderBodies, isEmpty);

        // 31 giây (> 30s)
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 31));
        await vm.onAppResumed();
        expect(vm.activeSnapshot!.lastReturnNoticeVi, contains('31 giây'));
        expect(bridge.shownReminderBodies, hasLength(1));

        // Rời lần nữa 35 giây -> hủy cái cũ lúc quay lại và thay bằng nhắc mới (không chồng)
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 35));
        await vm.onAppResumed();
        expect(bridge.cancelCalls, greaterThanOrEqualTo(2));
        expect(vm.activeSnapshot!.lastReturnNoticeVi, contains('35 giây'));

        // 2) Cam kết: 5s không dừng; 11s dừng tập trung trong app & yêu cầu bấm Tiếp tục học
        await vm.discardActiveSession();
        vm.setFocusLevel(StudyFocusLevel.commitment);
        await vm.startSession(overrideTaskTitle: 'Làm đề Hóa');
        clock.advance(const Duration(seconds: 60));

        // 5 giây (<= 10s): tiếp tục bình thường
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 5));
        await vm.onAppResumed();
        expect(vm.activeSnapshot!.commitmentAwaitingResume, isFalse);
        expect(vm.inAppFocusSeconds, 60);

        // 11 giây (> 10s): dừng in-app focus, chờ bấm Tiếp tục học, đồng hồ thực vẫn tăng
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 11));
        await vm.onAppResumed();
        expect(vm.activeSnapshot!.commitmentAwaitingResume, isTrue);
        expect(vm.inAppFocusSeconds, 60);
        expect(vm.remainingSeconds, 1440);
        expect(vm.elapsedWallSeconds, 76);

        // Chờ thêm 20 giây trước khi bấm Tiếp tục học -> không tăng inAppFocusSeconds
        clock.advance(const Duration(seconds: 20));
        expect(vm.inAppFocusSeconds, 60);
        expect(vm.elapsedWallSeconds, 96);

        await vm.resumeSession();
        expect(vm.activeSnapshot!.commitmentAwaitingResume, isFalse);
        clock.advance(const Duration(seconds: 30));
        expect(vm.inAppFocusSeconds, 90);
      },
    );

    test(
      'SF-TC-04 & SF-TC-05 (F07): lưu hoàn thành idempotent theo sessionId, không XP ảo, tách biệt dữ liệu A ↔ B ↔ guest',
      () async {
        final _FakeClock clock =
            _FakeClock(DateTime(2026, 11, 14, 20, 0, 0));
        final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
        final LocalStudyFocusRepository repo =
            LocalStudyFocusRepository(store: kv);
        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();

        final StudyFocusViewModel vm = StudyFocusViewModel(
          repository: repo,
          bridge: bridge,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
        );
        await vm.initialize(ownerScopeKey: 'user:alice');
        await vm.startSession(overrideTaskTitle: 'Ôn Hình học');
        final String sessionId = vm.activeSnapshot!.sessionId;

        clock.advance(const Duration(minutes: 25));
        vm.checkClockTick();
        expect(vm.activeSnapshot!.status, StudyFocusStatus.completed);

        // Idempotent repository write với cùng sessionId
        final StudyFocusRecord? firstSave =
            await vm.saveFinishedSession(notesDone: 'Xong 2 bài');
        expect(firstSave, isNotNull);
        expect(firstSave!.xpAwardedByTimer, 0);

        final List<StudyFocusRecord> afterDuplicate =
            await repo.saveRecordIdempotent(firstSave);
        expect(afterDuplicate, hasLength(1));

        // Đổi sang user:bob -> không thấy lịch sử hay snapshot của alice
        await vm.setOwnerScope('user:bob');
        expect(vm.history, isEmpty);
        expect(vm.activeSnapshot, isNull);

        await vm.startSession(overrideTaskTitle: 'Phiên của Bob');
        await vm.setOwnerScope('guest');
        expect(vm.history, isEmpty);
        expect(vm.activeSnapshot, isNull);

        // Quay lại alice -> vẫn còn đúng 1 bản ghi của alice
        await vm.setOwnerScope('user:alice');
        expect(vm.history, hasLength(1));
        expect(vm.history.first.taskTitle, 'Ôn Hình học');
      },
    );

    testWidgets(
      'SF-TC-06 & SF-TC-07 (F08, F09): Digital Wellbeing không có vẫn chạy ổn định; responsive 320/360/390/600 dp, chữ 200%, Reduce Motion & Semantics',
      (WidgetTester tester) async {
        final _FakeClock clock =
            _FakeClock(DateTime(2026, 11, 14, 15, 0, 0));
        final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
        final _StubAlarmScheduler alarmScheduler = _StubAlarmScheduler();
        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: kv),
          alarmScheduler: alarmScheduler,
        );
        await guestVm.initialize();

        final StudyFocusViewModel studyVm = StudyFocusViewModel(
          repository: LocalStudyFocusRepository(store: kv),
          bridge: bridge,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
        );
        await studyVm.initialize();

        for (final double width in <double>[320, 360, 390, 600]) {
          final Size surfaceSize = Size(width, 760);
          tester.view.physicalSize = surfaceSize;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: surfaceSize,
                textScaler: const TextScaler.linear(2.0),
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

          expect(find.text(AppStrings.studySpaceTitle), findsOneWidget);
          expect(find.textContaining('không khóa các app khác'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        // Bấm mở Digital Wellbeing khi thiết bị trả về unavailable -> báo trung thực & không crash
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('study-open-digital-wellbeing')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('study-open-digital-wellbeing')),
        );
        await tester.pumpAndSettle();
        expect(bridge.openWellbeingCalls, 1);
        expect(
          find.byKey(const ValueKey<String>('study-wellbeing-feedback')),
          findsOneWidget,
        );

        // Bắt đầu phiên với Reduce Motion -> không vẽ progress ring, có Semantics timer & nút Tạm nghỉ / Kết thúc
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('study-start-button')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('study-start-button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('study-progress-ring')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey<String>('study-timer-clock')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('study-pause-button')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('study-finish-button')), findsOneWidget);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      'SF-TC-08 (F02): từ Hôm nay mở Không gian học, chuông báo thức vẫn ưu tiên reo trên đầu và Dừng khẩn cấp hoạt động',
      (WidgetTester tester) async {
        final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
        final _StubAlarmScheduler alarmScheduler = _StubAlarmScheduler();
        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();

        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(360, 780)),
            child: MindClockApp(
              repository: GuestWorkspaceRepository(store: kv),
              alarmScheduler: alarmScheduler,
              studyFocusBridge: bridge,
              enableStudyTicker: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Bỏ qua onboarding nhanh -> vào Hôm nay -> mở Không gian học
        await tester.tap(find.byKey(const ValueKey<String>('guest-skip-later')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('today-open-study-space')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('today-open-study-space')),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.studySpaceTitle), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('study-start-button')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('study-start-button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey<String>('study-timer-clock')), findsOneWidget);

        // Giả lập báo thức reo khi người dùng đang mở ứng dụng -> AlarmRingScreen đè lên trên
        alarmScheduler.pendingRing = const AlarmRingPayload(
          alarmId: 'morning_alarm',
          formattedTime: '06:00',
          mode: AlarmMode.normal,
          label: 'Dậy ôn bài',
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.ringEmergencyStop), findsOneWidget);
        await tester.tap(find.text(AppStrings.ringEmergencyStop));
        await tester.pumpAndSettle();

        expect(alarmScheduler.emergencyStopCalled, isTrue);
        // Quay lại Hôm nay vẫn thấy nút Quay lại phiên học đang mở
        expect(find.text('Quay lại phiên học'), findsOneWidget);
      },
    );

    test(
      'Hợp đồng MethodChannel mindclock/study_focus gửi đúng bridgeVersion = 1 và ánh xạ unavailable an toàn',
      () async {
        MethodCall? captured;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          MethodChannelStudyFocusBridge.defaultChannel,
          (MethodCall call) async {
            captured = call;
            if (call.method == 'openDigitalWellbeingFocusSettings') {
              return <String, dynamic>{
                'opened': false,
                'target': 'unavailable',
                'messageVi': 'Máy test không có Digital Wellbeing.',
              };
            }
            return <String, dynamic>{'status': 'granted'};
          },
        );
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            MethodChannelStudyFocusBridge.defaultChannel,
            null,
          );
        });

        const MethodChannelStudyFocusBridge bridge =
            MethodChannelStudyFocusBridge();
        final DigitalWellbeingOpenResult res =
            await bridge.openDigitalWellbeingFocusSettings();

        expect(captured?.method, 'openDigitalWellbeingFocusSettings');
        expect((captured?.arguments as Map<dynamic, dynamic>)['bridgeVersion'], 1);
        expect(res.opened, isFalse);
        expect(res.target, DigitalWellbeingTarget.unavailable);
        expect(res.messageVi, contains('Digital Wellbeing'));
      },
    );
  });
}
