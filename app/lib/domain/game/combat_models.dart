import 'combat_catalog.dart';

class PlayerCombatSnapshot {
  const PlayerCombatSnapshot({
    required this.userId,
    required this.championId,
    required this.hp,
    required this.armor,
    required this.ward,
    required this.qi,
    required this.skill1Used,
    required this.skill2Used,
    required this.isAlive,
  });

  factory PlayerCombatSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerCombatSnapshot(
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      championId: ChampionId.fromCode(
        json['championId'] as String? ??
            json['champion_id'] as String? ??
            'ha_nhan',
      ),
      hp: json['hp'] as int? ?? 100,
      armor: json['armor'] as int? ?? 50,
      ward: json['ward'] as int? ?? 0,
      qi: json['qi'] as int? ?? 0,
      skill1Used: json['skill1Used'] as bool? ??
          json['skill_1_used'] as bool? ??
          false,
      skill2Used: json['skill2Used'] as bool? ??
          json['skill_2_used'] as bool? ??
          false,
      isAlive: json['isAlive'] as bool? ?? json['is_alive'] as bool? ?? true,
    );
  }

  final String userId;
  final ChampionId championId;
  final int hp;
  final int armor;
  final int ward;
  final int qi;
  final bool skill1Used;
  final bool skill2Used;
  final bool isAlive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'championId': championId.code,
        'hp': hp,
        'armor': armor,
        'ward': ward,
        'qi': qi,
        'skill1Used': skill1Used,
        'skill2Used': skill2Used,
        'isAlive': isAlive,
      };
}

class PlayerRoundDeltaSnapshot {
  const PlayerRoundDeltaSnapshot({
    required this.userId,
    required this.actionUsed,
    required this.rawDamageDealt,
    required this.damageTaken,
    required this.wardAbsorbed,
    required this.armorDamageTaken,
    required this.hpDamageTaken,
    required this.hpHealed,
    required this.armorHealed,
    required this.wardAddedInRound,
    required this.qiSpent,
    required this.qiGained,
    required this.passiveTriggered,
    this.passiveEffectVi,
    required this.newHp,
    required this.newArmor,
    required this.newWard,
    required this.newQi,
    required this.isAlive,
  });

  factory PlayerRoundDeltaSnapshot.fromJson(Map<String, dynamic> json) {
    final String? actionStr = json['actionUsed'] as String? ??
        json['action_used'] as String?;
    return PlayerRoundDeltaSnapshot(
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      actionUsed: actionStr != null ? CombatActionType.fromCode(actionStr) : null,
      rawDamageDealt: json['rawDamageDealt'] as int? ??
          json['raw_damage_dealt'] as int? ??
          0,
      damageTaken: json['damageTaken'] as int? ??
          json['damage_taken'] as int? ??
          0,
      wardAbsorbed: json['wardAbsorbed'] as int? ??
          json['ward_absorbed'] as int? ??
          0,
      armorDamageTaken: json['armorDamageTaken'] as int? ??
          json['armor_damage_taken'] as int? ??
          0,
      hpDamageTaken: json['hpDamageTaken'] as int? ??
          json['hp_damage_taken'] as int? ??
          0,
      hpHealed: json['hpHealed'] as int? ?? json['hp_healed'] as int? ?? 0,
      armorHealed: json['armorHealed'] as int? ??
          json['armor_healed'] as int? ??
          0,
      wardAddedInRound: json['wardAddedInRound'] as int? ??
          json['ward_added_in_round'] as int? ??
          0,
      qiSpent: json['qiSpent'] as int? ?? json['qi_spent'] as int? ?? 0,
      qiGained: json['qiGained'] as int? ?? json['qi_gained'] as int? ?? 0,
      passiveTriggered: json['passiveTriggered'] as bool? ??
          json['passive_triggered'] as bool? ??
          false,
      passiveEffectVi: json['passiveEffectVi'] as String? ??
          json['passive_effect_vi'] as String?,
      newHp: json['newHp'] as int? ?? json['new_hp'] as int? ?? 0,
      newArmor: json['newArmor'] as int? ?? json['new_armor'] as int? ?? 0,
      newWard: json['newWard'] as int? ?? json['new_ward'] as int? ?? 0,
      newQi: json['newQi'] as int? ?? json['new_qi'] as int? ?? 0,
      isAlive: json['isAlive'] as bool? ?? json['is_alive'] as bool? ?? true,
    );
  }

  final String userId;
  final CombatActionType? actionUsed;
  final int rawDamageDealt;
  final int damageTaken;
  final int wardAbsorbed;
  final int armorDamageTaken;
  final int hpDamageTaken;
  final int hpHealed;
  final int armorHealed;
  final int wardAddedInRound;
  final int qiSpent;
  final int qiGained;
  final bool passiveTriggered;
  final String? passiveEffectVi;
  final int newHp;
  final int newArmor;
  final int newWard;
  final int newQi;
  final bool isAlive;
}

class RoundSettleSnapshot {
  const RoundSettleSnapshot({
    required this.ruleVersion,
    required this.roundNo,
    required this.isSecretRound,
    required this.playerADelta,
    required this.playerBDelta,
    required this.matchFinished,
    this.winnerUserId,
    this.finishReason,
  });

  factory RoundSettleSnapshot.fromJson(Map<String, dynamic> json) {
    return RoundSettleSnapshot(
      ruleVersion: json['ruleVersion'] as String? ??
          json['rule_version'] as String? ??
          combatRuleVersion,
      roundNo: json['roundNo'] as int? ?? json['round_no'] as int? ?? 1,
      isSecretRound: json['isSecretRound'] as bool? ??
          json['is_secret_round'] as bool? ??
          false,
      playerADelta: PlayerRoundDeltaSnapshot.fromJson(
        (json['playerADelta'] ??
            json['player_a_delta'] ??
            json['deltaA'] ??
            json['delta_a']) as Map<String, dynamic>,
      ),
      playerBDelta: PlayerRoundDeltaSnapshot.fromJson(
        (json['playerBDelta'] ??
            json['player_b_delta'] ??
            json['deltaB'] ??
            json['delta_b']) as Map<String, dynamic>,
      ),
      matchFinished: json['matchFinished'] as bool? ??
          json['match_finished'] as bool? ??
          false,
      winnerUserId: json['winnerUserId'] as String? ??
          json['winner_user_id'] as String?,
      finishReason: json['finishReason'] as String? ??
          json['finish_reason'] as String?,
    );
  }

  final String ruleVersion;
  final int roundNo;
  final bool isSecretRound;
  final PlayerRoundDeltaSnapshot playerADelta;
  final PlayerRoundDeltaSnapshot playerBDelta;
  final bool matchFinished;
  final String? winnerUserId;
  final String? finishReason;
}
