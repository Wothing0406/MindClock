import 'package:flutter/widgets.dart';

import '../../../../data/repositories/arena_cosmetic_store.dart';
import '../../../../domain/game/arena_lobby_models.dart';
import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import 'arena_sprite_stage.dart';

/// Khung viền mỹ thuật theo `equippedFrameId` (thuần `MindClockTheme`, 0 hex thô).
Color cosmeticFrameBorderColor(MindClockTheme mc, String frameId) {
  return switch (frameId) {
    'frame_kham_pha' => mc.primary,
    'frame_tinh_hoa' => mc.sunrise,
    'frame_binh_minh' => mc.error,
    _ => mc.outline,
  };
}

double cosmeticFrameBorderWidth(String frameId) {
  return switch (frameId) {
    'frame_binh_minh' => 3.0,
    'frame_tinh_hoa' || 'frame_kham_pha' => 2.5,
    _ => 1.5,
  };
}

/// Banner hồ sơ đấu trường + ví MindCoin + khung/avatar đang trang bị ở Sảnh chờ (`T064`).
class ArenaLobbyProfileBanner extends StatelessWidget {
  const ArenaLobbyProfileBanner({
    super.key,
    required this.profile,
    required this.cosmeticStore,
  });

  final StudyProfile profile;
  final ArenaCosmeticStore cosmeticStore;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final ArenaWalletState wallet = cosmeticStore.state;
    final ArenaRankTier tier = cosmeticStore.currentTier;
    final ArenaCosmeticItem? equippedAvatar =
        ArenaCosmeticCatalog.byId(wallet.equippedAvatarId);
    final ArenaCosmeticItem? equippedFrame =
        ArenaCosmeticCatalog.byId(wallet.equippedFrameId);
    final ArenaCosmeticItem? equippedAura =
        ArenaCosmeticCatalog.byId(wallet.equippedAuraId);

    final Color frameColor = cosmeticFrameBorderColor(mc, wallet.equippedFrameId);
    final double frameWidth = cosmeticFrameBorderWidth(wallet.equippedFrameId);
    final String alias =
        profile.alias.trim().isEmpty ? 'Bạn học' : profile.alias.trim();

    return MindClockCard(
      key: const ValueKey<String>('arena-lobby-profile-banner'),
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                key: ValueKey<String>(
                  'arena-equipped-frame-${wallet.equippedFrameId}',
                ),
                width: 60,
                height: 60,
                padding: EdgeInsets.all(mc.space4 / 2),
                decoration: BoxDecoration(
                  color: mc.night,
                  borderRadius: BorderRadius.circular(mc.radiusControl),
                  border: Border.all(color: frameColor, width: frameWidth),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mc.radiusChip),
                  child: (equippedAvatar?.previewAssetPath != null)
                      ? Image.asset(
                          equippedAvatar!.previewAssetPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => MindClockAvatarView(
                            avatarId: profile.avatarId,
                            customAvatarPath: profile.customAvatarPath,
                            size: 52,
                          ),
                        )
                      : MindClockAvatarView(
                          avatarId: profile.avatarId,
                          customAvatarPath: profile.customAvatarPath,
                          size: 52,
                        ),
                ),
              ),
              SizedBox(width: mc.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      alias,
                      style: mc.sectionTitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: mc.space4),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        MindClockStatusPill(
                          label: 'Bậc: ${tier.nameVi}',
                          accentWarm: false,
                        ),
                        Container(
                          key: const ValueKey<String>('arena-mindcoin-badge'),
                          padding: EdgeInsets.symmetric(
                            horizontal: mc.space8,
                            vertical: mc.space4 / 2,
                          ),
                          decoration: BoxDecoration(
                            color: mc.sunriseSoft,
                            borderRadius: BorderRadius.circular(mc.radiusChip),
                            border: Border.all(color: mc.sunrise),
                          ),
                          child: Text(
                            '${wallet.mindCoins} Xu',
                            style: mc.chipLabelStyle.copyWith(color: mc.ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          Text(
            'Trang bị: ${equippedFrame?.nameVi ?? "Cơ bản"} · '
            '${equippedAvatar?.nameVi ?? "Linh vật mặc định"}'
            '${equippedAura != null ? " · ${equippedAura.nameVi}" : ""}',
            style: mc.captionStyle,
          ),
          SizedBox(height: mc.space4),
          Text(
            'Mùa Giao hữu · Điểm: ${wallet.localFriendlyScore} · Trận đã đấu: ${wallet.localMatchesCount}',
            style: mc.captionStyle,
          ),
        ],
      ),
    );
  }
}

/// Khung giới thiệu tướng đứng sân animated idle ngay trong Sảnh chờ (`T064`).
class ArenaLobbyChampionShowcase extends StatelessWidget {
  const ArenaLobbyChampionShowcase({
    super.key,
    required this.selectedChampion,
    required this.equippedAuraId,
    required this.onSelectChampion,
    required this.onInspectChampion,
  });

  final ChampionId selectedChampion;
  final String equippedAuraId;
  final ValueChanged<ChampionId> onSelectChampion;
  final ValueChanged<ChampionSpec> onInspectChampion;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final ChampionSpec spec = CombatCatalog.getSpec(selectedChampion);
    final bool disableMotion = MediaQuery.disableAnimationsOf(context);
    final Color? auraRingColor = switch (equippedAuraId) {
      'aura_bamboo' => mc.primary,
      'aura_sunrise_halo' => mc.sunrise,
      _ => null,
    };

    return Container(
      key: const ValueKey<String>('arena-lobby-champion-showcase'),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: mc.night,
        borderRadius: BorderRadius.circular(mc.radiusCard),
        border: Border.all(color: auraRingColor ?? mc.nightSurface, width: 1.5),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.34,
              child: Image.asset(
                CombatCatalog.mapCourtyardAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    mc.night.withAlpha(180),
                    mc.night.withAlpha(140),
                    mc.night.withAlpha(230),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(mc.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      'Võ Đài Danh Tướng',
                      style: mc.sectionTitleStyle.copyWith(color: mc.nightText),
                    ),
                    MindClockStatusPill(
                      label: spec.roleVi,
                      accentWarm: spec.id == ChampionId.tuyetDinh,
                    ),
                  ],
                ),
                SizedBox(height: mc.space12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(mc.space8),
                      decoration: BoxDecoration(
                        color: mc.nightSurface.withAlpha(190),
                        borderRadius: BorderRadius.circular(mc.radiusControl),
                        border: Border.all(
                          color: auraRingColor ?? mc.primary,
                          width: auraRingColor != null ? 2.0 : 1.0,
                        ),
                      ),
                      child: ArenaSpriteActor(
                        spec: spec,
                        facingRight: true,
                        isBot: false,
                        disableMotion: disableMotion,
                        assetFallbackMode: false,
                        size: 98,
                      ),
                    ),
                    SizedBox(width: mc.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            spec.nameVi,
                            style: mc.sectionTitleStyle.copyWith(
                              color: mc.nightText,
                            ),
                          ),
                          SizedBox(height: mc.space4),
                          Text(
                            spec.loreVi,
                            style: mc.captionStyle.copyWith(color: mc.nightText),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: mc.space8),
                          Text(
                            'Nội tại: ${spec.passiveNameVi}',
                            style: mc.chipLabelStyle.copyWith(color: mc.sunrise),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: ChampionId.values.map((ChampionId id) {
                    final ChampionSpec cSpec = CombatCatalog.getSpec(id);
                    final bool active = id == selectedChampion;
                    return MindClockPressable(
                      key: ValueKey<String>('arena-lobby-champ-${id.code}'),
                      selected: active,
                      semanticLabel: 'Xem tướng ${cSpec.nameVi}',
                      onPressed: () => onSelectChampion(id),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? mc.primary : mc.nightSurface,
                          borderRadius: BorderRadius.circular(mc.radiusChip),
                          border: Border.all(
                            color: active ? mc.sunrise : mc.outline,
                          ),
                        ),
                        child: Text(
                          cSpec.nameVi,
                          style: mc.chipLabelStyle.copyWith(
                            color: mc.nightText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: mc.space8),
                MindClockButton(
                  key: const ValueKey<String>('arena-lobby-inspect-champ'),
                  label: 'Chiêu thức & Tuyệt kỹ · ${spec.nameVi}',
                  icon: MindClockIconKind.info,
                  variant: MindClockButtonVariant.subtle,
                  onPressed: () => onInspectChampion(spec),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bảng xếp hạng kiến thức giao hữu (`T064 AC-03`).
class ArenaLeaderboardPanel extends StatefulWidget {
  const ArenaLeaderboardPanel({
    super.key,
    required this.profile,
    required this.cosmeticStore,
  });

  final StudyProfile profile;
  final ArenaCosmeticStore cosmeticStore;

  @override
  State<ArenaLeaderboardPanel> createState() => _ArenaLeaderboardPanelState();
}

class _ArenaLeaderboardPanelState extends State<ArenaLeaderboardPanel> {
  String _subjectFilter = 'all';
  String _gradeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final ArenaWalletState wallet = widget.cosmeticStore.state;
    final String primarySubject = widget.profile.selectedSubjectCodes.isNotEmpty
        ? widget.profile.selectedSubjectCodes.first
        : 'math';
    final List<ArenaLeaderboardEntry> entries =
        widget.cosmeticStore.buildFriendlyLeaderboard(
      userAlias: widget.profile.alias,
      userGradeLevel: widget.profile.gradeLevel ?? 'Lớp 11',
      primarySubjectCode: primarySubject,
      subjectFilter: _subjectFilter,
      gradeFilter: _gradeFilter,
    );

    const List<String> subjects = <String>['all', 'math', 'physics', 'chemistry', 'english'];
    const List<String> grades = <String>['all', 'Lớp 10', 'Lớp 11', 'Lớp 12'];

    return Column(
      key: const ValueKey<String>('arena-leaderboard-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const MindClockNoticeBanner(
          message:
              'Bảng xếp hạng Đấu trường · Xếp hạng công bằng theo độ chính xác và số trận thắng.',
          isWarm: false,
        ),
        SizedBox(height: mc.space12),
        MindClockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Quyền riêng tư bảng xếp hạng', style: mc.bodyStrongStyle),
              SizedBox(height: mc.space8),
              MindClockPressable(
                key: const ValueKey<String>('arena-leaderboard-optin-toggle'),
                selected: wallet.leaderboardOptIn,
                semanticLabel:
                    'Bật hoặc tắt hiển thị tên của bạn trên bảng xếp hạng',
                onPressed: () =>
                    widget.cosmeticStore.setLeaderboardOptIn(!wallet.leaderboardOptIn),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(mc.space12),
                  decoration: BoxDecoration(
                    color: wallet.leaderboardOptIn ? mc.primarySoft : mc.paper,
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                    border: Border.all(
                      color: wallet.leaderboardOptIn ? mc.primary : mc.outline,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          wallet.leaderboardOptIn
                              ? 'Đang tham gia BXH với biệt danh riêng (nhấn để ẩn)'
                              : 'Đang ẩn khỏi BXH (nhấn để tham gia lại)',
                          style: mc.bodyStrongStyle,
                        ),
                      ),
                      SizedBox(width: mc.space8),
                      MindClockStatusPill(
                        label: wallet.leaderboardOptIn ? 'Đang bật' : 'Đã ẩn',
                        accentWarm: !wallet.leaderboardOptIn,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: mc.space12),
              Text('Lọc theo môn học:', style: mc.captionStyle),
              SizedBox(height: mc.space4),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: subjects.map((String code) {
                  final bool selected = _subjectFilter == code;
                  final String label =
                      code == 'all' ? 'Tất cả môn' : SubjectCatalog.nameFor(code);
                  return MindClockPressable(
                    key: ValueKey<String>('arena-lb-subject-$code'),
                    selected: selected,
                    semanticLabel: 'Lọc BXH môn $label',
                    onPressed: () => setState(() => _subjectFilter = code),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: mc.space12,
                        vertical: mc.space8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? mc.primary : mc.paper,
                        borderRadius: BorderRadius.circular(mc.radiusChip),
                        border: Border.all(
                          color: selected ? mc.primary : mc.outline,
                        ),
                      ),
                      child: Text(
                        label,
                        style: mc.chipLabelStyle.copyWith(
                          color: selected ? mc.onPrimary : mc.ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: mc.space12),
              Text('Lọc theo khối lớp THPT:', style: mc.captionStyle),
              SizedBox(height: mc.space4),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: grades.map((String grade) {
                  final bool selected = _gradeFilter == grade;
                  final String label = grade == 'all' ? 'Tất cả khối' : grade;
                  return MindClockPressable(
                    key: ValueKey<String>('arena-lb-grade-$grade'),
                    selected: selected,
                    semanticLabel: 'Lọc BXH $label',
                    onPressed: () => setState(() => _gradeFilter = grade),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: mc.space12,
                        vertical: mc.space8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? mc.primary : mc.paper,
                        borderRadius: BorderRadius.circular(mc.radiusChip),
                        border: Border.all(
                          color: selected ? mc.primary : mc.outline,
                        ),
                      ),
                      child: Text(
                        label,
                        style: mc.chipLabelStyle.copyWith(
                          color: selected ? mc.onPrimary : mc.ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: mc.space12),
        if (entries.isEmpty)
          MindClockCard(
            child: Text(
              'Chưa có đấu thủ nào trong mục này.',
              style: mc.bodyStyle,
            ),
          )
        else
          ...List<Widget>.generate(entries.length, (int index) {
            final ArenaLeaderboardEntry entry = entries[index];
            final int rank = index + 1;
            return Padding(
              padding: EdgeInsets.only(bottom: mc.space8),
              child: MindClockCard(
                key: ValueKey<String>('arena-lb-entry-${entry.id}'),
                highlighted: entry.isCurrentUser,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3 ? mc.sunriseSoft : mc.paper,
                        borderRadius: BorderRadius.circular(mc.radiusChip),
                        border: Border.all(
                          color: rank <= 3 ? mc.sunrise : mc.outline,
                        ),
                      ),
                      child: Text('#$rank', style: mc.bodyStrongStyle),
                    ),
                    SizedBox(width: mc.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: mc.space8,
                            runSpacing: mc.space4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Text(
                                entry.displayName,
                                style: mc.bodyStrongStyle,
                              ),
                              if (entry.isCurrentUser)
                                const MindClockStatusPill(label: 'Bạn'),
                            ],
                          ),
                          SizedBox(height: mc.space4),
                          Text(
                            '${entry.gradeBand} · ${SubjectCatalog.nameFor(entry.subjectCode)} · '
                            'Chính xác ${entry.accuracyPercent}% · ${entry.validMatchesCount} trận',
                            style: mc.captionStyle,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: mc.space8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '${entry.friendlyScore}',
                          style: mc.sectionTitleStyle.copyWith(color: mc.primary),
                        ),
                        Text('điểm', style: mc.captionStyle),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Cửa hàng Daily Shop mỹ thuật (`T064 AC-04`, 0 pay-to-win).
class ArenaDailyShopPanel extends StatefulWidget {
  const ArenaDailyShopPanel({
    super.key,
    required this.cosmeticStore,
  });

  final ArenaCosmeticStore cosmeticStore;

  @override
  State<ArenaDailyShopPanel> createState() => _ArenaDailyShopPanelState();
}

class _ArenaDailyShopPanelState extends State<ArenaDailyShopPanel> {
  String? _feedbackVi;

  Future<void> _handleShopItemTap(
    ArenaCosmeticItem item,
    bool owned,
  ) async {
    final CosmeticActionOutcome outcome = owned
        ? await widget.cosmeticStore.equipItem(item)
        : await widget.cosmeticStore.buyItem(item);
    if (!mounted) return;
    setState(() => _feedbackVi = outcome.messageVi);
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final ArenaWalletState wallet = widget.cosmeticStore.state;
    final List<ArenaCosmeticItem> dailyItems =
        widget.cosmeticStore.todayOfferings;

    return Column(
      key: const ValueKey<String>('arena-daily-shop-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MindClockNoticeBanner(
          message:
              'Daily Shop ngày ${widget.cosmeticStore.todayDateKey} · Sưu tầm Khung viền, Avatar và Hào quang thuần ngoại hình bằng MindCoin từ các trận đấu.',
          isWarm: false,
        ),
        if (_feedbackVi != null) ...<Widget>[
          SizedBox(height: mc.space8),
          MindClockNoticeBanner(
            key: const ValueKey<String>('arena-shop-feedback'),
            message: _feedbackVi!,
            isWarm: false,
          ),
        ],
        SizedBox(height: mc.space12),
        Text(
          'Nổi bật hôm nay (Đổi theo ngày)',
          style: mc.sectionTitleStyle,
        ),
        SizedBox(height: mc.space8),
        ...dailyItems.map((ArenaCosmeticItem item) {
          return _buildShopItemCard(mc, wallet, item);
        }),
        SizedBox(height: mc.space16),
        Text(
          'Bộ sưu tập mỹ thuật của bạn',
          style: mc.sectionTitleStyle,
        ),
        SizedBox(height: mc.space8),
        ...ArenaCosmeticCatalog.allItems
            .where((ArenaCosmeticItem i) => wallet.ownedItemIds.contains(i.id))
            .map((ArenaCosmeticItem item) {
          return _buildShopItemCard(mc, wallet, item, isCollectionSection: true);
        }),
      ],
    );
  }

  Widget _buildShopItemCard(
    MindClockTheme mc,
    ArenaWalletState wallet,
    ArenaCosmeticItem item, {
    bool isCollectionSection = false,
  }) {
    final bool owned = wallet.ownedItemIds.contains(item.id);
    final bool equipped = switch (item.category) {
      ArenaCosmeticCategory.frame => wallet.equippedFrameId == item.id,
      ArenaCosmeticCategory.avatar => wallet.equippedAvatarId == item.id,
      ArenaCosmeticCategory.aura => wallet.equippedAuraId == item.id,
    };
    final bool canAfford = wallet.mindCoins >= item.priceCoins;
    final String buttonLabel = equipped
        ? 'Đang trang bị'
        : (owned
            ? 'Trang bị'
            : (canAfford ? 'Mở khóa · ${item.priceCoins} Xu' : 'Chưa đủ Xu (${item.priceCoins})'));

    final String keySuffix = isCollectionSection ? 'owned-${item.id}' : item.id;

    return Padding(
      padding: EdgeInsets.only(bottom: mc.space8),
      child: MindClockCard(
        key: ValueKey<String>('arena-shop-card-$keySuffix'),
        highlighted: equipped,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ShopPreviewThumb(item: item),
            SizedBox(width: mc.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(item.nameVi, style: mc.bodyStrongStyle),
                      MindClockStatusPill(
                        label: '${item.category.labelVi} · ${item.tierBadgeVi}',
                        accentWarm: !owned,
                      ),
                    ],
                  ),
                  SizedBox(height: mc.space4),
                  Text(item.descriptionVi, style: mc.captionStyle),
                  SizedBox(height: mc.space4),
                  Text(
                    'Trang bị ngoại hình · ${item.category.labelVi}',
                    style: mc.captionStyle.copyWith(color: mc.primary),
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: ValueKey<String>('arena-shop-action-$keySuffix'),
                    label: buttonLabel,
                    variant: equipped
                        ? MindClockButtonVariant.subtle
                        : (owned
                            ? MindClockButtonVariant.secondary
                            : MindClockButtonVariant.primary),
                    onPressed: equipped || (!owned && !canAfford)
                        ? null
                        : () => _handleShopItemTap(item, owned),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopPreviewThumb extends StatelessWidget {
  const _ShopPreviewThumb({required this.item});

  final ArenaCosmeticItem item;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    if (item.previewAssetPath != null) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: mc.night,
          borderRadius: BorderRadius.circular(mc.radiusControl),
          border: Border.all(color: mc.primary),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(mc.radiusControl - 1),
          child: Image.asset(
            item.previewAssetPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: MindClockIcon(MindClockIconKind.sunrise, color: mc.sunrise),
            ),
          ),
        ),
      );
    }

    if (item.category == ArenaCosmeticCategory.frame) {
      final Color color = cosmeticFrameBorderColor(mc, item.id);
      return Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: mc.night,
          borderRadius: BorderRadius.circular(mc.radiusControl),
          border: Border.all(color: color, width: cosmeticFrameBorderWidth(item.id)),
        ),
        child: MindClockIcon(MindClockIconKind.shield, color: color),
      );
    }

    final Color auraColor =
        item.id == 'aura_sunrise_halo' ? mc.sunrise : mc.primary;
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: mc.nightSurface,
        borderRadius: BorderRadius.circular(mc.radiusControl),
        border: Border.all(color: auraColor, width: 2),
      ),
      child: MindClockIcon(MindClockIconKind.sunrise, color: auraColor),
    );
  }
}
