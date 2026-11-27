import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/models/subject_catalog.dart';
import 'package:mindclock_app/domain/models/timetable.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/me_guest_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/timetable_profile_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _TestAuth extends DebugFixtureAuthGateway {
  @override
  bool get isDebugFixture => false;
}

class _TestCam implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async =>
      const CameraCaptureOutcome(status: CameraCaptureStatus.unavailable);
}

class _FakeProfileSyncRepo extends DebugFixturePersonalFlowRepository {
  @override
  bool get isDebugFixture => false;

  StudyProfile? syncedProfile;
  WeeklyTimetable? syncedTimetable;
  StudyProfile? remoteSnapshot;
  WeeklyTimetable? remoteTimetable;

  @override
  Future<void> syncProfile({required StudyProfile profile}) async {
    syncedProfile = profile;
  }

  @override
  Future<void> syncTimetable({required WeeklyTimetable timetable}) async {
    syncedTimetable = timetable;
  }

  @override
  Future<StudyProfile?> fetchProfileSnapshot() async => remoteSnapshot;

  @override
  Future<WeeklyTimetable?> fetchTimetableSnapshot() async => remoteTimetable;
}

void main() {
  test('T078 SubjectCatalog chuẩn hóa mã môn server (TOAN/NGU_VAN/TIENG_ANH) chính xác',
      () {
    expect(SubjectCatalog.normalizeCode('TOAN'), 'math');
    expect(SubjectCatalog.normalizeCode('NGU_VAN'), 'literature');
    expect(SubjectCatalog.normalizeCode('TIENG_ANH'), 'english');
    expect(SubjectCatalog.normalizeCode('VAT_LY'), 'physics');
    expect(SubjectCatalog.normalizeCode('GDCD'), 'civic_econ');

    expect(SubjectCatalog.nameFor('TOAN'), 'Toán');
    expect(SubjectCatalog.nameFor('NGU_VAN'), 'Ngữ văn');
    expect(SubjectCatalog.isApproved('TOAN'), isTrue);
    expect(SubjectCatalog.isApproved('TIENG_ANH'), isTrue);
    expect(SubjectCatalog.isApproved('SINH_HOC'), isTrue);
  });

  test('T078 RemotePersonalFlowRepository khôi phục chuẩn /v1/me & /v1/timetable qua HTTP',
      () async {
    final HttpOverrides? prev = HttpOverrides.current;
    HttpOverrides.global = null;
    final HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      HttpOverrides.global = prev;
      await server.close(force: true);
    });

    server.listen((HttpRequest req) async {
      req.response.headers.contentType = ContentType.json;
      if (req.uri.path == '/v1/me') {
        req.response.write(jsonEncode(<String, dynamic>{
          'id': 'u_real_1',
          'alias': 'Minh Anh 12A1',
          'avatarId': 'avatar_cu_meo',
          'gradeLevel': 'Lớp 12',
          'selectedSubjects': <String>['TOAN', 'TIENG_ANH'],
          'goalLabel': 'Đạt 9+ Toán THPT',
        }));
      } else if (req.uri.path == '/v1/timetable') {
        req.response.write(jsonEncode(<String, dynamic>{
          'slots': <Map<String, dynamic>>[
            <String, dynamic>{
              'weekday': 1,
              'subjectCode': 'TOAN',
              'topicId': 'Giải tích',
              'position': 0,
            },
            <String, dynamic>{
              'weekday': 3,
              'subjectCode': 'TIENG_ANH',
              'topicId': '',
              'position': 0,
            },
          ],
        }));
      }
      await req.response.close();
    });

    final _TestAuth auth = _TestAuth();
    await auth.signInWithEmail(
      email: 'minhanh@example.test',
      password: 'Password@123',
    );
    final RemotePersonalFlowRepository repo = RemotePersonalFlowRepository(
      apiClient: PersonalApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        authGateway: auth,
      ),
    );

    final StudyProfile? profile = await repo.fetchProfileSnapshot();
    expect(profile, isNotNull);
    expect(profile!.alias, 'Minh Anh 12A1');
    expect(profile.avatarId, 'cu_meo');
    expect(profile.gradeLevel, 'Lớp 12');
    expect(profile.selectedSubjectCodes, <String>['math', 'english']);
    expect(profile.goalLabel, 'Đạt 9+ Toán THPT');

    final WeeklyTimetable? tt = await repo.fetchTimetableSnapshot();
    expect(tt, isNotNull);
    expect(tt!.dayFor(1).entries.first.subjectCode, 'math');
    expect(tt.dayFor(1).entries.first.note, 'Giải tích');
    expect(tt.dayFor(3).entries.first.subjectCode, 'english');
  });

  testWidgets(
      'T078 MeGuestScreen hiển thị Hồ sơ học sinh rõ ràng & TimetableProfileScreen sửa được Biệt danh/Avatar ở 320dp 200%',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final InMemoryKeyValueStore store = InMemoryKeyValueStore();
    final GuestWorkspaceViewModel workspaceVm = GuestWorkspaceViewModel(
      repository: GuestWorkspaceRepository(store: store),
      alarmScheduler: const UnboundAlarmSchedulerService(),
    );
    await workspaceVm.initialize();
    await workspaceVm.saveStudyProfile(
      const StudyProfile(
        alias: 'Gia Bảo',
        avatarId: 'sunrise',
        gradeLevel: 'Lớp 12',
        selectedSubjectCodes: <String>['math', 'english'],
        goalLabel: 'Đỗ Bách Khoa',
      ),
    );

    final _FakeProfileSyncRepo repo = _FakeProfileSyncRepo()
      ..remoteSnapshot = const StudyProfile(
        alias: 'Gia Bảo Server',
        avatarId: 'cu_meo',
        gradeLevel: 'Lớp 12',
        selectedSubjectCodes: <String>['math', 'physics'],
        goalLabel: 'Đỗ Bách Khoa',
      );
    final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
      authGateway: _TestAuth(),
      repository: repo,
      cameraGateway: _TestCam(),
      draftStore: OfflineTextDraftStore(store: InMemoryKeyValueStore()),
    );
    addTearDown(workspaceVm.dispose);
    addTearDown(personalVm.dispose);
    await personalVm.signIn(
      email: 'giabao@example.test',
      password: 'Password@123',
    );

    bool openedEdit = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2.0),
          ),
          child: Scaffold(
            body: MeGuestScreen(
              viewModel: workspaceVm,
              personalViewModel: personalVm,
              onEditProfileAndTimetable: () => openedEdit = true,
              onResetGuestData: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hồ sơ học sinh'), findsOneWidget);
    expect(find.text('Gia Bảo'), findsOneWidget);
    expect(find.text('giabao@example.test'), findsOneWidget);
    expect(find.text('Toán'), findsOneWidget);
    expect(find.text('Tiếng Anh'), findsOneWidget);

    final Finder editProfileBtn =
        find.byKey(const ValueKey<String>('me-edit-profile-top'));
    await tester.ensureVisible(editProfileBtn);
    await tester.tap(editProfileBtn);
    await tester.pumpAndSettle();
    expect(openedEdit, isTrue);

    final Finder syncBtn =
        find.byKey(const ValueKey<String>('me-sync-profile-now'));
    await tester.ensureVisible(syncBtn);
    await tester.tap(syncBtn);
    await tester.pumpAndSettle();
    expect(workspaceVm.profile.alias, 'Gia Bảo Server');

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: Scaffold(
          body: TimetableProfileScreen(
            viewModel: workspaceVm,
            personalViewModel: personalVm,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder aliasField =
        find.byKey(const ValueKey<String>('profile-alias-input'));
    await tester.ensureVisible(aliasField);
    await tester.enterText(aliasField, 'Minh Khôi 12A');
    final Finder avatarBtn =
        find.byKey(const ValueKey<String>('profile-avatar-cao_giay'));
    await tester.ensureVisible(avatarBtn);
    await tester.tap(avatarBtn);
    final Finder saveBtn =
        find.byKey(const ValueKey<String>('save-profile-changes'));
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(workspaceVm.profile.alias, 'Minh Khôi 12A');
    expect(workspaceVm.profile.avatarId, 'cao_giay');
    expect(repo.syncedProfile?.alias, 'Minh Khôi 12A');
    expect(repo.syncedProfile?.avatarId, 'cao_giay');
  });
}
