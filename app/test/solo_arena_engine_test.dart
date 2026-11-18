import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/domain/game/combat_catalog.dart';
import 'package:mindclock_app/domain/game/solo_combat_engine.dart';
import 'package:mindclock_app/domain/game/solo_training_question_bank.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';

void main() {
  group('G1 Solo Combat Engine & Bot Deterministic (solo-three-v0.1)', () {
    test('Sát thương trừ tuần tự ward -> armor -> HP và không hồi cứu khi HP 0', () {
      const SoloCombatantState player = SoloCombatantState(
        actorId: 'student',
        displayName: 'Bạn',
        championId: ChampionId.haNhan,
        isBot: false,
        hp: 10,
        armor: 0,
        qi: 2,
      );
      const SoloCombatantState bot = SoloCombatantState(
        actorId: 'bot',
        displayName: 'Máy tập',
        championId: ChampionId.tuyetDinh,
        isBot: true,
        hp: 100,
        armor: 15,
        passivePendingWard: 10,
      );

      final SoloRoundResolution res = settleSoloRound(
        roundNo: 1,
        playerState: player,
        botState: bot,
        playerGrade: SoloGradeStatus.correct,
        playerActionRequested: CombatActionType.skill2,
        botDecision: const BotRoundDecision(
          roundNo: 1,
          rollPercent: 10,
          grade: SoloGradeStatus.correct,
          chosenAction: CombatActionType.basic,
          summaryVi: 'Bot đánh thường',
        ),
      );

      // Player còn 10 HP nhận 28 ST -> 0 HP, Chiêu 2 Hà Nhân (+8 HP) KHÔNG được hồi cứu
      expect(res.nextPlayerState.hp, 0);
      expect(res.settle.playerADelta.hpHealed, 0);
      expect(res.settle.matchFinished, isTrue);
      expect(res.settle.winnerUserId, 'bot');
      expect(res.settle.finishReason, 'ko');

      // Bot nhận 32 ST từ Chiêu 2 Hà Nhân: 10 vào ward, 15 vào armor, 7 vào HP -> HP còn 93
      expect(res.settle.playerBDelta.wardAbsorbed, 10);
      expect(res.settle.playerBDelta.armorDamageTaken, 15);
      expect(res.settle.playerBDelta.hpDamageTaken, 7);
      expect(res.nextBotState.hp, 93);
      expect(res.nextBotState.armor, 0);
    });

    test('Nội tại 3 tướng và cấm Chiêu 2 Tuyệt Đỉnh ở round 6', () {
      // 1. Hàn Bối Pháp: giáp về 0 lần đầu tạo 12 ward cho round kế
      const SoloCombatantState hbp = SoloCombatantState(
        actorId: 'student',
        displayName: 'Bạn',
        championId: ChampionId.hanBoiPhap,
        isBot: false,
        armor: 10,
      );
      const SoloCombatantState bot = SoloCombatantState(
        actorId: 'bot',
        displayName: 'Máy tập',
        championId: ChampionId.tuyetDinh,
        isBot: true,
      );

      final SoloRoundResolution r1 = settleSoloRound(
        roundNo: 1,
        playerState: hbp,
        botState: bot,
        playerGrade: SoloGradeStatus.incorrect,
        playerActionRequested: CombatActionType.basic,
        botDecision: const BotRoundDecision(
          roundNo: 1,
          rollPercent: 5,
          grade: SoloGradeStatus.correct,
          chosenAction: CombatActionType.basic,
          summaryVi: 'Bot đánh thường',
        ),
      );
      expect(r1.nextPlayerState.armor, 0);
      expect(r1.settle.playerADelta.passiveTriggered, isTrue);
      expect(r1.nextPlayerState.passivePendingWard, 12);

      // 2. Tuyệt Đỉnh ở round 6: Chiêu 2 bị khóa có lý do rõ
      const SoloCombatantState tuyetDinhR6 = SoloCombatantState(
        actorId: 'student',
        displayName: 'Bạn',
        championId: ChampionId.tuyetDinh,
        isBot: false,
        qi: 3,
      );
      final List<SoloActionAvailability> opts = evaluateActionAvailability(
        state: tuyetDinhR6,
        roundNo: 6,
        playerGrade: SoloGradeStatus.correct,
        actionWindowOpen: true,
      );
      final SoloActionAvailability s2 = opts.firstWhere(
        (SoloActionAvailability a) => a.actionType == CombatActionType.skill2,
      );
      expect(s2.enabled, isFalse);
      expect(s2.disabledReasonVi, contains('round 6'));
    });

    test('Double KO -> Hòa, tie-break round 6 và Secret round 3 +1 bonus Qi', () {
      const SoloCombatantState lowA = SoloCombatantState(
        actorId: 'student',
        displayName: 'Bạn',
        championId: ChampionId.haNhan,
        isBot: false,
        hp: 10,
        armor: 0,
      );
      const SoloCombatantState lowB = SoloCombatantState(
        actorId: 'bot',
        displayName: 'Máy tập',
        championId: ChampionId.tuyetDinh,
        isBot: true,
        hp: 10,
        armor: 0,
      );
      final SoloRoundResolution koRes = settleSoloRound(
        roundNo: 3,
        playerState: lowA,
        botState: lowB,
        playerGrade: SoloGradeStatus.correct,
        playerActionRequested: CombatActionType.basic,
        botDecision: const BotRoundDecision(
          roundNo: 3,
          rollPercent: 1,
          grade: SoloGradeStatus.correct,
          chosenAction: CombatActionType.basic,
          summaryVi: 'Bot đánh thường',
        ),
        isSecretRound: true,
      );
      expect(koRes.settle.matchFinished, isTrue);
      expect(koRes.settle.winnerUserId, 'draw');
      expect(koRes.settle.finishReason, 'double_ko');
      expect(koRes.settle.playerADelta.qiGained, 2); // +1 thường +1 secret
    });

    test('Bot deterministic: cùng seed & trạng thái luôn tạo cùng chuỗi quyết định (Replay)', () {
      const DeterministicTrainingBot bot1 = DeterministicTrainingBot(
        seed: 20261118,
        difficulty: BotDifficulty.tieuChuan,
      );
      const DeterministicTrainingBot bot2 = DeterministicTrainingBot(
        seed: 20261118,
        difficulty: BotDifficulty.tieuChuan,
      );
      const SoloCombatantState state = SoloCombatantState(
        actorId: 'bot',
        displayName: 'Máy tập',
        championId: ChampionId.hanBoiPhap,
        isBot: true,
        qi: 2,
      );

      for (int round = 1; round <= maxCombatRounds; round++) {
        final BotRoundDecision d1 =
            bot1.decideRound(roundNo: round, botState: state);
        final BotRoundDecision d2 =
            bot2.decideRound(roundNo: round, botState: state);
        expect(d1.rollPercent, d2.rollPercent);
        expect(d1.grade, d2.grade);
        expect(d1.chosenAction, d2.chosenAction);
      }
    });
  });

  group('G1 Question Bank & 3-state Grading (GAME-06)', () {
    test('Chấm 3 trạng thái correct / incorrect / uncertain chuẩn xác', () {
      final SoloApprovedQuestion q =
          SoloTrainingQuestionBank.questionsForSubject('math').first;

      // 1. Đúng đáp án + có bước trình bày -> correct
      final SoloGradingFeedback ok = gradeSoloTrainingSubmission(
        question: q,
        answerText: 'x = 8',
        reasoningText: 'Chia hai vế cho 2 được x - 3 = 5 rồi chuyển vế',
      );
      expect(ok.status, SoloGradeStatus.correct);
      expect(ok.canRevealRubric, isTrue);

      // 2. Thiếu bước trình bày -> incorrect + gợi ý 1 bước
      final SoloGradingFeedback noStep = gradeSoloTrainingSubmission(
        question: q,
        answerText: '8',
        reasoningText: '',
      );
      expect(noStep.status, SoloGradeStatus.incorrect);
      expect(noStep.oneStepHintVi, isNotNull);

      // 3. Có dấu hiệu mơ hồ -> uncertain + cho sửa bài hoặc đổi câu không phạt
      final SoloGradingFeedback unc = gradeSoloTrainingSubmission(
        question: q,
        answerText: '8?',
        reasoningText: 'Chưa chắc lắm',
      );
      expect(unc.status, SoloGradeStatus.uncertain);
      expect(unc.canRetry, isTrue);
      expect(unc.canSwapQuestion, isTrue);
      expect(unc.canRevealRubric, isFalse);

      // 4. Môn chưa có pool cache -> trả về false
      expect(SoloTrainingQuestionBank.hasApprovedCacheFor('history'), isFalse);
      expect(SoloTrainingQuestionBank.hasApprovedCacheFor('math'), isTrue);
    });

    test('SoloArenaViewModel chạy trọn trận offline & Replay cùng seed khớp 100%', () {
      final SoloArenaViewModel vm = SoloArenaViewModel(initialSeed: 777);
      vm.openSoloSetup();
      vm.selectSubject('history');
      expect(vm.startSoloMatch(), isFalse);
      expect(vm.setupErrorVi, isNotNull);

      vm.selectSubject('math');
      vm.selectPlayerChampion(ChampionId.haNhan);
      expect(vm.startSoloMatch(playerName: 'An'), isTrue);
      expect(vm.section, ArenaSection.battle);
      expect(vm.soundEnabled, isFalse); // Âm tắt mặc định

      final String firstQuestionId = vm.currentQuestion!.id;
      // Thử uncertain -> đổi câu không mất HP hay round
      vm.submitAnswer(answerText: '8?', reasoningText: 'chưa rõ');
      expect(vm.phase, SoloBattlePhase.gradedUncertain);
      expect(vm.playerState.hp, maxHp);
      vm.swapQuestionOnUncertain();
      expect(vm.currentRound, 1);
      expect(vm.currentQuestion!.id, isNot(firstQuestionId));

      // Giải đúng hết các round tới khi kết thúc
      while (vm.section == ArenaSection.battle) {
        final SoloApprovedQuestion q = vm.currentQuestion!;
        vm.submitAnswer(
          answerText: q.acceptedAnswers.first,
          reasoningText: '${q.reasoningKeywords.first} = 10',
        );
        expect(vm.phase, SoloBattlePhase.choosingAction);
        vm.chooseAction(CombatActionType.basic);
        expect(vm.phase, SoloBattlePhase.roundFeedback);
        vm.advanceAfterFeedback();
      }

      expect(vm.section, ArenaSection.summary);
      expect(vm.history, isNotEmpty);

      // Replay cùng seed -> câu đầu tiên giống hệt firstQuestionId
      expect(vm.replayWithSameSeed(playerName: 'An'), isTrue);
      expect(vm.currentQuestion!.id, firstQuestionId);
      expect(vm.playerState.hp, maxHp);
      expect(vm.botState.hp, maxHp);
    });
  });
}
