import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/repositories/remote_community_repository.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/community_models.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_room_session_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_room_session_panel.dart';

StudyRoomDetail _room(
        {String title = 'Phòng ôn', bool host = true, String id = 'room1'}) =>
    StudyRoomDetail.fromJson({
      'roomId': id,
      'title': title,
      'maxMembers': 4,
      'memberCount': 1,
      'members': [
        {
          'userId': 'self',
          'alias': 'Bạn',
          'isSelf': true,
          'role': host ? 'host' : 'member'
        }
      ],
    });

class _Repo extends DebugFixtureCommunityRepository {
  @override
  bool get isDebugFixture => false;
  int fetchCalls = 0;
  int saveCalls = 0;
  StudyRoomDetail current = _room();
  Future<StudyRoomDetail> Function()? onFetch;
  Future<StudyRoomDetail> Function()? onSave;
  Future<void> Function()? onLeave;
  @override
  Future<StudyRoomDetail> fetchRoom(String roomId) {
    fetchCalls++;
    return onFetch?.call() ?? Future.value(current);
  }

  @override
  Future<StudyRoomDetail> updateRoomSettings(
    String roomId, {
    String? title,
    int? maxMembers,
    String? visibility,
    bool? aiCompanionEnabled,
  }) async {
    saveCalls++;
    if (onSave != null) return onSave!();
    current = current.copyWith(
        summary: current.summary.copyWith(
            title: title,
            maxMembers: maxMembers,
            visibility: visibility,
            aiCompanionEnabled: aiCompanionEnabled));
    return current;
  }

  @override
  Future<void> leaveRoom(String roomId, {bool transferHost = false}) async {
    await onLeave?.call();
  }
}

StudyRoomSessionViewModel _vm(_Repo repo) => StudyRoomSessionViewModel(
    repository: repo, initialRoom: repo.current, enablePolling: false);

Future<void> _tap(WidgetTester tester, String key) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final finder = find.byKey(ValueKey<String>(key));
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
      'không gửi hai settings trùng khi thao tác chưa xong, disposed bỏ response',
      () async {
    final repo = _Repo();
    final vm = _vm(repo);
    final pending = Completer<StudyRoomDetail>();
    repo.onSave = () => pending.future;
    final saving = vm.saveSettings(title: 'Đang lưu');
    expect(await vm.saveSettings(maxMembers: 3), isFalse);
    expect(repo.saveCalls, 1);
    vm.dispose();
    pending.complete(_room(title: 'Response muộn'));
    expect(await saving, isFalse);
  });

  test('rời phòng lỗi mạng vẫn giữ thông tin và có thể thử lại', () async {
    final repo = _Repo();
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    repo.onLeave = () async => throw const PersonalApiException(
        code: 'NETWORK', messageVi: 'Chưa rời được trên máy chủ');
    expect(await vm.leave(), isFalse);
    expect(vm.room, isNotNull);
    expect(vm.message, 'Chưa rời được trên máy chủ');
    repo.onLeave = null;
    expect(await vm.leave(), isTrue);
    expect(vm.room, isNull);
  });
  test('offline giữ snapshot, thử lại nhận snapshot mới; 404 bỏ phòng',
      () async {
    final repo = _Repo();
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    repo.onFetch = () async => throw const PersonalApiException(
        code: 'NETWORK', messageVi: 'Chưa kết nối được', httpStatus: 503);
    await vm.refresh();
    expect(vm.room, isNotNull);
    expect(vm.message, 'Chưa kết nối được');
    repo.onFetch = () async => _room(title: 'Phòng cập nhật');
    await vm.refresh();
    expect(vm.room!.summary.title, 'Phòng cập nhật');
    expect(vm.syncedAt, isNotNull);
    expect(vm.message, isNull);
    repo.onFetch = () async => throw const PersonalApiException(
        code: 'ROOM_NOT_FOUND', messageVi: 'Phòng đã đóng', httpStatus: 404);
    await vm.refresh();
    expect(vm.room, isNull);
    expect(vm.message, 'Phòng đã đóng');
  });

  testWidgets('poll không chồng; background/dispose ngừng, resume cập nhật',
      (tester) async {
    final repo = _Repo();
    final pending = Completer<StudyRoomDetail>();
    repo.onFetch = () => pending.future;
    final vm =
        StudyRoomSessionViewModel(repository: repo, initialRoom: repo.current);
    await tester.pump(const Duration(seconds: 5));
    expect(repo.fetchCalls, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(repo.fetchCalls, 1);
    vm.setForeground(false);
    pending.complete(_room(title: 'Bản cũ'));
    await tester.pump();
    expect(vm.room!.summary.title, 'Phòng ôn');
    await tester.pump(const Duration(seconds: 20));
    expect(repo.fetchCalls, 1);
    repo.onFetch = () async => _room(title: 'Sau resume');
    vm.setForeground(true);
    await tester.pump();
    expect(repo.fetchCalls, 2);
    expect(vm.room!.summary.title, 'Sau resume');
    vm.dispose();
    await tester.pump(const Duration(seconds: 20));
    expect(repo.fetchCalls, 2);
  });

  test('response poll cũ không ghi đè settings hoặc làm sống lại phòng đã rời',
      () async {
    final repo = _Repo();
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    var pending = Completer<StudyRoomDetail>();
    repo.onFetch = () => pending.future;
    final old = vm.refresh();
    expect(await vm.saveSettings(title: 'Tên mới'), isTrue);
    pending.complete(_room(title: 'Tên cũ'));
    await old;
    expect(vm.room!.summary.title, 'Tên mới');
    pending = Completer<StudyRoomDetail>();
    final another = vm.refresh();
    expect(await vm.leave(), isTrue);
    pending.complete(_room());
    await another;
    expect(vm.room, isNull);
  });

  test('request đổi room và lỗi capacity không làm mất phòng', () async {
    final repo = _Repo();
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    final pending = Completer<StudyRoomDetail>();
    repo.onFetch = () => pending.future;
    final old = vm.refresh();
    vm.attach(_room(id: 'room2', title: 'Phòng khác'));
    pending.complete(_room());
    await old;
    expect(vm.room!.summary.roomId, 'room2');
    repo.onSave = () async => throw const PersonalApiException(
        code: 'CAPACITY_BELOW_MEMBERS',
        messageVi: 'Phòng đang có nhiều người hơn',
        httpStatus: 409);
    expect(await vm.saveSettings(maxMembers: 2), isFalse);
    expect(vm.room!.summary.roomId, 'room2');
    expect(vm.message, 'Phòng đang có nhiều người hơn');
  });

  test('member không thể save; response không còn self và 403 bỏ phòng',
      () async {
    final repo = _Repo()..current = _room(host: false);
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    expect(await vm.saveSettings(title: 'Không được'), isFalse);
    expect(repo.saveCalls, 0);
    repo.onFetch = () async => repo.current.copyWith(members: []);
    await vm.refresh();
    expect(vm.room, isNull);
    vm.attach(_room());
    repo.onFetch = () async => throw const PersonalApiException(
        code: 'FORBIDDEN', messageVi: 'Không có quyền', httpStatus: 403);
    await vm.refresh();
    expect(vm.room, isNull);
  });

  test('remote repository gửi đúng GET/PATCH và chỉ các field thay đổi',
      () async {
    final overrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      HttpOverrides.global = overrides;
    });
    final calls = <String>[];
    final bodies = <Map<String, dynamic>>[];
    server.listen((request) async {
      calls.add('${request.method} ${request.uri.path}');
      if (request.method == 'PATCH') {
        bodies.add(jsonDecode(await utf8.decodeStream(request))
            as Map<String, dynamic>);
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'roomId': 'r1',
        'title': 'Tên mới',
        'maxMembers': 3,
        'members': []
      }));
      await request.response.close();
    });
    final auth = DebugFixtureAuthGateway();
    await auth.signInWithEmail(email: 'a@example.test', password: 'test');
    final repo = RemoteCommunityRepository(
        apiClient: PersonalApiClient(
            baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
            authGateway: auth));
    await repo.fetchRoom('r1');
    final updated = await repo.updateRoomSettings('r1', maxMembers: 3);
    expect(
        calls, ['GET /v1/study-rooms/r1', 'PATCH /v1/study-rooms/r1/settings']);
    expect(bodies.single, {'maxMembers': 3});
    expect(updated.summary.maxMembers, 3);
  });

  testWidgets('host sửa cài đặt ở 320dp200%, member không thấy editor',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    final vm = _vm(repo);
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
    await _tap(tester, 'room-open-settings');
    await tester.enterText(
        find.byKey(const ValueKey('room-settings-title')), 'Nhóm mới');
    await _tap(tester, 'room-settings-capacity-3');
    await _tap(tester, 'room-settings-invite_only');
    await _tap(tester, 'room-settings-save');
    expect(vm.room!.summary.title, 'Nhóm mới');
    expect(vm.room!.summary.maxMembers, 3);
    expect(vm.room!.summary.visibility, 'invite_only');
    vm.attach(_room(host: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-open-settings')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
