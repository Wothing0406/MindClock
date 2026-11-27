import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/commitment_group_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_screen.dart';
import 'package:mindclock_app/ui/features/community/views/commitment_group_sheet.dart';
import 'package:mindclock_app/ui/features/community/views/today_pet_card.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';

class _GroupStreakTestCommunityRepository
    extends DebugFixtureCommunityRepository {
  _GroupStreakTestCommunityRepository(this._detail);

  CommitmentGroupDetail _detail;

  @override
  Future<CommitmentGroupHub> fetchCommitmentGroupHub() async =>
      CommitmentGroupHub(
        groups: <CommitmentGroupDetail>[_detail],
        incomingInvites: const <CommitmentGroupInviteItem>[],
        membershipLimit: 3,
      );
}

CommitmentGroupDetail _buildGroup({
  required int currentStreakDays,
  required int bestStreakDays,
  required int todayCareCount,
  required bool allMembersDoneToday,
  String? streakMilestoneLabelVi,
}) {
  return CommitmentGroupDetail(
    groupId: 'grp_t079',
    groupCode: 'NHOM79',
    name: 'Nhóm Ôn Thi 12A',
    ownerId: 'self_user',
    isOwner: true,
    isPrimary: true,
    maxMembers: 4,
    members: const <CommitmentGroupMemberItem>[
      CommitmentGroupMemberItem(
        userId: 'self_user',
        alias: 'Bạn',
        avatarId: 'avatar_sunrise',
        role: 'owner',
        isSelf: true,
      ),
      CommitmentGroupMemberItem(
        userId: 'peer_1',
        alias: 'Minh Anh',
        avatarId: 'avatar_book',
        role: 'member',
        isSelf: false,
      ),
    ],
    pendingRequests: const <CommitmentJoinRequestItem>[],
    pet: CommitmentPetSummary(
      keyName: 'mam',
      name: 'Mầm Xanh',
      stage: currentStreakDays >= 100 ? 4 : 1,
      stageLabelVi: currentStreakDays >= 100 ? 'Cây cổ thụ' : 'Mầm non',
      totalCareDays: currentStreakDays,
      currentStreakDays: currentStreakDays,
      bestStreakDays: bestStreakDays,
      todayCareCount: todayCareCount,
      memberCount: 2,
      allMembersDoneToday: allMembersDoneToday,
      streakMilestoneLabelVi: streakMilestoneLabelVi,
      totalXp: currentStreakDays * 20,
      nextStageXp: 600,
      progressionVersion: 'pet-progression-v0.1',
    ),
  );
}

void main() {
  testWidgets(
    'T079 TC-01/TC-02: Pet nhóm hiển thị 1/2 đang chờ vs đủ 2/2 giữ Chuỗi 100+ ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _GroupStreakTestCommunityRepository repo =
          _GroupStreakTestCommunityRepository(
        _buildGroup(
          currentStreakDays: 0,
          bestStreakDays: 0,
          todayCareCount: 1,
          allMembersDoneToday: false,
          streakMilestoneLabelVi: 'Chưa mở chuỗi',
        ),
      );

      final ValueNotifier<int> tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: TodayPetCard(
                  repository: repo,
                  refreshTick: tick,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chuỗi 0 ngày'), findsOneWidget);
      expect(find.text('Hôm nay 1/2'), findsOneWidget);
      expect(
        find.text(
          'Cả nhóm 1/2 cùng hoàn thành hôm nay để giữ và tăng Chuỗi.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      repo._detail = _buildGroup(
        currentStreakDays: 100,
        bestStreakDays: 100,
        todayCareCount: 2,
        allMembersDoneToday: true,
        streakMilestoneLabelVi: 'Chuỗi 100+',
      );
      tick.value += 1;
      await tester.pumpAndSettle();

      expect(find.text('Chuỗi 100+ · 100 ngày'), findsOneWidget);
      expect(find.text('Hôm nay 2/2'), findsOneWidget);
      expect(
        find.text('Cả nhóm đã hoàn thành hôm nay · Đã giữ Chuỗi!'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: CommitmentGroupSheet(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Chuỗi 100+'), findsWidgets);
      expect(find.textContaining('Hôm nay 2/2 người'), findsOneWidget);
      expect(find.textContaining('100 ngày đủ nhóm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'T079 TC-03: Đấu trường không chứa ngôn từ meta/demo nội bộ trên sảnh, Luyện đơn & PvP 1v1',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: kv),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      final SoloArenaViewModel arenaVm = SoloArenaViewModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: ArenaScreen(
              guestViewModel: guestVm,
              arenaViewModel: arenaVm,
              currentUserId: 'self_user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const List<String> forbiddenLabels = <String>[
        'Tướng gốc',
        'tướng gốc',
        'solo-three-v0.1',
        'bộ pose',
        '0 RP',
        'playtest',
        'bảng thử nghiệm',
        'v0.1',
        ' · G1',
        ' · G2',
        ' · G3',
        'G1 ·',
      ];

      void assertCleanTexts(String scope) {
        final Iterable<Text> allTexts =
            tester.widgetList<Text>(find.byType(Text));
        for (final Text textWidget in allTexts) {
          final String value = textWidget.data ?? '';
          for (final String forbidden in forbiddenLabels) {
            expect(
              value.contains(forbidden),
              isFalse,
              reason: 'Phát hiện chữ nội bộ "$forbidden" tại $scope: "$value"',
            );
          }
        }
      }

      expect(find.text('Đấu trường'), findsOneWidget);
      assertCleanTexts('Sảnh Đấu trường');

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-toggle-rules')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-toggle-rules')),
      );
      await tester.pumpAndSettle();
      assertCleanTexts('Luật đấu');

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-lobby-tab-leaderboard')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-lobby-tab-leaderboard')),
      );
      await tester.pumpAndSettle();
      assertCleanTexts('Bảng xếp hạng');

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-lobby-tab-lobby')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-lobby-tab-lobby')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-enter-solo')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-enter-solo')),
      );
      await tester.pumpAndSettle();
      assertCleanTexts('Thiết lập Luyện đơn');

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-setup-back')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-setup-back')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-enter-1v1')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-enter-1v1')),
      );
      await tester.pumpAndSettle();
      assertCleanTexts('Sảnh PvP 1v1');
    },
  );
}
