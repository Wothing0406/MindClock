import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/repositories/remote_community_repository.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/community_models.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_room_session_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_room_session_panel.dart';

StudyRoomDetail _room({bool host = true}) => StudyRoomDetail.fromJson({
      'roomId': 'room-t073',
      'roomCode': 'T073',
      'title': 'Phòng ôn chung',
      'maxMembers': 4,
      'memberCount': 2,
      'members': [
        {
          'userId': 'self',
          'alias': 'Bạn',
          'isSelf': true,
          'role': host ? 'host' : 'member',
        },
        {
          'userId': 'peer',
          'alias': 'Bạn học',
          'isSelf': false,
          'role': host ? 'member' : 'host',
        },
      ],
    });

class _Repo extends DebugFixtureCommunityRepository {
  StudyRoomDetail current;
  _Repo({bool host = true}) : current = _room(host: host);
  Object? removeError;
  Object? deleteError;
  int removeCalls = 0;
  int deleteCalls = 0;

  @override
  bool get isDebugFixture => false;

  @override
  Future<StudyRoomDetail> removeRoomMember(
      String roomId, String memberUserId) async {
    removeCalls++;
    if (removeError != null) throw removeError!;
    current = current.copyWith(
        members: current.members
            .where((member) => member.userId != memberUserId)
            .toList(growable: false));
    return current;
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    deleteCalls++;
    if (deleteError != null) throw deleteError!;
  }
}

Future<void> _pumpPanel(
    WidgetTester tester, _Repo repo, StudyRoomSessionViewModel vm) async {
  await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: Scaffold(
          body: SingleChildScrollView(
              child: StudyRoomSessionPanel(
                  viewModel: vm, repository: repo, animateAi: false)))));
  await tester.pumpAndSettle();
}

void main() {
  test('remote repository gửi DELETE member và DELETE room đúng contract',
      () async {
    final HttpOverrides? originalOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      HttpOverrides.global = originalOverrides;
    });
    final List<String> calls = <String>[];
    server.listen((HttpRequest request) async {
      calls.add('${request.method} ${request.uri.path}');
      if (request.uri.path.endsWith('/members/peer')) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(<String, dynamic>{
          'roomId': 'room-t073',
          'title': 'Phòng ôn chung',
          'members': <Map<String, dynamic>>[
            <String, dynamic>{
              'userId': 'self',
              'alias': 'Bạn',
              'isSelf': true,
              'role': 'host',
            },
          ],
        }));
      } else {
        request.response.statusCode = HttpStatus.noContent;
      }
      await request.response.close();
    });
    final DebugFixtureAuthGateway auth = DebugFixtureAuthGateway();
    await auth.signInWithEmail(email: 'host@example.test', password: 'test');
    final RemoteCommunityRepository repository = RemoteCommunityRepository(
      apiClient: PersonalApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        authGateway: auth,
      ),
    );
    final StudyRoomDetail detail =
        await repository.removeRoomMember('room-t073', 'peer');
    expect(detail.members.map((member) => member.userId), <String>['self']);
    await repository.deleteRoom('room-t073');
    expect(calls, <String>[
      'DELETE /v1/study-rooms/room-t073/members/peer',
      'DELETE /v1/study-rooms/room-t073',
    ]);
  });

  test('host remove/delete cập nhật state; member không gọi được', () async {
    final repo = _Repo();
    final vm = StudyRoomSessionViewModel(
        repository: repo, initialRoom: repo.current, enablePolling: false);
    addTearDown(vm.dispose);
    expect(await vm.removeMember('peer'), isTrue);
    expect(vm.room!.members.map((m) => m.userId), ['self']);
    expect(await vm.deleteRoom(), isTrue);
    expect(vm.room, isNull);

    final memberRepo = _Repo(host: false);
    final memberVm = StudyRoomSessionViewModel(
        repository: memberRepo,
        initialRoom: memberRepo.current,
        enablePolling: false);
    addTearDown(memberVm.dispose);
    expect(await memberVm.removeMember('self'), isFalse);
    expect(await memberVm.deleteRoom(), isFalse);
    expect(memberRepo.removeCalls, 0);
    expect(memberRepo.deleteCalls, 0);
  });

  testWidgets('host xác nhận kick và xóa; timer shell không bị thay thế',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    final vm = StudyRoomSessionViewModel(
        repository: repo, initialRoom: repo.current, enablePolling: false);
    addTearDown(vm.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true),
            child: child!),
        home: Scaffold(
            body: SingleChildScrollView(
                child: StudyRoomSessionPanel(
                    viewModel: vm, repository: repo, animateAi: false)))));
    await tester.pumpAndSettle();
    final remove = find.byKey(const ValueKey<String>('room-remove-peer'));
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text('Mời thành viên ra?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('room-remove-confirm')));
    await tester.pumpAndSettle();
    expect(repo.removeCalls, 1);

    final delete = find.byKey(const ValueKey<String>('meet-delete-room'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Xóa phòng học?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('room-delete-confirm')));
    await tester.pumpAndSettle();
    expect(repo.deleteCalls, 1);
    expect(vm.room, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member không thấy kick hoặc xóa phòng', (tester) async {
    final repo = _Repo(host: false);
    final vm = StudyRoomSessionViewModel(
        repository: repo, initialRoom: repo.current, enablePolling: false);
    addTearDown(vm.dispose);
    await _pumpPanel(tester, repo, vm);
    expect(
        find.byKey(const ValueKey<String>('room-remove-self')), findsNothing);
    expect(
        find.byKey(const ValueKey<String>('meet-delete-room')), findsNothing);
  });
}
