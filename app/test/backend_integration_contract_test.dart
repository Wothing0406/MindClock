import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_alarm_sync_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_study_ai_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/repositories/remote_alarm_sync_gateway.dart';
import 'package:mindclock_app/data/repositories/remote_study_ai_gateway.dart';
import 'package:mindclock_app/data/services/firebase_auth_gateway.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/pending_alarm_event_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/models/study_ai_models.dart';
import 'package:mindclock_app/domain/models/study_focus_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/alarm_sync_gateway.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/today_screen.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

import 'support/loopback_v1_contract_server.dart';

class _RecordingAlarmScheduler implements AlarmSchedulerService {
  int scheduleCallCount = 0;
  int emergencyStopCallCount = 0;
  final List<String> callLog = <String>[];

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
    scheduleCallCount += 1;
    callLog.add('schedule:${config.id}');
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.scheduledReady,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã lập lịch báo thức trên hệ thống.',
    );
  }

  @override
  Future<AlarmScheduleResult> cancelAlarm(String alarmId) async {
    callLog.add('cancel:$alarmId');
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã hủy báo thức local.',
    );
  }

  @override
  Future<AlarmScheduleResult> snoozeAlarm(
    AlarmConfig config, {
    int minutes = 5,
  }) async {
    callLog.add('snooze:${config.id}');
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.scheduledReady,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã hoãn 5 phút.',
    );
  }

  @override
  Future<AlarmScheduleResult> triggerEmergencyStop({String? alarmId}) async {
    emergencyStopCallCount += 1;
    callLog.add('emergency_stop:${alarmId ?? "none"}');
    return const AlarmScheduleResult(
      status: AlarmSyncStatus.savedConfigOnly,
      errorCode: AlarmBridgeErrorCode.ok,
      messageVi: 'Đã dừng khẩn cấp chuông và rung.',
    );
  }

  @override
  Future<bool> openPermissionSettings(AlarmPermissionAction action) async =>
      true;

  @override
  Future<AlarmRingPayload?> consumePendingRingLaunch() async => null;
}

class _StubStudyFocusBridge implements StudyFocusBridge {
  @override
  bool get isPlatformConnected => true;

  @override
  Future<void> cancelStudyReminder() async {}

  @override
  Future<StudyNotificationPermission> getNotificationPermissionStatus() async =>
      StudyNotificationPermission.granted;

  @override
  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings() async =>
      const DigitalWellbeingOpenResult(
        opened: false,
        target: DigitalWellbeingTarget.unavailable,
        messageVi: 'MindClock không khóa app khác.',
      );

  @override
  Future<void> playSessionEndCue() async {}

  @override
  Future<StudyNotificationPermission> requestNotificationPermission() async =>
      StudyNotificationPermission.granted;

  @override
  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  }) async {}
}

class _FakeClock {
  _FakeClock(this.now);
  DateTime now;
  void advance(Duration delta) => now = now.add(delta);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HttpOverrides? previousHttpOverrides;
  late LoopbackV1ContractServer server;

  setUp(() async {
    previousHttpOverrides = HttpOverrides.global;
    HttpOverrides.global = null;
    server = await LoopbackV1ContractServer.start();
  });

  tearDown(() async {
    await server.close();
    HttpOverrides.global = previousHttpOverrides;
  });

  ({
    FirebaseAuthGateway authGateway,
    PersonalApiClient apiClient,
    GuestWorkspaceViewModel guestVm,
    StudyFocusViewModel studyVm,
    _RecordingAlarmScheduler scheduler,
    _FakeClock clock,
  }) buildHarness({
    Duration requestTimeout = const Duration(seconds: 15),
    InMemoryKeyValueStore? sharedStore,
  }) {
    final InMemoryKeyValueStore store = sharedStore ?? InMemoryKeyValueStore();
    final FirebaseAuthGateway authGateway = FirebaseAuthGateway(
      store: store,
      firebaseWebApiKey: 'test-firebase-key',
      identityBaseUri: server.identityBaseUri,
      secureTokenBaseUri: server.secureTokenBaseUri,
    );
    final PersonalApiClient apiClient = PersonalApiClient(
      baseUri: server.baseUri,
      authGateway: authGateway,
      requestTimeout: requestTimeout,
    );
    final _RecordingAlarmScheduler scheduler = _RecordingAlarmScheduler();
    final _FakeClock clock = _FakeClock(DateTime(2026, 11, 14, 7, 0, 0));

    final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
      repository: GuestWorkspaceRepository(store: store),
      alarmScheduler: scheduler,
      alarmSyncGateway: RemoteAlarmSyncGateway(apiClient: apiClient),
      pendingAlarmEventStore: PendingAlarmEventStore(
        store: store,
        nowProvider: () => clock.now,
      ),
      nowProvider: () => clock.now,
    );

    final StudyFocusViewModel studyVm = StudyFocusViewModel(
      repository: LocalStudyFocusRepository(store: store),
      bridge: _StubStudyFocusBridge(),
      aiGateway: RemoteStudyAiGateway(apiClient: apiClient),
      nowProvider: () => clock.now,
      enablePeriodicTicker: false,
    );

    return (
      authGateway: authGateway,
      apiClient: apiClient,
      guestVm: guestVm,
      studyVm: studyVm,
      scheduler: scheduler,
      clock: clock,
    );
  }

  group('Tích hợp Frontend ↔ Backend /v1 (T019)', () {
    testWidgets(
        'INT-TC-01: Lưu & lập lịch báo thức local trước; API lỗi 503 không hủy chuông OS; UI phân biệt 3 trạng thái',
        (WidgetTester tester) async {
      final h = buildHarness();
      await h.guestVm.initialize();
      await h.authGateway.signInWithEmailPassword(
        email: 'usera@mindclock.vn',
        password: 'password123',
      );
      await h.guestVm.setAccountContext(
        ownerScopeKey: 'user:uid_a',
        isAuthenticated: true,
      );

      // Giả lập backend báo thức tạm lỗi 503 ở lần đồng bộ đầu
      server.failNextAlarmSync = true;
      await h.guestVm.saveAlarm(
        const AlarmConfig(
          id: 'alarm_ch1',
          hour: 6,
          minute: 15,
          mode: AlarmMode.challenge,
          subjectCode: 'TOAN',
          repeatWeekdays: <int>[1, 3, 5],
        ),
      );
      await h.guestVm.waitForPendingServerSync();

      expect(h.scheduler.scheduleCallCount, 1);
      final AlarmConfig afterFail = h.guestVm.alarms.first;
      expect(afterFail.syncStatus, AlarmSyncStatus.scheduledReady);
      expect(afterFail.serverSyncStatus, AlarmServerSyncStatus.syncFailed);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: AnimatedBuilder(
              animation: h.guestVm,
              builder: (_, __) => TodayScreen(
                viewModel: h.guestVm,
                onCreateAlarm: () {},
                onEditAlarm: (_) {},
                onOpenTimetableAndProfile: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Đã lưu local'), findsOneWidget);
      expect(find.text('OS: Đã sẵn sàng'), findsOneWidget);
      expect(
        find.text('Server: Chưa đồng bộ server (lỗi/offline)'),
        findsOneWidget,
      );

      // Đồng bộ lại thành công
      await h.guestVm.syncAllAlarmsAndEvents();
      await tester.pump();

      expect(h.guestVm.alarms.first.serverSyncStatus,
          AlarmServerSyncStatus.synced);
      expect(h.guestVm.alarms.first.serverAlarmId, isNotNull);
      expect(find.text('Server: Đã đồng bộ server'), findsOneWidget);
    });

    test(
        'INT-TC-02: Dừng khẩn cấp dừng chuông OS ngay, ghi queue 7 ngày khi offline, gửi dismiss khi có mạng và KHÔNG re-schedule',
        () async {
      final h = buildHarness();
      await h.guestVm.initialize();
      await h.guestVm.saveAlarm(
        const AlarmConfig(
          id: 'alarm_em',
          hour: 6,
          minute: 0,
          mode: AlarmMode.challenge,
        ),
      );
      final int schedulesBeforeStop = h.scheduler.scheduleCallCount;

      // Dừng khẩn cấp khi đang offline/chưa đăng nhập: phải tắt chuông OS ngay & lưu hàng đợi local
      await h.guestVm.triggerEmergencyStop(
        alarmId: 'alarm_em',
        activeSessionId: 'srv_s_em_1',
      );
      expect(h.scheduler.emergencyStopCallCount, 1);
      expect(h.scheduler.scheduleCallCount, schedulesBeforeStop);
      expect(h.guestVm.pendingEventCount, 1);

      // Đăng nhập + tạo phiên để server có session owner khớp, rồi flush sự kiện
      await h.authGateway.signInWithEmailPassword(
        email: 'usera@mindclock.vn',
        password: 'password123',
      );
      await h.apiClient.postJson(
        '/sessions',
        idempotencyKey: 'create-s-em',
        body: <String, dynamic>{'localSessionId': 's_em_1'},
      );
      await h.guestVm.setAccountContext(
        ownerScopeKey: 'user:uid_a',
        isAuthenticated: true,
      );
      await h.guestVm.waitForPendingServerSync();

      // Sự kiện dismiss đã đồng bộ hoặc queue của guest sạch; nếu tạo sự kiện mới dưới user đã đăng nhập khi offline -> flush được lên server
      server.forcePermanentAuthFailure = true;
      await h.guestVm.triggerEmergencyStop(
        alarmId: 'alarm_em',
        activeSessionId: 'srv_s_em_1',
      );
      expect(h.guestVm.pendingEventCount, 1);
      expect(h.scheduler.scheduleCallCount, schedulesBeforeStop);

      server.forcePermanentAuthFailure = false;
      await h.guestVm.syncAllAlarmsAndEvents();
      expect(h.guestVm.pendingEventCount, 0);
      expect(server.recordedEmergencyDismissEvents, contains('srv_s_em_1'));
      expect(h.scheduler.scheduleCallCount, schedulesBeforeStop);
    });

    test(
        'INT-TC-03: Tạo phiên học /v1/study/sessions gửi đúng clientSessionId khi retry và không gửi leftAt/XP',
        () async {
      final h = buildHarness();
      await h.studyVm.initialize(ownerScopeKey: 'user:uid_a');
      await h.authGateway.signInWithEmailPassword(
        email: 'usera@mindclock.vn',
        password: 'password123',
      );
      await h.studyVm.setAccountAuthenticated(true, gradeLevel: 'Lớp 9');

      // Khi offline, startSession vẫn chạy bộ đếm local ngay
      server.forcePermanentAuthFailure = true;
      h.studyVm.setCustomTaskTitle('Ôn hình học');
      h.studyVm.setDurationMinutes(25);
      await h.studyVm.startSession();
      await h.studyVm.waitForPendingRemoteWork();

      expect(h.studyVm.hasOngoingSession, isTrue);
      expect(h.studyVm.activeSnapshot!.remoteSessionSynced, isFalse);

      // Có mạng lại và bấm Thử tạo phiên server lại: dùng lại clientSessionId + createIdempotencyKey
      server.forcePermanentAuthFailure = false;
      final bool created = await h.studyVm.retryCreateRemoteSession();
      expect(created, isTrue);
      expect(h.studyVm.activeSnapshot!.remoteSessionSynced, isTrue);
      expect(server.studyCreateRequests, hasLength(1));
      final Map<String, dynamic> payload = server.studyCreateRequests.single;
      expect(payload['clientSessionId'], h.studyVm.activeSnapshot!.sessionId);
      expect(payload.containsKey('leftAt'), isFalse);
      expect(payload.containsKey('xp'), isFalse);
    });

    testWidgets(
        'INT-TC-04: Hỏi AI qua /v1/study/help xử lý 429 & timeout, giữ câu đang nhập khi lỗi, gửi tối đa 3 lượt gần nhất và không tự gửi lại',
        (WidgetTester tester) async {
      final h = buildHarness(requestTimeout: const Duration(milliseconds: 120));
      await h.guestVm.initialize();
      await h.studyVm.initialize(ownerScopeKey: 'user:uid_a');
      await h.authGateway.signInWithEmailPassword(
        email: 'usera@mindclock.vn',
        password: 'password123',
      );
      await h.studyVm.setAccountAuthenticated(true, gradeLevel: 'Lớp 9');

      h.studyVm.setCustomTaskTitle('Giải hệ phương trình');
      await h.studyVm.startSession();
      await h.studyVm.waitForPendingRemoteWork();

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: AnimatedBuilder(
            animation: h.studyVm,
            builder: (_, __) => StudySpaceScreen(
              guestViewModel: h.guestVm,
              studyViewModel: h.studyVm,
              onClose: () {},
            ),
          ),
        ),
      );

      // 1) Giả lập HTTP 429: giữ nguyên text người dùng nhập
      server.rateLimitNextStudyHelp = true;
      await tester.enterText(
        find.byKey(const ValueKey<String>('study-ai-question-input')),
        'Làm sao khử ẩn y trước?',
      );
      await tester.tap(find.byKey(const ValueKey<String>('study-ai-send-button')));
      await tester.pumpAndSettle();

      expect(h.studyVm.aiStatus, StudyAiRequestStatus.rateLimited);
      expect(
        find.byKey(const ValueKey<String>('study-ai-error-banner')),
        findsOneWidget,
      );
      final TextField fieldAfter429 = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('study-ai-question-input')),
      );
      expect(fieldAfter429.controller?.text, 'Làm sao khử ẩn y trước?');

      // Không tự gửi lại khi cập nhật trạng thái auth
      final int helpRequestsAfter429 = server.studyHelpRequests.length;
      await h.studyVm.setAccountAuthenticated(true, gradeLevel: 'Lớp 9');
      expect(server.studyHelpRequests.length, helpRequestsAfter429);

      // 2) Giả lập Timeout (>120ms): câu hỏi vẫn giữ nguyên
      server.artificialStudyHelpDelay = const Duration(milliseconds: 300);
      await tester.tap(find.byKey(const ValueKey<String>('study-ai-retry-button')));
      await tester.pumpAndSettle();
      expect(h.studyVm.aiStatus, StudyAiRequestStatus.timeout);
      expect(fieldAfter429.controller?.text, 'Làm sao khử ẩn y trước?');

      // 3) Thử lại thành công -> xóa ô nhập & hiển thị gợi ý Socratic
      server.artificialStudyHelpDelay = Duration.zero;
      await tester.tap(find.byKey(const ValueKey<String>('study-ai-retry-button')));
      await tester.pumpAndSettle();
      expect(h.studyVm.aiStatus, StudyAiRequestStatus.ready);
      expect(fieldAfter429.controller?.text, '');
      expect(h.studyVm.aiTurns.length, 2);

      // Gửi thêm 2 câu hỏi nữa để kiểm tra cắt recentTurns tối đa 3 lượt gần nhất
      await h.studyVm.requestAiHelp(questionText: 'Bước 2 tính x sao ạ?');
      await h.studyVm.requestAiHelp(questionText: 'Bước 3 thử lại nghiệm thế nào?');
      expect(h.studyVm.aiTurns.length, 6);
      final List<dynamic> lastSentTurns =
          server.studyHelpRequests.last['recentTurns'] as List<dynamic>;
      expect(lastSentTurns.length, 3);
    });

    test(
        'INT-TC-05: Kết thúc phiên học idempotent; API lỗi 503 vẫn thoát màn học ngay và retry dùng lại finishIdempotencyKey',
        () async {
      final h = buildHarness();
      await h.studyVm.initialize(ownerScopeKey: 'user:uid_a');
      await h.authGateway.signInWithEmailPassword(
        email: 'usera@mindclock.vn',
        password: 'password123',
      );
      await h.studyVm.setAccountAuthenticated(true, gradeLevel: 'Lớp 9');

      h.studyVm.setCustomTaskTitle('Đọc hiểu Văn');
      await h.studyVm.startSession();
      await h.studyVm.waitForPendingRemoteWork();

      h.clock.advance(const Duration(minutes: 10));
      await h.studyVm.finishSession(early: true);

      server.failNextStudyFinish = true;
      final StudyFocusRecord? saved = await h.studyVm.saveFinishedSession(
        notesDone: 'Hoàn thành ý chính',
      );
      await h.studyVm.waitForPendingRemoteWork();

      // Phải thoát phiên ngay (activeSnapshot == null) dù server lỗi
      expect(saved, isNotNull);
      expect(h.studyVm.activeSnapshot, isNull);
      expect(h.studyVm.history.first.remoteFinishSynced, isFalse);

      // Retry thủ công cùng finishIdempotencyKey -> thành công; gọi lại thêm lần nữa -> idempotent
      final String finishIdempKey = h.studyVm.history.first.finishIdempotencyKey;
      expect(finishIdempKey, isNotEmpty);

      final bool ok1 = await h.studyVm.retryFinishRecordSync(saved!.sessionId);
      final bool ok2 = await h.studyVm.retryFinishRecordSync(saved.sessionId);
      expect(ok1, isTrue);
      expect(ok2, isTrue);
      expect(h.studyVm.history.first.remoteFinishSynced, isTrue);
      expect(server.uniqueStudyFinishCount, 1);
      expect(h.studyVm.history.first.xpAwardedByTimer, 0);
    });

    test(
        'INT-TC-06: Token 401 refresh tự động; hết hạn không hỏng chuông local; đổi A/B cô lập báo thức & chat 403',
        () async {
      final h = buildHarness();
      await h.guestVm.initialize();
      await h.studyVm.initialize(ownerScopeKey: 'user:uid_a');
      await h.authGateway.signInWithEmailPassword(
        email: 'usera@mindclock.vn',
        password: 'password123',
      );
      await h.guestVm.setAccountContext(
        ownerScopeKey: 'user:uid_a',
        isAuthenticated: true,
      );

      await h.guestVm.saveAlarm(
        const AlarmConfig(
          id: 'alarm_a1',
          hour: 5,
          minute: 45,
          mode: AlarmMode.challenge,
        ),
      );
      await h.guestVm.waitForPendingServerSync();
      final String alarmAServerId = h.guestVm.alarms.first.serverAlarmId!;

      // Token A hết hạn trên server -> refresh 1 lần thành công khi đồng bộ
      server.tokenVersion = 2;
      await h.guestVm.syncAllAlarmsAndEvents();
      expect(h.guestVm.alarms.first.serverSyncStatus,
          AlarmServerSyncStatus.synced);

      // Chuyển sang tài khoản B: báo thức local trên máy vẫn còn, nhưng metadata server cũ bị reset
      // và User B gọi sửa báo thức của User A phải bị 403
      await h.authGateway.signInWithEmailPassword(
        email: 'userb@mindclock.vn',
        password: 'password123',
      );
      await h.guestVm.setAccountContext(
        ownerScopeKey: 'user:uid_b',
        isAuthenticated: true,
      );
      await h.studyVm.setOwnerScope('user:uid_b');

      expect(h.guestVm.alarms, hasLength(1));
      expect(h.studyVm.aiTurns, isEmpty);

      await expectLater(
        () => h.apiClient.patchJson(
          '/alarms/$alarmAServerId',
          idempotencyKey: 'cross-owner-patch',
          body: <String, dynamic>{'enabled': false},
        ),
        throwsA(isA<PersonalApiException>()
            .having((PersonalApiException e) => e.isForbidden, 'isForbidden', true)),
      );
    });

    test(
        'INT-TC-07: Tách biệt fixture debug rõ ràng và .env.example không lộ secret thật',
        () async {
      const DebugFixtureAlarmSyncGateway debugAlarm =
          DebugFixtureAlarmSyncGateway();
      const DebugFixtureStudyAiGateway debugAi = DebugFixtureStudyAiGateway();
      expect(debugAlarm.isDebugFixture, isTrue);
      expect(debugAi.isDebugFixture, isTrue);

      final File envExample = File('.env.example');
      final File targetEnv = envExample.existsSync()
          ? envExample
          : File('app/.env.example');
      expect(targetEnv.existsSync(), isTrue);
      final String envContent = targetEnv.readAsStringSync();
      expect(envContent, contains('MINDCLOCK_API_BASE_URL'));
      expect(envContent, contains('MINDCLOCK_FIREBASE_WEB_API_KEY'));
      expect(envContent, isNot(contains('AIza')));
    });
  });
}
