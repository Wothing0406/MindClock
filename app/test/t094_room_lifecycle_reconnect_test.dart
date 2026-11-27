import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/repositories/remote_community_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/community_models.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/models/study_focus_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_room_session_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _NoopCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(
      status: CameraCaptureStatus.unavailable,
      messageVi: 'Test camera.',
    );
  }
}

StudyRoomDetail _makeRoom({
  String id = 'room_t094',
  String status = 'waiting',
}) {
  return StudyRoomDetail.fromJson(<String, dynamic>{
    'roomId': id,
    'roomCode': 'MC94',
    'ownerUserId': 'u_host',
    'title': 'Phòng ôn Lý 12',
    'subjectCode': 'VAT_LY',
    'gradeLevel': 'Lớp 12',
    'status': status,
    'maxMembers': 4,
    'memberCount': 1,
    'members': <Map<String, dynamic>>[
      <String, dynamic>{
        'userId': 'u_host',
        'alias': 'Chủ phòng',
        'role': 'host',
        'isSelf': true,
      },
    ],
  });
}

class _LifecycleFakeRepo extends DebugFixtureCommunityRepository {
  StudyRoomDetail nextRoom = _makeRoom(status: 'waiting');
  Object? fetchError;
  int heartbeatCalls = 0;

  @override
  bool get isDebugFixture => false;

  @override
  Future<StudyRoomDetail> fetchRoom(String roomId) async {
    if (fetchError != null) throw fetchError!;
    return nextRoom;
  }

  @override
  Future<StudyRoomDetail> heartbeatRoom(
    String roomId, {
    String? statusNote,
  }) async {
    heartbeatCalls += 1;
    if (fetchError != null) throw fetchError!;
    return nextRoom;
  }
}

void main() {
  test(
    'T094 TC-05a: StudyRoomSessionViewModel chấp nhận waiting & active, dọn sạch ngay khi closed/expired/410',
    () async {
      final _LifecycleFakeRepo repo = _LifecycleFakeRepo();
      final StudyRoomSessionViewModel vm = StudyRoomSessionViewModel(
        repository: repo,
        initialRoom: _makeRoom(status: 'waiting'),
        enablePolling: false,
      );
      addTearDown(vm.dispose);

      expect(vm.room, isNotNull);
      expect(vm.room!.summary.status, 'waiting');

      repo.nextRoom = _makeRoom(status: 'active');
      expect(await vm.sendHeartbeat(statusNote: 'Đang giải bài'), isTrue);
      expect(repo.heartbeatCalls, 1);
      expect(vm.room!.summary.status, 'active');

      // Server trả trạng thái expired -> xóa cache phòng ngay lập tức
      repo.nextRoom = _makeRoom(status: 'expired');
      await vm.refresh();
      expect(vm.room, isNull);

      // Truyền phòng đã closed vào constructor hoặc attach cũng bị từ chối ngay
      final StudyRoomSessionViewModel closedVm = StudyRoomSessionViewModel(
        repository: repo,
        initialRoom: _makeRoom(status: 'closed'),
        enablePolling: false,
      );
      addTearDown(closedVm.dispose);
      expect(closedVm.room, isNull);

      vm.attach(_makeRoom(status: 'active'));
      expect(vm.room, isNotNull);
      repo.fetchError = const PersonalApiException(
        code: 'INVITE_EXPIRED',
        messageVi: 'Phòng không còn hiệu lực',
        httpStatus: 410,
      );
      await vm.refresh();
      expect(vm.room, isNull);
    },
  );

  testWidgets(
    'T094 TC-05b: Mở lại ứng dụng hoặc mở StudySpaceScreen khi phòng đã đóng không tự đưa user vào phòng cũ, giữ nguyên timer cá nhân',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      await guestVm.completeOnboardingAsLater(alarmOnly: false);
      addTearDown(guestVm.dispose);

      final DebugFixtureAuthGateway auth = DebugFixtureAuthGateway();
      await auth.signInWithEmail(email: 'student@mindclock.vn', password: 'password123');
      final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
        authGateway: auth,
        repository: DebugFixturePersonalFlowRepository(),
        draftStore: OfflineTextDraftStore(store: store),
        cameraGateway: _NoopCameraGateway(),
      );
      await personalVm.initialize();
      addTearDown(personalVm.dispose);

      final StudyFocusViewModel studyVm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        enablePeriodicTicker: false,
      );
      await studyVm.initialize(ownerScopeKey: personalVm.authSession.ownerScopeKey);
      studyVm.setRoomMode(StudyRoomMode.solo);
      await studyVm.startSession(overrideTaskTitle: 'Giải đề Lý 12');
      addTearDown(studyVm.dispose);

      final _LifecycleFakeRepo repo = _LifecycleFakeRepo();
      StudyRoomDetail? cachedRoom = _makeRoom(status: 'closed');

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: StudySpaceScreen(
            guestViewModel: guestVm,
            studyViewModel: studyVm,
            communityRepository: repo,
            initialRoom: cachedRoom,
            onRoomChanged: (StudyRoomDetail? r) => cachedRoom = r,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Không được mở lưới phòng đã đóng; callback dọn cachedRoom về null, đồng hồ cá nhân vẫn chạy
      expect(find.byKey(const ValueKey<String>('meet-study-room-panel')), findsNothing);
      expect(cachedRoom, isNull);
      expect(find.byKey(const ValueKey<String>('study-timer-clock')), findsOneWidget);

      // Kiểm tra MindClockShellScreen khi resume sau khi phòng bị đóng trên server (404)
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MindClockShellScreen(
            viewModel: guestVm,
            personalViewModel: personalVm,
            studyViewModel: studyVm,
            communityRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      repo.fetchError = const PersonalApiException(
        code: 'ROOM_NOT_FOUND',
        messageVi: 'Phòng đã đóng',
        httpStatus: 404,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('meet-study-room-panel')), findsNothing);
    },
  );

  test(
    'T094 TC-05c: RemoteCommunityRepository gửi đúng contract heartbeat, close, invite create/revoke/redeem và transferHost',
    () async {
      final HttpOverrides? prev = HttpOverrides.current;
      HttpOverrides.global = null;
      final HttpServer server =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
        HttpOverrides.global = prev;
      });

      final List<String> calls = <String>[];
      final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[];
      server.listen((HttpRequest req) async {
        calls.add('${req.method} ${req.uri.path}');
        final String raw = await utf8.decodeStream(req);
        if (raw.isNotEmpty) {
          bodies.add(jsonDecode(raw) as Map<String, dynamic>);
        }
        req.response.headers.contentType = ContentType.json;
        if (req.uri.path.endsWith('/invites')) {
          req.response.statusCode = HttpStatus.created;
          req.response.write(jsonEncode(<String, dynamic>{
            'inviteId': 'inv_1',
            'roomId': 'r94',
            'inviteToken': 'opaque_tok_94',
            'inviteLink': 'https://mindclock.app/study-rooms/join?invite=opaque_tok_94',
            'qrPayload': 'https://mindclock.app/study-rooms/join?invite=opaque_tok_94',
            'maxUses': 4,
            'useCount': 0,
            'revoked': false,
          }));
        } else {
          req.response.write(jsonEncode(<String, dynamic>{
            'roomId': 'r94',
            'title': 'Phòng T094',
            'status': 'active',
            'members': const <Map<String, dynamic>>[],
          }));
        }
        await req.response.close();
      });

      final DebugFixtureAuthGateway auth = DebugFixtureAuthGateway();
      await auth.signInWithEmail(email: 'host@mindclock.vn', password: 'password123');
      final RemoteCommunityRepository remote = RemoteCommunityRepository(
        apiClient: PersonalApiClient(
          baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
          authGateway: auth,
        ),
      );

      await remote.heartbeatRoom('r94', statusNote: 'Đang ôn');
      final StudyRoomInviteLink inv =
          await remote.createRoomInvite('r94', ttlMinutes: 20, maxUses: 4);
      expect(inv.inviteToken, 'opaque_tok_94');
      await remote.redeemRoomInvite(inv.qrPayload);
      await remote.revokeRoomInvite('r94', 'inv_1');
      await remote.leaveRoom('r94', transferHost: true);
      await remote.closeRoom('r94');

      expect(calls, <String>[
        'POST /v1/study-rooms/r94/heartbeat',
        'POST /v1/study-rooms/r94/invites',
        'POST /v1/study-rooms/invites/redeem',
        'POST /v1/study-rooms/r94/invites/inv_1/revoke',
        'POST /v1/study-rooms/r94/leave',
        'POST /v1/study-rooms/r94/close',
      ]);
      expect(bodies[4], const <String, dynamic>{'transferHost': true});
    },
  );
}
