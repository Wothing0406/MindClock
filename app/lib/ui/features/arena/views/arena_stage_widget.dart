import 'package:flutter/widgets.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_icon.dart';
import 'arena_sprite_stage.dart';

/// Khung sân đấu màn dọc cho G1 Luyện đơn (dùng đồ họa vector chuẩn MindClockTheme).
///
/// - Khi đang giải câu (`compact: true`): sân thu gọn tối đa để ưu tiên câu & ô trình bày.
/// - Khi chọn chiêu hoặc xem phản hồi (`compact: false`): sân mở rộng rõ hai tướng đối diện,
///   thông số HP/Giáp/Chắn/Qi bằng số và chữ, hỗ trợ Reduce Motion, Bỏ qua hiệu ứng và fallback khi lỗi asset.
class ArenaStageWidget extends StatelessWidget {
  const ArenaStageWidget({
    super.key,
    required this.playerState,
    required this.botState,
    required this.compact,
    required this.reduceMotion,
    required this.skipEffects,
    required this.soundEnabled,
    required this.assetFallbackMode,
    this.lastResolution,
    this.playerIsWinner = false,
    this.botIsWinner = false,
  });

  final SoloCombatantState playerState;
  final SoloCombatantState botState;
  final bool compact;
  final bool reduceMotion;
  final bool skipEffects;
  final bool soundEnabled;
  final bool assetFallbackMode;
  final SoloRoundResolution? lastResolution;
  final bool playerIsWinner;
  final bool botIsWinner;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool disableMotion =
        reduceMotion || skipEffects || MediaQuery.disableAnimationsOf(context);
    final ChampionSpec playerSpec = CombatCatalog.getSpec(playerState.championId);
    final ChampionSpec botSpec = CombatCatalog.getSpec(botState.championId);

    return Container(
      key: ValueKey<String>(compact ? 'arena-stage-compact' : 'arena-stage-expanded'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 0 : 264),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: mc.night,
        borderRadius: BorderRadius.circular(mc.radiusCard),
        border: Border.all(
          color: botState.qi >= 2 ? mc.sunrise : mc.nightSurface,
          width: botState.qi >= 2 ? 2.0 : 1.5,
        ),
      ),
      child: Stack(
        children: <Widget>[
          if (!assetFallbackMode)
            Positioned.fill(
              child: Opacity(
                opacity: compact ? 0.24 : 0.38,
                child: Image.asset(
                  CombatCatalog.mapCourtyardAssetPath,
                  key: const ValueKey<String>('arena-stage-map-image'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (!assetFallbackMode)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      mc.night.withAlpha(190),
                      mc.night.withAlpha(140),
                      mc.night.withAlpha(220),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(compact ? mc.space12 : mc.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      assetFallbackMode
                          ? 'Khung tĩnh dự phòng (khi asset lỗi)'
                          : 'Võ đường Bình minh · Bản gốc MindClock',
                      key: const ValueKey<String>('arena-stage-mode-label'),
                      style: mc.captionStyle.copyWith(color: mc.sunrise),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        MindClockIcon(
                          soundEnabled
                              ? MindClockIconKind.volumeOn
                              : MindClockIconKind.volumeOff,
                          color: mc.nightText,
                          size: 16,
                        ),
                        SizedBox(width: mc.space4),
                        Text(
                          soundEnabled ? 'Âm: Bật (chờ SFX G4)' : 'Âm: Tắt',
                          style: mc.captionStyle.copyWith(color: mc.nightText),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: mc.space8),
                // Thanh cảnh báo tụ chiêu của đối thủ (T086 Card-Battle HUD)
                Container(
                  key: const ValueKey<String>('arena-enemy-charge-bar'),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: mc.space12,
                    vertical: mc.space8,
                  ),
                  decoration: BoxDecoration(
                    color: mc.nightSurface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                    border: Border.all(
                      color: botState.qi >= 2 ? mc.error : mc.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: mc.space8,
                        runSpacing: mc.space4,
                        alignment: WrapAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            botState.qi >= 2
                                ? 'Cảnh báo tụ chiêu: ${botSpec.nameVi} sẵn sàng tung ${botSpec.skill2.nameVi}!'
                                : 'Tụ chiêu đối thủ (${botSpec.nameVi}): ${botState.qi}/$maxQi khí lực',
                            style: mc.captionStyle.copyWith(
                              color: botState.qi >= 2 ? mc.sunrise : mc.nightText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: mc.space4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(mc.radiusChip),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          color: mc.night,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (botState.qi / maxQi).clamp(0.12, 1.0),
                            child: ColoredBox(
                              color: botState.qi >= 2 ? mc.error : mc.sunrise,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? mc.space8 : mc.space12),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool narrow = constraints.maxWidth < 310;
                    final Widget leftCard = _CombatantSlotCard(
                      key: const ValueKey<String>('arena-slot-player'),
                      state: playerState,
                      spec: playerSpec,
                      facingRight: true,
                      compact: compact,
                      disableMotion: disableMotion,
                      assetFallbackMode: assetFallbackMode,
                      deltaDamageTaken: lastResolution?.settle.playerADelta.damageTaken ?? 0,
                      deltaHealAmount: (lastResolution?.settle.playerADelta.hpHealed ?? 0) +
                          (lastResolution?.settle.playerADelta.armorHealed ?? 0),
                      deltaActionUsed: lastResolution?.settle.playerADelta.actionUsed,
                      isWinner: playerIsWinner,
                    );
                    final Widget rightCard = _CombatantSlotCard(
                      key: const ValueKey<String>('arena-slot-bot'),
                      state: botState,
                      spec: botSpec,
                      facingRight: false,
                      compact: compact,
                      disableMotion: disableMotion,
                      assetFallbackMode: assetFallbackMode,
                      deltaDamageTaken: lastResolution?.settle.playerBDelta.damageTaken ?? 0,
                      deltaHealAmount: (lastResolution?.settle.playerBDelta.hpHealed ?? 0) +
                          (lastResolution?.settle.playerBDelta.armorHealed ?? 0),
                      deltaActionUsed: lastResolution?.settle.playerBDelta.actionUsed,
                      isWinner: botIsWinner,
                    );

                    if (narrow) {
                      return Column(
                        children: <Widget>[
                          leftCard,
                          SizedBox(height: mc.space8),
                          rightCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(child: leftCard),
                        SizedBox(width: mc.space8),
                        Expanded(child: rightCard),
                      ],
                    );
                  },
                ),
                if (!compact && lastResolution != null) ...<Widget>[
                  SizedBox(height: mc.space12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(mc.space12),
                    decoration: BoxDecoration(
                      color: mc.nightSurface,
                      borderRadius: BorderRadius.circular(mc.radiusControl),
                      border: Border.all(color: mc.primary),
                    ),
                    child: Text(
                      disableMotion
                          ? 'Chế độ tĩnh (Reduce Motion / Bỏ qua hiệu ứng): số liệu sát thương và hồi phục không đổi.'
                          : 'Hiệu ứng riêng tướng: ${_fxSummary(playerSpec, botSpec, lastResolution!)}',
                      key: const ValueKey<String>('arena-stage-fx-banner'),
                      style: mc.captionStyle.copyWith(color: mc.nightText),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fxSummary(
    ChampionSpec playerSpec,
    ChampionSpec botSpec,
    SoloRoundResolution res,
  ) {
    final String pAct = _actionName(playerSpec, res.settle.playerADelta.actionUsed);
    final String bAct = _actionName(botSpec, res.settle.playerBDelta.actionUsed);
    return '${playerSpec.nameVi} ($pAct: ${res.settle.playerADelta.rawDamageDealt} ST) '
        'vs ${botSpec.nameVi} ($bAct: ${res.settle.playerBDelta.rawDamageDealt} ST)';
  }

  String _actionName(ChampionSpec spec, CombatActionType? action) {
    if (action == null) return 'Không ra đòn';
    return switch (action) {
      CombatActionType.basic => 'Đánh thường',
      CombatActionType.skill1 => spec.skill1.nameVi,
      CombatActionType.skill2 => spec.skill2.nameVi,
    };
  }
}

class _CombatantSlotCard extends StatelessWidget {
  const _CombatantSlotCard({
    super.key,
    required this.state,
    required this.spec,
    required this.facingRight,
    required this.compact,
    required this.disableMotion,
    required this.assetFallbackMode,
    required this.deltaDamageTaken,
    required this.deltaHealAmount,
    required this.deltaActionUsed,
    required this.isWinner,
  });

  final SoloCombatantState state;
  final ChampionSpec spec;
  final bool facingRight;
  final bool compact;
  final bool disableMotion;
  final bool assetFallbackMode;
  final int deltaDamageTaken;
  final int deltaHealAmount;
  final CombatActionType? deltaActionUsed;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final double hpRatio = (state.hp / maxHp).clamp(0.0, 1.0);
    final double armorRatio = (state.armor / maxArmor).clamp(0.0, 1.0);
    final Color accentColor = state.isBot ? mc.sunrise : mc.primary;

    return Semantics(
      label:
          '${state.displayName}, tướng ${spec.nameVi}, HP ${state.hp} trên $maxHp, '
          'Giáp ${state.armor} trên $maxArmor, Qi ${state.qi} trên $maxQi',
      child: Container(
        padding: EdgeInsets.all(compact ? mc.space8 : mc.space12),
        decoration: BoxDecoration(
          color: mc.nightSurface,
          borderRadius: BorderRadius.circular(mc.radiusControl),
          border: Border.all(
            color: deltaDamageTaken > 0 && !compact ? mc.error : accentColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: mc.space4,
              runSpacing: mc.space4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  state.displayName,
                  style: mc.chipLabelStyle.copyWith(color: mc.nightText),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: mc.space8,
                    vertical: mc.space4 / 2,
                  ),
                  decoration: BoxDecoration(
                    color: state.isBot ? mc.sunriseSoft : mc.primarySoft,
                    borderRadius: BorderRadius.circular(mc.radiusChip),
                  ),
                  child: Text(
                    state.isBot ? 'Máy tập' : 'Người học',
                    style: mc.chipLabelStyle.copyWith(color: mc.ink),
                  ),
                ),
              ],
            ),
            SizedBox(height: mc.space4),
            Text(
              '${spec.nameVi} · ${facingRight ? "Nhìn phải →" : "← Nhìn trái"}',
              style: mc.captionStyle.copyWith(color: mc.sunrise),
            ),
            ...<Widget>[
              SizedBox(height: mc.space8),
              Center(
                child: ArenaSpriteActor(
                  spec: spec,
                  facingRight: facingRight,
                  isBot: state.isBot,
                  disableMotion: disableMotion,
                  assetFallbackMode: assetFallbackMode,
                  actionUsed: deltaActionUsed,
                  damageTaken: deltaDamageTaken,
                  healAmount: deltaHealAmount,
                  isWinner: isWinner,
                  size: compact ? 68.0 : 104.0,
                ),
              ),
            ],
            SizedBox(height: mc.space8),
            _NumericStatBar(
              label: 'HP ${state.hp}/$maxHp',
              ratio: hpRatio,
              fillColor: state.hp <= 25 ? mc.error : mc.primary,
              trackColor: mc.night,
              textColor: mc.nightText,
              disableMotion: disableMotion,
            ),
            SizedBox(height: mc.space4),
            _NumericStatBar(
              label: 'Giáp ${state.armor}/$maxArmor',
              ratio: armorRatio,
              fillColor: mc.sunrise,
              trackColor: mc.night,
              textColor: mc.nightText,
              disableMotion: disableMotion,
            ),
            SizedBox(height: mc.space4),
            Text(
              'Qi: ${state.qi}/$maxQi${state.passivePendingWard > 0 ? " · Chắn vòng sau: +${state.passivePendingWard}" : ""}',
              style: mc.captionStyle.copyWith(color: mc.nightText),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumericStatBar extends StatelessWidget {
  const _NumericStatBar({
    required this.label,
    required this.ratio,
    required this.fillColor,
    required this.trackColor,
    required this.textColor,
    required this.disableMotion,
  });

  final String label;
  final double ratio;
  final Color fillColor;
  final Color trackColor;
  final Color textColor;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: mc.captionStyle.copyWith(color: textColor)),
        SizedBox(height: mc.space4 / 2),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(mc.radiusChip),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: AnimatedContainer(
              duration: disableMotion ? Duration.zero : mc.transitionDuration,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(mc.radiusChip),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
