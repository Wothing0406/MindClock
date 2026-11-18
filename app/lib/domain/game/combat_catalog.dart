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
    required this.iconAssetPath,
    required this.descriptionVi,
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
  final String iconAssetPath;
  final String descriptionVi;
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
    required this.loreVi,
    required this.portraitAssetPath,
    required this.passiveNameVi,
    required this.passiveDescriptionVi,
    required this.basicAttackDescriptionVi,
    required this.skill1,
    required this.skill2,
  });

  final ChampionId id;
  final String nameVi;
  final String roleVi;
  final String loreVi;
  final String portraitAssetPath;
  final String passiveNameVi;
  final String passiveDescriptionVi;
  final String basicAttackDescriptionVi;
  final SkillSpec skill1;
  final SkillSpec skill2;

  String assetForAction(CombatActionType action) {
    switch (action) {
      case CombatActionType.basic:
        return CombatCatalog.basicAttackAssetPath;
      case CombatActionType.skill1:
        return skill1.iconAssetPath;
      case CombatActionType.skill2:
        return skill2.iconAssetPath;
    }
  }
}

class CombatCatalog {
  const CombatCatalog._();

  static const String mapCourtyardAssetPath = 'assets/arena/map_courtyard.png';
  static const String basicAttackAssetPath = 'assets/arena/skill_basic.png';

  static const Map<ChampionId, ChampionSpec> champions =
      <ChampionId, ChampionSpec>{
    ChampionId.haNhan: ChampionSpec(
      id: ChampionId.haNhan,
      nameVi: 'Hà Nhân',
      roleVi: 'Bền bỉ, burst thấp',
      loreVi:
          'Môn sinh giữ nhịp học đều đặn mỗi sáng. Mạnh ở khả năng hồi giáp, hồi phục ổn định qua từng vòng giải đúng liên tiếp.',
      portraitAssetPath: 'assets/arena/champ_ha_nhan.png',
      passiveNameVi: 'Kiên Định',
      passiveDescriptionVi:
          '2 round đúng liên tiếp hồi 8 giáp sau settle, tối đa 2 lần/trận.',
      basicAttackDescriptionVi:
          'Đòn tiêu chuẩn chắc tay 28 sát thương (0 Qi). Thích hợp giữ nhịp tích Qi để bật chiêu hồi phục.',
      skill1: SkillSpec(
        id: 'buoc_vung',
        nameVi: 'Bước Vững',
        qiCost: 1,
        damage: 25,
        healArmor: 6,
        iconAssetPath: 'assets/arena/skill_ha_nhan_1.png',
        descriptionVi:
            'Tung đòn 25 sát thương đồng thời củng cố thêm 6 Giáp giúp trụ vững trước đối thủ sát thương cao.',
      ),
      skill2: SkillSpec(
        id: 'tinh_tam_phan_kich',
        nameVi: 'Tĩnh Tâm Phản Kích',
        qiCost: 2,
        damage: 32,
        healHp: 8,
        iconAssetPath: 'assets/arena/skill_ha_nhan_2.png',
        descriptionVi:
            'Phản công 32 sát thương và hồi lại 8 HP trực tiếp sau khi chịu đòn trong pha settle.',
      ),
    ),
    ChampionId.tuyetDinh: ChampionSpec(
      id: ChampionId.tuyetDinh,
      nameVi: 'Tuyệt Đỉnh',
      roleVi: 'Sát thương, ít thủ',
      loreVi:
          'Kiếm sĩ thư pháp chú trọng tốc độ tư duy và độ sắc bén. Dứt điểm nhanh khi duy trì được chuỗi trả lời đúng chính xác.',
      portraitAssetPath: 'assets/arena/champ_tuyet_dinh.png',
      passiveNameVi: 'Tập Trung Đột Phá',
      passiveDescriptionVi:
          '2 round đúng liên tiếp buff Đánh thường kế +6 damage, tối đa 2 lần, không dồn.',
      basicAttackDescriptionVi:
          'Gây 28 sát thương cơ bản (tăng thành 34 ST nếu vừa kích hoạt nội tại Tập Trung Đột Phá).',
      skill1: SkillSpec(
        id: 'mot_net_thanh_chieu',
        nameVi: 'Một Nét Thành Chiêu',
        qiCost: 1,
        damage: 38,
        iconAssetPath: 'assets/arena/skill_tuyet_dinh_1.png',
        descriptionVi:
            'Chém một đường bút dứt khoát gây 38 sát thương chỉ với 1 Qi, áp lực lớn từ sớm.',
      ),
      skill2: SkillSpec(
        id: 'duong_kiem_cuoi_trang',
        nameVi: 'Đường Kiếm Cuối Trang',
        qiCost: 2,
        damage: 46,
        nextRoundBasicPenalty: 6,
        forbidRound6: true,
        iconAssetPath: 'assets/arena/skill_tuyet_dinh_2.png',
        descriptionVi:
            'Đòn tất sát 46 sát thương. Nhược điểm: Đánh thường vòng sau giảm 6 ST và bị khóa ở round 6.',
      ),
    ),
    ChampionId.hanBoiPhap: ChampionSpec(
      id: ChampionId.hanBoiPhap,
      nameVi: 'Hàn Bối Pháp',
      roleVi: 'Tanker, kết trận chậm',
      loreVi:
          'Hộ vệ giữ cổ thư với lớp Chắn và Giáp dày. Chịu đòn tốt ở nửa đầu trận rồi áp đảo bằng lượng phòng ngự vượt trội về cuối.',
      portraitAssetPath: 'assets/arena/champ_han_boi_phap.png',
      passiveNameVi: 'Bích Chướng Cổ Giới',
      passiveDescriptionVi:
          'Giáp về 0 lần đầu tạo 12 ward round kế, một lần/trận.',
      basicAttackDescriptionVi:
          'Đánh thường 28 sát thương (0 Qi), kết hợp tích Qi để dựng kết giới Chắn và hồi Giáp.',
      skill1: SkillSpec(
        id: 'dung_thap',
        nameVi: 'Dựng Tháp',
        qiCost: 1,
        damage: 18,
        addWard: 14,
        iconAssetPath: 'assets/arena/skill_han_boi_phap_1.png',
        descriptionVi:
            'Gây 18 sát thương và dựng lớp Chắn +14 giảm trực tiếp sát thương đòn đánh tiếp theo của đối phương.',
      ),
      skill2: SkillSpec(
        id: 'tran_thap',
        nameVi: 'Trấn Tháp',
        qiCost: 2,
        damage: 28,
        healArmor: 16,
        iconAssetPath: 'assets/arena/skill_han_boi_phap_2.png',
        descriptionVi:
            'Giáng cổ tháp gây 28 sát thương và hồi mạnh +16 Giáp để kéo dài lợi thế về cuối trận.',
      ),
    ),
  };

  static ChampionSpec getSpec(ChampionId id) => champions[id]!;

  static ChampionSpec getSpecByCode(String code) =>
      getSpec(ChampionId.fromCode(code));
}
