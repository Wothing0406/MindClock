import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/domain/models/commitment_group_models.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/community/views/commitment_group_screen.dart';
import 'package:mindclock_app/ui/features/community/views/today_pet_card.dart';

class _T084BusyRepo extends DebugFixtureCommunityRepository {
  bool reportedBusy = false;
  String? lastReason;

  CommitmentGroupDetail _buildDetail() => CommitmentGroupDetail(
        groupId: 'grp_84',
        groupCode: 'BUSY84',
        name: 'Nhóm Ôn Thi',
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
          stage: 2,
          stageLabelVi: 'Chồi non',
          totalCareDays: 12,
          currentStreakDays: 12,
          bestStreakDays: 12,
          todayCareCount: 1,
          memberCount: 2,
          allMembersDoneToday: false,
          streakMilestoneLabelVi: 'Chuỗi 12',
          busyCountToday: reportedBusy ? 1 : 0,
          streakPreservedToday: reportedBusy,
          shieldsAvailable: 1,
          myBusyQuotaUsed: reportedBusy ? 1 : 0,
          myBusyQuotaLimit: 2,
          busyTodayByMe: reportedBusy,
          totalXp: 120,
          nextStageXp: 160,
          progressionVersion: 'pet-progression-v0.1',
        ),
      );

  @override
  Future<CommitmentGroupHub> fetchCommitmentGroupHub() async =>
      CommitmentGroupHub(
        groups: <CommitmentGroupDetail>[_buildDetail()],
        incomingInvites: const <CommitmentGroupInviteItem>[],
        membershipLimit: 3,
      );

  @override
  Future<CommitmentGroupDetail> reportCommitmentBusyToday(
    String groupId, {
    String reason = 'exam',
  }) async {
    reportedBusy = true;
    lastReason = reason;
    return _buildDetail();
  }
}

void main() {
  testWidgets(
    'T084: CommitmentGroupScreen & TodayPetCard hỗ trợ Báo bận bảo lưu Chuỗi ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _T084BusyRepo repo = _T084BusyRepo();

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: CommitmentGroupScreen(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('group-busy-today-btn')),
        findsOneWidget,
      );
      expect(find.textContaining('còn 2/2 lượt'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('group-busy-today-btn')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('group-busy-today-btn')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('group-busy-confirm-btn')),
      );
      await tester.pumpAndSettle();

      expect(repo.reportedBusy, isTrue);
      expect(repo.lastReason, 'exam');
      expect(find.textContaining('Đang bảo lưu Chuỗi 12'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TodayPetCard(repository: repo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Đang bảo lưu Chuỗi 12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
