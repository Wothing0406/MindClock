import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/repositories/remote_study_ai_gateway.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/models/study_focus_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/auth_session_gateway.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
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
  int endCueCalls = 0;
  int shownReminderCalls = 0;

  @override
  bool get isPlatformConnected => true;

  @override
  Future<void> cancelStudyReminder() async {}

  @override
  Future<StudyNotificationPermission> getNotificationPermissionStatus() async =>
      StudyNotificationPermission.granted;

  @override
  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings() async {
    return const DigitalWellbeingOpenResult(
      opened: false,
      target: DigitalWellbeingTarget.unavailable,
      messageVi: 'Không hỗ trợ',
    );
  }

  @override
  Future<void> playSessionEndCue() async {
    endCueCalls += 1;
  }

  @override
  Future<StudyNotificationPermission> requestNotificationPermission() async =>
      StudyNotificationPermission.granted;

  @override
  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  }) async {
    shownReminderCalls += 1;
  }
}

class _AuthStubGateway implements AuthSessionGateway {
  _AuthStubGateway(this._session);
  final AuthSession _session;

  @override
  bool get isDebugFixture => false;

  @override
  Future<AuthSession> loadSavedSession() async => _session;

  @override
  Future<AuthSession> markSessionExpired({String? messageVi}) async =>
      const AuthSession.guest();

  @override
  Future<AuthSession> refreshIdToken() async => _session;

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _session;

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) async =>
      _session;
}

class _LoopbackStudyServer {
  _LoopbackStudyServer._(this._server);
  final HttpServer _server;
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  Uri get baseUri => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_LoopbackStudyServer> start() async {
    final HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final _LoopbackStudyServer wrapper = _LoopbackStudyServer._(server);
    server.listen(wrapper._handle);
    return wrapper;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final String rawBody = await utf8.decoder.bind(request).join();
    final Map<String, dynamic>? body = rawBody.trim().isEmpty
        ? null
        : jsonDecode(rawBody) as Map<String, dynamic>;
    requests.add(<String, dynamic>{
      'method': request.method,
      'path': request.uri.path,
      'body': body,
    });

    request.response.headers.contentType = ContentType.json;
    if (request.method == 'POST' && request.uri.path == '/v1/study/sessions') {
      request.response.statusCode = 200;
      request.response.write(
        jsonEncode(<String, dynamic>{
          'sessionId': 'srv_study_loop_1',
          'clientSessionId': body?['clientSessionId'] ?? '',
          'state': 'active',
        }),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'POST' &&
        request.uri.path.endsWith('/finish')) {
      request.response.statusCode = 200;
      final int inApp = (body?['inAppFocusSeconds'] as num?)?.toInt() ?? 0;
      final String finalStatus = body?['finalStatus'] as String? ?? 'completed';
      final int awarded =
          (finalStatus == 'completed' && inApp >= 300) ? (inApp ~/ 300).clamp(0, 12) : 0;
      request.response.write(
        jsonEncode(<String, dynamic>{
          'sessionId': 'srv_study_loop_1',
          'clientSessionId': body?['clientSessionId'] ?? '',
          'state': finalStatus,
          'xpAwarded': awarded,
          'xpStatus': awarded > 0 ? 'confirmed' : 'below_minimum_duration',
          'dailyStudyXpRemaining': 30 - awarded,
        }),
      );
      await request.response.close();
      return;
    }

    request.response.statusCode = 404;
    await request.response.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T052 R5 Không gian học: solo/AI, Học sâu im lặng & server EXP ledger', () {
    test(
      'TC-04: Học sâu im lặng tắt âm/nhắc & đồng bộ loopback nhận confirmedXpAwarded từ /finish',
      () async {
        final HttpOverrides? previousHttpOverrides = HttpOverrides.current;
        HttpOverrides.global = null;
        final _LoopbackStudyServer server = await _LoopbackStudyServer.start();
        addTearDown(() async {
          await server.close();
          HttpOverrides.global = previousHttpOverrides;
        });

        final _FakeClock clock = _FakeClock(DateTime(2026, 11, 18, 9, 0, 0));
        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();
        int xpSyncedCallbackCount = 0;

        final RemoteStudyAiGateway aiGateway = RemoteStudyAiGateway(
          apiClient: PersonalApiClient(
            baseUri: server.baseUri,
            authGateway: _AuthStubGateway(
              const AuthSession(
                status: AuthStatus.authenticated,
                uid: 'uid_r5_1',
                email: 'r5@mindclock.test',
                idToken: 'fake-id-token',
                refreshToken: 'fake-refresh',
              ),
            ),
          ),
        );

        final StudyFocusViewModel vm = StudyFocusViewModel(
          repository: LocalStudyFocusRepository(store: store),
          bridge: bridge,
          aiGateway: aiGateway,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
          onStudyXpSynced: () {
            xpSyncedCallbackCount += 1;
          },
        );
        await vm.initialize(ownerScopeKey: 'uid:uid_r5_1');
        await vm.setAccountAuthenticated(true, gradeLevel: 'Lớp 11');

        // Bật Học sâu im lặng + Học một mình
        vm.setRoomMode(StudyRoomMode.solo);
        vm.setCadence(StudyCadence.deepSilent);
        expect(vm.draftEndSoundEnabled, isFalse);
        expect(vm.draftNotifyOutsideApp, isFalse);

        // Thử bật âm báo khi đang Học sâu phải bị giữ ở false
        vm.setEndSoundEnabled(true);
        await vm.setNotifyOutsideApp(true);
        expect(vm.draftEndSoundEnabled, isFalse);
        expect(vm.draftNotifyOutsideApp, isFalse);

        vm.setDurationMinutes(15);
        await vm.startSession(overrideTaskTitle: 'Ôn hàm số lớp 11');
        expect(vm.activeSnapshot!.roomMode, StudyRoomMode.solo);
        expect(vm.activeSnapshot!.cadence, StudyCadence.deepSilent);

        // Hỏi AI trong chế độ solo bị chặn từ ViewModel
        final bool aiSentInSolo =
            await vm.requestAiHelp(questionText: 'Giải giúp bài này');
        expect(aiSentInSolo, isFalse);

        // Rời app quá 31s trong Học sâu -> tuyệt đối KHÔNG bắn reminder
        await vm.onAppBackgrounded();
        clock.advance(const Duration(seconds: 31));
        await vm.onAppResumed();
        expect(bridge.shownReminderCalls, 0);

        // Hoàn thành đủ 15 phút -> không phát âm hết giờ vì Học sâu im lặng
        clock.advance(const Duration(minutes: 15));
        vm.checkClockTick();
        expect(vm.activeSnapshot!.status, StudyFocusStatus.completed);
        expect(bridge.endCueCalls, 0);

        final StudyFocusRecord? saved = await vm.saveFinishedSession();
        expect(saved, isNotNull);
        expect(saved!.xpAwardedByTimer, 0);
        expect(saved.estimatedStudyXp, 3);
        expect(saved.confirmedXpAwarded, isNull);

        await vm.waitForPendingRemoteWork();

        expect(vm.history, hasLength(1));
        expect(vm.history.first.remoteFinishSynced, isTrue);
        expect(vm.history.first.confirmedXpAwarded, 3);
        expect(vm.history.first.dailyStudyXpRemaining, 27);
        expect(xpSyncedCallbackCount, 1);

        expect(
          server.requests.any(
            (r) =>
                r['path'] == '/v1/study/sessions' &&
                r['body']['roomMode'] == 'solo' &&
                r['body']['cadence'] == 'deep',
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'TC-03: StudySpaceScreen phân tách Học một mình vs Học cùng MindClock và Học sâu im lặng',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(420, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final _FakeClock clock = _FakeClock(DateTime(2026, 11, 18, 10, 0, 0));
        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final _FakeStudyFocusBridge bridge = _FakeStudyFocusBridge();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        final StudyFocusViewModel studyVm = StudyFocusViewModel(
          repository: LocalStudyFocusRepository(store: store),
          bridge: bridge,
          nowProvider: () => clock.now,
          enablePeriodicTicker: false,
        );
        await studyVm.initialize();

        await tester.pumpWidget(
          MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: StudySpaceScreen(
              guestViewModel: guestVm,
              studyViewModel: studyVm,
              onClose: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mặc định withAi: thấy phần câu hỏi cá nhân hóa và Gemini Live
        expect(
          find.byKey(const ValueKey<String>('study-personalized-generate-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('study-live-consent-toggle')),
          findsOneWidget,
        );

        // Chuyển sang Học một mình -> ẩn phần AI & hiện thông báo không AI
        await tester.tap(find.byKey(const ValueKey<String>('study-mode-solo')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('study-personalized-generate-button')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('study-live-consent-toggle')),
          findsNothing,
        );

        // Bắt đầu phiên Học một mình -> trong phiên không có AI Socratic card
        final Finder startBtn = find.byKey(
          const ValueKey<String>('study-start-button'),
        );
        await Scrollable.ensureVisible(
          tester.element(startBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(startBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('study-ai-question-input')),
          findsNothing,
        );

        // Kết thúc 15 phút -> màn tổng kết hiện EXP dự kiến: 3 XP
        clock.advance(const Duration(minutes: 25));
        await tester.tap(find.byKey(const ValueKey<String>('study-finish-button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('study-summary-xp')),
          findsOneWidget,
        );
        expect(find.textContaining('EXP dự kiến'), findsOneWidget);

        // Lưu phiên -> quay lại setup và thử Học cùng MindClock + Học sâu
        final Finder saveBtn = find.byKey(
          const ValueKey<String>('study-save-session-button'),
        );
        await Scrollable.ensureVisible(
          tester.element(saveBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        final Finder aiModeBtn = find.byKey(
          const ValueKey<String>('study-mode-ai'),
        );
        await Scrollable.ensureVisible(
          tester.element(aiModeBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(aiModeBtn);
        await tester.pumpAndSettle();

        final Finder deepChip = find.byKey(
          const ValueKey<String>('study-cadence-deep'),
        );
        await Scrollable.ensureVisible(
          tester.element(deepChip),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(deepChip);
        await tester.pumpAndSettle();

        // Trong Học sâu, Gemini Live ẩn nhưng AI text vẫn sẵn sàng trong phiên
        expect(
          find.byKey(const ValueKey<String>('study-live-consent-toggle')),
          findsNothing,
        );

        await Scrollable.ensureVisible(
          tester.element(find.byKey(const ValueKey<String>('study-start-button'))),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(find.byKey(const ValueKey<String>('study-start-button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('study-deep-silent-pill')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('study-ai-companion-label')),
          findsOneWidget,
        );
        expect(find.textContaining('chỉ trả chữ khi hỏi'), findsOneWidget);
      },
    );
  });
}
