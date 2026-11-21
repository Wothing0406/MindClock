import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/domain/models/commitment_group_models.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/community/views/commitment_group_sheet.dart';

void main() {
  test('T074 parses multi-group pet EXP from server contract', () {
    final CommitmentGroupHub hub = CommitmentGroupHub.fromJson(
      <String, dynamic>{
        'membershipLimit': 3,
        'groups': <Map<String, dynamic>>[
          _groupJson('g1', 'Nhóm Toán', 70, 2),
          _groupJson('g2', 'Nhóm Anh', 20, 1),
        ],
        'incomingInvites': <dynamic>[],
      },
    );
    expect(hub.groups, hasLength(2));
    expect(hub.membershipLimit, 3);
    expect(hub.groups.first.pet.totalXp, 70);
    expect(hub.groups.first.pet.stage, 2);
  });

  testWidgets('T074 creates a private group and renders real pet state',
      (WidgetTester tester) async {
    final DebugFixtureCommunityRepository repository =
        DebugFixtureCommunityRepository();
    await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: Scaffold(body: CommitmentGroupSheet(repository: repository)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('commitment-group-name')),
        findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey<String>('commitment-group-name')),
        'Nhóm ôn sáng');
    await tester.pump();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final Finder createButton =
        find.byKey(const ValueKey<String>('commitment-create'));
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Nhóm ôn sáng'), findsOneWidget);
    expect(find.text('Chuỗi nhóm 0 ngày'), findsOneWidget);
    expect(find.text('0/60 EXP nhóm'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('commitment-leave-or-delete')),
        findsOneWidget);
  });

  testWidgets('T074 fits 320dp and 200 percent text scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 720),
          textScaler: TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: CommitmentGroupSheet(
              repository: DebugFixtureCommunityRepository()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tạo nhóm riêng'), findsOneWidget);
  });
}

Map<String, dynamic> _groupJson(
        String id, String name, int totalXp, int stage) =>
    <String, dynamic>{
      'groupId': id,
      'groupCode': 'ABC123',
      'name': name,
      'ownerId': 'u1',
      'isOwner': true,
      'isPrimary': id == 'g1',
      'maxMembers': 4,
      'members': <Map<String, dynamic>>[
        <String, dynamic>{
          'userId': 'u1',
          'alias': 'Bạn',
          'avatarId': 'avatar_sunrise',
          'role': 'owner',
          'isSelf': true,
        }
      ],
      'pendingRequests': <dynamic>[],
      'pet': <String, dynamic>{
        'key': 'mam',
        'name': 'Mầm',
        'stage': stage,
        'stageLabelVi': stage == 2 ? 'Mầm khỏe' : 'Mầm non',
        'totalCareDays': 2,
        'currentStreakDays': 2,
        'todayCareCount': 1,
        'totalXp': totalXp,
        'nextStageXp': stage == 2 ? 160 : 60,
        'progressionVersion': 'pet-progression-v0.1',
      },
    };
