/// Mô hình dữ liệu Sảnh chờ, Bảng xếp hạng kiến thức và Daily Shop mỹ thuật (`T064`).
///
/// Bất biến sản phẩm (`AGENTS.md §3`, `docs/04-game/03-rank-mua-va-kinh-te.md`):
/// - Mọi vật phẩm Daily Shop chỉ là mỹ thuật (khung, avatar linh vật, hào quang sảnh);
///   `bonusDamage == 0`, `bonusHp == 0`, `bonusArmor == 0` (tuyệt đối 0 pay-to-win).
/// - Bảng xếp hạng chỉ xếp theo độ chính xác & điểm kiến thức giao hữu, tuyệt đối không
///   hiển thị hay xếp hạng theo giờ dậy, tên trường, thời khóa biểu hay email.
library;

enum ArenaCosmeticCategory {
  frame('frame', 'Khung viền'),
  avatar('avatar', 'Avatar linh vật'),
  aura('aura', 'Hào quang sảnh');

  const ArenaCosmeticCategory(this.code, this.labelVi);
  final String code;
  final String labelVi;
}

class ArenaRankTier {
  const ArenaRankTier({
    required this.id,
    required this.nameVi,
    required this.minScore,
  });

  final String id;
  final String nameVi;
  final int minScore;
}

class ArenaCosmeticItem {
  const ArenaCosmeticItem({
    required this.id,
    required this.nameVi,
    required this.descriptionVi,
    required this.category,
    required this.priceCoins,
    required this.tierBadgeVi,
    this.previewAssetPath,
  });

  final String id;
  final String nameVi;
  final String descriptionVi;
  final ArenaCosmeticCategory category;
  final int priceCoins;
  final String tierBadgeVi;
  final String? previewAssetPath;

  /// Bảo đảm bất biến chống pay-to-win.
  int get bonusDamage => 0;
  int get bonusHp => 0;
  int get bonusArmor => 0;
}

class ArenaLeaderboardEntry {
  const ArenaLeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.gradeBand,
    required this.subjectCode,
    required this.accuracyPercent,
    required this.validMatchesCount,
    required this.friendlyScore,
    required this.rankTierId,
    this.isCurrentUser = false,
  });

  final String id;
  final String displayName;
  final String gradeBand;
  final String subjectCode;
  final int accuracyPercent;
  final int validMatchesCount;
  final int friendlyScore;
  final String rankTierId;
  final bool isCurrentUser;
}

class ArenaCosmeticCatalog {
  const ArenaCosmeticCatalog._();

  static const String defaultFrameId = 'frame_so_hoc';
  static const String defaultAvatarId = 'avatar_sunrise';
  static const String defaultAuraId = 'aura_none';

  static const List<ArenaRankTier> rankTiers = <ArenaRankTier>[
    ArenaRankTier(id: 'so_hoc', nameVi: 'Sơ Học', minScore: 0),
    ArenaRankTier(id: 'dong_hanh', nameVi: 'Đồng Hành', minScore: 120),
    ArenaRankTier(id: 'kham_pha', nameVi: 'Khám Phá', minScore: 260),
    ArenaRankTier(id: 'tinh_hoa', nameVi: 'Tinh Hoa', minScore: 450),
    ArenaRankTier(id: 'kien_trien', nameVi: 'Kiên Triển', minScore: 700),
    ArenaRankTier(id: 'minh_triet', nameVi: 'Minh Triết', minScore: 1000),
    ArenaRankTier(id: 'binh_minh', nameVi: 'Bình Minh', minScore: 1400),
  ];

  static ArenaRankTier tierForScore(int friendlyScore) {
    ArenaRankTier matched = rankTiers.first;
    for (final ArenaRankTier tier in rankTiers) {
      if (friendlyScore >= tier.minScore) {
        matched = tier;
      }
    }
    return matched;
  }

  static const List<ArenaCosmeticItem> allItems = <ArenaCosmeticItem>[
    ArenaCosmeticItem(
      id: 'frame_so_hoc',
      nameVi: 'Khung Sơ Học Mộc',
      descriptionVi: 'Khung viền mặc định cho người mới vào Võ đường.',
      category: ArenaCosmeticCategory.frame,
      priceCoins: 0,
      tierBadgeVi: 'Cơ bản',
    ),
    ArenaCosmeticItem(
      id: 'frame_kham_pha',
      nameVi: 'Khung Khám Phá Ngọc',
      descriptionVi: 'Viền xanh ngọc rạng rỡ quanh avatar và thẻ tướng ở Sảnh.',
      category: ArenaCosmeticCategory.frame,
      priceCoins: 60,
      tierBadgeVi: 'Hiếm',
    ),
    ArenaCosmeticItem(
      id: 'frame_tinh_hoa',
      nameVi: 'Khung Tinh Hoa Hoàng Kim',
      descriptionVi: 'Khung vàng ánh bình minh dành cho người bền bỉ ôn luyện.',
      category: ArenaCosmeticCategory.frame,
      priceCoins: 90,
      tierBadgeVi: 'Nổi bật',
    ),
    ArenaCosmeticItem(
      id: 'frame_binh_minh',
      nameVi: 'Khung Bình Minh Huy Hoàng',
      descriptionVi: 'Khung danh dự rạng đông mùa giao hữu, hoàn toàn mỹ thuật.',
      category: ArenaCosmeticCategory.frame,
      priceCoins: 140,
      tierBadgeVi: 'Đặc biệt',
    ),
    ArenaCosmeticItem(
      id: 'avatar_sunrise',
      nameVi: 'Linh vật Bình Minh',
      descriptionVi: 'Biểu tượng đồng hồ mặt trời sáng bừng.',
      category: ArenaCosmeticCategory.avatar,
      priceCoins: 0,
      tierBadgeVi: 'Mặc định',
      previewAssetPath: 'assets/game/ui/avatars/sunrise-avatar.webp',
    ),
    ArenaCosmeticItem(
      id: 'avatar_cu_meo',
      nameVi: 'Linh vật Cú Mèo Cổ Thư',
      descriptionVi: 'Linh vật chăm chỉ đồng hành trong các buổi giải đề.',
      category: ArenaCosmeticCategory.avatar,
      priceCoins: 50,
      tierBadgeVi: 'Phổ thông',
      previewAssetPath: 'assets/game/ui/avatars/cu-meo-avatar.webp',
    ),
    ArenaCosmeticItem(
      id: 'avatar_cao_giay',
      nameVi: 'Linh vật Cáo Giấy Tinh Anh',
      descriptionVi: 'Cáo giấy nhanh nhẹn yêu thích tốc độ tư duy.',
      category: ArenaCosmeticCategory.avatar,
      priceCoins: 70,
      tierBadgeVi: 'Hiếm',
      previewAssetPath: 'assets/game/ui/avatars/cao-giay-avatar.webp',
    ),
    ArenaCosmeticItem(
      id: 'avatar_ca_chep',
      nameVi: 'Linh vật Cá Chép Vượt Vũ Môn',
      descriptionVi: 'Biểu tượng kiên trì ôn tập từng chuyên đề khó.',
      category: ArenaCosmeticCategory.avatar,
      priceCoins: 80,
      tierBadgeVi: 'Nổi bật',
      previewAssetPath: 'assets/game/ui/avatars/ca-chep-avatar.webp',
    ),
    ArenaCosmeticItem(
      id: 'avatar_rua_xanh',
      nameVi: 'Linh vật Rùa Xanh Vững Chãi',
      descriptionVi: 'Chậm mà chắc, tích lũy kiến thức mỗi ngày.',
      category: ArenaCosmeticCategory.avatar,
      priceCoins: 55,
      tierBadgeVi: 'Phổ thông',
      previewAssetPath: 'assets/game/ui/avatars/rua-xanh-avatar.webp',
    ),
    ArenaCosmeticItem(
      id: 'avatar_may_nho',
      nameVi: 'Linh vật Mây Nhỏ Nhẹ Nhàng',
      descriptionVi: 'Tâm thế thư thái trước mỗi bài thi.',
      category: ArenaCosmeticCategory.avatar,
      priceCoins: 65,
      tierBadgeVi: 'Hiếm',
      previewAssetPath: 'assets/game/ui/avatars/may-nho-avatar.webp',
    ),
    ArenaCosmeticItem(
      id: 'aura_bamboo',
      nameVi: 'Hào quang Lá Trúc Thanh Tịnh',
      descriptionVi: 'Hiệu ứng nền xanh ngọc cho bệ đứng tướng ở Sảnh chờ.',
      category: ArenaCosmeticCategory.aura,
      priceCoins: 75,
      tierBadgeVi: 'Hiếm',
    ),
    ArenaCosmeticItem(
      id: 'aura_sunrise_halo',
      nameVi: 'Hào quang Ánh Nắng Sớm',
      descriptionVi: 'Vòng sáng ấm áp nâng đỡ tướng yêu thích ở Sảnh.',
      category: ArenaCosmeticCategory.aura,
      priceCoins: 110,
      tierBadgeVi: 'Nổi bật',
    ),
  ];

  static ArenaCosmeticItem? byId(String id) {
    for (final ArenaCosmeticItem item in allItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Trả về 4 vật phẩm Daily Shop luân phiên theo ngày `YYYY-MM-DD` (chỉ có giá > 0).
  static List<ArenaCosmeticItem> dailyOfferingsForDate(DateTime date) {
    final List<ArenaCosmeticItem> paid =
        allItems.where((ArenaCosmeticItem i) => i.priceCoins > 0).toList();
    if (paid.length <= 4) return paid;

    final int seed = date.year * 10000 + date.month * 100 + date.day;
    final int start = seed % paid.length;
    final List<ArenaCosmeticItem> selected = <ArenaCosmeticItem>[];
    for (int i = 0; i < 4; i++) {
      selected.add(paid[(start + i * 2) % paid.length]);
    }
    return selected;
  }

  static String formatDateKey(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class ArenaWalletState {
  const ArenaWalletState({
    required this.mindCoins,
    required this.ownedItemIds,
    required this.equippedFrameId,
    required this.equippedAvatarId,
    required this.equippedAuraId,
    required this.leaderboardOptIn,
    required this.localFriendlyScore,
    required this.localMatchesCount,
    required this.localCorrectRounds,
    required this.localTotalRounds,
    required this.rewardedMatchKeys,
  });

  factory ArenaWalletState.initial() => const ArenaWalletState(
        mindCoins: 120,
        ownedItemIds: <String>{
          ArenaCosmeticCatalog.defaultFrameId,
          ArenaCosmeticCatalog.defaultAvatarId,
        },
        equippedFrameId: ArenaCosmeticCatalog.defaultFrameId,
        equippedAvatarId: ArenaCosmeticCatalog.defaultAvatarId,
        equippedAuraId: ArenaCosmeticCatalog.defaultAuraId,
        leaderboardOptIn: true,
        localFriendlyScore: 140,
        localMatchesCount: 0,
        localCorrectRounds: 0,
        localTotalRounds: 0,
        rewardedMatchKeys: <String>{},
      );

  factory ArenaWalletState.fromJson(Map<String, dynamic> json) {
    final Set<String> owned = (json['owned_item_ids'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => e.toString())
        .toSet()
      ..add(ArenaCosmeticCatalog.defaultFrameId)
      ..add(ArenaCosmeticCatalog.defaultAvatarId);

    final Set<String> rewarded =
        (json['rewarded_match_keys'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toSet();

    return ArenaWalletState(
      mindCoins: (json['mind_coins'] as int? ?? 120).clamp(0, 999999),
      ownedItemIds: owned,
      equippedFrameId:
          json['equipped_frame_id'] as String? ?? ArenaCosmeticCatalog.defaultFrameId,
      equippedAvatarId:
          json['equipped_avatar_id'] as String? ?? ArenaCosmeticCatalog.defaultAvatarId,
      equippedAuraId:
          json['equipped_aura_id'] as String? ?? ArenaCosmeticCatalog.defaultAuraId,
      leaderboardOptIn: json['leaderboard_opt_in'] as bool? ?? true,
      localFriendlyScore: json['local_friendly_score'] as int? ?? 140,
      localMatchesCount: json['local_matches_count'] as int? ?? 0,
      localCorrectRounds: json['local_correct_rounds'] as int? ?? 0,
      localTotalRounds: json['local_total_rounds'] as int? ?? 0,
      rewardedMatchKeys: rewarded,
    );
  }

  final int mindCoins;
  final Set<String> ownedItemIds;
  final String equippedFrameId;
  final String equippedAvatarId;
  final String equippedAuraId;
  final bool leaderboardOptIn;
  final int localFriendlyScore;
  final int localMatchesCount;
  final int localCorrectRounds;
  final int localTotalRounds;
  final Set<String> rewardedMatchKeys;

  int get localAccuracyPercent {
    if (localTotalRounds <= 0) return 0;
    return ((localCorrectRounds * 100) / localTotalRounds).round().clamp(0, 100);
  }

  ArenaWalletState copyWith({
    int? mindCoins,
    Set<String>? ownedItemIds,
    String? equippedFrameId,
    String? equippedAvatarId,
    String? equippedAuraId,
    bool? leaderboardOptIn,
    int? localFriendlyScore,
    int? localMatchesCount,
    int? localCorrectRounds,
    int? localTotalRounds,
    Set<String>? rewardedMatchKeys,
  }) {
    return ArenaWalletState(
      mindCoins: mindCoins ?? this.mindCoins,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      equippedFrameId: equippedFrameId ?? this.equippedFrameId,
      equippedAvatarId: equippedAvatarId ?? this.equippedAvatarId,
      equippedAuraId: equippedAuraId ?? this.equippedAuraId,
      leaderboardOptIn: leaderboardOptIn ?? this.leaderboardOptIn,
      localFriendlyScore: localFriendlyScore ?? this.localFriendlyScore,
      localMatchesCount: localMatchesCount ?? this.localMatchesCount,
      localCorrectRounds: localCorrectRounds ?? this.localCorrectRounds,
      localTotalRounds: localTotalRounds ?? this.localTotalRounds,
      rewardedMatchKeys: rewardedMatchKeys ?? this.rewardedMatchKeys,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mind_coins': mindCoins,
        'owned_item_ids': ownedItemIds.toList(),
        'equipped_frame_id': equippedFrameId,
        'equipped_avatar_id': equippedAvatarId,
        'equipped_aura_id': equippedAuraId,
        'leaderboard_opt_in': leaderboardOptIn,
        'local_friendly_score': localFriendlyScore,
        'local_matches_count': localMatchesCount,
        'local_correct_rounds': localCorrectRounds,
        'local_total_rounds': localTotalRounds,
        'rewarded_match_keys': rewardedMatchKeys.toList(),
      };
}
