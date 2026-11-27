import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/me_guest_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _TestAuthGateway extends DebugFixtureAuthGateway {
  @override
  bool get isDebugFixture => false;

  @override
  Future<AuthSession> loadSavedSession() async => const AuthSession(
        status: AuthStatus.authenticated,
        uid: 'u_t085',
        email: 'hs@mindclock.vn',
        idToken: 'tok_t085',
        isDebugFixture: false,
      );
}

class _TestCam implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async =>
      const CameraCaptureOutcome(status: CameraCaptureStatus.unavailable);
}

class _FakeShowcaseRepo extends DebugFixturePersonalFlowRepository {
  @override
  bool get isDebugFixture => false;

  bool optedIn = false;

  @override
  Future<void> recordConsent({
    required String scope,
    required String version,
    required bool granted,
  }) async {
    if (scope == 'weekly_leaderboard_opt_in') {
      optedIn = granted;
    }
  }

  @override
  Future<ProfileShowcase> fetchProfileShowcase() async {
    return ProfileShowcase(
      userId: 'u_t085',
      alias: 'Minh Anh 11A1',
      avatarId: 'avatar_sunrise',
      gradeLevel: 'Lớp 11',
      xp: 360,
      level: 3,
      streak: 6,
      bestStreak: 9,
      seasonRank: const ProfileSeasonRank(
        seasonCode: '2026-S4',
        tier: 'vang',
        labelVi: 'Vàng · Bình minh',
        frameColorHex: '#D9932B',
        minXp: 300,
        nextMinXp: 700,
      ),
      equippedTitleVi: 'Chiến thần Bình minh tuần',
      earlyBirdDaysThisWeek: 5,
      topSubject: const ProfileTopSubject(
        subjectCode: 'TOAN',
        subjectNameVi: 'Toán',
        masteryScore: 84,
        attemptsCount: 10,
        correctCount: 9,
        accuracyPct: 90,
        currentWeek: 14,
      ),
      stamps: const <ProfileStamp>[
        ProfileStamp(
          id: 'streak',
          titleVi: 'Chuỗi bền bỉ',
          valueVi: '6 ngày',
          subtitleVi: 'Kỷ lục 9 ngày',
          kind: 'flame',
        ),
        ProfileStamp(
          id: 'early_bird',
          titleVi: 'Dậy sớm tuần',
          valueVi: '5/7 ngày',
          subtitleVi: 'Hoàn thành thử thách sáng',
          kind: 'sunrise',
        ),
        ProfileStamp(
          id: 'top_subject',
          titleVi: 'Sở trường',
          valueVi: 'Toán',
          subtitleVi: '84% · Tuần 14',
          kind: 'book',
        ),
      ],
      groups: const <ProfileShowcaseGroupItem>[
        ProfileShowcaseGroupItem(
          id: 'g1',
          name: 'Tổ 6h sáng',
          groupCode: 'ABC123',
          streakDays: 6,
          memberCount: 4,
          maxMembers: 8,
          petName: 'Mầm Xanh',
        ),
        ProfileShowcaseGroupItem(
          id: 'g2',
          name: 'Toán chuyên',
          groupCode: 'TOAN99',
          streakDays: 4,
          memberCount: 3,
          maxMembers: 8,
          petName: 'Cú Nhỏ',
        ),
      ],
      leaderboardOptIn: optedIn,
    );
  }

  @override
  Future<WeeklySubjectLeaderboard> fetchWeeklySubjectLeaderboard({
    String subjectCode = 'TOAN',
    int limit = 20,
  }) async {
    return WeeklySubjectLeaderboard(
      subjectCode: subjectCode,
      subjectNameVi: subjectCode == 'NGU_VAN' ? 'Ngữ văn' : 'Toán',
      weekWindowVi: '7 ngày gần nhất',
      currentUserOptedIn: optedIn,
      entries: <WeeklyLeaderboardEntry>[
        if (optedIn)
          WeeklyLeaderboardEntry(
            rank: 1,
            userId: 'u_t085',
            alias: 'Minh Anh 11A1',
            avatarId: 'avatar_sunrise',
            gradeLevel: 'Lớp 11',
            seasonRank: const ProfileSeasonRank(
              seasonCode: '2026-S4',
              tier: 'vang',
              labelVi: 'Vàng · Bình minh',
              frameColorHex: '#D9932B',
              minXp: 300,
              nextMinXp: 700,
            ),
            equippedTitleVi: 'Chiến thần Bình minh tuần',
            subjectCode: subjectCode,
            subjectNameVi: subjectCode == 'NGU_VAN' ? 'Ngữ văn' : 'Toán',
            weeklyScore: 220,
            accuracyPct: 90,
            attemptsCount: 10,
            earlyBirdDaysThisWeek: 5,
            isCurrentUser: true,
          ),
      ],
    );
  }
}

void main() {
  testWidgets(
      'T085 MeGuestScreen hiển thị Profile Showcase, 3 dấu ấn, các nhóm và BXH Học bá tuần không overflow ở 320dp 200%',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
    final GuestWorkspaceRepository wsRepo = GuestWorkspaceRepository(store: kv);
    final GuestWorkspaceViewModel wsVm = GuestWorkspaceViewModel(
      repository: wsRepo,
      alarmScheduler: const UnboundAlarmSchedulerService(),
    );
    await wsVm.initialize();
    await wsVm.saveStudyProfile(
      const StudyProfile(
        alias: 'Minh Anh 11A1',
        avatarId: 'sunrise',
        gradeLevel: 'Lớp 11',
        selectedSubjectCodes: <String>['TOAN', 'NGU_VAN'],
        goalLabel: 'Mỗi ngày 1 đề ngắn',
      ),
    );

    final _FakeShowcaseRepo repo = _FakeShowcaseRepo();
    final PersonalFlowViewModel pvm = PersonalFlowViewModel(
      authGateway: _TestAuthGateway(),
      repository: repo,
      cameraGateway: _TestCam(),
      draftStore: OfflineTextDraftStore(store: kv),
    );
    await pvm.initialize();
    await pvm.loadProfileShowcase();

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: MeGuestScreen(
              viewModel: wsVm,
              personalViewModel: pvm,
              onEditProfileAndTimetable: () {},
              onResetGuestData: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('me-season-rank-pill')),
        findsOneWidget);
    expect(find.text('Vàng · Bình minh'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('me-equipped-title')),
        findsOneWidget);
    expect(find.text('Danh hiệu: Chiến thần Bình minh tuần'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('me-stamp-streak')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('me-stamp-early_bird')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('me-stamp-top_subject')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('me-group-chip-g1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('me-group-chip-g2')), findsOneWidget);

    // Mở sheet BXH Học bá tuần và bật opt-in
    final Finder openBtn =
        find.byKey(const ValueKey<String>('me-open-weekly-leaderboard-btn'));
    await tester.ensureVisible(openBtn);
    await tester.tap(openBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('weekly-leaderboard-sheet')),
        findsOneWidget);
    await tester.tap(
        find.byKey(const ValueKey<String>('weekly-leaderboard-optin-btn')));
    await tester.pumpAndSettle();

    expect(repo.optedIn, isTrue);
    expect(find.text('220 đ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
