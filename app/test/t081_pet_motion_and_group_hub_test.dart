import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/domain/models/commitment_group_models.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/core/widgets/mam_pet_view.dart';
import 'package:mindclock_app/ui/features/community/views/commitment_group_screen.dart';
import 'package:mindclock_app/ui/features/community/views/floating_mini_pet_overlay.dart';

class _T081CommunityRepo extends DebugFixtureCommunityRepository {
  _T081CommunityRepo(this._groups);

  final List<CommitmentGroupDetail> _groups;

  @override
  Future<CommitmentGroupHub> fetchCommitmentGroupHub() async =>
      CommitmentGroupHub(
        groups: _groups,
        incomingInvites: const <CommitmentGroupInviteItem>[],
        membershipLimit: 3,
      );
}

CommitmentGroupDetail _makeGroup(String id, String name, int streak) =>
    CommitmentGroupDetail(
      groupId: id,
      groupCode: 'MC$id',
      name: name,
      ownerId: 'self_user',
      isOwner: true,
      isPrimary: id == '1',
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
        stage: 2,
        stageLabelVi: 'Chồi non',
        totalCareDays: streak,
        currentStreakDays: streak,
        bestStreakDays: streak,
        todayCareCount: 2,
        memberCount: 2,
        allMembersDoneToday: true,
        streakMilestoneLabelVi: 'Chuỗi $streak',
        totalXp: 80,
        nextStageXp: 160,
        progressionVersion: 'pet-progression-v0.1',
      ),
    );

void main() {
  testWidgets(
    'T081 TC-01: MamPetView cử động & FloatingMiniPetOverlay mở popup + thu gọn vào mép',
    (WidgetTester tester) async {
      final _T081CommunityRepo repo = _T081CommunityRepo(
        <CommitmentGroupDetail>[_makeGroup('1', 'Nhóm 12A', 14)],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                const Center(child: MamPetView(reaction: MamPetReaction.happy)),
                FloatingMiniPetOverlay(repository: repo),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const ValueKey<String>('floating-mini-pet')),
        findsOneWidget,
      );
      expect(find.text('Chuỗi 14'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('floating-mini-pet')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const ValueKey<String>('mini-pet-open-group-btn')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mini-pet-collapse-btn')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const ValueKey<String>('mini-pet-collapsed-tab')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'T081 TC-02: CommitmentGroupScreen hiển thị empty state & multi-group switcher không overflow ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _T081CommunityRepo emptyRepo =
          _T081CommunityRepo(const <CommitmentGroupDetail>[]);
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: CommitmentGroupScreen(repository: emptyRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('group-screen-empty-hero')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('group-empty-create-btn')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('group-empty-join-btn')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final _T081CommunityRepo multiRepo = _T081CommunityRepo(
        <CommitmentGroupDetail>[
          _makeGroup('1', 'Nhóm Lý', 7),
          _makeGroup('2', 'Nhóm Toán', 21),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: CommitmentGroupScreen(
              key: const ValueKey<String>('multi-group-screen'),
              repository: multiRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhóm của bạn (2/3)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('group-screen-hero-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('group-copy-code-btn')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('group-chip-2')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chuỗi 21'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
