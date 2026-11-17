import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/domain/game/combat_catalog.dart';
import 'package:mindclock_app/domain/game/combat_models.dart';

void main() {
  group('Combat Catalog & Models (solo-three-v0.1)', () {
    test('Catalog chốt 3 tướng và ánh xạ han_boi_thap -> hanBoiPhap', () {
      expect(ChampionId.fromCode('ha_nhan'), ChampionId.haNhan);
      expect(ChampionId.fromCode('ha-nhan'), ChampionId.haNhan);
      expect(ChampionId.fromCode('tuyet_dinh'), ChampionId.tuyetDinh);
      expect(ChampionId.fromCode('tuyet-dinh'), ChampionId.tuyetDinh);
      expect(ChampionId.fromCode('han_boi_phap'), ChampionId.hanBoiPhap);
      expect(ChampionId.fromCode('han-boi-phap'), ChampionId.hanBoiPhap);
      expect(ChampionId.fromCode('han_boi_thap'), ChampionId.hanBoiPhap);
      expect(ChampionId.fromCode('han-boi-thap'), ChampionId.hanBoiPhap);

      expect(
        () => ChampionId.fromCode('invalid_champ'),
        throwsA(isA<ArgumentError>()),
      );

      final ChampionSpec hbpSpec =
          CombatCatalog.getSpec(ChampionId.hanBoiPhap);
      expect(hbpSpec.nameVi, 'Hàn Bối Pháp');
      expect(hbpSpec.roleVi, 'Tanker, kết trận chậm');
      expect(hbpSpec.skill1.nameVi, 'Dựng Tháp');
      expect(hbpSpec.skill1.qiCost, 1);
      expect(hbpSpec.skill1.damage, 18);
      expect(hbpSpec.skill1.addWard, 14);
      expect(hbpSpec.skill2.nameVi, 'Trấn Tháp');
      expect(hbpSpec.skill2.qiCost, 2);
      expect(hbpSpec.skill2.damage, 28);
      expect(hbpSpec.skill2.healArmor, 16);
    });

    test('Thông số Hà Nhân và Tuyệt Đỉnh khớp GDD', () {
      final ChampionSpec haNhan = CombatCatalog.getSpec(ChampionId.haNhan);
      expect(haNhan.nameVi, 'Hà Nhân');
      expect(haNhan.skill1.qiCost, 1);
      expect(haNhan.skill1.damage, 25);
      expect(haNhan.skill1.healArmor, 6);
      expect(haNhan.skill2.qiCost, 2);
      expect(haNhan.skill2.damage, 32);
      expect(haNhan.skill2.healHp, 8);

      final ChampionSpec tuyetDinh =
          CombatCatalog.getSpec(ChampionId.tuyetDinh);
      expect(tuyetDinh.nameVi, 'Tuyệt Đỉnh');
      expect(tuyetDinh.skill1.qiCost, 1);
      expect(tuyetDinh.skill1.damage, 38);
      expect(tuyetDinh.skill2.qiCost, 2);
      expect(tuyetDinh.skill2.damage, 46);
      expect(tuyetDinh.skill2.forbidRound6, isTrue);
      expect(tuyetDinh.skill2.nextRoundBasicPenalty, 6);
    });

    test('PlayerCombatSnapshot serialize/deserialize JSON', () {
      const PlayerCombatSnapshot snapshot = PlayerCombatSnapshot(
        userId: 'usr_1',
        championId: ChampionId.hanBoiPhap,
        hp: 92,
        armor: 34,
        ward: 12,
        qi: 2,
        skill1Used: true,
        skill2Used: false,
        isAlive: true,
      );

      final Map<String, dynamic> json = snapshot.toJson();
      expect(json['championId'], 'han_boi_phap');
      expect(json['hp'], 92);
      expect(json['ward'], 12);

      final PlayerCombatSnapshot parsed = PlayerCombatSnapshot.fromJson(json);
      expect(parsed.userId, 'usr_1');
      expect(parsed.championId, ChampionId.hanBoiPhap);
      expect(parsed.hp, 92);
      expect(parsed.armor, 34);
      expect(parsed.ward, 12);
      expect(parsed.qi, 2);
      expect(parsed.skill1Used, isTrue);
      expect(parsed.skill2Used, isFalse);
    });

    test('RoundSettleSnapshot parse từ response server', () {
      final Map<String, dynamic> serverResponse = <String, dynamic>{
        'ruleVersion': combatRuleVersion,
        'roundNo': 2,
        'isSecretRound': false,
        'playerADelta': <String, dynamic>{
          'userId': 'usr_a',
          'actionUsed': 'basic',
          'rawDamageDealt': 28,
          'damageTaken': 0,
          'wardAbsorbed': 0,
          'armorDamageTaken': 0,
          'hpDamageTaken': 0,
          'hpHealed': 0,
          'armorHealed': 0,
          'wardAddedInRound': 0,
          'qiSpent': 0,
          'qiGained': 1,
          'passiveTriggered': false,
          'newHp': 100,
          'newArmor': 50,
          'newWard': 0,
          'newQi': 1,
          'isAlive': true,
        },
        'playerBDelta': <String, dynamic>{
          'userId': 'usr_b',
          'actionUsed': null,
          'rawDamageDealt': 0,
          'damageTaken': 28,
          'wardAbsorbed': 0,
          'armorDamageTaken': 28,
          'hpDamageTaken': 0,
          'hpHealed': 0,
          'armorHealed': 0,
          'wardAddedInRound': 0,
          'qiSpent': 0,
          'qiGained': 0,
          'passiveTriggered': false,
          'newHp': 100,
          'newArmor': 22,
          'newWard': 0,
          'newQi': 0,
          'isAlive': true,
        },
        'matchFinished': false,
        'winnerUserId': null,
        'finishReason': null,
      };

      final RoundSettleSnapshot settle =
          RoundSettleSnapshot.fromJson(serverResponse);
      expect(settle.ruleVersion, combatRuleVersion);
      expect(settle.roundNo, 2);
      expect(settle.playerADelta.rawDamageDealt, 28);
      expect(settle.playerBDelta.damageTaken, 28);
      expect(settle.playerBDelta.newArmor, 22);
      expect(settle.matchFinished, isFalse);
    });

    test('RoundSettleSnapshot parse snake_case từ Python backend và alias khoảng trắng', () {
      expect(combatRuleVersion, 'solo-three-v0.1');
      expect(ChampionId.fromCode('han boi thap'), ChampionId.hanBoiPhap);

      final Map<String, dynamic> snakePayload = <String, dynamic>{
        'rule_version': 'solo-three-v0.1',
        'round_no': 1,
        'is_secret_round': false,
        'delta_a': <String, dynamic>{
          'user_id': 'u_a',
          'action_used': 'basic',
          'raw_damage_dealt': 28,
          'damage_taken': 0,
          'ward_absorbed': 0,
          'armor_damage_taken': 0,
          'hp_damage_taken': 0,
          'hp_healed': 0,
          'armor_healed': 0,
          'ward_added_in_round': 0,
          'qi_spent': 0,
          'qi_gained': 1,
          'passive_triggered': false,
          'new_hp': 100,
          'new_armor': 50,
          'new_ward': 0,
          'new_qi': 1,
          'is_alive': true,
        },
        'delta_b': <String, dynamic>{
          'user_id': 'u_b',
          'action_used': null,
          'raw_damage_dealt': 0,
          'damage_taken': 28,
          'ward_absorbed': 0,
          'armor_damage_taken': 28,
          'hp_damage_taken': 0,
          'hp_healed': 0,
          'armor_healed': 0,
          'ward_added_in_round': 0,
          'qi_spent': 0,
          'qi_gained': 0,
          'passive_triggered': false,
          'new_hp': 100,
          'new_armor': 22,
          'new_ward': 0,
          'new_qi': 0,
          'is_alive': true,
        },
        'match_finished': false,
        'winner_user_id': null,
        'finish_reason': null,
      };

      final RoundSettleSnapshot settle =
          RoundSettleSnapshot.fromJson(snakePayload);
      expect(settle.ruleVersion, 'solo-three-v0.1');
      expect(settle.roundNo, 1);
      expect(settle.playerADelta.userId, 'u_a');
      expect(settle.playerADelta.actionUsed, CombatActionType.basic);
      expect(settle.playerBDelta.actionUsed, isNull);
      expect(settle.playerBDelta.newArmor, 22);
      expect(settle.matchFinished, isFalse);
    });
  });
}
