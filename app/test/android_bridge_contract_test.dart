import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/app.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/strings/app_strings.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/alarm_ring_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(AlarmSchedulerService.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AndroidMethodChannelAlarmSchedulerService contract v1', () {
    test('MissingPluginException rơi về bridgeUnbound và savedConfigOnly',
        () async {
      final AndroidMethodChannelAlarmSchedulerService service =
          AndroidMethodChannelAlarmSchedulerService();

      final AlarmServiceCapabilities caps = await service.checkCapabilities();
      expect(caps.isOsBridgeConnected, isFalse);
      expect(caps.errorCode, AlarmBridgeErrorCode.bridgeUnbound);

      final AlarmScheduleResult res = await service.scheduleAlarm(
        const AlarmConfig(id: 'a1', hour: 6, minute: 0),
      );
      expect(res.status, AlarmSyncStatus.savedConfigOnly);
      expect(res.errorCode, AlarmBridgeErrorCode.bridgeUnbound);
      expect(res.permissionSnapshot.allGranted, isFalse);
    });

    test('Phát hiện sai bridgeVersion và không báo scheduledReady', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        final Map<dynamic, dynamic> args =
            call.arguments as Map<dynamic, dynamic>;
        expect(args['bridgeVersion'], AlarmSchedulerService.currentBridgeVersion);
        return <String, dynamic>{
          'bridgeVersion': 99,
          'errorCode': 'OK',
          'isOsBridgeConnected': true,
          'status': 'scheduledReady',
        };
      });

      final AndroidMethodChannelAlarmSchedulerService service =
          AndroidMethodChannelAlarmSchedulerService();
      final AlarmServiceCapabilities caps = await service.checkCapabilities();
      expect(caps.isOsBridgeConnected, isFalse);
      expect(caps.errorCode, AlarmBridgeErrorCode.unsupportedVersion);

      final AlarmScheduleResult res = await service.scheduleAlarm(
        const AlarmConfig(id: 'a1', hour: 6, minute: 0),
      );
      expect(res.status, AlarmSyncStatus.osFailed);
      expect(res.errorCode, AlarmBridgeErrorCode.unsupportedVersion);
    });

    test('Từ chối quyền Exact Alarm / Thông báo / Màn khóa không được báo Đã sẵn sàng',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'checkCapabilities':
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'OK',
              'isOsBridgeConnected': true,
              'supportsExactAlarm': true,
              'supportsFullScreenIntent': true,
              'statusSummaryVi': 'Đã nối Android.',
            };
          case 'getPermissionStatus':
          case 'scheduleAlarm':
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'PERMISSION_EXACT_ALARM_DENIED',
              // Cố tình giả lập native trả sai status để kiểm tra chốt an toàn ở Dart
              'status': 'scheduledReady',
              'messageVi': 'Thiếu quyền Exact Alarm.',
              'permissions': <String, String>{
                'exactAlarm': 'denied',
                'notifications': 'granted',
                'fullScreenIntent': 'denied',
              },
              'exactAlarm': 'denied',
              'notifications': 'granted',
              'fullScreenIntent': 'denied',
            };
          default:
            return <String, dynamic>{'bridgeVersion': 1, 'errorCode': 'OK'};
        }
      });

      final AndroidMethodChannelAlarmSchedulerService service =
          AndroidMethodChannelAlarmSchedulerService();
      final AlarmScheduleResult res = await service.scheduleAlarm(
        const AlarmConfig(id: 'a1', hour: 6, minute: 15),
      );

      expect(res.status, AlarmSyncStatus.osPermissionMissing);
      expect(res.errorCode, AlarmBridgeErrorCode.permissionExactAlarmDenied);
      expect(res.permissionSnapshot.allGranted, isFalse);
      expect(
        res.permissionSnapshot.missingActions(),
        containsAll(<AlarmPermissionAction>[
          AlarmPermissionAction.exactAlarmSettings,
          AlarmPermissionAction.fullScreenIntentSettings,
        ]),
      );
    });

    test('Đủ quyền và OS xác nhận đặt lịch mới trả scheduledReady', () async {
      final List<String> calledMethods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calledMethods.add(call.method);
        switch (call.method) {
          case 'checkCapabilities':
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'OK',
              'isOsBridgeConnected': true,
              'supportsExactAlarm': true,
              'supportsFullScreenIntent': true,
              'statusSummaryVi': 'Đã nối dịch vụ báo thức local Android.',
            };
          case 'getPermissionStatus':
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'OK',
              'exactAlarm': 'granted',
              'notifications': 'granted',
              'fullScreenIntent': 'granted',
            };
          case 'scheduleAlarm':
            final Map<dynamic, dynamic> args =
                call.arguments as Map<dynamic, dynamic>;
            expect(args['vibrateEnabled'], isTrue);
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'OK',
              'status': 'scheduledReady',
              'messageVi': 'Đã sẵn sàng: Android xác nhận báo thức lúc 06:00.',
              'scheduledNextEpochMillis': 1800000000000,
              'permissions': <String, String>{
                'exactAlarm': 'granted',
                'notifications': 'granted',
                'fullScreenIntent': 'granted',
              },
            };
          case 'snoozeAlarm':
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'OK',
              'status': 'scheduledReady',
              'messageVi': 'Đã đặt Hoãn 5 phút cho chế độ thường.',
              'permissions': <String, String>{
                'exactAlarm': 'granted',
                'notifications': 'granted',
                'fullScreenIntent': 'granted',
              },
            };
          case 'emergencyStop':
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'OK',
              'status': 'savedConfigOnly',
              'messageVi': 'Đã dừng khẩn cấp.',
              'permissions': <String, String>{
                'exactAlarm': 'granted',
                'notifications': 'granted',
                'fullScreenIntent': 'granted',
              },
            };
          case 'consumePendingRingLaunch':
            return <String, dynamic>{
              'bridgeVersion': 1,
              'errorCode': 'OK',
              'payload': null,
            };
          default:
            return <String, dynamic>{'bridgeVersion': 1, 'errorCode': 'OK'};
        }
      });

      final AndroidMethodChannelAlarmSchedulerService service =
          AndroidMethodChannelAlarmSchedulerService();
      await service.checkCapabilities();
      final AlarmScheduleResult scheduled = await service.scheduleAlarm(
        const AlarmConfig(
          id: 'morning_1',
          hour: 6,
          minute: 0,
          mode: AlarmMode.challenge,
        ),
      );
      expect(scheduled.status, AlarmSyncStatus.scheduledReady);
      expect(scheduled.errorCode, AlarmBridgeErrorCode.ok);
      expect(scheduled.scheduledNextEpochMillis, 1800000000000);

      // Challenge mode từ chối Hoãn ngay từ service layer
      final AlarmScheduleResult rejectedSnooze = await service.snoozeAlarm(
        const AlarmConfig(
          id: 'morning_1',
          hour: 6,
          minute: 0,
          mode: AlarmMode.challenge,
        ),
      );
      expect(rejectedSnooze.errorCode, AlarmBridgeErrorCode.invalidArgument);
      expect(calledMethods, isNot(contains('snoozeAlarm')));

      // Normal mode cho phép Hoãn
      final AlarmScheduleResult normalSnooze = await service.snoozeAlarm(
        const AlarmConfig(
          id: 'morning_normal',
          hour: 6,
          minute: 0,
          mode: AlarmMode.normal,
        ),
      );
      expect(normalSnooze.status, AlarmSyncStatus.scheduledReady);
      expect(calledMethods, contains('snoozeAlarm'));

      final AlarmScheduleResult stopped =
          await service.triggerEmergencyStop('morning_1');
      expect(stopped.errorCode, AlarmBridgeErrorCode.ok);
      expect(calledMethods, contains('emergencyStop'));
    });
  });

  group('UI S07 chuông reo & trạng thái quyền trên Widget', () {
    testWidgets(
      'S07 normal hiện Hoãn 5 phút và Dừng khẩn cấp; challenge ẩn Hoãn ở 320dp 200%',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool emergencyCalled = false;
        bool openQuestionCalled = false;
        bool snoozeCalled = false;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: Scaffold(
                body: AlarmRingScreen(
                  payload: const AlarmRingPayload(
                    alarmId: 'c1',
                    formattedTime: '05:45',
                    mode: AlarmMode.challenge,
                    label: 'Dậy ôn Toán',
                    subjectCode: 'TOAN',
                  ),
                  onOpenQuestion: () => openQuestionCalled = true,
                  onEmergencyStop: () => emergencyCalled = true,
                  onSnooze5Min: () => snoozeCalled = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('05:45'), findsOneWidget);
        expect(find.text(AppStrings.ringOpenQuestion), findsOneWidget);
        expect(find.text(AppStrings.ringEmergencyStop), findsOneWidget);
        expect(find.text(AppStrings.ringSnooze5m), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text(AppStrings.ringEmergencyStop));
        await tester.tap(find.text(AppStrings.ringEmergencyStop));
        await tester.pumpAndSettle();
        expect(emergencyCalled, isTrue);
        expect(openQuestionCalled, isFalse);
        expect(snoozeCalled, isFalse);

        // Chế độ thường phải có nút Hoãn 5 phút
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(360, 780)),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: Scaffold(
                body: AlarmRingScreen(
                  payload: const AlarmRingPayload(
                    alarmId: 'n1',
                    formattedTime: '06:00',
                    mode: AlarmMode.normal,
                    label: 'Báo thức buổi sáng',
                  ),
                  onOpenQuestion: () => openQuestionCalled = true,
                  onEmergencyStop: () => emergencyCalled = true,
                  onSnooze5Min: () => snoozeCalled = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.ringSnooze5m), findsOneWidget);
        await tester.tap(find.text(AppStrings.ringSnooze5m));
        await tester.pumpAndSettle();
        expect(snoozeCalled, isTrue);
      },
    );

    testWidgets(
      'ViewModel & Shell chỉ hiển thị Đã sẵn sàng sau khi OS xác nhận đủ quyền và đặt lịch',
      (WidgetTester tester) async {
        bool grantExact = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
          switch (call.method) {
            case 'checkCapabilities':
              return <String, dynamic>{
                'bridgeVersion': 1,
                'errorCode': 'OK',
                'isOsBridgeConnected': true,
                'supportsExactAlarm': true,
                'supportsFullScreenIntent': true,
                'statusSummaryVi': 'Đã nối Android.',
              };
            case 'getPermissionStatus':
              return <String, dynamic>{
                'bridgeVersion': 1,
                'errorCode':
                    grantExact ? 'OK' : 'PERMISSION_EXACT_ALARM_DENIED',
                'exactAlarm': grantExact ? 'granted' : 'denied',
                'notifications': 'granted',
                'fullScreenIntent': 'granted',
              };
            case 'scheduleAlarm':
              return <String, dynamic>{
                'bridgeVersion': 1,
                'errorCode':
                    grantExact ? 'OK' : 'PERMISSION_EXACT_ALARM_DENIED',
                'status':
                    grantExact ? 'scheduledReady' : 'osPermissionMissing',
                'messageVi':
                    grantExact ? 'Đã sẵn sàng.' : 'Thiếu quyền Exact Alarm.',
                'permissions': <String, String>{
                  'exactAlarm': grantExact ? 'granted' : 'denied',
                  'notifications': 'granted',
                  'fullScreenIntent': 'granted',
                },
              };
            case 'consumePendingRingLaunch':
              return <String, dynamic>{
                'bridgeVersion': 1,
                'errorCode': 'OK',
                'payload': null,
              };
            default:
              return <String, dynamic>{'bridgeVersion': 1, 'errorCode': 'OK'};
          }
        });

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceRepository repo =
            GuestWorkspaceRepository(store: store);
        final AndroidMethodChannelAlarmSchedulerService bridge =
            AndroidMethodChannelAlarmSchedulerService();
        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: repo,
          alarmScheduler: bridge,
        );
        await vm.initialize();

        await vm.saveAlarm(const AlarmConfig(id: 'a1', hour: 6, minute: 30));
        expect(vm.statusLabelForAlarm(vm.alarms.first),
            AppStrings.alarmPermissionMissingLabel);

        grantExact = true;
        await vm.saveAlarm(const AlarmConfig(id: 'a1', hour: 6, minute: 30));
        expect(vm.statusLabelForAlarm(vm.alarms.first), AppStrings.alarmReadyOs);

        await tester.pumpWidget(
          MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: MindClockApp(
              repository: repo,
              alarmScheduler: bridge,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.alarmReadyOs), findsOneWidget);
      },
    );
  });
}
