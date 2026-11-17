from __future__ import annotations

from dataclasses import dataclass, field
from typing import Final

from app.game.combat_catalog import (
    ActionType,
    BASIC_ATTACK_DAMAGE,
    ChampionId,
    COMBAT_RULE_VERSION,
    get_champion_spec,
    MAX_ARMOR,
    MAX_HP,
    MAX_QI,
    MAX_ROUNDS,
    MAX_WARD,
)


@dataclass
class PlayerCombatState:
    user_id: str
    champion_id: ChampionId
    hp: int = MAX_HP
    armor: int = MAX_ARMOR
    ward: int = 0
    qi: int = 0
    consecutive_correct: int = 0
    skill_1_used: bool = False
    skill_2_used: bool = False
    passive_trigger_count: int = 0
    passive_pending_ward: int = 0
    buff_next_basic_bonus: int = 0
    penalty_next_basic: int = 0

    @property
    def is_alive(self) -> bool:
        return self.hp > 0


@dataclass(frozen=True)
class RoundActionInput:
    user_id: str
    grade: str  # 'correct', 'incorrect', 'uncertain', 'timeout'
    action: ActionType = ActionType.BASIC


@dataclass(frozen=True)
class PlayerRoundDelta:
    user_id: str
    action_used: ActionType | None
    raw_damage_dealt: int
    damage_taken: int
    ward_absorbed: int
    armor_damage_taken: int
    hp_damage_taken: int
    hp_healed: int
    armor_healed: int
    ward_added_in_round: int
    qi_spent: int
    qi_gained: int
    passive_triggered: bool
    passive_effect_vi: str | None
    new_hp: int
    new_armor: int
    new_ward: int
    new_qi: int
    is_alive: bool


@dataclass(frozen=True)
class RoundSettleResult:
    rule_version: str
    round_no: int
    is_secret_round: bool
    player_a_delta: PlayerRoundDelta
    player_b_delta: PlayerRoundDelta
    match_finished: bool
    winner_user_id: str | None  # user_id hoặc 'draw' nếu hòa, None nếu trận chưa xong
    finish_reason: str | None  # 'ko', 'double_ko', 'hp_tiebreak', 'armor_tiebreak', 'draw_tiebreak', None


def settle_combat_round(
    *,
    round_no: int,
    player_a: PlayerCombatState,
    player_b: PlayerCombatState,
    input_a: RoundActionInput,
    input_b: RoundActionInput,
    is_secret_round: bool = False,
) -> RoundSettleResult:
    """Xử lý đồng thời một round combat theo luật Server-Authoritative `solo-three-v0.1`."""
    spec_a = get_champion_spec(player_a.champion_id)
    spec_b = get_champion_spec(player_b.champion_id)

    # 1. Khởi tạo ward đầu round từ passive round trước (nếu có)
    ward_start_a = min(MAX_WARD, player_a.passive_pending_ward)
    ward_start_b = min(MAX_WARD, player_b.passive_pending_ward)
    player_a.passive_pending_ward = 0
    player_b.passive_pending_ward = 0

    # 2. Xác thực và chốt hành động của từng bên
    action_a, qi_spent_a = _resolve_player_action(
        state=player_a,
        action_req=input_a.action,
        grade=input_a.grade,
        round_no=round_no,
    )
    action_b, qi_spent_b = _resolve_player_action(
        state=player_b,
        action_req=input_b.action,
        grade=input_b.grade,
        round_no=round_no,
    )

    # 3. Kích hoạt buff chắn trong round (trước khi nhận sát thương)
    ward_added_a = 0
    ward_added_b = 0
    if action_a == ActionType.SKILL_1 and spec_a.skill_1.add_ward > 0:
        ward_added_a = spec_a.skill_1.add_ward
    if action_b == ActionType.SKILL_1 and spec_b.skill_1.add_ward > 0:
        ward_added_b = spec_b.skill_1.add_ward

    effective_ward_a = min(MAX_WARD, ward_start_a + ward_added_a)
    effective_ward_b = min(MAX_WARD, ward_start_b + ward_added_b)

    # 4. Tính sát thương thô gây ra bởi mỗi bên
    raw_dmg_a = _compute_raw_damage(
        state=player_a,
        action=action_a,
    )
    raw_dmg_b = _compute_raw_damage(
        state=player_b,
        action=action_b,
    )

    # 5. Phân bổ sát thương đồng thời: ward -> armor -> HP
    armor_before_a = player_a.armor
    armor_before_b = player_b.armor

    dmg_taken_a, ward_abs_a, armor_dmg_a, hp_dmg_a = _absorb_damage(
        damage=raw_dmg_b,
        ward=effective_ward_a,
        armor=player_a.armor,
        hp=player_a.hp,
    )
    dmg_taken_b, ward_abs_b, armor_dmg_b, hp_dmg_b = _absorb_damage(
        damage=raw_dmg_a,
        ward=effective_ward_b,
        armor=player_b.armor,
        hp=player_b.hp,
    )

    hp_after_dmg_a = player_a.hp - hp_dmg_a
    hp_after_dmg_b = player_b.hp - hp_dmg_b
    armor_after_dmg_a = player_a.armor - armor_dmg_a
    armor_after_dmg_b = player_b.armor - armor_dmg_b

    # 6. Hồi phục máu và giáp SAU KHI chịu đòn (HP <= 0 không được hồi cứu)
    hp_healed_a = 0
    armor_healed_a = 0
    if hp_after_dmg_a > 0:
        if action_a == ActionType.SKILL_1 and spec_a.skill_1.heal_armor > 0:
            armor_healed_a = spec_a.skill_1.heal_armor
        elif action_a == ActionType.SKILL_2:
            if spec_a.skill_2.heal_hp > 0:
                hp_healed_a = spec_a.skill_2.heal_hp
            if spec_a.skill_2.heal_armor > 0:
                armor_healed_a = spec_a.skill_2.heal_armor

    hp_healed_b = 0
    armor_healed_b = 0
    if hp_after_dmg_b > 0:
        if action_b == ActionType.SKILL_1 and spec_b.skill_1.heal_armor > 0:
            armor_healed_b = spec_b.skill_1.heal_armor
        elif action_b == ActionType.SKILL_2:
            if spec_b.skill_2.heal_hp > 0:
                hp_healed_b = spec_b.skill_2.heal_hp
            if spec_b.skill_2.heal_armor > 0:
                armor_healed_b = spec_b.skill_2.heal_armor

    final_hp_a = min(MAX_HP, hp_after_dmg_a + hp_healed_a)
    final_hp_b = min(MAX_HP, hp_after_dmg_b + hp_healed_b)
    final_armor_a = min(MAX_ARMOR, armor_after_dmg_a + armor_healed_a)
    final_armor_b = min(MAX_ARMOR, armor_after_dmg_b + armor_healed_b)

    # 7. Xử lý nội tại và hiệu ứng vòng kế
    passive_trig_a, passive_desc_a = _process_passive(
        state=player_a,
        grade=input_a.grade,
        armor_before=armor_before_a,
        armor_after=final_armor_a,
        is_alive=(final_hp_a > 0),
    )
    if passive_trig_a and player_a.champion_id == ChampionId.HA_NHAN and final_hp_a > 0:
        final_armor_a = min(MAX_ARMOR, final_armor_a + 8)

    passive_trig_b, passive_desc_b = _process_passive(
        state=player_b,
        grade=input_b.grade,
        armor_before=armor_before_b,
        armor_after=final_armor_b,
        is_alive=(final_hp_b > 0),
    )
    if passive_trig_b and player_b.champion_id == ChampionId.HA_NHAN and final_hp_b > 0:
        final_armor_b = min(MAX_ARMOR, final_armor_b + 8)

    # Tuyệt Đỉnh Skill 2 gây giảm sát thương đánh thường round kế
    if action_a == ActionType.SKILL_2 and spec_a.skill_2.next_round_basic_penalty > 0:
        player_a.penalty_next_basic = spec_a.skill_2.next_round_basic_penalty
    else:
        player_a.penalty_next_basic = 0

    if action_b == ActionType.SKILL_2 and spec_b.skill_2.next_round_basic_penalty > 0:
        player_b.penalty_next_basic = spec_b.skill_2.next_round_basic_penalty
    else:
        player_b.penalty_next_basic = 0

    # Tiêu thụ / reset buff đánh thường Tuyệt Đỉnh nếu vừa đánh thường
    if action_a == ActionType.BASIC:
        player_a.buff_next_basic_bonus = 0
    if action_b == ActionType.BASIC:
        player_b.buff_next_basic_bonus = 0

    # 8. Cập nhật Qi (Đúng -> +1 qi sau settle, secret round -> +1 bonus)
    qi_gained_a = 0
    if input_a.grade == 'correct':
        qi_gained_a += 1
        if is_secret_round:
            qi_gained_a += 1

    qi_gained_b = 0
    if input_b.grade == 'correct':
        qi_gained_b += 1
        if is_secret_round:
            qi_gained_b += 1

    final_qi_a = min(MAX_QI, max(0, player_a.qi - qi_spent_a) + qi_gained_a)
    final_qi_b = min(MAX_QI, max(0, player_b.qi - qi_spent_b) + qi_gained_b)

    # 9. Ghi đè trạng thái mới lên State
    player_a.hp = final_hp_a
    player_a.armor = final_armor_a
    player_a.ward = 0  # Ward chỉ tồn tại trong round
    player_a.qi = final_qi_a
    if action_a == ActionType.SKILL_1:
        player_a.skill_1_used = True
    elif action_a == ActionType.SKILL_2:
        player_a.skill_2_used = True

    player_b.hp = final_hp_b
    player_b.armor = final_armor_b
    player_b.ward = 0
    player_b.qi = final_qi_b
    if action_b == ActionType.SKILL_1:
        player_b.skill_1_used = True
    elif action_b == ActionType.SKILL_2:
        player_b.skill_2_used = True

    delta_a = PlayerRoundDelta(
        user_id=player_a.user_id,
        action_used=action_a,
        raw_damage_dealt=raw_dmg_a,
        damage_taken=dmg_taken_a,
        ward_absorbed=ward_abs_a,
        armor_damage_taken=armor_dmg_a,
        hp_damage_taken=hp_dmg_a,
        hp_healed=hp_healed_a,
        armor_healed=armor_healed_a,
        ward_added_in_round=ward_added_a,
        qi_spent=qi_spent_a,
        qi_gained=qi_gained_a,
        passive_triggered=passive_trig_a,
        passive_effect_vi=passive_desc_a,
        new_hp=player_a.hp,
        new_armor=player_a.armor,
        new_ward=player_a.ward,
        new_qi=player_a.qi,
        is_alive=player_a.is_alive,
    )

    delta_b = PlayerRoundDelta(
        user_id=player_b.user_id,
        action_used=action_b,
        raw_damage_dealt=raw_dmg_b,
        damage_taken=dmg_taken_b,
        ward_absorbed=ward_abs_b,
        armor_damage_taken=armor_dmg_b,
        hp_damage_taken=hp_dmg_b,
        hp_healed=hp_healed_b,
        armor_healed=armor_healed_b,
        ward_added_in_round=ward_added_b,
        qi_spent=qi_spent_b,
        qi_gained=qi_gained_b,
        passive_triggered=passive_trig_b,
        passive_effect_vi=passive_desc_b,
        new_hp=player_b.hp,
        new_armor=player_b.armor,
        new_ward=player_b.ward,
        new_qi=player_b.qi,
        is_alive=player_b.is_alive,
    )

    # 10. Phân định thắng/thua hoặc kết thúc trận
    finished, winner_id, finish_reason = _evaluate_match_finish(
        round_no=round_no,
        state_a=player_a,
        state_b=player_b,
    )

    return RoundSettleResult(
        rule_version=COMBAT_RULE_VERSION,
        round_no=round_no,
        is_secret_round=is_secret_round,
        player_a_delta=delta_a,
        player_b_delta=delta_b,
        match_finished=finished,
        winner_user_id=winner_id,
        finish_reason=finish_reason,
    )


def _resolve_player_action(
    *,
    state: PlayerCombatState,
    action_req: ActionType,
    grade: str,
    round_no: int,
) -> tuple[ActionType | None, int]:
    """Kiểm tra tính hợp lệ của action dựa trên grade bài làm, qi hiện tại và lượt sử dụng."""
    if grade != 'correct':
        return None, 0

    spec = get_champion_spec(state.champion_id)
    if action_req == ActionType.SKILL_1:
        if not state.skill_1_used and state.qi >= spec.skill_1.qi_cost:
            return ActionType.SKILL_1, spec.skill_1.qi_cost
        # Không đủ qi hoặc đã dùng -> rơi về Đánh thường
        return ActionType.BASIC, 0

    if action_req == ActionType.SKILL_2:
        if (
            not state.skill_2_used
            and state.qi >= spec.skill_2.qi_cost
            and not (spec.skill_2.forbid_round_6 and round_no >= MAX_ROUNDS)
        ):
            return ActionType.SKILL_2, spec.skill_2.qi_cost
        return ActionType.BASIC, 0

    return ActionType.BASIC, 0


def _compute_raw_damage(
    *,
    state: PlayerCombatState,
    action: ActionType | None,
) -> int:
    if action is None:
        return 0

    spec = get_champion_spec(state.champion_id)
    if action == ActionType.BASIC:
        dmg = (
            BASIC_ATTACK_DAMAGE
            + state.buff_next_basic_bonus
            - state.penalty_next_basic
        )
        return max(0, dmg)
    if action == ActionType.SKILL_1:
        return spec.skill_1.damage
    if action == ActionType.SKILL_2:
        return spec.skill_2.damage

    return 0


def _absorb_damage(
    *,
    damage: int,
    ward: int,
    armor: int,
    hp: int,
) -> tuple[int, int, int, int]:
    """Hấp thụ sát thương theo thứ tự ward -> armor -> HP."""
    ward_abs = min(ward, damage)
    rem_after_ward = damage - ward_abs

    armor_dmg = min(armor, rem_after_ward)
    rem_after_armor = rem_after_ward - armor_dmg

    hp_dmg = min(hp, rem_after_armor)
    total_taken = ward_abs + armor_dmg + hp_dmg

    return total_taken, ward_abs, armor_dmg, hp_dmg


def _process_passive(
    *,
    state: PlayerCombatState,
    grade: str,
    armor_before: int,
    armor_after: int,
    is_alive: bool,
) -> tuple[bool, str | None]:
    """Xử lý nội tại nhân vật sau khi tính toán sát thương."""
    if state.champion_id == ChampionId.HA_NHAN:
        if grade == 'correct':
            state.consecutive_correct += 1
            if state.consecutive_correct == 2 and state.passive_trigger_count < 2:
                state.passive_trigger_count += 1
                state.consecutive_correct = 0
                return (
                    True,
                    'Kiên Định: 2 round đúng liên tiếp -> Hồi 8 giáp sau settle.',
                )
        else:
            state.consecutive_correct = 0
        return False, None

    if state.champion_id == ChampionId.TUYET_DINH:
        if grade == 'correct':
            state.consecutive_correct += 1
            if state.consecutive_correct == 2 and state.passive_trigger_count < 2:
                state.passive_trigger_count += 1
                state.consecutive_correct = 0
                state.buff_next_basic_bonus = 6
                return (
                    True,
                    'Tập Trung Đột Phá: 2 round đúng liên tiếp -> Đánh thường kế +6 sát thương.',
                )
        else:
            state.consecutive_correct = 0
        return False, None

    if state.champion_id == ChampionId.HAN_BOI_PHAP:
        if (
            armor_before > 0
            and armor_after == 0
            and state.passive_trigger_count == 0
            and is_alive
        ):
            state.passive_trigger_count += 1
            state.passive_pending_ward = 12
            return (
                True,
                'Bích Chướng Cổ Giới: Giáp về 0 lần đầu -> Tạo 12 ward cho round kế.',
            )
        return False, None

    return False, None


def _evaluate_match_finish(
    *,
    round_no: int,
    state_a: PlayerCombatState,
    state_b: PlayerCombatState,
) -> tuple[bool, str | None, str | None]:
    """Đánh giá điều kiện kết thúc trận đấu."""
    a_dead = state_a.hp <= 0
    b_dead = state_b.hp <= 0

    if a_dead and b_dead:
        return True, 'draw', 'double_ko'
    if a_dead:
        return True, state_b.user_id, 'ko'
    if b_dead:
        return True, state_a.user_id, 'ko'

    if round_no >= MAX_ROUNDS:
        if state_a.hp > state_b.hp:
            return True, state_a.user_id, 'hp_tiebreak'
        if state_b.hp > state_a.hp:
            return True, state_b.user_id, 'hp_tiebreak'
        # HP bằng nhau -> so sánh giáp
        if state_a.armor > state_b.armor:
            return True, state_a.user_id, 'armor_tiebreak'
        if state_b.armor > state_a.armor:
            return True, state_b.user_id, 'armor_tiebreak'
        # Cả HP và giáp đều bằng nhau -> Hòa
        return True, 'draw', 'draw_tiebreak'

    return False, None, None
