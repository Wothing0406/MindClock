const String combatRuleVersion = 'solo-three-v0.1';

const int baseHp = 100;
const int maxHp = 100;
const int baseArmor = 50;
const int maxArmor = 50;
const int maxWard = 20;
const int maxQi = 3;

const int basicAttackDamage = 28;
const int basicAttackQiCost = 0;
const int maxCombatRounds = 6;

enum ChampionId {
  haNhan('ha_nhan'),
  tuyetDinh('tuyet_dinh'),
  hanBoiPhap('han_boi_phap');

  const ChampionId(this.code);
  final String code;

  static ChampionId fromCode(String raw) {
    final String norm =
        raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (norm) {
      case 'ha_nhan':
        return ChampionId.haNhan;
      case 'tuyet_dinh':
        return ChampionId.tuyetDinh;
      case 'han_boi_phap':
      case 'han_boi_thap': // Hỗ trợ định danh legacy từ PRD
        return ChampionId.hanBoiPhap;
      default:
        throw ArgumentError('Mã tướng không hợp lệ: $raw');
    }
  }
}

enum CombatActionType {
  basic('basic'),
  skill1('skill_1'),
  skill2('skill_2');

  const CombatActionType(this.code);
  final String code;

  static CombatActionType fromCode(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'skill_1':
      case 'skill1':
        return CombatActionType.skill1;
      case 'skill_2':
      case 'skill2':
        return CombatActionType.skill2;
      case 'basic':
      default:
        return CombatActionType.basic;
    }
  }
}

class SkillSpec {
  const SkillSpec({
    required this.id,
    required this.nameVi,
    required this.qiCost,
    required this.damage,
    this.healHp = 0,
    this.healArmor = 0,
    this.addWard = 0,
    this.nextRoundBasicPenalty = 0,
    this.forbidRound6 = false,
  });

  final String id;
  final String nameVi;
  final int qiCost;
  final int damage;
  final int healHp;
  final int healArmor;
  final int addWard;
  final int nextRoundBasicPenalty;
  final bool forbidRound6;
}

class ChampionSpec {
  const ChampionSpec({
    required this.id,
    required this.nameVi,
    required this.roleVi,
    required this.passiveNameVi,
    required this.passiveDescriptionVi,
    required this.skill1,
    required this.skill2,
  });

  final ChampionId id;
  final String nameVi;
  final String roleVi;
  final String passiveNameVi;
  final String passiveDescriptionVi;
  final SkillSpec skill1;
  final SkillSpec skill2;
}

class CombatCatalog {
  const CombatCatalog._();

  static const Map<ChampionId, ChampionSpec> champions =
      <ChampionId, ChampionSpec>{
    ChampionId.haNhan: ChampionSpec(
      id: ChampionId.haNhan,
      nameVi: 'Hà Nhân',
      roleVi: 'Bền bỉ, burst thấp',
      passiveNameVi: 'Kiên Định',
      passiveDescriptionVi:
          '2 round đúng liên tiếp hồi 8 giáp sau settle, tối đa 2 lần/trận.',
      skill1: SkillSpec(
        id: 'buoc_vung',
        nameVi: 'Bước Vững',
        qiCost: 1,
        damage: 25,
        healArmor: 6,
      ),
      skill2: SkillSpec(
        id: 'tinh_tam_phan_kich',
        nameVi: 'Tĩnh Tâm Phản Kích',
        qiCost: 2,
        damage: 32,
        healHp: 8,
      ),
    ),
    ChampionId.tuyetDinh: ChampionSpec(
      id: ChampionId.tuyetDinh,
      nameVi: 'Tuyệt Đỉnh',
      roleVi: 'Sát thương, ít thủ',
      passiveNameVi: 'Tập Trung Đột Phá',
      passiveDescriptionVi:
          '2 round đúng liên tiếp buff Đánh thường kế +6 damage, tối đa 2 lần, không dồn.',
      skill1: SkillSpec(
        id: 'mot_net_thanh_chieu',
        nameVi: 'Một Nét Thành Chiêu',
        qiCost: 1,
        damage: 38,
      ),
      skill2: SkillSpec(
        id: 'duong_kiem_cuoi_trang',
        nameVi: 'Đường Kiếm Cuối Trang',
        qiCost: 2,
        damage: 46,
        nextRoundBasicPenalty: 6,
        forbidRound6: true,
      ),
    ),
    ChampionId.hanBoiPhap: ChampionSpec(
      id: ChampionId.hanBoiPhap,
      nameVi: 'Hàn Bối Pháp',
      roleVi: 'Tanker, kết trận chậm',
      passiveNameVi: 'Bích Chướng Cổ Giới',
      passiveDescriptionVi:
          'Giáp về 0 lần đầu tạo 12 ward round kế, một lần/trận.',
      skill1: SkillSpec(
        id: 'dung_thap',
        nameVi: 'Dựng Tháp',
        qiCost: 1,
        damage: 18,
        addWard: 14,
      ),
      skill2: SkillSpec(
        id: 'tran_thap',
        nameVi: 'Trấn Tháp',
        qiCost: 2,
        damage: 28,
        healArmor: 16,
      ),
    ),
  };

  static ChampionSpec getSpec(ChampionId id) => champions[id]!;

  static ChampionSpec getSpecByCode(String code) =>
      getSpec(ChampionId.fromCode(code));
}
