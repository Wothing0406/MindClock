import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/domain/game/combat_catalog.dart';
import 'package:mindclock_app/domain/game/solo_combat_engine.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_skill_hand.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_sprite_stage.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_stage_widget.dart';

void main() {
  const player = SoloCombatantState(
      actorId: 'p',
      displayName: 'Bạn',
      championId: ChampionId.haNhan,
      isBot: false,
      qi: 2);
  testWidgets('TC03: bài chưa đúng khóa thẻ; đúng mở chiêu theo engine',
      (tester) async {
    CombatActionType? action;
    Future<void> render(SoloGradeStatus? grade) =>
        tester.pumpWidget(MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
              body: ArenaSkillHand(
                  champion: player.championId,
                  options: evaluateActionAvailability(
                      state: player,
                      roundNo: 1,
                      playerGrade: grade,
                      actionWindowOpen: true),
                  onAction: (value) => action = value)),
        ));
    await render(null);
    final basic = find.byKey(const ValueKey<String>('arena-action-basic'));
    await tester.tap(basic);
    expect(action, isNull);
    await render(SoloGradeStatus.correct);
    await tester.tap(basic);
    expect(action, CombatActionType.basic);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC04: sân thu gọn vẫn giữ cả hai tướng', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: const Scaffold(
          body: ArenaStageWidget(
              playerState: player,
              botState: SoloCombatantState(
                  actorId: 'b',
                  displayName: 'Máy',
                  championId: ChampionId.tuyetDinh,
                  isBot: true),
              compact: true,
              reduceMotion: true,
              skipEffects: true,
              soundEnabled: false,
              assetFallbackMode: false)),
    ));
    expect(find.byType(ArenaSpriteActor), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
