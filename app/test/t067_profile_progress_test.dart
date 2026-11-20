import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/models/xp_history.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';
import 'package:mindclock_app/ui/features/personal_flow/views/profile_progress_card.dart';

// Test doubles exercise production state/UI; no real authentication is claimed.
class _Auth extends DebugFixtureAuthGateway {
  @override
  bool get isDebugFixture => false;
}

class _Camera implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async =>
      const CameraCaptureOutcome(status: CameraCaptureStatus.unavailable);
}

ProgressSummary summary(int xp) => ProgressSummary.fromJson({
      'xp': xp,
      'level': 2,
      'levelStartXp': 100,
      'nextLevelXp': 400,
      'xpToNextLevel': 400 - xp,
      'streak': 3,
      'completedSessions': 7,
    });
XpHistoryEntry entry(String id) => XpHistoryEntry(
    id: id,
    delta: 10,
    reason: 'challenge_correct',
    createdAt: DateTime.utc(2026, 11, 20));

class _Repo extends DebugFixturePersonalFlowRepository {
  @override
  bool get isDebugFixture => false;
  Future<ProgressSummary> Function()? onSummary;
  Future<XpHistoryPage> Function(int)? onHistory;
  final offsets = <int>[];
  @override
  Future<ProgressSummary> fetchProgressSummary() =>
      onSummary?.call() ?? Future.value(summary(160));
  @override
  Future<XpHistoryPage> fetchXpHistory({int limit = 20, int offset = 0}) {
    offsets.add(offset);
    return onHistory?.call(offset) ??
        Future.value(const XpHistoryPage(items: []));
  }
}

PersonalFlowViewModel _create(_Repo repo) => PersonalFlowViewModel(
      authGateway: _Auth(),
      repository: repo,
      cameraGateway: _Camera(),
      draftStore: OfflineTextDraftStore(store: InMemoryKeyValueStore()),
    );
Future<void> login(PersonalFlowViewModel vm, [String user = 'a']) =>
    vm.signIn(email: '$user@example.test', password: 'test-password');

void main() {
  testWidgets('khách và fixture không hiện level/EXP thật', (tester) async {
    final vm = PersonalFlowViewModel(
        authGateway: DebugFixtureAuthGateway(),
        repository: DebugFixturePersonalFlowRepository(),
        cameraGateway: _Camera(),
        draftStore: OfflineTextDraftStore(store: InMemoryKeyValueStore()));
    addTearDown(vm.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: Scaffold(body: ProfileProgressCard(viewModel: vm))));
    expect(find.textContaining('Đăng nhập để xem'), findsOneWidget);
    await login(vm);
    await tester.pumpAndSettle();
    expect(find.textContaining('Dữ liệu thử nghiệm'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-level')), findsNothing);
    expect(find.byKey(const ValueKey('profile-level-bar')), findsNothing);
  });

  testWidgets(
      'lịch sử rỗng hiện đúng; lỗi refresh giữ dữ liệu đã tải kèm thông báo',
      (tester) async {
    final repo = _Repo();
    final vm = _create(repo);
    addTearDown(vm.dispose);
    await login(vm);
    await tester.pumpWidget(MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: Scaffold(
            body: SingleChildScrollView(
                child: ProfileProgressCard(viewModel: vm)))));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có EXP được ghi nhận.'), findsOneWidget);
    repo.onSummary = () async => throw const PersonalApiException(
        code: 'NETWORK', messageVi: 'Mất mạng thử lại');
    await vm.refreshProgressAndHistory();
    await tester.pumpAndSettle();
    expect(find.text('Mất mạng thử lại'), findsOneWidget);
    expect(find.text('Cấp 2'), findsOneWidget);
    expect(find.textContaining('Đồng bộ '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('repo gửi offset/limit đúng và đọc payload XP history qua HTTP',
      () async {
    final overrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      HttpOverrides.global = overrides;
    });
    final requestSeen = Completer<Uri>();
    server.listen((request) async {
      requestSeen.complete(request.uri);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'items': [
          {
            'id': 'server-event',
            'delta': 12,
            'reason': 'study_time_v0_1',
            'createdAt': '2026-11-20T10:00:00+00:00',
          }
        ],
        'nextOffset': null
      }));
      await request.response.close();
    });
    final auth = _Auth();
    await auth.signInWithEmail(email: 'a@example.test', password: 'test');
    final repo = RemotePersonalFlowRepository(
        apiClient: PersonalApiClient(
            baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
            authGateway: auth));
    final page = await repo.fetchXpHistory(limit: 7, offset: 20);
    final uri = await requestSeen.future;
    expect(uri.path, '/v1/progress/xp-history');
    expect(uri.queryParameters, {'limit': '7', 'offset': '20'});
    expect(page.items.single.delta, 12);
    expect(page.items.single.id, 'server-event');
  });

  test('auth hết hạn ẩn EXP và lịch sử cũ', () async {
    final repo = _Repo();
    final vm = _create(repo);
    addTearDown(vm.dispose);
    await login(vm);
    repo.onHistory = (_) async => XpHistoryPage(items: [entry('private')]);
    await vm.loadXpHistory();
    repo.onHistory = (_) async => throw const PersonalApiException(
        code: 'AUTH_EXPIRED', messageVi: 'Cần đăng nhập lại', httpStatus: 401);
    await vm.loadXpHistory(refresh: true);
    expect(vm.authSession.isAuthenticated, isFalse);
    expect(vm.progressSummary.isServerAuthoritative, isFalse);
    expect(vm.xpHistory, isEmpty);
  });
  test('server mốc level, timestamp UTC và dữ liệu cũ không tự suy level', () {
    expect(summary(160).levelFraction, 0.2);
    expect(ProgressSummary.fromJson({'xp': 900}).level, isNull);
    final page = XpHistoryPage.fromJson({
      'items': [
        {
          'id': 'x',
          'delta': 10,
          'reason': 'challenge_correct',
          'createdAt': '2026-11-20T10:00:00',
        }
      ],
      'nextOffset': 20
    });
    expect(page.items.single.createdAt, DateTime.utc(2026, 11, 20, 10));
    expect(page.nextOffset, 20);
  });

  test('phân trang bỏ ID trùng, lỗi retry cùng offset, refresh về đầu',
      () async {
    final repo = _Repo();
    final vm = _create(repo);
    addTearDown(vm.dispose);
    await login(vm);
    repo.onHistory = (offset) async => offset == 0
        ? XpHistoryPage(items: [entry('a')], nextOffset: 20)
        : throw const PersonalApiException(
            code: 'NETWORK', messageVi: 'Mất kết nối');
    await vm.loadXpHistory();
    await vm.loadXpHistory();
    expect(vm.xpHistoryError, 'Mất kết nối');
    expect(vm.xpHistory.single.id, 'a');
    repo.onHistory =
        (_) async => XpHistoryPage(items: [entry('a'), entry('b')]);
    await vm.loadXpHistory();
    expect(vm.xpHistory.map((e) => e.id), ['a', 'b']);
    expect(repo.offsets, [0, 20, 20]);
    repo.onHistory = (_) async => XpHistoryPage(items: [entry('c')]);
    await vm.loadXpHistory(refresh: true);
    expect(repo.offsets.last, 0);
    expect(vm.xpHistory.single.id, 'c');
  });

  test('response A về muộn sau logout và login B không ghi lại tiến độ/lịch sử',
      () async {
    final repo = _Repo();
    final vm = _create(repo);
    addTearDown(vm.dispose);
    await login(vm);
    final oldSummary = Completer<ProgressSummary>();
    final oldHistory = Completer<XpHistoryPage>();
    repo.onSummary = () => oldSummary.future;
    repo.onHistory = (_) => oldHistory.future;
    final loading = vm.refreshProgressAndHistory();
    final historyLoading = vm.loadXpHistory();
    await vm.signOut();
    repo.onSummary = () async => summary(230);
    repo.onHistory = (_) async => XpHistoryPage(items: [entry('b')]);
    await login(vm, 'b');
    await vm.loadXpHistory();
    oldSummary.complete(summary(999));
    oldHistory.complete(XpHistoryPage(items: [entry('private-a')]));
    await Future.wait([loading, historyLoading]);
    expect(vm.progressSummary.xp, 230);
    expect(vm.xpHistory.single.id, 'b');
  });

  test('refresh mới thắng response phân trang cũ', () async {
    final repo = _Repo();
    final vm = _create(repo);
    addTearDown(vm.dispose);
    await login(vm);
    final pending = Completer<XpHistoryPage>();
    repo.onHistory = (_) => pending.future;
    final old = vm.loadXpHistory();
    repo.onHistory = (_) async => XpHistoryPage(items: [entry('new')]);
    await vm.loadXpHistory(refresh: true);
    pending.complete(XpHistoryPage(items: [entry('old')]));
    await old;
    expect(vm.xpHistory.single.id, 'new');
  });

  testWidgets(
      'tab profile 320dp chữ 200%, Reduce Motion: thanh EXP, lịch sử, logout',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo()
      ..onHistory = (_) async => XpHistoryPage(items: [entry('a')]);
    final vm = _create(repo);
    addTearDown(vm.dispose);
    await login(vm);
    await tester.pumpWidget(MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true),
            child: child!),
        home: Scaffold(
            body: SingleChildScrollView(
                child: ProfileProgressCard(viewModel: vm)))));
    await tester.pumpAndSettle();
    expect(find.text('Cấp 2'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('profile-level-bar')));
    expect(bar.value, 0.2);
    expect(find.textContaining('Hoàn thành câu ôn'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await vm.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Cấp 2'), findsNothing);
    expect(find.textContaining('Hoàn thành câu ôn'), findsNothing);
    expect(find.textContaining('Đăng nhập để xem'), findsOneWidget);
  });
}
