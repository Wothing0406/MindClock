import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/community/views/pet_share_card.dart';
import 'package:mindclock_app/ui/features/community/views/today_pet_card.dart';

void main() {
  testWidgets('T075 dashboard renders the primary pet from repository',
      (WidgetTester tester) async {
    final DebugFixtureCommunityRepository repository =
        DebugFixtureCommunityRepository();
    await repository.createCommitmentGroup(
        name: 'Nhóm 12A', petName: 'Mầm Xanh');
    await tester.pumpWidget(_app(TodayPetCard(repository: repository)));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('today-pet-card')), findsOneWidget);
    expect(find.text('Mầm Xanh'), findsOneWidget);
    expect(find.text('0/60 EXP nhóm'), findsOneWidget);
  });

  testWidgets('T075 empty state never invents pet progress',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        _app(TodayPetCard(repository: DebugFixtureCommunityRepository())));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('today-pet-empty')), findsOneWidget);
    expect(find.textContaining('EXP nhóm'), findsNothing);
  });

  testWidgets('T075 opens a private share preview',
      (WidgetTester tester) async {
    final DebugFixtureCommunityRepository repository =
        DebugFixtureCommunityRepository();
    await repository.createCommitmentGroup(
        name: 'Tên nhóm riêng tư', petName: 'Mầm Xanh');
    await tester.pumpWidget(_app(TodayPetCard(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('today-pet-share')));
    await tester.pumpAndSettle();
    expect(find.text('Xem trước thẻ chia sẻ'), findsOneWidget);
    expect(find.text('Tên nhóm riêng tư'), findsNothing);
    expect(find.textContaining('không chứa mã nhóm'), findsOneWidget);
  });

  testWidgets('T075 share card is square and excludes private group data',
      (WidgetTester tester) async {
    final DebugFixtureCommunityRepository repository =
        DebugFixtureCommunityRepository();
    await repository.createCommitmentGroup(
        name: 'Tên nhóm riêng tư', petName: 'Mầm Xanh');
    final group = (await repository.fetchCommitmentGroupHub()).group!;
    await tester.pumpWidget(
        _app(Center(child: PetShareCard(group: group, showGroupName: false))));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PetShareCard)), const Size(320, 320));
    expect(find.text('Tên nhóm riêng tư'), findsNothing);
    expect(find.text('Mầm Xanh'), findsOneWidget);
  });

  testWidgets('T075 pet dashboard fits 320dp and 200 percent text',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final DebugFixtureCommunityRepository repository =
        DebugFixtureCommunityRepository();
    await repository.createCommitmentGroup(name: 'Nhóm 12A', petName: 'Mầm');
    await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2),
            disableAnimations: true),
        child: Scaffold(
            body: SingleChildScrollView(
                child: TodayPetCard(repository: repository))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child) => MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
