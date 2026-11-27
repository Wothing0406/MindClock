import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/domain/game/combat_catalog.dart';
import 'package:mindclock_app/domain/game/solo_combat_engine.dart';
import 'package:mindclock_app/domain/game/solo_training_question_bank.dart';
import 'package:mindclock_app/domain/models/study_ai_models.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_skill_hand.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_sprite_stage.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_stage_widget.dart';

void _answerCorrect(SoloArenaViewModel vm) {
  final SoloApprovedQuestion q = vm.currentQuestion!;
  vm.submitAnswer(
    answerText: q.acceptedAnswers.first,
    reasoningText: '${q.reasoningKeywords.first} = 10',
  );
}

const PersonalizedPracticeQuestion _grade12Ai = PersonalizedPracticeQuestion(
  questionId: 'ai_q_test12',
  subjectCode: 'TOAN',
  gradeBand: 'Lớp 12',
  topicId: 'don_dieu',
  difficulty: 1,
  prompt: 'Cho hàm số y = x^3 - 3x. Hàm số đạt cực đại tại x bằng bao nhiêu?',
  reasoningPromptVi: 'Viết bước tính đạo hàm.',
  steps: <String>["Bước 1: y' = 3x^2 - 3 = 0 suy ra x = 1 hoặc x = -1."],
  acceptedAnswers: <String>['-1', 'x=-1'],
  status: 'draft',
  sourceType: 'ai_personalized_draft',
  modelVersion: 'gemini-3.8-flash',
);

void main() {
  test('TC-01: bản đồ Ngẫu nhiên chốt cố định trước trận và giữ xuyên suốt trận', () {
    final SoloArenaViewModel vm =
        SoloArenaViewModel(initialSeed: 20261127, enableRoundTimer: false);
    vm.selectMap('random');
    expect(vm.startSoloMatch(showLoadingScreen: true), isTrue);
    final String lockedBeforeBattle = vm.resolvedMapId;
    expect(SoloArenaViewModel.concreteMapIds, contains(lockedBeforeBattle));
    vm.completeArenaLoading();
    expect(vm.resolvedMapId, lockedBeforeBattle);

    vm.selectMap('dawn_peak');
    vm.startSoloMatch();
    expect(vm.resolvedMapId, 'dawn_peak');
  });

  test('TC-02: Né chiêu đổi làn và giảm sát thương nhận vào theo luật', () {
    final SoloArenaViewModel dodger =
        SoloArenaViewModel(initialSeed: 77, enableRoundTimer: false);
    final SoloArenaViewModel plain =
        SoloArenaViewModel(initialSeed: 77, enableRoundTimer: false);
    dodger.selectDifficulty(BotDifficulty.thuThach);
    plain.selectDifficulty(BotDifficulty.thuThach);
    dodger.startSoloMatch();
    plain.startSoloMatch();

    final int laneBefore = dodger.playerLane;
    dodger.triggerPlayerDodge();
    expect(dodger.playerLane, isNot(laneBefore));
    expect(dodger.playerLane, isNot(dodger.botAttackLane));
    expect(dodger.dodgeActiveThisTurn, isTrue);

    bool sawDodgeHit = false;
    for (int r = 0; r < 4; r++) {
      if (dodger.matchFinished || plain.matchFinished) break;
      if (!dodger.dodgeActiveThisTurn) dodger.triggerPlayerDodge();
      _answerCorrect(dodger);
      _answerCorrect(plain);
      dodger.chooseAction(CombatActionType.basic);
      plain.chooseAction(CombatActionType.basic);
      if ((dodger.dodgeNoticeVi ?? '').contains('Né thành công')) {
        sawDodgeHit = true;
      }
      dodger.advanceAfterFeedback();
      plain.advanceAfterFeedback();
    }
    expect(plain.playerState.hp, lessThan(maxHp));
    expect(sawDodgeHit, isTrue);
    expect(dodger.playerState.hp, greaterThan(plain.playerState.hp));
  });

  test('TC-03: Tự tung chỉ chọn chiêu hợp lệ từ engine sau khi giải đúng', () {
    final SoloArenaViewModel vm = SoloArenaViewModel(enableRoundTimer: false);
    vm.startSoloMatch();
    expect(vm.autoCastSpecial, isFalse);
    vm.toggleAutoCastSpecial();
    _answerCorrect(vm);
    expect(vm.phase, SoloBattlePhase.roundFeedback);
    expect(vm.lastResolution, isNotNull);
    expect(
      vm.lastResolution!.settle.playerADelta.actionUsed,
      CombatActionType.basic,
    );
  });

  test('TC-04: nạp câu từ bank lớp 12 và nguồn AI cá nhân hóa có kiểm soát',
      () async {
    final SoloApprovedQuestion? q =
        SoloTrainingQuestionBank.fromPersonalizedQuestion(_grade12Ai);
    expect(q, isNotNull);
    expect(q!.gradeBand, 'Lớp 12');
    expect(q.subjectCode, 'math');
    expect(q.isAiGenerated, isTrue);
    final SoloGradingFeedback g = gradeSoloTrainingSubmission(
      question: q,
      answerText: '-1',
      reasoningText: "y' = 3x^2 - 3 = 0",
    );
    expect(g.status, SoloGradeStatus.correct);

    final SoloArenaViewModel vm = SoloArenaViewModel(enableRoundTimer: false);
    vm.setGradeLevel('Lớp 12');
    vm.setContinuousQuestionProvider(({
      required String subjectCode,
      required String seedQuestionId,
      required int roundNo,
    }) async =>
        q);
    vm.startSoloMatch();
    expect(vm.currentQuestion!.gradeBand, 'Lớp 12');
    final bool ok = await vm.fetchAiQuestionNow();
    expect(ok, isTrue);
    expect(vm.currentQuestion!.id, 'ai_q_test12');
  });

  testWidgets(
      'TC-05: màn dọc hiển thị map, hướng đối diện, hit-impact đúng phía và icon chiêu',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int dodges = 0;
    const SoloCombatantState player = SoloCombatantState(
      actorId: 'local_student',
      displayName: 'Bạn',
      championId: ChampionId.haNhan,
      isBot: false,
      qi: 2,
      passiveTriggerCount: 1,
    );
    const SoloCombatantState bot = SoloCombatantState(
      actorId: 'training_bot',
      displayName: 'Máy tập',
      championId: ChampionId.tuyetDinh,
      isBot: true,
      hp: 72,
    );
    // Settled round: người chơi đánh trúng Máy tập, Máy tập trượt (0 sát thương lên người chơi)
    final SoloRoundResolution settlePlayerHitsOnly = settleSoloRound(
      roundNo: 1,
      playerState: player,
      botState: bot,
      playerGrade: SoloGradeStatus.correct,
      playerActionRequested: CombatActionType.skill1,
      botDecision: const BotRoundDecision(
        roundNo: 1,
        rollPercent: 99,
        grade: SoloGradeStatus.incorrect,
        chosenAction: CombatActionType.basic,
        summaryVi: 'Máy tập trượt lượt này.',
      ),
      isSecretRound: false,
    );

    await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            ArenaStageWidget(
              playerState: settlePlayerHitsOnly.nextPlayerState,
              botState: settlePlayerHitsOnly.nextBotState,
              compact: false,
              reduceMotion: true,
              skipEffects: false,
              soundEnabled: false,
              assetFallbackMode: false,
              mapId: 'dawn_peak',
              playerLane: 0,
              botAttackLane: 2,
              lastResolution: settlePlayerHitsOnly,
              onDodge: () => dodges++,
            ),
            ArenaSkillHand(
              champion: ChampionId.haNhan,
              options: evaluateActionAvailability(
                state: player,
                roundNo: 1,
                playerGrade: SoloGradeStatus.correct,
                actionWindowOpen: true,
              ),
              onAction: (_) {},
              qi: 2,
              passiveTriggerCount: 1,
              onDodge: () => dodges++,
              autoCastSpecial: false,
              onToggleAutoCast: () {},
            ),
          ]),
        ),
      ),
    ));
    await tester.pump();

    // 1. Hai nhân vật đối diện nhau và đứng đúng phần trái/phải sân
    final List<ArenaSpriteActor> actors =
        tester.widgetList<ArenaSpriteActor>(find.byType(ArenaSpriteActor)).toList();
    expect(actors.length, 2);
    final ArenaSpriteActor selfActor = actors.firstWhere((ArenaSpriteActor a) => !a.isBot);
    final ArenaSpriteActor botActor = actors.firstWhere((ArenaSpriteActor a) => a.isBot);
    expect(selfActor.facingRight, isTrue);
    expect(botActor.facingRight, isFalse);

    final Offset playerPos = tester.getCenter(
      find.byKey(const ValueKey<String>('arena-slot-player')),
    );
    final Offset botPos = tester.getCenter(
      find.byKey(const ValueKey<String>('arena-slot-bot')),
    );
    expect(playerPos.dx, lessThan(botPos.dx));

    // 2. Hiệu ứng trúng đòn CHỈ xuất hiện ở phía Máy tập bị đánh, không chồng sang bên người chơi
    expect(
      find.byKey(const ValueKey<String>('arena-hit-impact-bot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('arena-hit-impact-player')),
      findsNothing,
    );
    final Offset hitPos = tester.getCenter(
      find.byKey(const ValueKey<String>('arena-hit-impact-bot')),
    );
    expect((hitPos.dx - botPos.dx).abs(), lessThan(60));

    // 3. Nút kỹ năng dùng đúng icon chiêu (không dùng ảnh nhân vật) và nhãn gọn
    final Iterable<String> assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((Image i) => i.image)
        .whereType<AssetImage>()
        .map((AssetImage a) => a.assetName);
    expect(assetNames, contains('assets/arena/skill_ha_nhan_1.png'));
    expect(assetNames, contains('assets/arena/skill_ha_nhan_2.png'));
    expect(assetNames, contains('assets/arena/skill_basic.png'));
    expect(assetNames, contains('assets/arena/map_courtyard.png'));
    expect(find.text('Đánh thường'), findsOneWidget);
    expect(find.text('Chiêu 1'), findsOneWidget);
    expect(find.text('Chiêu 2'), findsOneWidget);
    expect(find.text('Chiêu 3'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('arena-passive-auto-badge')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('arena-dodge-btn')));
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('arena-dodge-skill-btn')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('arena-dodge-skill-btn')),
    );
    expect(dodges, 2);
    expect(tester.takeException(), isNull);
  });

  test('TC-06: không dùng hằng màu hex trực tiếp trong arena_stage_widget.dart', () {
    final String content =
        File('lib/ui/features/arena/views/arena_stage_widget.dart')
            .readAsStringSync();
    expect(RegExp(r'Color\(0x').hasMatch(content), isFalse);
  });
}
