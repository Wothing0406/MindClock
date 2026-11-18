import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/models/daily_study_plan.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/models/timetable.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/auth_session_gateway.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/me_guest_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/timetable_profile_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _NoopCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(
      status: CameraCaptureStatus.unavailable,
      messageVi: 'Chưa dùng camera',
    );
  }
}

class _StubAuthGateway implements AuthSessionGateway {
  _StubAuthGateway(this._session);

  AuthSession _session;
  int signOutCalls = 0;

  @override
  bool get isDebugFixture => false;

  @override
  Future<AuthSession> loadSavedSession() async => _session;

  @override
  Future<AuthSession> markSessionExpired({String? messageVi}) async {
    _session = const AuthSession.guest();
    return _session;
  }

  @override
  Future<AuthSession> refreshIdToken() async => _session;

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _session;
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _session;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    _session = const AuthSession.guest();
  }
}

class _SpyPersonalFlowRepository extends DebugFixturePersonalFlowRepository {
  final List<StudyProfile> syncedProfiles = <StudyProfile>[];
  final List<Map<String, dynamic>> recordedConsents = <Map<String, dynamic>>[];
  final List<WeeklyTimetable> syncedTimetables = <WeeklyTimetable>[];
  int deleteAccountCalls = 0;

  @override
  bool get isDebugFixture => false;

  @override
  Future<void> syncProfile({required StudyProfile profile}) async {
    syncedProfiles.add(profile);
  }

  @override
  Future<void> recordConsent({
    required String scope,
    required String version,
    required bool granted,
  }) async {
    recordedConsents.add(<String, dynamic>{
      'scope': scope,
      'version': version,
      'granted': granted,
    });
  }

  @override
  Future<void> syncTimetable({required WeeklyTimetable timetable}) async {
    syncedTimetables.add(timetable);
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalls += 1;
  }
}

class _RecordedHttpCall {
  const _RecordedHttpCall({
    required this.method,
    required this.path,
    this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic>? body;
}

class _LoopbackAccountSyncServer {
  _LoopbackAccountSyncServer._(this._server);

  final HttpServer _server;
  final List<_RecordedHttpCall> calls = <_RecordedHttpCall>[];
  bool failNextRequest = false;

  Uri get baseUri => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_LoopbackAccountSyncServer> start() async {
    final HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final _LoopbackAccountSyncServer wrapper =
        _LoopbackAccountSyncServer._(server);
    server.listen(wrapper._handle);
    return wrapper;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final String rawBody = await utf8.decoder.bind(request).join();
    Map<String, dynamic>? jsonBody;
    if (rawBody.trim().isNotEmpty) {
      jsonBody = jsonDecode(rawBody) as Map<String, dynamic>;
    }
    calls.add(
      _RecordedHttpCall(
        method: request.method,
        path: request.uri.path,
        body: jsonBody,
      ),
    );

    if (failNextRequest) {
      failNextRequest = false;
      request.response.statusCode = 503;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{
          'error': <String, dynamic>{
            'code': 'SERVICE_UNAVAILABLE',
            'message': 'Temporary offline test error',
          },
        }),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/v1/progress/summary') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{
          'xpTotal': 0,
          'currentStreakDays': 0,
          'longestStreakDays': 0,
          'completedSessionsCount': 0,
        }),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/v1/study/sessions') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{'items': <dynamic>[]}),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'PATCH' && request.uri.path == '/v1/me') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{'id': 'uid_sync_1', 'status': 'ok'}),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/v1/me/consent') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{'ok': true}),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'PUT' && request.uri.path == '/v1/timetable') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{'saved': true}),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'DELETE' && request.uri.path == '/v1/me') {
      request.response.statusCode = 202;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{
          'status': 'deleted',
          'userId': 'uid_sync_1',
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

  group('T051 đồng bộ hồ sơ, TKB, consent & xóa tài khoản', () {
    test(
      'TC-03: syncProfile, recordConsent, syncTimetable, deleteAccount khớp endpoint /v1 và chịu lỗi mạng',
      () async {
        final HttpOverrides? previousHttpOverrides = HttpOverrides.current;
        HttpOverrides.global = null;
        final _LoopbackAccountSyncServer server =
            await _LoopbackAccountSyncServer.start();
        addTearDown(() async {
          await server.close();
          HttpOverrides.global = previousHttpOverrides;
        });

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final _StubAuthGateway authGateway = _StubAuthGateway(
          const AuthSession(
            status: AuthStatus.authenticated,
            uid: 'uid_sync_1',
            email: 'sync@mindclock.test',
            idToken: 'fake-id-token-a',
            refreshToken: 'fake-refresh-a',
            emailVerified: true,
          ),
        );
        final PersonalApiClient client = PersonalApiClient(
          baseUri: server.baseUri,
          authGateway: authGateway,
        );
        final RemotePersonalFlowRepository repo = RemotePersonalFlowRepository(
          apiClient: client,
        );
        final PersonalFlowViewModel vm = PersonalFlowViewModel(
          authGateway: authGateway,
          repository: repo,
          cameraGateway: _NoopCameraGateway(),
          draftStore: OfflineTextDraftStore(store: store),
        );
        await vm.initialize();
        expect(vm.authSession.isAuthenticated, isTrue);
        server.calls.clear();

        const StudyProfile profile = StudyProfile(
          alias: 'Minh Anh',
          avatarId: 'owl',
          gradeLevel: 'Lớp 11',
          selectedSubjectCodes: <String>['math', 'english'],
          prioritySubjects: <PrioritySubject>[
            PrioritySubject(subjectCode: 'math', level: PriorityLevel.high),
          ],
          goalLabel: 'Ôn đại học',
        );
        final bool profileOk = await vm.syncProfileToServer(profile);
        expect(profileOk, isTrue);

        final bool consentOk = await vm.recordConsent(
          scope: 'terms_and_privacy',
          version: '2026-11',
          granted: true,
        );
        expect(consentOk, isTrue);

        final WeeklyTimetable timetable = WeeklyTimetable(
          days: <DaySchedule>[
            const DaySchedule(
              weekday: 1,
              entries: <TimetableEntry>[
                TimetableEntry(
                  id: 't1',
                  subjectCode: 'math',
                  startMinutes: 450,
                  note: 'Tiết 1',
                ),
              ],
            ),
            const DaySchedule(weekday: 7, isRestDay: true),
          ],
        );
        final bool ttOk = await vm.syncTimetableToServer(timetable);
        expect(ttOk, isTrue);

        // Lỗi 503 ở syncProfile không làm mất phiên hoặc crash
        server.failNextRequest = true;
        final bool profileOfflineFail = await vm.syncProfileToServer(profile);
        expect(profileOfflineFail, isFalse);
        expect(vm.authSession.isAuthenticated, isTrue);

        // Lỗi 503 ở deleteAccount giữ nguyên phiên để người dùng thử lại
        server.failNextRequest = true;
        final bool deleteFailed = await vm.deleteAccount();
        expect(deleteFailed, isFalse);
        expect(vm.authSession.isAuthenticated, isTrue);
        expect(vm.errorMessageVi, isNotNull);

        // Delete thành công trả 202, xóa draft scoped và signOut
        final bool deleteOk = await vm.deleteAccount();
        expect(deleteOk, isTrue);
        expect(vm.authSession.isAuthenticated, isFalse);
        expect(authGateway.signOutCalls, 1);

        expect(server.calls.length, 6);
        expect(server.calls[0].method, 'PATCH');
        expect(server.calls[0].path, '/v1/me');
        expect(server.calls[0].body?['alias'], 'Minh Anh');
        expect(server.calls[0].body?['gradeLevel'], 'Lớp 11');
        expect(
          server.calls[0].body?['selectedSubjects'],
          <String>['math', 'english'],
        );

        expect(server.calls[1].method, 'POST');
        expect(server.calls[1].path, '/v1/me/consent');
        expect(server.calls[1].body?['scope'], 'terms_and_privacy');
        expect(server.calls[1].body?['version'], '2026-11');
        expect(server.calls[1].body?['granted'], isTrue);

        expect(server.calls[2].method, 'PUT');
        expect(server.calls[2].path, '/v1/timetable');
        final List<dynamic> slots =
            server.calls[2].body?['slots'] as List<dynamic>;
        expect(slots.length, 1);
        expect((slots.first as Map<String, dynamic>)['weekday'], 1);
        expect((slots.first as Map<String, dynamic>)['subjectCode'], 'math');
        expect((slots.first as Map<String, dynamic>)['topicId'], 'Tiết 1');

        expect(server.calls[5].method, 'DELETE');
        expect(server.calls[5].path, '/v1/me');
      },
    );

    testWidgets(
      'TC-04: TimetableProfileScreen lưu hồ sơ không làm mất alias, avatarId, selfAssessments và confirmedPlan',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(420, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        const DailyStudyPlan confirmedPlan = DailyStudyPlan(
          plannerRuleVersion: DailyStudyPlan.currentRuleVersion,
          catalogVersion: DailyStudyPlan.currentCatalogVersion,
          source: 'rule_based',
          sourceLabelVi: 'Gợi ý theo quy tắc',
          gradeLevel: 'Lớp 11',
          items: <DailyPlanItem>[
            DailyPlanItem(
              subjectCode: 'math',
              subjectNameVi: 'Toán',
              titleVi: 'Ôn hàm số bậc 2',
              durationMinutes: 15,
              reasonVi: 'Môn ưu tiên',
              hasApprovedQuestions: true,
              assessment: SubjectSelfAssessment.examPrep,
            ),
          ],
          confirmedAtIso: '2026-11-18T06:00:00Z',
        );

        await guestVm.saveStudyProfile(
          const StudyProfile(
            alias: 'Hoàng Nam',
            avatarId: 'sunburst',
            gradeLevel: 'Lớp 11',
            selectedSubjectCodes: <String>['math', 'english'],
            prioritySubjects: <PrioritySubject>[
              PrioritySubject(subjectCode: 'math', level: PriorityLevel.high),
            ],
            selfAssessments: <String, SubjectSelfAssessment>{
              'math': SubjectSelfAssessment.examPrep,
            },
            confirmedPlan: confirmedPlan,
            goalLabel: 'Mục tiêu cũ',
          ),
        );

        final _StubAuthGateway authGateway = _StubAuthGateway(
          const AuthSession(
            status: AuthStatus.authenticated,
            uid: 'uid_sync_1',
            email: 'nam@mindclock.test',
            idToken: 'fake-id-token-a',
            refreshToken: 'fake-refresh-a',
          ),
        );
        final _SpyPersonalFlowRepository spyRepo =
            _SpyPersonalFlowRepository();
        final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
          authGateway: authGateway,
          repository: spyRepo,
          cameraGateway: _NoopCameraGateway(),
          draftStore: OfflineTextDraftStore(store: store),
        );
        await personalVm.initialize();

        await tester.pumpWidget(
          MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: Scaffold(
              body: TimetableProfileScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder grade12Chip = find.byKey(
          const ValueKey<String>('profile-grade-Lớp 12'),
        );
        await Scrollable.ensureVisible(
          tester.element(grade12Chip),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(grade12Chip);
        await tester.pumpAndSettle();

        final Finder saveBtn = find.byKey(
          const ValueKey<String>('save-profile-changes'),
        );
        await Scrollable.ensureVisible(
          tester.element(saveBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(guestVm.profile.gradeLevel, 'Lớp 12');
        expect(guestVm.profile.alias, 'Hoàng Nam');
        expect(guestVm.profile.avatarId, 'sunburst');
        expect(
          guestVm.profile.selfAssessments['math'],
          SubjectSelfAssessment.examPrep,
        );
        expect(guestVm.profile.confirmedPlan?.isConfirmed, isTrue);
        expect(guestVm.profile.confirmedPlan?.items.length, 1);

        expect(spyRepo.syncedProfiles.length, 1);
        expect(spyRepo.syncedProfiles.first.alias, 'Hoàng Nam');
        expect(spyRepo.syncedProfiles.first.gradeLevel, 'Lớp 12');
      },
    );

    testWidgets(
      'TC-05: MeGuestScreen & MindClockShellScreen xác nhận 2 bước xóa tài khoản, quay về Welcome và giữ nguyên báo thức local',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(420, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();
        await guestVm.setAccountContext(
          ownerScopeKey: 'uid:uid_sync_1',
          isAuthenticated: true,
        );
        await guestVm.saveStudyProfile(
          const StudyProfile(
            alias: 'Lan Vy',
            gradeLevel: 'Lớp 10',
            selectedSubjectCodes: <String>['math'],
            confirmedPlan: DailyStudyPlan(
              plannerRuleVersion: DailyStudyPlan.currentRuleVersion,
              catalogVersion: DailyStudyPlan.currentCatalogVersion,
              source: 'rule_based',
              sourceLabelVi: 'Gợi ý theo quy tắc',
              gradeLevel: 'Lớp 10',
              items: <DailyPlanItem>[],
              confirmedAtIso: '2026-11-18T06:00:00Z',
            ),
          ),
        );
        await guestVm.saveAlarm(
          const AlarmConfig(
            id: 'local-morning-1',
            hour: 5,
            minute: 45,
            mode: AlarmMode.challenge,
          ),
        );

        final _StubAuthGateway authGateway = _StubAuthGateway(
          const AuthSession(
            status: AuthStatus.authenticated,
            uid: 'uid_sync_1',
            email: 'lanvy@mindclock.test',
            idToken: 'fake-id-token-a',
            refreshToken: 'fake-refresh-a',
          ),
        );
        final _SpyPersonalFlowRepository spyRepo =
            _SpyPersonalFlowRepository();
        final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
          authGateway: authGateway,
          repository: spyRepo,
          cameraGateway: _NoopCameraGateway(),
          draftStore: OfflineTextDraftStore(store: store),
        );
        await personalVm.initialize();

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

        // Chuyển sang tab Tôi (index 3)
        await tester.tap(find.byKey(const ValueKey<String>('nav-me')));
        await tester.pumpAndSettle();

        final Finder deleteBtn = find.byKey(
          const ValueKey<String>('me-delete-account-btn'),
        );
        expect(deleteBtn, findsOneWidget);

        await Scrollable.ensureVisible(
          tester.element(deleteBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Bước 1: hiện thẻ xác nhận, có thể hủy giữ lại tài khoản
        expect(
          find.byKey(const ValueKey<String>('me-delete-account-confirm-card')),
          findsOneWidget,
        );
        final Finder cancelBtn = find.byKey(
          const ValueKey<String>('me-delete-account-cancel'),
        );
        await Scrollable.ensureVisible(
          tester.element(cancelBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.pumpAndSettle();
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('me-delete-account-confirm-card')),
          findsNothing,
        );
        expect(personalVm.authSession.isAuthenticated, isTrue);

        // Bước 2: mở lại và xác nhận xóa thật
        await Scrollable.ensureVisible(
          tester.element(deleteBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        final Finder confirmBtn = find.byKey(
          const ValueKey<String>('me-delete-account-confirm'),
        );
        await Scrollable.ensureVisible(
          tester.element(confirmBtn),
          alignment: 0.4,
          duration: Duration.zero,
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Đã xóa trên server, đăng xuất local, xóa profile scoped, quay về Welcome
        expect(spyRepo.deleteAccountCalls, 1);
        expect(personalVm.authSession.isAuthenticated, isFalse);
        expect(guestVm.ownerScopeKey, 'guest');
        expect(guestVm.profile.alias, isEmpty);
        expect(
          find.byKey(const ValueKey<String>('welcome-permission-guide')),
          findsOneWidget,
        );

        // Báo thức local trên thiết bị VẪN ĐƯỢC GIỮ NGUYÊN
        expect(guestVm.alarms.length, 1);
        expect(guestVm.alarms.first.id, 'local-morning-1');
        expect(guestVm.alarms.first.hour, 5);
        expect(guestVm.alarms.first.minute, 45);
      },
    );

    test(
      'MeGuestScreen & DebugFixture repository hỗ trợ chữ ký sync/delete không văng lỗi',
      () async {
        final DebugFixturePersonalFlowRepository fixtureRepo =
            DebugFixturePersonalFlowRepository();
        await fixtureRepo.syncProfile(
          profile: const StudyProfile(alias: 'Test'),
        );
        await fixtureRepo.recordConsent(
          scope: 'terms_and_privacy',
          version: '2026-11',
          granted: true,
        );
        await fixtureRepo.syncTimetable(
          timetable: WeeklyTimetable(),
        );
        await fixtureRepo.deleteAccount();
        expect(fixtureRepo.isDebugFixture, isTrue);
      },
    );

    testWidgets(
      'MeGuestScreen ẩn nút xóa tài khoản khi chưa đăng nhập',
      (WidgetTester tester) async {
        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        await tester.pumpWidget(
          MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: Scaffold(
              body: MeGuestScreen(
                viewModel: guestVm,
                onEditProfileAndTimetable: () {},
                onResetGuestData: () {},
                onDeleteAccount: () async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('me-delete-account-btn')),
          findsNothing,
        );
      },
    );
  });
}
