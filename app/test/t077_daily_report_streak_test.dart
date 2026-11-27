import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';
import 'package:mindclock_app/ui/features/personal_flow/views/streak_detail_sheet.dart';
import 'package:mindclock_app/ui/features/personal_flow/views/today_streak_card.dart';

class _TestAuthGateway extends DebugFixtureAuthGateway {
  @override
  bool get isDebugFixture => false;
}

class _TestCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async =>
      const CameraCaptureOutcome(status: CameraCaptureStatus.unavailable);
}

class _StreakRepo extends DebugFixturePersonalFlowRepository {
  @override
  bool get isDebugFixture => false;

  bool reportedToday = false;
  int streak = 0;
  String lastNote = '';

  @override
  Future<ProgressSummary> fetchProgressSummary() async {
    return ProgressSummary(
      xp: reportedToday ? 5 : 0,
      level: 1,
      levelStartXp: 0,
      nextLevelXp: 100,
      xpToNextLevel: reportedToday ? 95 : 100,
      streak: streak,
      bestStreak: streak,
      totalActiveDays: streak,
      todayCompleted: reportedToday,
      todayReportSubmitted: reportedToday,
      todaySources:
          reportedToday ? const <String>['daily_report'] : const <String>[],
      recentDays: <StreakDayActivity>[
        for (int i = 6; i >= 0; i--)
          StreakDayActivity(
            date: '2026-11-${(27 - i).toString().padLeft(2, '0')}',
            weekdayLabel: const <String>[
              'T2',
              'T3',
              'T4',
              'T5',
              'T6',
              'T7',
              'CN',
            ][(4 - i + 7) % 7],
            isToday: i == 0,
            completed: i == 0 ? reportedToday : false,
            hasDailyReport: i == 0 ? reportedToday : false,
            hasStudy: false,
            hasChallenge: false,
            xpEarned: i == 0 && reportedToday ? 5 : 0,
          ),
      ],
      completedSessions: 0,
      topicsToReview: const <String>[],
      isServerAuthoritative: true,
      isDebugFixture: false,
    );
  }

  @override
  Future<DailyReportSubmitResult> submitDailyReport({
    required int tasksCompleted,
    required String feeling,
    required String reflectionNote,
    required String idempotencyKey,
  }) async {
    final bool already = reportedToday;
    reportedToday = true;
    streak = 1;
    lastNote = reflectionNote;
    final DailyReportRecord report = DailyReportRecord(
      reportId: 'rep_2026_11_27',
      localDate: '2026-11-27',
      studyMinutes: 25,
      tasksCompleted: tasksCompleted,
      challengeCompleted: true,
      feeling: feeling,
      reflectionNote: reflectionNote,
      xpAwarded: 5,
      createdAt: DateTime.utc(2026, 11, 27, 12),
    );
    return DailyReportSubmitResult(
      report: report,
      alreadyReportedToday: already,
      xpAwarded: already ? 0 : 5,
      streakAwardedToday: !already,
      summary: await fetchProgressSummary(),
    );
  }

  @override
  Future<List<DailyReportRecord>> fetchDailyReports({int limit = 14}) async {
    if (!reportedToday) return const <DailyReportRecord>[];
    return <DailyReportRecord>[
      DailyReportRecord(
        reportId: 'rep_2026_11_27',
        localDate: '2026-11-27',
        studyMinutes: 25,
        tasksCompleted: 3,
        challengeCompleted: true,
        feeling: 'focused',
        reflectionNote: lastNote,
        xpAwarded: 5,
        createdAt: DateTime.utc(2026, 11, 27, 12),
      ),
    ];
  }
}

PersonalFlowViewModel _makeVm(_StreakRepo repo) => PersonalFlowViewModel(
      authGateway: _TestAuthGateway(),
      repository: repo,
      cameraGateway: _TestCameraGateway(),
      draftStore: OfflineTextDraftStore(store: InMemoryKeyValueStore()),
    );

void main() {
  testWidgets(
      'T077 nộp báo cáo ngày nâng thành 1 streak, cập nhật UI và xem được lịch sử',
      (WidgetTester tester) async {
    final _StreakRepo repo = _StreakRepo();
    final PersonalFlowViewModel vm = _makeVm(repo);
    addTearDown(vm.dispose);
    await vm.signIn(email: 'hs@example.test', password: 'Password@123');
    int petRefreshed = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodayStreakCard(
              personalViewModel: vm,
              onReportSubmitted: () => petRefreshed += 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 ngày Streak'), findsOneWidget);
    expect(find.text('Chưa giữ hôm nay'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('today-open-daily-report')));
    await tester.pumpAndSettle();

    expect(find.text('Báo cáo học tập hôm nay'), findsOneWidget);
    final Finder incBtn =
        find.byKey(const ValueKey<String>('daily-report-tasks-inc'));
    await tester.ensureVisible(incBtn);
    await tester.tap(incBtn);
    await tester.pumpAndSettle();

    final Finder feelingBtn =
        find.byKey(const ValueKey<String>('daily-report-feeling-focused'));
    await tester.ensureVisible(feelingBtn);
    await tester.tap(feelingBtn);
    await tester.pumpAndSettle();

    final Finder noteField =
        find.byKey(const ValueKey<String>('daily-report-note'));
    await tester.ensureVisible(noteField);
    await tester.enterText(
      noteField,
      'Hoàn thành xong mục tiêu Toán hôm nay.',
    );
    await tester.pumpAndSettle();

    final Finder submitBtn =
        find.byKey(const ValueKey<String>('daily-report-submit'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(petRefreshed, 1);
    expect(find.text('1 ngày Streak'), findsOneWidget);
    expect(find.text('Đã giữ hôm nay'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('today-open-streak-detail')));
    await tester.pumpAndSettle();

    expect(find.text('Chuỗi Streak & Báo cáo ngày'), findsOneWidget);
    expect(find.text('Lịch 14 ngày gần nhất'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hoàn thành xong mục tiêu Toán hôm nay.'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Nhật ký Báo cáo ngày'), findsOneWidget);
    expect(find.text('Hoàn thành xong mục tiêu Toán hôm nay.'), findsOneWidget);
  });

  testWidgets('T077 StreakDetailSheet & TodayStreakCard fit 320dp và chữ 200%',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _StreakRepo repo = _StreakRepo()
      ..reportedToday = true
      ..streak = 3
      ..lastNote = 'Giữ nhịp đều mỗi ngày';
    final PersonalFlowViewModel vm = _makeVm(repo);
    addTearDown(vm.dispose);
    await vm.signIn(email: 'hs@example.test', password: 'Password@123');

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2.0),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: TodayStreakCard(personalViewModel: vm),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2.0),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SizedBox(
              height: 720 * 0.92,
              child: StreakDetailSheet(viewModel: vm),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('T077 RemotePersonalFlowRepository gọi đúng POST /progress/daily-report & GET /progress/daily-reports',
      () async {
    final HttpOverrides? prev = HttpOverrides.current;
    HttpOverrides.global = null;
    final HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      HttpOverrides.global = prev;
      await server.close(force: true);
    });

    final List<String> paths = <String>[];
    server.listen((HttpRequest req) async {
      paths.add('${req.method} ${req.uri.path}');
      req.response.headers.contentType = ContentType.json;
      if (req.uri.path == '/v1/progress/daily-report') {
        req.response.write(jsonEncode(<String, dynamic>{
          'alreadyReportedToday': false,
          'xpAwarded': 5,
          'streakAwardedToday': true,
          'report': <String, dynamic>{
            'reportId': 'rep_1',
            'localDate': '2026-11-27',
            'studyMinutes': 20,
            'tasksCompleted': 2,
            'challengeCompleted': false,
            'feeling': 'steady',
            'reflectionNote': 'Ổn định',
            'xpAwarded': 5,
            'createdAt': '2026-11-27T05:00:00Z',
          },
          'summary': <String, dynamic>{
            'xp': 5,
            'streak': 1,
            'bestStreak': 1,
            'totalActiveDays': 1,
            'todayCompleted': true,
            'todayReportSubmitted': true,
            'todaySources': <String>['daily_report'],
            'recentDays': const <dynamic>[],
            'completedSessions': 0,
            'topicsToReview': const <String>[],
          },
        }));
      } else {
        req.response.write(jsonEncode(<String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'reportId': 'rep_1',
              'localDate': '2026-11-27',
              'studyMinutes': 20,
              'tasksCompleted': 2,
              'challengeCompleted': false,
              'feeling': 'steady',
              'reflectionNote': 'Ổn định',
              'xpAwarded': 5,
              'createdAt': '2026-11-27T05:00:00Z',
            },
          ],
        }));
      }
      await req.response.close();
    });

    final RemotePersonalFlowRepository repo = RemotePersonalFlowRepository(
      apiClient: PersonalApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        authGateway: _TestAuthGateway(),
      ),
    );
    final _TestAuthGateway auth = _TestAuthGateway();
    await auth.signInWithEmail(
      email: 'hs@example.test',
      password: 'Password@123',
    );
    final RemotePersonalFlowRepository authedRepo = RemotePersonalFlowRepository(
      apiClient: PersonalApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        authGateway: auth,
      ),
    );

    final DailyReportSubmitResult res = await authedRepo.submitDailyReport(
      tasksCompleted: 2,
      feeling: 'steady',
      reflectionNote: 'Ổn định',
      idempotencyKey: 'idem-t077-http',
    );
    expect(res.summary.streak, 1);
    expect(res.streakAwardedToday, isTrue);

    final List<DailyReportRecord> items = await authedRepo.fetchDailyReports();
    expect(items, hasLength(1));
    expect(items.first.localDate, '2026-11-27');
    expect(paths, <String>[
      'POST /v1/progress/daily-report',
      'GET /v1/progress/daily-reports',
    ]);
    expect(repo, isNotNull);
  });
}
