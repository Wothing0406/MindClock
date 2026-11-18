import 'combat_catalog.dart';
import 'combat_models.dart';

/// Trạng thái chấm bài 3 mức cho Luyện đơn cục bộ (G1 / GAME-06).
enum SoloGradeStatus {
  correct('correct', 'Đúng rõ'),
  incorrect('incorrect', 'Chưa đúng'),
  uncertain('uncertain', 'Chưa chắc');

  const SoloGradeStatus(this.code, this.labelVi);

  final String code;
  final String labelVi;
}

/// Mức độ công khai của Máy tập (bot mô phỏng theo luật, không phải AI chấm HP hay người thật).
enum BotDifficulty {
  coBan('co_ban', 'Cơ bản', 55, 'Máy tập trả lời đúng khoảng 55% lượt, ưu tiên Đánh thường.'),
  tieuChuan('tieu_chuan', 'Tiêu chuẩn', 70, 'Máy tập trả lời đúng khoảng 70% lượt, biết dùng Chiêu 1/Chiêu 2 khi đủ Qi.'),
  thuThach('thu_thach', 'Thử thách', 85, 'Máy tập trả lời đúng khoảng 85% lượt, tận dụng tối đa Qi và nội tại.');

  const BotDifficulty(
    this.code,
    this.labelVi,
    this.accuracyPercent,
    this.descriptionVi,
  );

  final String code;
  final String labelVi;
  final int accuracyPercent;
  final String descriptionVi;
}

/// Trạng thái chiến đấu của một đấu thủ trong Luyện đơn cục bộ (`solo-three-v0.1`).
class SoloCombatantState {
  const SoloCombatantState({
    required this.actorId,
    required this.displayName,
    required this.championId,
    required this.isBot,
    this.hp = maxHp,
    this.armor = maxArmor,
    this.ward = 0,
    this.qi = 0,
    this.consecutiveCorrect = 0,
    this.skill1Used = false,
    this.skill2Used = false,
    this.passiveTriggerCount = 0,
    this.passivePendingWard = 0,
    this.buffNextBasicBonus = 0,
    this.penaltyNextBasic = 0,
  });

  final String actorId;
  final String displayName;
  final ChampionId championId;
  final bool isBot;
  final int hp;
  final int armor;
  final int ward;
  final int qi;
  final int consecutiveCorrect;
  final bool skill1Used;
  final bool skill2Used;
  final int passiveTriggerCount;
  final int passivePendingWard;
  final int buffNextBasicBonus;
  final int penaltyNextBasic;

  bool get isAlive => hp > 0;

  SoloCombatantState copyWith({
    int? hp,
    int? armor,
    int? ward,
    int? qi,
    int? consecutiveCorrect,
    bool? skill1Used,
    bool? skill2Used,
    int? passiveTriggerCount,
    int? passivePendingWard,
    int? buffNextBasicBonus,
    int? penaltyNextBasic,
  }) {
    return SoloCombatantState(
      actorId: actorId,
      displayName: displayName,
      championId: championId,
      isBot: isBot,
      hp: hp ?? this.hp,
      armor: armor ?? this.armor,
      ward: ward ?? this.ward,
      qi: qi ?? this.qi,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      skill1Used: skill1Used ?? this.skill1Used,
      skill2Used: skill2Used ?? this.skill2Used,
      passiveTriggerCount: passiveTriggerCount ?? this.passiveTriggerCount,
      passivePendingWard: passivePendingWard ?? this.passivePendingWard,
      buffNextBasicBonus: buffNextBasicBonus ?? this.buffNextBasicBonus,
      penaltyNextBasic: penaltyNextBasic ?? this.penaltyNextBasic,
    );
  }

  PlayerCombatSnapshot toSnapshot() => PlayerCombatSnapshot(
        userId: actorId,
        championId: championId,
        hp: hp,
        armor: armor,
        ward: ward,
        qi: qi,
        skill1Used: skill1Used,
        skill2Used: skill2Used,
        isAlive: isAlive,
      );
}

/// Khả năng bấm nút hành động kèm lý do vô hiệu hóa hiển thị trên UI (`docs/04-game/04 §5`).
class SoloActionAvailability {
  const SoloActionAvailability({
    required this.actionType,
    required this.titleVi,
    required this.effectSummaryVi,
    required this.qiCost,
    required this.enabled,
    this.disabledReasonVi,
  });

  final CombatActionType actionType;
  final String titleVi;
  final String effectSummaryVi;
  final int qiCost;
  final bool enabled;
  final String? disabledReasonVi;
}

/// Quyết định có thể phát lại (deterministic) của Máy tập cho từng round.
class BotRoundDecision {
  const BotRoundDecision({
    required this.roundNo,
    required this.rollPercent,
    required this.grade,
    required this.chosenAction,
    required this.summaryVi,
  });

  final int roundNo;
  final int rollPercent;
  final SoloGradeStatus grade;
  final CombatActionType chosenAction;
  final String summaryVi;
}

/// Kết quả 1 round Luyện đơn (đồng bộ luật `solo-three-v0.1` với backend Python).
class SoloRoundResolution {
  const SoloRoundResolution({
    required this.settle,
    required this.nextPlayerState,
    required this.nextBotState,
    required this.botDecision,
    required this.effectiveWardPlayer,
    required this.effectiveWardBot,
  });

  final RoundSettleSnapshot settle;
  final SoloCombatantState nextPlayerState;
  final SoloCombatantState nextBotState;
  final BotRoundDecision botDecision;
  final int effectiveWardPlayer;
  final int effectiveWardBot;
}

/// Bot luyện tập deterministic theo seed và rule version `solo-three-v0.1`.
///
/// Không gọi Gemini tự quyết HP, không giả đối thủ người thật.
class DeterministicTrainingBot {
  const DeterministicTrainingBot({
    required this.seed,
    required this.difficulty,
  });

  final int seed;
  final BotDifficulty difficulty;

  /// Sinh số giả ngẫu nhiên 0..99 hoàn toàn xác định từ `(seed, roundNo, salt)`.
  int deterministicRollPercent(int roundNo, {int salt = 17}) {
    int x = (seed ^ (roundNo * 0x9E3779B9) ^ (salt * 0x85EBCA6B)) & 0x7FFFFFFF;
    x = ((x * 1103515245) + 12345) & 0x7FFFFFFF;
    x = ((x >> 16) ^ x) & 0x7FFFFFFF;
    return x % 100;
  }

  BotRoundDecision decideRound({
    required int roundNo,
    required SoloCombatantState botState,
  }) {
    final int roll = deterministicRollPercent(roundNo);
    final bool botCorrect = roll < difficulty.accuracyPercent;
    if (!botCorrect) {
      return BotRoundDecision(
        roundNo: roundNo,
        rollPercent: roll,
        grade: SoloGradeStatus.incorrect,
        chosenAction: CombatActionType.basic,
        summaryVi: 'Máy tập chưa giải đúng lượt này nên không ra đòn.',
      );
    }

    final List<SoloActionAvailability> options = evaluateActionAvailability(
      state: botState,
      roundNo: roundNo,
      playerGrade: SoloGradeStatus.correct,
      actionWindowOpen: true,
    );

    final SoloActionAvailability skill2 = options.firstWhere(
      (SoloActionAvailability a) => a.actionType == CombatActionType.skill2,
    );
    final SoloActionAvailability skill1 = options.firstWhere(
      (SoloActionAvailability a) => a.actionType == CombatActionType.skill1,
    );

    CombatActionType picked = CombatActionType.basic;
    if (difficulty == BotDifficulty.thuThach) {
      if (skill2.enabled) {
        picked = CombatActionType.skill2;
      } else if (skill1.enabled) {
        picked = CombatActionType.skill1;
      }
    } else if (difficulty == BotDifficulty.tieuChuan) {
      final int skillRoll = deterministicRollPercent(roundNo, salt: 53);
      if (skill2.enabled && skillRoll < 70) {
        picked = CombatActionType.skill2;
      } else if (skill1.enabled && skillRoll < 65) {
        picked = CombatActionType.skill1;
      }
    } else {
      final int skillRoll = deterministicRollPercent(roundNo, salt: 53);
      if (skill1.enabled && skillRoll < 35) {
        picked = CombatActionType.skill1;
      }
    }

    final ChampionSpec spec = CombatCatalog.getSpec(botState.championId);
    final String actionLabel = switch (picked) {
      CombatActionType.basic => 'Đánh thường',
      CombatActionType.skill1 => 'Chiêu 1 (${spec.skill1.nameVi})',
      CombatActionType.skill2 => 'Chiêu 2 (${spec.skill2.nameVi})',
    };

    return BotRoundDecision(
      roundNo: roundNo,
      rollPercent: roll,
      grade: SoloGradeStatus.correct,
      chosenAction: picked,
      summaryVi: 'Máy tập giải đúng theo luật (seed #$seed) và chọn $actionLabel.',
    );
  }
}

/// Đánh giá 3 nút Đánh thường / Chiêu 1 / Chiêu 2 kèm text lý do khi bị vô hiệu hóa.
List<SoloActionAvailability> evaluateActionAvailability({
  required SoloCombatantState state,
  required int roundNo,
  required SoloGradeStatus? playerGrade,
  required bool actionWindowOpen,
}) {
  final ChampionSpec spec = CombatCatalog.getSpec(state.championId);
  final int basicDmg = (basicAttackDamage +
          state.buffNextBasicBonus -
          state.penaltyNextBasic)
      .clamp(0, 999);

  String? gateReason() {
    if (!actionWindowOpen) {
      return 'Nộp và chấm câu hỏi trước khi chọn chiêu.';
    }
    if (playerGrade != SoloGradeStatus.correct) {
      return 'Chỉ câu trả lời đúng rõ mới kích hoạt chiêu.';
    }
    return null;
  }

  final String? commonGate = gateReason();

  final String? s1Reason;
  if (commonGate != null) {
    s1Reason = commonGate;
  } else if (state.skill1Used) {
    s1Reason = 'Đã dùng 1 lần trong trận này.';
  } else if (state.qi < spec.skill1.qiCost) {
    s1Reason = 'Thiếu Qi (cần ${spec.skill1.qiCost}, đang có ${state.qi}).';
  } else {
    s1Reason = null;
  }

  final String? s2Reason;
  if (commonGate != null) {
    s2Reason = commonGate;
  } else if (state.skill2Used) {
    s2Reason = 'Đã dùng 1 lần trong trận này.';
  } else if (spec.skill2.forbidRound6 && roundNo >= maxCombatRounds) {
    s2Reason = 'Cấm dùng Đường Kiếm Cuối Trang ở round 6.';
  } else if (state.qi < spec.skill2.qiCost) {
    s2Reason = 'Thiếu Qi (cần ${spec.skill2.qiCost}, đang có ${state.qi}).';
  } else {
    s2Reason = null;
  }

  return <SoloActionAvailability>[
    SoloActionAvailability(
      actionType: CombatActionType.basic,
      titleVi: 'Đánh thường',
      effectSummaryVi:
          '$basicDmg sát thương · 0 Qi${state.buffNextBasicBonus > 0 ? " (đang +${state.buffNextBasicBonus})" : ""}${state.penaltyNextBasic > 0 ? " (giảm ${state.penaltyNextBasic})" : ""}',
      qiCost: basicAttackQiCost,
      enabled: commonGate == null,
      disabledReasonVi: commonGate,
    ),
    SoloActionAvailability(
      actionType: CombatActionType.skill1,
      titleVi: 'Chiêu 1 · ${spec.skill1.nameVi}',
      effectSummaryVi: _describeSkill(spec.skill1),
      qiCost: spec.skill1.qiCost,
      enabled: s1Reason == null,
      disabledReasonVi: s1Reason,
    ),
    SoloActionAvailability(
      actionType: CombatActionType.skill2,
      titleVi: 'Chiêu 2 · ${spec.skill2.nameVi}',
      effectSummaryVi: _describeSkill(spec.skill2),
      qiCost: spec.skill2.qiCost,
      enabled: s2Reason == null,
      disabledReasonVi: s2Reason,
    ),
  ];
}

String _describeSkill(SkillSpec skill) {
  final List<String> parts = <String>['${skill.damage} sát thương'];
  if (skill.addWard > 0) parts.add('+${skill.addWard} chắn trong round');
  if (skill.healArmor > 0) parts.add('hồi ${skill.healArmor} giáp');
  if (skill.healHp > 0) parts.add('hồi ${skill.healHp} HP nếu sống');
  if (skill.nextRoundBasicPenalty > 0) {
    parts.add('đánh thường round sau còn ${basicAttackDamage - skill.nextRoundBasicPenalty}');
  }
  if (skill.forbidRound6) parts.add('cấm round 6');
  return '${parts.join(" · ")} · ${skill.qiCost} Qi (1 lần/trận)';
}

/// Xử lý đồng thời 1 round Luyện đơn cục bộ khớp 1:1 luật `solo-three-v0.1`.
SoloRoundResolution settleSoloRound({
  required int roundNo,
  required SoloCombatantState playerState,
  required SoloCombatantState botState,
  required SoloGradeStatus playerGrade,
  required CombatActionType playerActionRequested,
  required BotRoundDecision botDecision,
  bool isSecretRound = false,
}) {
  final ChampionSpec specA = CombatCatalog.getSpec(playerState.championId);
  final ChampionSpec specB = CombatCatalog.getSpec(botState.championId);

  // 1. Khởi tạo chắn (ward) đầu round từ nội tại round trước
  final int wardStartA = playerState.passivePendingWard.clamp(0, maxWard);
  final int wardStartB = botState.passivePendingWard.clamp(0, maxWard);

  // 2. Xác thực hành động theo grade, qi, lượt dùng và luật round 6
  final _ResolvedAction actA = _resolveAction(
    state: playerState,
    requested: playerActionRequested,
    grade: playerGrade,
    roundNo: roundNo,
  );
  final _ResolvedAction actB = _resolveAction(
    state: botState,
    requested: botDecision.chosenAction,
    grade: botDecision.grade,
    roundNo: roundNo,
  );

  // 3. Kích hoạt buff chắn trong round (trước khi chịu sát thương)
  final int wardAddedA =
      actA.action == CombatActionType.skill1 ? specA.skill1.addWard : 0;
  final int wardAddedB =
      actB.action == CombatActionType.skill1 ? specB.skill1.addWard : 0;

  final int effectiveWardA = (wardStartA + wardAddedA).clamp(0, maxWard);
  final int effectiveWardB = (wardStartB + wardAddedB).clamp(0, maxWard);

  // 4. Tính sát thương thô đồng thời từ snapshot đầu round
  final int rawDmgA = _computeRawDamage(state: playerState, action: actA.action);
  final int rawDmgB = _computeRawDamage(state: botState, action: actB.action);

  // 5. Hấp thụ sát thương tuần tự: ward -> armor -> HP
  final int armorBeforeA = playerState.armor;
  final int armorBeforeB = botState.armor;

  final _AbsorbResult absA = _absorbDamage(
    damage: rawDmgB,
    ward: effectiveWardA,
    armor: playerState.armor,
    hp: playerState.hp,
  );
  final _AbsorbResult absB = _absorbDamage(
    damage: rawDmgA,
    ward: effectiveWardB,
    armor: botState.armor,
    hp: botState.hp,
  );

  final int hpAfterDmgA = playerState.hp - absA.hpDamage;
  final int hpAfterDmgB = botState.hp - absB.hpDamage;
  final int armorAfterDmgA = playerState.armor - absA.armorDamage;
  final int armorAfterDmgB = botState.armor - absB.armorDamage;

  // 6. Hồi HP & giáp SAU sát thương; HP <= 0 không hồi cứu
  int hpHealedA = 0;
  int armorHealedA = 0;
  if (hpAfterDmgA > 0) {
    if (actA.action == CombatActionType.skill1 && specA.skill1.healArmor > 0) {
      armorHealedA = specA.skill1.healArmor;
    } else if (actA.action == CombatActionType.skill2) {
      hpHealedA = specA.skill2.healHp;
      armorHealedA = specA.skill2.healArmor;
    }
  }

  int hpHealedB = 0;
  int armorHealedB = 0;
  if (hpAfterDmgB > 0) {
    if (actB.action == CombatActionType.skill1 && specB.skill1.healArmor > 0) {
      armorHealedB = specB.skill1.healArmor;
    } else if (actB.action == CombatActionType.skill2) {
      hpHealedB = specB.skill2.healHp;
      armorHealedB = specB.skill2.healArmor;
    }
  }

  final int finalHpA = (hpAfterDmgA + hpHealedA).clamp(0, maxHp);
  final int finalHpB = (hpAfterDmgB + hpHealedB).clamp(0, maxHp);
  int finalArmorA = (armorAfterDmgA + armorHealedA).clamp(0, maxArmor);
  int finalArmorB = (armorAfterDmgB + armorHealedB).clamp(0, maxArmor);

  // 7. Nội tại & hiệu ứng vòng sau
  final _PassiveOutcome passiveA = _processPassive(
    state: playerState,
    grade: playerGrade,
    armorBefore: armorBeforeA,
    armorAfter: finalArmorA,
    isAlive: finalHpA > 0,
  );
  if (passiveA.triggered &&
      playerState.championId == ChampionId.haNhan &&
      finalHpA > 0) {
    finalArmorA = (finalArmorA + 8).clamp(0, maxArmor);
  }

  final _PassiveOutcome passiveB = _processPassive(
    state: botState,
    grade: botDecision.grade,
    armorBefore: armorBeforeB,
    armorAfter: finalArmorB,
    isAlive: finalHpB > 0,
  );
  if (passiveB.triggered &&
      botState.championId == ChampionId.haNhan &&
      finalHpB > 0) {
    finalArmorB = (finalArmorB + 8).clamp(0, maxArmor);
  }

  final int nextPenaltyA = actA.action == CombatActionType.skill2
      ? specA.skill2.nextRoundBasicPenalty
      : 0;
  final int nextPenaltyB = actB.action == CombatActionType.skill2
      ? specB.skill2.nextRoundBasicPenalty
      : 0;

  final int nextBuffA = actA.action == CombatActionType.basic
      ? (passiveA.nextBasicBonus > 0 ? passiveA.nextBasicBonus : 0)
      : (passiveA.nextBasicBonus > 0
          ? passiveA.nextBasicBonus
          : playerState.buffNextBasicBonus);
  final int nextBuffB = actB.action == CombatActionType.basic
      ? (passiveB.nextBasicBonus > 0 ? passiveB.nextBasicBonus : 0)
      : (passiveB.nextBasicBonus > 0
          ? passiveB.nextBasicBonus
          : botState.buffNextBasicBonus);

  // 8. Cộng Qi sau settle (tối đa 3; secret round +1 bonus qi)
  final int qiGainedA =
      playerGrade == SoloGradeStatus.correct ? (isSecretRound ? 2 : 1) : 0;
  final int qiGainedB =
      botDecision.grade == SoloGradeStatus.correct ? (isSecretRound ? 2 : 1) : 0;

  final int finalQiA =
      ((playerState.qi - actA.qiSpent).clamp(0, maxQi) + qiGainedA)
          .clamp(0, maxQi);
  final int finalQiB =
      ((botState.qi - actB.qiSpent).clamp(0, maxQi) + qiGainedB)
          .clamp(0, maxQi);

  final SoloCombatantState nextPlayer = playerState.copyWith(
    hp: finalHpA,
    armor: finalArmorA,
    ward: 0,
    qi: finalQiA,
    consecutiveCorrect: passiveA.nextConsecutiveCorrect,
    skill1Used:
        playerState.skill1Used || actA.action == CombatActionType.skill1,
    skill2Used:
        playerState.skill2Used || actA.action == CombatActionType.skill2,
    passiveTriggerCount: passiveA.nextTriggerCount,
    passivePendingWard: passiveA.nextPendingWard,
    buffNextBasicBonus: nextBuffA,
    penaltyNextBasic: nextPenaltyA,
  );

  final SoloCombatantState nextBot = botState.copyWith(
    hp: finalHpB,
    armor: finalArmorB,
    ward: 0,
    qi: finalQiB,
    consecutiveCorrect: passiveB.nextConsecutiveCorrect,
    skill1Used: botState.skill1Used || actB.action == CombatActionType.skill1,
    skill2Used: botState.skill2Used || actB.action == CombatActionType.skill2,
    passiveTriggerCount: passiveB.nextTriggerCount,
    passivePendingWard: passiveB.nextPendingWard,
    buffNextBasicBonus: nextBuffB,
    penaltyNextBasic: nextPenaltyB,
  );

  final _FinishEval finish = _evaluateMatchFinish(
    roundNo: roundNo,
    stateA: nextPlayer,
    stateB: nextBot,
  );

  final PlayerRoundDeltaSnapshot deltaA = PlayerRoundDeltaSnapshot(
    userId: nextPlayer.actorId,
    actionUsed: actA.action,
    rawDamageDealt: rawDmgA,
    damageTaken: absA.totalTaken,
    wardAbsorbed: absA.wardAbsorbed,
    armorDamageTaken: absA.armorDamage,
    hpDamageTaken: absA.hpDamage,
    hpHealed: hpHealedA,
    armorHealed: armorHealedA,
    wardAddedInRound: wardAddedA,
    qiSpent: actA.qiSpent,
    qiGained: qiGainedA,
    passiveTriggered: passiveA.triggered,
    passiveEffectVi: passiveA.descriptionVi,
    newHp: nextPlayer.hp,
    newArmor: nextPlayer.armor,
    newWard: 0,
    newQi: nextPlayer.qi,
    isAlive: nextPlayer.isAlive,
  );

  final PlayerRoundDeltaSnapshot deltaB = PlayerRoundDeltaSnapshot(
    userId: nextBot.actorId,
    actionUsed: actB.action,
    rawDamageDealt: rawDmgB,
    damageTaken: absB.totalTaken,
    wardAbsorbed: absB.wardAbsorbed,
    armorDamageTaken: absB.armorDamage,
    hpDamageTaken: absB.hpDamage,
    hpHealed: hpHealedB,
    armorHealed: armorHealedB,
    wardAddedInRound: wardAddedB,
    qiSpent: actB.qiSpent,
    qiGained: qiGainedB,
    passiveTriggered: passiveB.triggered,
    passiveEffectVi: passiveB.descriptionVi,
    newHp: nextBot.hp,
    newArmor: nextBot.armor,
    newWard: 0,
    newQi: nextBot.qi,
    isAlive: nextBot.isAlive,
  );

  return SoloRoundResolution(
    settle: RoundSettleSnapshot(
      ruleVersion: combatRuleVersion,
      roundNo: roundNo,
      isSecretRound: isSecretRound,
      playerADelta: deltaA,
      playerBDelta: deltaB,
      matchFinished: finish.finished,
      winnerUserId: finish.winnerId,
      finishReason: finish.reason,
    ),
    nextPlayerState: nextPlayer,
    nextBotState: nextBot,
    botDecision: botDecision,
    effectiveWardPlayer: effectiveWardA,
    effectiveWardBot: effectiveWardB,
  );
}

class _ResolvedAction {
  const _ResolvedAction(this.action, this.qiSpent);
  final CombatActionType? action;
  final int qiSpent;
}

_ResolvedAction _resolveAction({
  required SoloCombatantState state,
  required CombatActionType requested,
  required SoloGradeStatus grade,
  required int roundNo,
}) {
  if (grade != SoloGradeStatus.correct) {
    return const _ResolvedAction(null, 0);
  }
  final ChampionSpec spec = CombatCatalog.getSpec(state.championId);
  if (requested == CombatActionType.skill1) {
    if (!state.skill1Used && state.qi >= spec.skill1.qiCost) {
      return _ResolvedAction(CombatActionType.skill1, spec.skill1.qiCost);
    }
    return const _ResolvedAction(CombatActionType.basic, 0);
  }
  if (requested == CombatActionType.skill2) {
    if (!state.skill2Used &&
        state.qi >= spec.skill2.qiCost &&
        !(spec.skill2.forbidRound6 && roundNo >= maxCombatRounds)) {
      return _ResolvedAction(CombatActionType.skill2, spec.skill2.qiCost);
    }
    return const _ResolvedAction(CombatActionType.basic, 0);
  }
  return const _ResolvedAction(CombatActionType.basic, 0);
}

int _computeRawDamage({
  required SoloCombatantState state,
  required CombatActionType? action,
}) {
  if (action == null) return 0;
  final ChampionSpec spec = CombatCatalog.getSpec(state.championId);
  switch (action) {
    case CombatActionType.basic:
      final int dmg = basicAttackDamage +
          state.buffNextBasicBonus -
          state.penaltyNextBasic;
      return dmg < 0 ? 0 : dmg;
    case CombatActionType.skill1:
      return spec.skill1.damage;
    case CombatActionType.skill2:
      return spec.skill2.damage;
  }
}

class _AbsorbResult {
  const _AbsorbResult({
    required this.totalTaken,
    required this.wardAbsorbed,
    required this.armorDamage,
    required this.hpDamage,
  });

  final int totalTaken;
  final int wardAbsorbed;
  final int armorDamage;
  final int hpDamage;
}

_AbsorbResult _absorbDamage({
  required int damage,
  required int ward,
  required int armor,
  required int hp,
}) {
  final int wardAbs = damage < ward ? damage : ward;
  final int remAfterWard = damage - wardAbs;

  final int armorDmg = remAfterWard < armor ? remAfterWard : armor;
  final int remAfterArmor = remAfterWard - armorDmg;

  final int hpDmg = remAfterArmor < hp ? remAfterArmor : hp;
  return _AbsorbResult(
    totalTaken: wardAbs + armorDmg + hpDmg,
    wardAbsorbed: wardAbs,
    armorDamage: armorDmg,
    hpDamage: hpDmg,
  );
}

class _PassiveOutcome {
  const _PassiveOutcome({
    required this.triggered,
    required this.descriptionVi,
    required this.nextConsecutiveCorrect,
    required this.nextTriggerCount,
    required this.nextPendingWard,
    required this.nextBasicBonus,
  });

  final bool triggered;
  final String? descriptionVi;
  final int nextConsecutiveCorrect;
  final int nextTriggerCount;
  final int nextPendingWard;
  final int nextBasicBonus;
}

_PassiveOutcome _processPassive({
  required SoloCombatantState state,
  required SoloGradeStatus grade,
  required int armorBefore,
  required int armorAfter,
  required bool isAlive,
}) {
  if (state.championId == ChampionId.haNhan) {
    if (grade == SoloGradeStatus.correct) {
      final int nextStreak = state.consecutiveCorrect + 1;
      if (nextStreak == 2 && state.passiveTriggerCount < 2) {
        return _PassiveOutcome(
          triggered: true,
          descriptionVi:
              'Kiên Định: 2 round đúng liên tiếp -> Hồi 8 giáp sau settle.',
          nextConsecutiveCorrect: 0,
          nextTriggerCount: state.passiveTriggerCount + 1,
          nextPendingWard: 0,
          nextBasicBonus: 0,
        );
      }
      return _PassiveOutcome(
        triggered: false,
        descriptionVi: null,
        nextConsecutiveCorrect: nextStreak,
        nextTriggerCount: state.passiveTriggerCount,
        nextPendingWard: 0,
        nextBasicBonus: 0,
      );
    }
    return _PassiveOutcome(
      triggered: false,
      descriptionVi: null,
      nextConsecutiveCorrect: 0,
      nextTriggerCount: state.passiveTriggerCount,
      nextPendingWard: 0,
      nextBasicBonus: 0,
    );
  }

  if (state.championId == ChampionId.tuyetDinh) {
    if (grade == SoloGradeStatus.correct) {
      final int nextStreak = state.consecutiveCorrect + 1;
      if (nextStreak == 2 && state.passiveTriggerCount < 2) {
        return _PassiveOutcome(
          triggered: true,
          descriptionVi:
              'Tập Trung Đột Phá: 2 round đúng liên tiếp -> Đánh thường kế +6 sát thương.',
          nextConsecutiveCorrect: 0,
          nextTriggerCount: state.passiveTriggerCount + 1,
          nextPendingWard: 0,
          nextBasicBonus: 6,
        );
      }
      return _PassiveOutcome(
        triggered: false,
        descriptionVi: null,
        nextConsecutiveCorrect: nextStreak,
        nextTriggerCount: state.passiveTriggerCount,
        nextPendingWard: 0,
        nextBasicBonus: 0,
      );
    }
    return _PassiveOutcome(
      triggered: false,
      descriptionVi: null,
      nextConsecutiveCorrect: 0,
      nextTriggerCount: state.passiveTriggerCount,
      nextPendingWard: 0,
      nextBasicBonus: 0,
    );
  }

  if (state.championId == ChampionId.hanBoiPhap) {
    if (armorBefore > 0 &&
        armorAfter == 0 &&
        state.passiveTriggerCount == 0 &&
        isAlive) {
      return const _PassiveOutcome(
        triggered: true,
        descriptionVi:
            'Bích Chướng Cổ Giới: Giáp về 0 lần đầu -> Tạo 12 chắn cho round kế.',
        nextConsecutiveCorrect: 0,
        nextTriggerCount: 1,
        nextPendingWard: 12,
        nextBasicBonus: 0,
      );
    }
    return _PassiveOutcome(
      triggered: false,
      descriptionVi: null,
      nextConsecutiveCorrect: 0,
      nextTriggerCount: state.passiveTriggerCount,
      nextPendingWard: 0,
      nextBasicBonus: 0,
    );
  }

  return _PassiveOutcome(
    triggered: false,
    descriptionVi: null,
    nextConsecutiveCorrect: state.consecutiveCorrect,
    nextTriggerCount: state.passiveTriggerCount,
    nextPendingWard: 0,
    nextBasicBonus: 0,
  );
}

class _FinishEval {
  const _FinishEval(this.finished, this.winnerId, this.reason);
  final bool finished;
  final String? winnerId;
  final String? reason;
}

_FinishEval _evaluateMatchFinish({
  required int roundNo,
  required SoloCombatantState stateA,
  required SoloCombatantState stateB,
}) {
  final bool aDead = stateA.hp <= 0;
  final bool bDead = stateB.hp <= 0;

  if (aDead && bDead) {
    return const _FinishEval(true, 'draw', 'double_ko');
  }
  if (aDead) {
    return _FinishEval(true, stateB.actorId, 'ko');
  }
  if (bDead) {
    return _FinishEval(true, stateA.actorId, 'ko');
  }

  if (roundNo >= maxCombatRounds) {
    if (stateA.hp > stateB.hp) {
      return _FinishEval(true, stateA.actorId, 'hp_tiebreak');
    }
    if (stateB.hp > stateA.hp) {
      return _FinishEval(true, stateB.actorId, 'hp_tiebreak');
    }
    if (stateA.armor > stateB.armor) {
      return _FinishEval(true, stateA.actorId, 'armor_tiebreak');
    }
    if (stateB.armor > stateA.armor) {
      return _FinishEval(true, stateB.actorId, 'armor_tiebreak');
    }
    return const _FinishEval(true, 'draw', 'draw_tiebreak');
  }

  return const _FinishEval(false, null, null);
}
