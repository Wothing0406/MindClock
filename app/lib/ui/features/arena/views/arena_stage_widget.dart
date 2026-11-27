import 'package:flutter/widgets.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import 'arena_sprite_stage.dart';

/// Thông tin hiển thị của từng bản đồ chiến đấu (toàn bộ màu dẫn xuất từ `MindClockTheme`).
class ArenaMapTheme {
  const ArenaMapTheme({
    required this.id,
    required this.nameVi,
    required this.assetPath,
  });

  final String id;
  final String nameVi;
  final String assetPath;

  static const ArenaMapTheme courtyard = ArenaMapTheme(
    id: 'courtyard',
    nameVi: 'Võ đường Bình minh',
    assetPath: 'assets/game/maps/study-courtyard.webp',
  );

  static const ArenaMapTheme dawnPeak = ArenaMapTheme(
    id: 'dawn_peak',
    nameVi: 'Đỉnh Tri thức',
    assetPath: 'assets/arena/map_courtyard.png',
  );

  static const ArenaMapTheme nightLibrary = ArenaMapTheme(
    id: 'night_library',
    nameVi: 'Thư viện Đêm',
    assetPath: 'assets/game/maps/study-courtyard.webp',
  );

  static ArenaMapTheme byId(String id) => switch (id) {
        'dawn_peak' => dawnPeak,
        'night_library' => nightLibrary,
        _ => courtyard,
      };

  Color skyTop(MindClockTheme mc) => switch (id) {
        'dawn_peak' => mc.sunriseSoft.withValues(alpha: 0.34),
        'night_library' => mc.night.withValues(alpha: 0.64),
        _ => mc.sunrise.withValues(alpha: 0.18),
      };

  Color skyBottom(MindClockTheme mc) => switch (id) {
        'dawn_peak' => mc.nightSurface.withValues(alpha: 0.82),
        'night_library' => mc.night.withValues(alpha: 0.92),
        _ => mc.night.withValues(alpha: 0.78),
      };

  Color groundLine(MindClockTheme mc) => switch (id) {
        'dawn_peak' => mc.sunrise.withValues(alpha: 0.48),
        'night_library' => mc.primary.withValues(alpha: 0.44),
        _ => mc.sunrise.withValues(alpha: 0.34),
      };
}

/// Sân đấu 2D không gian dọc cho Đấu trường (`T091`).
///
/// - Hai tướng đứng trực tiếp trên bản đồ đối diện nhau (bên trái nhìn phải, bên phải nhìn trái), mỗi bên 3 làn.
/// - Đối thủ báo trước làn sắp đánh; người chơi bấm `Né` để đổi làn và giảm sát thương nhận vào.
/// - Đòn đánh bay từ người ra đòn tới đúng vị trí mục tiêu; hiệu ứng trúng đòn chỉ hiện tại phía nhận sát thương.
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
    this.mapId = 'courtyard',
    this.playerLane = 1,
    this.botAttackLane = 1,
    this.dodgeActive = false,
    this.dodgeNoticeVi,
    this.onDodge,
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
  final String mapId;
  final int playerLane;
  final int botAttackLane;
  final bool dodgeActive;
  final String? dodgeNoticeVi;
  final VoidCallback? onDodge;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool disableMotion =
        reduceMotion || skipEffects || MediaQuery.disableAnimationsOf(context);
    final ChampionSpec playerSpec = CombatCatalog.getSpec(playerState.championId);
    final ChampionSpec botSpec = CombatCatalog.getSpec(botState.championId);
    final ArenaMapTheme map = ArenaMapTheme.byId(mapId);
    final double fieldHeight = compact ? 150 : 212;
    final double spriteSize = compact ? 64 : 96;

    final int playerDamageTaken =
        lastResolution?.settle.playerADelta.damageTaken ?? 0;
    final int botDamageTaken =
        lastResolution?.settle.playerBDelta.damageTaken ?? 0;

    return Container(
      key: ValueKey<String>(compact ? 'arena-stage-compact' : 'arena-stage-expanded'),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: mc.night,
        borderRadius: BorderRadius.circular(mc.radiusCard),
        border: Border.all(
          color: botState.qi >= 2 ? mc.sunrise : mc.nightSurface,
          width: botState.qi >= 2 ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(mc.space8, mc.space8, mc.space8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _HudPanel(
                    state: playerState,
                    spec: playerSpec,
                    alignRight: false,
                    disableMotion: disableMotion,
                  ),
                ),
                SizedBox(width: mc.space8),
                Expanded(
                  child: _HudPanel(
                    state: botState,
                    spec: botSpec,
                    alignRight: true,
                    disableMotion: disableMotion,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(mc.space8, mc.space4, mc.space8, 0),
            child: Text(
              assetFallbackMode
                  ? 'Khung tĩnh dự phòng (khi asset lỗi)'
                  : '${map.nameVi} · Làn đứng ${playerLane + 1}/3',
              key: const ValueKey<String>('arena-stage-mode-label'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mc.captionStyle.copyWith(color: mc.sunrise),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(mc.space8, mc.space4, mc.space8, 0),
            child: _EnemyChargeBar(botState: botState, botSpec: botSpec),
          ),
          SizedBox(height: mc.space4),
          SizedBox(
            height: fieldHeight,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double w = c.maxWidth;
                final double laneStep = (fieldHeight - spriteSize) / 2;
                double laneTop(int lane) => laneStep * lane.clamp(0, 2);
                final double playerLeft =
                    (w * 0.06) + playerLane.clamp(0, 2) * (w * 0.03);
                final double botLeft = w -
                    spriteSize -
                    (w * 0.06) -
                    botAttackLane.clamp(0, 2) * (w * 0.02);
                final CombatActionType? pAct =
                    lastResolution?.settle.playerADelta.actionUsed;
                final CombatActionType? bAct =
                    lastResolution?.settle.playerBDelta.actionUsed;
                final Duration move = disableMotion
                    ? Duration.zero
                    : mc.transitionDuration;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    if (!assetFallbackMode)
                      Positioned.fill(
                        child: Image.asset(
                          map.assetPath,
                          key: const ValueKey<String>('arena-stage-map-image'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[map.skyTop(mc), map.skyBottom(mc)],
                          ),
                        ),
                      ),
                    ),
                    for (int lane = 0; lane < 3; lane++)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: laneTop(lane) + spriteSize - 6,
                        height: 2,
                        child: ColoredBox(color: map.groundLine(mc)),
                      ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: w * 0.42,
                      child: ColoredBox(
                        color: mc.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: w * 0.42,
                      child: ColoredBox(
                        color: mc.sunrise.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      key: const ValueKey<String>('arena-telegraph-lane'),
                      left: 0,
                      width: w * 0.5,
                      top: laneTop(botAttackLane),
                      height: spriteSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              mc.error.withValues(alpha: 0.30),
                              mc.error.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: move,
                      curve: Curves.easeOut,
                      left: playerLeft,
                      top: laneTop(playerLane),
                      child: Semantics(
                        key: const ValueKey<String>('arena-slot-player'),
                        label:
                            '${playerState.displayName}, ${playerSpec.nameVi}, HP ${playerState.hp}, làn ${playerLane + 1}',
                        child: DecoratedBox(
                          decoration: dodgeActive
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: mc.primarySoft,
                                    width: 2,
                                  ),
                                )
                              : const BoxDecoration(),
                          child: ArenaSpriteActor(
                            spec: playerSpec,
                            facingRight: true,
                            isBot: false,
                            disableMotion: disableMotion,
                            assetFallbackMode: assetFallbackMode,
                            actionUsed: pAct,
                            damageTaken: playerDamageTaken,
                            healAmount:
                                (lastResolution?.settle.playerADelta.hpHealed ??
                                        0) +
                                    (lastResolution
                                            ?.settle.playerADelta.armorHealed ??
                                        0),
                            isWinner: playerIsWinner,
                            size: spriteSize,
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: move,
                      curve: Curves.easeOut,
                      left: botLeft,
                      top: laneTop(botAttackLane),
                      child: Semantics(
                        key: const ValueKey<String>('arena-slot-bot'),
                        label:
                            '${botState.displayName}, ${botSpec.nameVi}, HP ${botState.hp}',
                        child: ArenaSpriteActor(
                          spec: botSpec,
                          facingRight: false,
                          isBot: true,
                          disableMotion: disableMotion,
                          assetFallbackMode: assetFallbackMode,
                          actionUsed: bAct,
                          damageTaken: botDamageTaken,
                          healAmount:
                              (lastResolution?.settle.playerBDelta.hpHealed ??
                                      0) +
                                  (lastResolution
                                          ?.settle.playerBDelta.armorHealed ??
                                      0),
                          isWinner: botIsWinner,
                          size: spriteSize,
                        ),
                      ),
                    ),
                    if (lastResolution != null && pAct != null)
                      _Projectile(
                        key: ValueKey<String>(
                            'arena-projectile-player-${pAct.code}'),
                        assetPath: playerSpec.assetForAction(pAct),
                        fromX: playerLeft + spriteSize * 0.65,
                        fromY: laneTop(playerLane) + spriteSize * 0.35,
                        toX: botLeft + spriteSize * 0.35,
                        toY: laneTop(botAttackLane) + spriteSize * 0.35,
                        size: compact ? 28 : 38,
                        disableMotion: disableMotion,
                      ),
                    if (lastResolution != null && bAct != null)
                      _Projectile(
                        key: ValueKey<String>(
                            'arena-projectile-bot-${bAct.code}'),
                        assetPath: botSpec.assetForAction(bAct),
                        fromX: botLeft + spriteSize * 0.25,
                        fromY: laneTop(botAttackLane) + spriteSize * 0.42,
                        toX: playerLeft + spriteSize * 0.50,
                        toY: laneTop(botAttackLane) + spriteSize * 0.42,
                        size: compact ? 28 : 38,
                        disableMotion: disableMotion,
                      ),
                    if (botDamageTaken > 0)
                      Positioned(
                        key: const ValueKey<String>('arena-hit-impact-bot'),
                        left: botLeft + spriteSize * 0.2,
                        top: laneTop(botAttackLane) + spriteSize * 0.15,
                        child: _HitSpark(
                          color: mc.sunrise,
                          size: spriteSize * 0.55,
                        ),
                      ),
                    if (playerDamageTaken > 0)
                      Positioned(
                        key: const ValueKey<String>('arena-hit-impact-player'),
                        left: playerLeft + spriteSize * 0.2,
                        top: laneTop(playerLane) + spriteSize * 0.15,
                        child: _HitSpark(
                          color: mc.error,
                          size: spriteSize * 0.55,
                        ),
                      ),
                    if (onDodge != null)
                      Positioned(
                        left: mc.space8,
                        bottom: mc.space8,
                        child: MindClockPressable(
                          key: const ValueKey<String>('arena-dodge-btn'),
                          semanticLabel: 'Né chiêu, đổi làn đứng sang vùng an toàn',
                          onPressed: onDodge,
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: mc.minTouchTarget,
                              minHeight: mc.minTouchTarget,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: mc.space12,
                              vertical: mc.space8,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(mc.radiusChip),
                              color: dodgeActive
                                  ? mc.primary
                                  : mc.night.withValues(alpha: 0.86),
                              border: Border.all(color: mc.primary, width: 2),
                            ),
                            child: Text(
                              dodgeActive ? 'Đang né' : 'Né chiêu',
                              maxLines: 1,
                              style: mc.chipLabelStyle.copyWith(
                                color: dodgeActive ? mc.onPrimary : mc.nightText,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (dodgeNoticeVi != null)
            Padding(
              padding: EdgeInsets.fromLTRB(mc.space8, mc.space4, mc.space8, 0),
              child: Text(
                dodgeNoticeVi!,
                key: const ValueKey<String>('arena-dodge-notice'),
                style: mc.captionStyle.copyWith(color: mc.primarySoft),
              ),
            ),
          if (!compact && lastResolution != null)
            Padding(
              padding: EdgeInsets.all(mc.space8),
              child: Text(
                disableMotion
                    ? 'Chế độ tĩnh: số liệu sát thương và hồi phục không đổi.'
                    : _fxSummary(playerSpec, botSpec, lastResolution!),
                key: const ValueKey<String>('arena-stage-fx-banner'),
                style: mc.captionStyle.copyWith(color: mc.nightText),
              ),
            ),
          SizedBox(height: mc.space4),
        ],
      ),
    );
  }

  String _fxSummary(
    ChampionSpec playerSpec,
    ChampionSpec botSpec,
    SoloRoundResolution res,
  ) {
    final String pAct =
        _actionName(playerSpec, res.settle.playerADelta.actionUsed);
    final String bAct =
        _actionName(botSpec, res.settle.playerBDelta.actionUsed);
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

class _HitSpark extends StatelessWidget {
  const _HitSpark({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.85), width: 2.5),
          color: color.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

class _HudPanel extends StatelessWidget {
  const _HudPanel({
    required this.state,
    required this.spec,
    required this.alignRight,
    required this.disableMotion,
  });

  final SoloCombatantState state;
  final ChampionSpec spec;
  final bool alignRight;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final CrossAxisAlignment align =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Text(
          spec.nameVi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mc.chipLabelStyle.copyWith(color: mc.nightText),
        ),
        SizedBox(height: mc.space4 / 2),
        _Bar(
          ratio: (state.hp / maxHp).clamp(0.0, 1.0),
          fill: state.isBot ? mc.error : mc.primary,
          alignRight: alignRight,
          height: 9,
          disableMotion: disableMotion,
        ),
        const SizedBox(height: 2),
        _Bar(
          ratio: (state.armor / maxArmor).clamp(0.0, 1.0),
          fill: mc.sunrise,
          alignRight: alignRight,
          height: 4,
          disableMotion: disableMotion,
        ),
        Text(
          'HP ${state.hp} · Giáp ${state.armor}${state.ward > 0 ? " · Chắn ${state.ward}" : ""}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mc.captionStyle.copyWith(color: mc.nightText),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.ratio,
    required this.fill,
    required this.alignRight,
    required this.height,
    required this.disableMotion,
  });

  final double ratio;
  final Color fill;
  final bool alignRight;
  final double height;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: mc.nightSurface,
        borderRadius: BorderRadius.circular(mc.radiusChip),
      ),
      child: FractionallySizedBox(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: ratio,
        child: AnimatedContainer(
          duration: disableMotion ? Duration.zero : mc.transitionDuration,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(mc.radiusChip),
          ),
        ),
      ),
    );
  }
}

class _EnemyChargeBar extends StatelessWidget {
  const _EnemyChargeBar({required this.botState, required this.botSpec});

  final SoloCombatantState botState;
  final ChampionSpec botSpec;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool danger = botState.qi >= 2;
    return Container(
      key: const ValueKey<String>('arena-enemy-charge-bar'),
      padding: EdgeInsets.symmetric(horizontal: mc.space8, vertical: mc.space4),
      decoration: BoxDecoration(
        color: mc.nightSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(mc.radiusControl),
        border: Border.all(color: danger ? mc.error : mc.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            danger
                ? 'Đối thủ tụ chiêu: sắp tung ${botSpec.skill2.nameVi}'
                : 'Khí lực đối thủ: ${botState.qi}/$maxQi',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: mc.captionStyle.copyWith(
              color: danger ? mc.sunrise : mc.nightText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(mc.radiusChip),
            child: Container(
              height: 5,
              width: double.infinity,
              color: mc.night,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (botState.qi / maxQi).clamp(0.08, 1.0),
                child: ColoredBox(color: danger ? mc.error : mc.sunrise),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Projectile extends StatelessWidget {
  const _Projectile({
    super.key,
    required this.assetPath,
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.size,
    required this.disableMotion,
  });

  final String assetPath;
  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  final double size;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final Widget icon = SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
    if (disableMotion) {
      return Positioned(
        left: toX - size / 2,
        top: toY - size / 2,
        child: icon,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: mc.transitionDuration,
      curve: Curves.easeIn,
      builder: (BuildContext context, double t, Widget? child) {
        final double x = fromX + (toX - fromX) * t - size / 2;
        final double y = fromY + (toY - fromY) * t - size / 2;
        return Positioned(
          left: x,
          top: y,
          child: Opacity(opacity: t < 0.92 ? 1 : (1 - t) * 12.5, child: child),
        );
      },
      child: icon,
    );
  }
}
