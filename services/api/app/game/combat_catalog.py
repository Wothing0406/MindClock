from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from typing import Final

COMBAT_RULE_VERSION: Final[str] = 'solo-three-v0.1'

BASE_HP: Final[int] = 100
MAX_HP: Final[int] = 100
BASE_ARMOR: Final[int] = 50
MAX_ARMOR: Final[int] = 50
MAX_WARD: Final[int] = 20
MAX_QI: Final[int] = 3

BASIC_ATTACK_DAMAGE: Final[int] = 28
BASIC_ATTACK_QI_COST: Final[int] = 0
MAX_ROUNDS: Final[int] = 6


class ChampionId(StrEnum):
    HA_NHAN = 'ha_nhan'
    TUYET_DINH = 'tuyet_dinh'
    HAN_BOI_PHAP = 'han_boi_phap'


# Ánh xạ tương thích ngược từ các ID legacy hoặc slug trong manifest
_CHAMPION_ALIAS_MAP: Final[dict[str, ChampionId]] = {
    'ha_nhan': ChampionId.HA_NHAN,
    'ha-nhan': ChampionId.HA_NHAN,
    'tuyet_dinh': ChampionId.TUYET_DINH,
    'tuyet-dinh': ChampionId.TUYET_DINH,
    'han_boi_phap': ChampionId.HAN_BOI_PHAP,
    'han-boi-phap': ChampionId.HAN_BOI_PHAP,
    'han_boi_thap': ChampionId.HAN_BOI_PHAP,  # Legacy ID trong PRD/archive
    'han-boi-thap': ChampionId.HAN_BOI_PHAP,
}


def normalize_champion_id(raw_id: str) -> ChampionId:
    normalized = raw_id.strip().lower().replace(' ', '_')
    if normalized in _CHAMPION_ALIAS_MAP:
        return _CHAMPION_ALIAS_MAP[normalized]
    raise ValueError(f'Unknown champion id or alias: {raw_id}')


class ActionType(StrEnum):
    BASIC = 'basic'
    SKILL_1 = 'skill_1'
    SKILL_2 = 'skill_2'


@dataclass(frozen=True)
class SkillSpec:
    id: str
    name_vi: str
    qi_cost: int
    damage: int
    heal_hp: int = 0
    heal_armor: int = 0
    add_ward: int = 0
    next_round_basic_penalty: int = 0
    forbid_round_6: bool = False


@dataclass(frozen=True)
class ChampionSpec:
    id: ChampionId
    name_vi: str
    role_vi: str
    passive_name_vi: str
    passive_description_vi: str
    skill_1: SkillSpec
    skill_2: SkillSpec


CHAMPION_CATALOG: Final[dict[ChampionId, ChampionSpec]] = {
    ChampionId.HA_NHAN: ChampionSpec(
        id=ChampionId.HA_NHAN,
        name_vi='Hà Nhân',
        role_vi='Bền bỉ, burst thấp',
        passive_name_vi='Kiên Định',
        passive_description_vi='2 round đúng liên tiếp hồi 8 giáp sau settle, tối đa 2 lần/trận.',
        skill_1=SkillSpec(
            id='buoc_vung',
            name_vi='Bước Vững',
            qi_cost=1,
            damage=25,
            heal_armor=6,
        ),
        skill_2=SkillSpec(
            id='tinh_tam_phan_kich',
            name_vi='Tĩnh Tâm Phản Kích',
            qi_cost=2,
            damage=32,
            heal_hp=8,
        ),
    ),
    ChampionId.TUYET_DINH: ChampionSpec(
        id=ChampionId.TUYET_DINH,
        name_vi='Tuyệt Đỉnh',
        role_vi='Sát thương, ít thủ',
        passive_name_vi='Tập Trung Đột Phá',
        passive_description_vi='2 round đúng liên tiếp buff Đánh thường kế +6 damage, tối đa 2 lần, không dồn.',
        skill_1=SkillSpec(
            id='mot_net_thanh_chieu',
            name_vi='Một Nét Thành Chiêu',
            qi_cost=1,
            damage=38,
        ),
        skill_2=SkillSpec(
            id='duong_kiem_cuoi_trang',
            name_vi='Đường Kiếm Cuối Trang',
            qi_cost=2,
            damage=46,
            next_round_basic_penalty=6,
            forbid_round_6=True,
        ),
    ),
    ChampionId.HAN_BOI_PHAP: ChampionSpec(
        id=ChampionId.HAN_BOI_PHAP,
        name_vi='Hàn Bối Pháp',
        role_vi='Tanker, kết trận chậm',
        passive_name_vi='Bích Chướng Cổ Giới',
        passive_description_vi='Giáp về 0 lần đầu tạo 12 ward round kế, một lần/trận.',
        skill_1=SkillSpec(
            id='dung_thap',
            name_vi='Dựng Tháp',
            qi_cost=1,
            damage=18,
            add_ward=14,
        ),
        skill_2=SkillSpec(
            id='tran_thap',
            name_vi='Trấn Tháp',
            qi_cost=2,
            damage=28,
            heal_armor=16,
        ),
    ),
}


def get_champion_spec(raw_id: str | ChampionId) -> ChampionSpec:
    champ_id = (
        raw_id if isinstance(raw_id, ChampionId) else normalize_champion_id(raw_id)
    )
    return CHAMPION_CATALOG[champ_id]
