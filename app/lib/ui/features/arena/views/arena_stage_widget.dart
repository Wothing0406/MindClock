import 'package:flutter/widgets.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_icon.dart';

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
  });

  final SoloCombatantState playerState;
  final SoloCombatantState botState;
  final bool compact;
  final bool reduceMotion;
  final bool skipEffects;
  final bool soundEnabled;
  final bool assetFallbackMode;
  final SoloRoundResolution? lastResolution;

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
      padding: EdgeInsets.all(compact ? mc.space12 : mc.space16),
      decoration: BoxDecoration(
        color: mc.night,
        borderRadius: BorderRadius.circular(mc.radiusCard),
        border: Border.all(color: mc.nightSurface, width: 1.5),
      ),
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
                    : 'Sân luyện · Đồ họa vector tạm (art gốc chờ duyệt G4)',
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
                deltaActionUsed: lastResolution?.settle.playerADelta.actionUsed,
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
                deltaActionUsed: lastResolution?.settle.playerBDelta.actionUsed,
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
    required this.deltaActionUsed,
  });

  final SoloCombatantState state;
  final ChampionSpec spec;
  final bool facingRight;
  final bool compact;
  final bool disableMotion;
  final bool assetFallbackMode;
  final int deltaDamageTaken;
  final CombatActionType? deltaActionUsed;

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
            if (!compact) ...<Widget>[
              SizedBox(height: mc.space8),
              Center(
                child: assetFallbackMode
                    ? Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mc.night,
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          border: Border.all(color: mc.outline),
                        ),
                        child: Text(
                          spec.nameVi.substring(0, 2).toUpperCase(),
                          style: mc.sectionTitleStyle.copyWith(
                            color: mc.nightText,
                          ),
                        ),
                      )
                    : CustomPaint(
                        size: const Size(76, 68),
                        painter: _ChampionCrestPainter(
                          championId: state.championId,
                          facingRight: facingRight,
                          primaryColor: accentColor,
                          strokeColor: mc.nightText,
                          highlightColor: mc.sunrise,
                          activePulse: !disableMotion && deltaActionUsed != null,
                        ),
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

/// Hình tượng vector placeholder riêng cho từng tướng (không đóng gói art nghiên cứu chưa duyệt quyền).
class _ChampionCrestPainter extends CustomPainter {
  const _ChampionCrestPainter({
    required this.championId,
    required this.facingRight,
    required this.primaryColor,
    required this.strokeColor,
    required this.highlightColor,
    required this.activePulse,
  });

  final ChampionId championId;
  final bool facingRight;
  final Color primaryColor;
  final Color strokeColor;
  final Color highlightColor;
  final bool activePulse;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint accent = Paint()
      ..color = activePulse ? highlightColor : primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = activePulse ? 2.6 : 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Đường nền chân (anchor baseline chung cho cả hai đấu thủ)
    canvas.drawLine(Offset(6, h - 6), Offset(w - 6, h - 6), accent);

    canvas.save();
    if (!facingRight) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    switch (championId) {
      case ChampionId.haNhan:
        // Biểu tượng sách mở & thế đứng vững
        canvas.drawCircle(Offset(w * 0.44, h * 0.28), 9, stroke);
        canvas.drawLine(Offset(w * 0.44, h * 0.42), Offset(w * 0.44, h * 0.72), stroke);
        canvas.drawLine(Offset(w * 0.44, h * 0.72), Offset(w * 0.30, h - 7), stroke);
        canvas.drawLine(Offset(w * 0.44, h * 0.72), Offset(w * 0.58, h - 7), stroke);
        canvas.drawLine(Offset(w * 0.30, h * 0.54), Offset(w * 0.72, h * 0.48), accent);
        canvas.drawRect(Rect.fromLTWH(w * 0.64, h * 0.36, 12, 16), accent);
      case ChampionId.tuyetDinh:
        // Biểu tượng bút kiếm tốc độ cao
        canvas.drawCircle(Offset(w * 0.40, h * 0.28), 9, stroke);
        canvas.drawLine(Offset(w * 0.40, h * 0.42), Offset(w * 0.46, h * 0.70), stroke);
        canvas.drawLine(Offset(w * 0.46, h * 0.70), Offset(w * 0.28, h - 7), stroke);
        canvas.drawLine(Offset(w * 0.46, h * 0.70), Offset(w * 0.60, h - 7), stroke);
        canvas.drawLine(Offset(w * 0.34, h * 0.54), Offset(w * 0.84, h * 0.24), accent);
        canvas.drawLine(Offset(w * 0.74, h * 0.22), Offset(w * 0.84, h * 0.24), accent);
      case ChampionId.hanBoiPhap:
        // Biểu tượng tháp chắn phòng thủ
        canvas.drawCircle(Offset(w * 0.42, h * 0.28), 9, stroke);
        canvas.drawLine(Offset(w * 0.42, h * 0.42), Offset(w * 0.42, h * 0.72), stroke);
        canvas.drawLine(Offset(w * 0.42, h * 0.72), Offset(w * 0.30, h - 7), stroke);
        canvas.drawLine(Offset(w * 0.42, h * 0.72), Offset(w * 0.54, h - 7), stroke);
        final Path tower = Path()
          ..moveTo(w * 0.60, h - 7)
          ..lineTo(w * 0.65, h * 0.30)
          ..lineTo(w * 0.77, h * 0.30)
          ..lineTo(w * 0.82, h - 7)
          ..close();
        canvas.drawPath(tower, accent);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChampionCrestPainter oldDelegate) =>
      oldDelegate.championId != championId ||
      oldDelegate.facingRight != facingRight ||
      oldDelegate.activePulse != activePulse ||
      oldDelegate.primaryColor != primaryColor;
}
