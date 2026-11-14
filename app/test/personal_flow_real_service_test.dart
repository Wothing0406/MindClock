import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/app.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/firebase_auth_gateway.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/strings/app_strings.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

import 'support/loopback_v1_contract_server.dart';

class _FakeCameraGateway implements CameraCaptureGateway {
  int captureCalls = 0;
  CameraCaptureOutcome nextOutcome = CameraCaptureOutcome(
    status: CameraCaptureStatus.captured,
    bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]),
    mimeType: 'image/jpeg',
    fileName: 'attempt.jpg',
  );

  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    captureCalls += 1;
    return nextOutcome;
  }
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

  PersonalFlowViewModel createRealVm({
    required InMemoryKeyValueStore store,
    required _FakeCameraGateway camera,
    Duration requestTimeout = const Duration(seconds: 15),
    int Function()? draftNowMillis,
  }) {
    final FirebaseAuthGateway authGateway = FirebaseAuthGateway(
      store: store,
      firebaseWebApiKey: 'test-firebase-key',
      identityBaseUri: server.identityBaseUri,
      secureTokenBaseUri: server.secureTokenBaseUri,
    );
    final PersonalApiClient client = PersonalApiClient(
      baseUri: server.baseUri,
      authGateway: authGateway,
      requestTimeout: requestTimeout,
    );
    final RemotePersonalFlowRepository repo = RemotePersonalFlowRepository(
      apiClient: client,
    );
    return PersonalFlowViewModel(
      authGateway: authGateway,
      repository: repo,
      cameraGateway: camera,
      draftStore: OfflineTextDraftStore(
        store: store,
        nowMillis: draftNowMillis,
      ),
    );
  }

  group('Dịch vụ thật /v1 & hợp đồng T017', () {
    test('PF-TC-01: Token 401 refresh một lần; hết hạn hẳn không phá báo thức local',
        () async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final _FakeCameraGateway camera = _FakeCameraGateway();
      final PersonalFlowViewModel vm = createRealVm(store: store, camera: camera);
      final GuestWorkspaceViewModel alarmVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await alarmVm.initialize();
      await alarmVm.saveAlarm(
        const AlarmConfig(
          id: 'alarm_safe',
          hour: 6,
          minute: 0,
          mode: AlarmMode.challenge,
        ),
      );

      final bool signedIn = await vm.signIn(
        email: 'usera@example.com',
        password: 'password123',
      );
      expect(signedIn, isTrue);

      // Token xoay vòng phía server -> client nhận 401 lần 1, tự refresh 1 lần và tiếp tục thành công
      server.tokenVersion = 2;
      await vm.startSession(subjectCode: 'TOAN', challengeMode: true);
      expect(vm.authSession.status, AuthStatus.authenticated);
      expect(vm.activeSession?.isOfflineLocal, isFalse);

      // Token hết hạn hẳn -> chuyển sang reauthRequired, báo thức local vẫn nguyên vẹn
      server.forcePermanentAuthFailure = true;
      await vm.refreshProgressAndHistory();
      expect(vm.authSession.status, AuthStatus.reauthRequired);
      expect(alarmVm.alarms.length, 1);
      expect(alarmVm.alarms.first.id, 'alarm_safe');
      final AlarmScheduleResult stopRes =
          await alarmVm.triggerEmergencyStop(alarmId: 'alarm_safe');
      expect(stopRes.errorCode, AlarmBridgeErrorCode.ok);
    });

    test('PF-TC-03/04: Challenge ẩn gợi ý lần 1-2, uncertain không tăng sai, retry giữ Idempotency-Key',
        () async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final _FakeCameraGateway camera = _FakeCameraGateway();
      final PersonalFlowViewModel vm = createRealVm(
        store: store,
        camera: camera,
        requestTimeout: const Duration(milliseconds: 200),
      );
      await vm.signIn(email: 'usera@example.com', password: 'password123');
      await vm.startSession(subjectCode: 'TOAN', challengeMode: true);

      // Lần 1 sai rõ -> ẩn gợi ý
      final GradingResult? r1 = await vm.submitTextAnswer(
        answerValue: '5',
        reasoningText: '2x - 3 = 10 nen x = 5',
      );
      expect(r1?.verdict, GradingVerdict.incorrect);
      expect(vm.clearWrongCount, 1);
      expect(vm.canRevealMethodHint, isFalse);

      // Uncertain không tăng lượt sai
      final GradingResult? u1 = await vm.submitTextAnswer(
        answerValue: '6',
        reasoningText: 'uncertain mo nhat',
      );
      expect(u1?.verdict, GradingVerdict.uncertain);
      expect(vm.clearWrongCount, 1);

      // Lần 2 sai rõ -> vẫn ẩn gợi ý
      await vm.submitTextAnswer(
        answerValue: '7',
        reasoningText: '2x = 14',
      );
      expect(vm.clearWrongCount, 2);
      expect(vm.canRevealMethodHint, isFalse);

      // Lần 3 sai rõ -> hiện gợi ý phương pháp
      final GradingResult? r3 = await vm.submitTextAnswer(
        answerValue: '9',
        reasoningText: '2x = 18',
      );
      expect(r3?.verdict, GradingVerdict.incorrect);
      expect(vm.clearWrongCount, 3);
      expect(vm.canRevealMethodHint, isTrue);

      // Timeout lần gửi đúng -> giữ nguyên Idempotency-Key & clientAttemptId khi retry
      server.artificialGradeDelay = const Duration(milliseconds: 500);
      final GradingResult? timedOut = await vm.submitTextAnswer(
        answerValue: '8',
        reasoningText: '2x - 6 = 10 => 2x = 16 => x = 8',
      );
      expect(timedOut, isNull);
      expect(vm.hasRetryableTextFailure, isTrue);
      final String? firstKey = vm.activeIdempotencyKey;
      final String? firstAttemptId = vm.activeClientAttemptId;
      expect(firstKey, isNotNull);

      // Retry lại khi server nhanh lại -> cùng key & không cấp trùng XP
      server.artificialGradeDelay = Duration.zero;
      final GradingResult? retried = await vm.submitTextAnswer(
        answerValue: '8',
        reasoningText: '2x - 6 = 10 => 2x = 16 => x = 8',
      );
      expect(retried?.verdict, GradingVerdict.correct);
      expect(retried?.authoritativeXpAwarded, 10);
      expect(vm.progressSummary.xp, 10);
      expect(
        server.seenIdempotencyKeys.where((String k) => k == firstKey).length,
        1,
      );
      expect(firstAttemptId, isNotNull);
    });

    test('PF-TC-06: Camera chỉ gọi khi bấm chụp; hủy không upload; xác nhận mới gửi multipart',
        () async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final _FakeCameraGateway camera = _FakeCameraGateway();
      final PersonalFlowViewModel vm = createRealVm(store: store, camera: camera);
      await vm.signIn(email: 'usera@example.com', password: 'password123');
      await vm.startSession(subjectCode: 'TOAN');

      // Khởi tạo chưa từng gọi camera
      expect(camera.captureCalls, 0);

      await vm.capturePhotoForReview();
      expect(camera.captureCalls, 1);
      expect(vm.pendingPhotoPreview, isNotNull);
      expect(server.attemptMultipartCount, 0);

      // Hủy trước khi gửi -> không gọi /attempts
      vm.cancelPhotoPreview();
      expect(vm.pendingPhotoPreview, isNull);
      expect(server.attemptMultipartCount, 0);

      // Chụp lại & xác nhận -> gọi multipart POST /attempts
      await vm.capturePhotoForReview();
      final GradingResult? photoRes =
          await vm.confirmAndUploadPhotoAttempt(answerValue: '8');
      expect(photoRes?.verdict, GradingVerdict.correct);
      expect(server.attemptMultipartCount, 1);
      expect(vm.pendingPhotoPreview, isNull);
    });

    test('PF-TC-07/08: Bản nháp 24h chỉ đồng bộ khi xác nhận; User A và User B cô lập hoàn toàn',
        () async {
      int fakeClockMillis = 1_700_000_000_000;
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final _FakeCameraGateway camera = _FakeCameraGateway();
      final PersonalFlowViewModel vm = createRealVm(
        store: store,
        camera: camera,
        draftNowMillis: () => fakeClockMillis,
      );

      // Khách offline làm câu mẫu -> không giả chấm, lưu nháp chữ 24h
      await vm.startSession(subjectCode: 'TOAN');
      final GradingResult? offlineRes = await vm.submitTextAnswer(
        answerValue: '8',
        reasoningText: '2x = 16',
      );
      expect(offlineRes, isNull);
      await vm.saveOfflineTextDraft(
        answerValue: '8',
        reasoningText: '2x = 16',
      );
      expect(vm.savedDraft, isNotNull);

      // User A đăng nhập -> không thấy nháp của guest, lưu nháp riêng cho User A
      await vm.signIn(email: 'usera@example.com', password: 'password123');
      expect(vm.savedDraft, isNull);
      await vm.startSession(subjectCode: 'TOAN');
      await vm.saveOfflineTextDraft(
        answerValue: '8',
        reasoningText: '2x - 6 = 10 => x = 8',
      );
      expect(vm.savedDraft, isNotNull);
      // Không tự upload trước khi xác nhận
      expect(server.answerPostCount, 0);

      // Đăng xuất User A & đăng nhập User B -> không thấy nháp/XP User A
      await vm.signOut();
      expect(vm.progressSummary.isServerAuthoritative, isFalse);
      await vm.signIn(email: 'userb@example.com', password: 'password123');
      expect(vm.savedDraft, isNull);
      expect(vm.progressSummary.xp, 0);

      // Đăng nhập lại User A trong hạn 24h -> thấy nháp của User A, xác nhận gửi -> cộng XP
      await vm.signOut();
      await vm.signIn(email: 'usera@example.com', password: 'password123');
      expect(vm.savedDraft, isNotNull);
      final GradingResult? synced = await vm.confirmAndUploadSavedDraft();
      expect(synced?.verdict, GradingVerdict.correct);
      expect(vm.progressSummary.xp, 10);
      expect(vm.savedDraft, isNull);

      // Kiểm tra hết hạn sau 24 giờ
      await vm.saveOfflineTextDraft(
        answerValue: '8',
        reasoningText: 'test ttl',
      );
      fakeClockMillis += const Duration(hours: 24, minutes: 1).inMilliseconds;
      await vm.initialize();
      expect(vm.savedDraft, isNull);
    });

    test('PF-TC-08b: Quyền sở hữu A/B bị chặn 403 trên API thật', () async {
      final InMemoryKeyValueStore storeA = InMemoryKeyValueStore();
      final InMemoryKeyValueStore storeB = InMemoryKeyValueStore();
      final PersonalFlowViewModel vmA = createRealVm(
        store: storeA,
        camera: _FakeCameraGateway(),
      );
      await vmA.signIn(email: 'usera@example.com', password: 'password123');
      await vmA.startSession(subjectCode: 'TOAN');
      final String sessionIdOfA = vmA.activeSession!.sessionId;

      final FirebaseAuthGateway authB = FirebaseAuthGateway(
        store: storeB,
        firebaseWebApiKey: 'test-firebase-key',
        identityBaseUri: server.identityBaseUri,
        secureTokenBaseUri: server.secureTokenBaseUri,
      );
      await authB.signInWithEmail(
        email: 'userb@example.com',
        password: 'password123',
      );
      final RemotePersonalFlowRepository repoB = RemotePersonalFlowRepository(
        apiClient: PersonalApiClient(
          baseUri: server.baseUri,
          authGateway: authB,
        ),
      );

      expect(
        () => repoB.submitTextAnswer(
          sessionId: sessionIdOfA,
          answerValue: '8',
          reasoningText: 'doc trom session A',
          clientAttemptId: 'att_cross',
          idempotencyKey: 'idemp_cross',
        ),
        throwsA(
          predicate<PersonalApiException>(
            (PersonalApiException e) => e.isForbidden && e.httpStatus == 403,
          ),
        ),
      );
    });

    testWidgets(
      'PF-TC-02: Debug fixture luôn mang nhãn rõ, tách dịch vụ thật, hiển thị tốt ở 320dp chữ 200%',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MindClockApp(
              repository: GuestWorkspaceRepository(store: store),
              authGateway: DebugFixtureAuthGateway(),
              personalRepository: DebugFixturePersonalFlowRepository(),
              cameraGateway: _FakeCameraGateway(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Bỏ qua chào mừng để vào tab Luyện tập
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('guest-skip-later')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('guest-skip-later')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('nav-practice')));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.debugFixtureLabel), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
