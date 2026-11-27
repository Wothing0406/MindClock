import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/firebase_auth_gateway.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/alarm_occurrence.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

import 'support/loopback_v1_contract_server.dart';

class _NoopCamera implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(
      status: CameraCaptureStatus.unavailable,
      messageVi: 'Không dùng camera trong test này.',
    );
  }
}

class _FakeRingAlarmScheduler extends UnboundAlarmSchedulerService {
  AlarmRingPayload? pendingRing;

  @override
  Future<AlarmRingPayload?> consumePendingRingLaunch() async {
    return pendingRing;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'TC-01 & TC-02: Chuông sáng chuyển đúng scheduled -> ringing -> question_open -> completed, ẩn thanh khẩn cấp và không hiện lại sau khi đóng/mở lại app',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final InMemoryKeyValueStore store = InMemoryKeyValueStore();
    final _FakeRingAlarmScheduler scheduler = _FakeRingAlarmScheduler();
    final DateTime fixedNow = DateTime(2026, 11, 27, 6, 0);

    final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
      repository: GuestWorkspaceRepository(store: store),
      alarmScheduler: scheduler,
      nowProvider: () => fixedNow,
    );
    await guestVm.initialize();
    await guestVm.saveStudyProfile(
      const StudyProfile(
        alias: 'Quang',
        gradeLevel: 'Lớp 12',
        selectedSubjectCodes: <String>['math', 'english'],
      ),
    );
    await guestVm.saveAlarm(
      const AlarmConfig(
        id: 'alarm_morning',
        hour: 6,
        minute: 0,
        mode: AlarmMode.challenge,
      ),
    );
    expect(
      guestVm.occurrenceForToday('alarm_morning')?.state,
      AlarmOccurrenceState.scheduled,
    );

    // 1. Báo thức reo -> chuyển sang ringing
    scheduler.pendingRing = AlarmRingPayload(
      alarmId: 'alarm_morning',
      formattedTime: '06:00',
      mode: AlarmMode.challenge,
      label: 'Báo thức buổi sáng',
      subjectCode: 'math',
      triggeredAtEpochMillis: fixedNow.millisecondsSinceEpoch,
    );
    await guestVm.refreshOsStatus();
    expect(
      guestVm.occurrenceForToday('alarm_morning')?.state,
      AlarmOccurrenceState.ringing,
    );

    final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
      authGateway: DebugFixtureAuthGateway(),
      repository: DebugFixturePersonalFlowRepository(),
      cameraGateway: _NoopCamera(),
      draftStore: OfflineTextDraftStore(store: store),
      nowProvider: () => fixedNow,
    );
    await personalVm.initialize();
    await personalVm.signIn(email: 'hs12@mindclock.vn', password: 'Password@123');

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: MindClockShellScreen(
          viewModel: guestVm,
          personalViewModel: personalVm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Màn chuông reo hiển thị nút Mở câu hỏi -> bấm mở
    expect(find.byKey(const ValueKey<String>('ring-open-question')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('ring-open-question')));
    await tester.pumpAndSettle();

    // Chuyển sang question_open, hiện thanh Dừng khẩn cấp và câu hỏi nằm TRƯỚC tiến độ, không có thẻ Đăng xuất
    expect(
      guestVm.occurrenceForToday('alarm_morning')?.state,
      AlarmOccurrenceState.questionOpen,
    );
    expect(
      find.byKey(const ValueKey<String>('shell-emergency-stop-bar')),
      findsOneWidget,
    );
    expect(find.textContaining('Đăng xuất'), findsNothing);
    expect(find.textContaining('Mở Không gian học tập trung (local)'), findsNothing);

    final Offset questionTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('practice-primary-question-card')),
    );
    final Offset progressTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('practice-progress-card')),
    );
    expect(questionTop.dy, lessThan(progressTop.dy));

    // 2. Giải đúng câu sáng -> chuyển sang completed và TỰ ĐỘNG ẩn thanh Dừng khẩn cấp
    await tester.enterText(
      find.byKey(const ValueKey<String>('practice-answer-field')),
      '8',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('practice-submit-text')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('practice-submit-text')));
    await tester.pumpAndSettle();

    expect(
      guestVm.occurrenceForToday('alarm_morning')?.state,
      AlarmOccurrenceState.completed,
    );
    expect(
      find.byKey(const ValueKey<String>('shell-emergency-stop-bar')),
      findsNothing,
    );

    // 3. Quay về Dashboard Hôm nay -> hiện "Đã hoàn thành hôm nay", không bắt làm lại
    await tester.tap(find.byKey(const ValueKey<String>('nav-today')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('today-morning-occurrence-status')),
      findsOneWidget,
    );
    expect(find.textContaining('Đã hoàn thành hôm nay'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('today-resume-morning-question')),
      findsNothing,
    );

    // 4. Khởi động lại app từ cùng store (kể cả OS còn gửi lại cùng payload cũ) -> vẫn giữ completed, không reo lại
    final GuestWorkspaceViewModel restartedVm = GuestWorkspaceViewModel(
      repository: GuestWorkspaceRepository(store: store),
      alarmScheduler: scheduler,
      nowProvider: () => fixedNow.add(const Duration(minutes: 5)),
    );
    await restartedVm.initialize();
    expect(restartedVm.activeRingPayload, isNull);
    expect(
      restartedVm.occurrenceForToday('alarm_morning')?.state,
      AlarmOccurrenceState.completed,
    );
    expect(tester.takeException(), isNull);
  });

  test(
      'TC-03 & TC-04: bấm nhiều lần hoặc mất mạng rồi retry (kể cả trắc nghiệm ABCD) chỉ tạo 1 kết quả, khôi phục question_open và báo Lỗi đồng bộ chuẩn xác',
      () async {
    final HttpOverrides? prevOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final LoopbackV1ContractServer server =
        await LoopbackV1ContractServer.start();
    addTearDown(() async {
      await server.close();
      HttpOverrides.global = prevOverrides;
    });

    final InMemoryKeyValueStore store = InMemoryKeyValueStore();
    final DateTime fixedNow = DateTime(2026, 11, 27, 6, 15);
    final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
      repository: GuestWorkspaceRepository(store: store),
      alarmScheduler: const UnboundAlarmSchedulerService(),
      nowProvider: () => fixedNow,
    );
    await guestVm.initialize();

    final FirebaseAuthGateway auth = FirebaseAuthGateway(
      store: store,
      firebaseWebApiKey: 'test-key',
      identityBaseUri: server.identityBaseUri,
      secureTokenBaseUri: server.secureTokenBaseUri,
    );
    final PersonalFlowViewModel vm = PersonalFlowViewModel(
      authGateway: auth,
      repository: RemotePersonalFlowRepository(
        apiClient: PersonalApiClient(
          baseUri: server.baseUri,
          authGateway: auth,
          requestTimeout: const Duration(milliseconds: 180),
        ),
      ),
      cameraGateway: _NoopCamera(),
      draftStore: OfflineTextDraftStore(store: store),
      nowProvider: () => fixedNow,
    );
    vm.onAlarmOccurrenceEvent = ({
      required String alarmId,
      required String event,
      String? sessionId,
      String? questionId,
      bool hasSyncError = false,
    }) {
      switch (event) {
        case 'question_open':
          guestVm.markAlarmQuestionOpened(
            alarmId: alarmId,
            sessionId: sessionId,
            questionId: questionId,
            hasSyncError: hasSyncError,
          );
        case 'submitted':
          guestVm.markAlarmOccurrenceSubmitted(
            alarmId: alarmId,
            sessionId: sessionId,
            questionId: questionId,
            hasSyncError: hasSyncError,
          );
        case 'sync_error':
          guestVm.markAlarmOccurrenceSyncError(
            alarmId: alarmId,
            sessionId: sessionId,
            questionId: questionId,
          );
        case 'completed':
          guestVm.markAlarmOccurrenceCompleted(
            alarmId: alarmId,
            sessionId: sessionId,
            questionId: questionId,
            hasSyncError: hasSyncError,
          );
        case 'skipped':
          guestVm.markAlarmOccurrenceSkipped(
            alarmId: alarmId,
            sessionId: sessionId,
            questionId: questionId,
            hasSyncError: hasSyncError,
          );
      }
    };

    await vm.signIn(email: 'usera@example.com', password: 'password123');
    await vm.resumeOrOpenAlarmQuestion(
      alarmId: 'alarm_mcq',
      subjectCode: 'TOAN',
      challengeMode: true,
    );
    final String initialSessionId = vm.activeSession!.sessionId;

    // Gọi lại resumeOrOpenAlarmQuestion cho cùng alarmId không tạo session mới
    await vm.resumeOrOpenAlarmQuestion(
      alarmId: 'alarm_mcq',
      subjectCode: 'TOAN',
      challengeMode: true,
    );
    expect(vm.activeSession!.sessionId, initialSessionId);

    // Giả lập timeout khi bấm trắc nghiệm ABCD -> đánh dấu Lỗi đồng bộ & giữ nguyên Idempotency-Key
    server.artificialGradeDelay = const Duration(milliseconds: 500);
    final GradingResult? timeoutMcq = await vm.submitMcqAnswer(0);
    expect(timeoutMcq, isNull);
    final String? lockedKey = vm.activeIdempotencyKey;
    expect(lockedKey, isNotNull);
    expect(
      guestVm.occurrenceForToday('alarm_mcq')?.dashboardStatusLabelVi,
      'Lỗi đồng bộ',
    );

    // Bấm kép song song khi mạng khôi phục -> chỉ 1 request đi qua với cùng Idempotency-Key
    server.artificialGradeDelay = Duration.zero;
    final List<GradingResult?> doubleTap = await Future.wait(<Future<GradingResult?>>[
      vm.submitMcqAnswer(0),
      vm.submitMcqAnswer(0),
    ]);
    expect(doubleTap.whereType<GradingResult>().length, 1);
    expect(
      server.seenIdempotencyKeys.where((String k) => k == lockedKey).length,
      1,
    );
  });
}
