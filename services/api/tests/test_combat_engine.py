from __future__ import annotations

import pytest

from app.game.combat_catalog import (
    ActionType,
    BASIC_ATTACK_DAMAGE,
    ChampionId,
    COMBAT_RULE_VERSION,
    get_champion_spec,
    MAX_ARMOR,
    MAX_HP,
    MAX_QI,
    normalize_champion_id,
)
from app.game.combat_engine import (
    PlayerCombatState,
    RoundActionInput,
    settle_combat_round,
)


def test_catalog_champions_and_legacy_id_mapping() -> None:
    # 3 tướng chuẩn
    assert normalize_champion_id('ha_nhan') == ChampionId.HA_NHAN
    assert normalize_champion_id('tuyet_dinh') == ChampionId.TUYET_DINH
    assert normalize_champion_id('han_boi_phap') == ChampionId.HAN_BOI_PHAP

    # Hỗ trợ slug manifest có dấu gạch ngang
    assert normalize_champion_id('han-boi-phap') == ChampionId.HAN_BOI_PHAP
    assert normalize_champion_id('ha-nhan') == ChampionId.HA_NHAN
    assert normalize_champion_id('tuyet-dinh') == ChampionId.TUYET_DINH

    # Ánh xạ legacy ID `han_boi_thap` từ docs/archive
    assert normalize_champion_id('han_boi_thap') == ChampionId.HAN_BOI_PHAP
    assert normalize_champion_id('han-boi-thap') == ChampionId.HAN_BOI_PHAP

    with pytest.raises(ValueError, match='Unknown champion id'):
        normalize_champion_id('unknown_hero')

    spec = get_champion_spec('han_boi_thap')
    assert spec.name_vi == 'Hàn Bối Pháp'
    assert spec.skill_1.name_vi == 'Dựng Tháp'
    assert spec.skill_2.name_vi == 'Trấn Tháp'


def test_damage_order_ward_armor_hp() -> None:
    # Player A đánh thường (28 damage), Player B có ward=10, armor=15, hp=100
    p_a = PlayerCombatState(user_id='user_a', champion_id=ChampionId.HA_NHAN)
    p_b = PlayerCombatState(
        user_id='user_b',
        champion_id=ChampionId.TUYET_DINH,
        ward=0,
        armor=15,
        hp=100,
        passive_pending_ward=10,  # Bắt đầu round với 10 ward
    )

    res = settle_combat_round(
        round_no=1,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(
            user_id='user_a', grade='correct', action=ActionType.BASIC
        ),
        input_b=RoundActionInput(
            user_id='user_b', grade='incorrect', action=ActionType.BASIC
        ),
    )

    # B nhận 28 damage:
    # - 10 trừ vào ward (ward còn 0)
    # - 15 trừ vào giáp (giáp còn 0)
    # - 3 trừ vào HP (HP còn 97)
    delta_b = res.player_b_delta
    assert delta_b.damage_taken == 28
    assert delta_b.ward_absorbed == 10
    assert delta_b.armor_damage_taken == 15
    assert delta_b.hp_damage_taken == 3
    assert delta_b.new_hp == 97
    assert delta_b.new_armor == 0
    assert delta_b.new_ward == 0  # Hết round ward reset


def test_heal_after_damage_and_zero_hp_no_revive() -> None:
    # 1. Player A dùng Chiêu 2 Hà Nhân (hồi 8 HP) và còn sống sau khi nhận đòn
    p_a = PlayerCombatState(
        user_id='user_a',
        champion_id=ChampionId.HA_NHAN,
        hp=50,
        armor=0,
        qi=2,
    )
    p_b = PlayerCombatState(
        user_id='user_b',
        champion_id=ChampionId.TUYET_DINH,
        hp=100,
        armor=50,
    )

    # B đánh thường 28 damage lên A -> A còn 50 - 28 = 22 HP, sau đó hồi 8 HP -> 30 HP
    res1 = settle_combat_round(
        round_no=1,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(
            user_id='user_a', grade='correct', action=ActionType.SKILL_2
        ),
        input_b=RoundActionInput(
            user_id='user_b', grade='correct', action=ActionType.BASIC
        ),
    )
    assert res1.player_a_delta.hp_damage_taken == 28
    assert res1.player_a_delta.hp_healed == 8
    assert res1.player_a_delta.new_hp == 30
    assert res1.player_a_delta.is_alive is True

    # 2. Player A chỉ còn 10 HP và nhận 28 damage -> HP về 0, KHÔNG ĐƯỢC HỒI MÁU CỨU SỐNG
    p_a_dead = PlayerCombatState(
        user_id='user_a',
        champion_id=ChampionId.HA_NHAN,
        hp=10,
        armor=0,
        qi=2,
    )
    res2 = settle_combat_round(
        round_no=2,
        player_a=p_a_dead,
        player_b=p_b,
        input_a=RoundActionInput(
            user_id='user_a', grade='correct', action=ActionType.SKILL_2
        ),
        input_b=RoundActionInput(
            user_id='user_b', grade='correct', action=ActionType.BASIC
        ),
    )
    assert res2.player_a_delta.new_hp == 0
    assert res2.player_a_delta.hp_healed == 0
    assert res2.player_a_delta.is_alive is False
    assert res2.match_finished is True
    assert res2.winner_user_id == 'user_b'
    assert res2.finish_reason == 'ko'


def test_skill_usage_cost_and_round_6_restriction() -> None:
    # Thiếu Qi hoặc đã dùng rồi -> Tự rơi về Đánh thường
    p_a = PlayerCombatState(
        user_id='user_a',
        champion_id=ChampionId.TUYET_DINH,
        qi=0,  # Chưa có Qi
    )
    p_b = PlayerCombatState(user_id='user_b', champion_id=ChampionId.HA_NHAN)

    res = settle_combat_round(
        round_no=1,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(
            user_id='user_a', grade='correct', action=ActionType.SKILL_1
        ),
        input_b=RoundActionInput(
            user_id='user_b', grade='incorrect', action=ActionType.BASIC
        ),
    )
    # Tự động rơi về BASIC vì thiếu Qi
    assert res.player_a_delta.action_used == ActionType.BASIC
    assert res.player_a_delta.raw_damage_dealt == BASIC_ATTACK_DAMAGE
    assert res.player_a_delta.qi_spent == 0
    # Sau khi trả lời đúng -> được +1 Qi sau settle
    assert res.player_a_delta.new_qi == 1

    # Tuyệt Đỉnh chiêu 2 cấm dùng ở round 6
    p_a.qi = 3
    p_a.skill_2_used = False
    res_r6 = settle_combat_round(
        round_no=6,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(
            user_id='user_a', grade='correct', action=ActionType.SKILL_2
        ),
        input_b=RoundActionInput(
            user_id='user_b', grade='incorrect', action=ActionType.BASIC
        ),
    )
    # Ở round 6, Chiêu 2 bị chặn -> rơi về Basic
    assert res_r6.player_a_delta.action_used == ActionType.BASIC


def test_champion_passives() -> None:
    # 1. Nội tại Hà Nhân: 2 round đúng liên tiếp hồi 8 giáp sau settle
    ha_nhan = PlayerCombatState(
        user_id='u1', champion_id=ChampionId.HA_NHAN, armor=20
    )
    dummy = PlayerCombatState(user_id='u2', champion_id=ChampionId.TUYET_DINH)

    # Round 1 đúng -> chưa kích hoạt
    r1 = settle_combat_round(
        round_no=1,
        player_a=ha_nhan,
        player_b=dummy,
        input_a=RoundActionInput(user_id='u1', grade='correct'),
        input_b=RoundActionInput(user_id='u2', grade='incorrect'),
    )
    assert r1.player_a_delta.passive_triggered is False
    assert ha_nhan.consecutive_correct == 1

    # Round 2 đúng -> kích hoạt hồi 8 giáp
    r2 = settle_combat_round(
        round_no=2,
        player_a=ha_nhan,
        player_b=dummy,
        input_a=RoundActionInput(user_id='u1', grade='correct'),
        input_b=RoundActionInput(user_id='u2', grade='incorrect'),
    )
    assert r2.player_a_delta.passive_triggered is True
    assert ha_nhan.passive_trigger_count == 1
    assert r2.player_a_delta.new_armor == 28  # 20 + 8

    # 2. Nội tại Hàn Bối Pháp: Giáp về 0 lần đầu -> tạo 12 ward cho round kế
    hbp = PlayerCombatState(
        user_id='u_hbp', champion_id=ChampionId.HAN_BOI_PHAP, armor=10
    )
    attacker = PlayerCombatState(user_id='u_atk', champion_id=ChampionId.TUYET_DINH)

    # Attacker gây 28 damage -> trừ hết 10 giáp của HBP
    r_hbp1 = settle_combat_round(
        round_no=1,
        player_a=attacker,
        player_b=hbp,
        input_a=RoundActionInput(user_id='u_atk', grade='correct'),
        input_b=RoundActionInput(user_id='u_hbp', grade='incorrect'),
    )
    assert r_hbp1.player_b_delta.new_armor == 0
    assert r_hbp1.player_b_delta.passive_triggered is True
    assert hbp.passive_trigger_count == 1
    assert hbp.passive_pending_ward == 12

    # Sang round 2: HBP có sẵn 12 ward đỡ đòn
    r_hbp2 = settle_combat_round(
        round_no=2,
        player_a=attacker,
        player_b=hbp,
        input_a=RoundActionInput(user_id='u_atk', grade='correct'),
        input_b=RoundActionInput(user_id='u_hbp', grade='incorrect'),
    )
    assert r_hbp2.player_b_delta.ward_absorbed == 12


def test_simultaneous_ko_results_in_draw() -> None:
    # Cả hai bên đều còn ít máu (10 HP, 0 giáp), cả hai trả lời đúng và đánh thường 28 damage
    p_a = PlayerCombatState(
        user_id='user_a', champion_id=ChampionId.HA_NHAN, hp=10, armor=0
    )
    p_b = PlayerCombatState(
        user_id='user_b', champion_id=ChampionId.TUYET_DINH, hp=10, armor=0
    )

    res = settle_combat_round(
        round_no=3,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(user_id='user_a', grade='correct'),
        input_b=RoundActionInput(user_id='user_b', grade='correct'),
    )
    assert res.player_a_delta.new_hp == 0
    assert res.player_b_delta.new_hp == 0
    assert res.match_finished is True
    assert res.winner_user_id == 'draw'
    assert res.finish_reason == 'double_ko'


def test_round_6_completion_and_tie_breakers() -> None:
    # 1. Hết round 6, bên nào HP cao hơn bên đó thắng
    p_a = PlayerCombatState(
        user_id='user_a', champion_id=ChampionId.HA_NHAN, hp=80, armor=10
    )
    p_b = PlayerCombatState(
        user_id='user_b', champion_id=ChampionId.TUYET_DINH, hp=60, armor=20
    )
    res_hp = settle_combat_round(
        round_no=6,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(user_id='user_a', grade='incorrect'),
        input_b=RoundActionInput(user_id='user_b', grade='incorrect'),
    )
    assert res_hp.match_finished is True
    assert res_hp.winner_user_id == 'user_a'
    assert res_hp.finish_reason == 'hp_tiebreak'

    # 2. Hết round 6, HP bằng nhau -> bên nào giáp cao hơn thắng
    p_a2 = PlayerCombatState(
        user_id='user_a', champion_id=ChampionId.HA_NHAN, hp=50, armor=15
    )
    p_b2 = PlayerCombatState(
        user_id='user_b', champion_id=ChampionId.TUYET_DINH, hp=50, armor=30
    )
    res_armor = settle_combat_round(
        round_no=6,
        player_a=p_a2,
        player_b=p_b2,
        input_a=RoundActionInput(user_id='user_a', grade='incorrect'),
        input_b=RoundActionInput(user_id='user_b', grade='incorrect'),
    )
    assert res_armor.match_finished is True
    assert res_armor.winner_user_id == 'user_b'
    assert res_armor.finish_reason == 'armor_tiebreak'

    # 3. Hết round 6, cả HP và giáp bằng nhau -> Hòa
    p_a3 = PlayerCombatState(
        user_id='user_a', champion_id=ChampionId.HA_NHAN, hp=50, armor=20
    )
    p_b3 = PlayerCombatState(
        user_id='user_b', champion_id=ChampionId.TUYET_DINH, hp=50, armor=20
    )
    res_draw = settle_combat_round(
        round_no=6,
        player_a=p_a3,
        player_b=p_b3,
        input_a=RoundActionInput(user_id='user_a', grade='incorrect'),
        input_b=RoundActionInput(user_id='user_b', grade='incorrect'),
    )
    assert res_draw.match_finished is True
    assert res_draw.winner_user_id == 'draw'
    assert res_draw.finish_reason == 'draw_tiebreak'


def test_secret_round_bonus_qi() -> None:
    p_a = PlayerCombatState(user_id='user_a', champion_id=ChampionId.HA_NHAN, qi=0)
    p_b = PlayerCombatState(
        user_id='user_b', champion_id=ChampionId.TUYET_DINH, qi=0
    )

    # Secret round: Trả lời đúng nhận +1 qi thường + 1 qi bonus = 2 qi
    res = settle_combat_round(
        round_no=3,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(user_id='user_a', grade='correct'),
        input_b=RoundActionInput(user_id='user_b', grade='incorrect'),
        is_secret_round=True,
    )
    assert res.player_a_delta.qi_gained == 2
    assert res.player_a_delta.new_qi == 2
    assert res.player_b_delta.qi_gained == 0
    assert res.player_b_delta.new_qi == 0


def test_rule_version_package_exports_and_python_dart_contract() -> None:
    import app.game as game_pkg

    assert COMBAT_RULE_VERSION == 'solo-three-v0.1'
    assert game_pkg.COMBAT_RULE_VERSION == 'solo-three-v0.1'
    assert game_pkg.normalize_champion_id('han_boi_thap') == ChampionId.HAN_BOI_PHAP
    assert game_pkg.normalize_champion_id('han boi thap') == ChampionId.HAN_BOI_PHAP
    assert MAX_HP == 100
    assert MAX_ARMOR == 50
    assert MAX_QI == 3

    p_a = PlayerCombatState(user_id='u_a', champion_id=ChampionId.HAN_BOI_PHAP)
    p_b = PlayerCombatState(user_id='u_b', champion_id=ChampionId.TUYET_DINH)
    res = settle_combat_round(
        round_no=1,
        player_a=p_a,
        player_b=p_b,
        input_a=RoundActionInput(user_id='u_a', grade='correct', action=ActionType.BASIC),
        input_b=RoundActionInput(user_id='u_b', grade='incorrect', action=ActionType.BASIC),
    )
    assert res.rule_version == 'solo-three-v0.1'
    assert res.round_no == 1
    assert res.player_a_delta.action_used == ActionType.BASIC
    assert res.player_b_delta.action_used is None
    assert res.player_b_delta.new_armor == 22
