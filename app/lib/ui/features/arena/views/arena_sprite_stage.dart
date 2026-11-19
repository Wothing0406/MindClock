import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';

/// Hoạt cảnh 2D cho từng đấu thủ + vệt chiêu thức trong Đấu trường (`T061 AC-01`).
///
/// - Diễn hoạt nhịp thở `idle`, xung kích khi dùng `Đánh thường / Chiêu 1 / Chiêu 2`,
///   tia/vệt hiệu ứng riêng tướng và nhãn sát thương nổi.
/// - Tự động tắt chuyển động lặp khi `disableMotion == true` hoặc `!animate`.
class ArenaSpriteActor extends StatefulWidget {
  const ArenaSpriteActor({
    super.key,
    required this.spec,
    required this.facingRight,
    required this.isBot,
    required this.disableMotion,
    required this.assetFallbackMode,
    this.animate = true,
    this.actionUsed,
    this.damageTaken = 0,
    this.isWinner = false,
  });

  final ChampionSpec spec;
  final bool facingRight;
  final bool isBot;
  final bool disableMotion;
  final bool assetFallbackMode;
  final bool animate;
  final CombatActionType? actionUsed;
  final int damageTaken;
  final bool isWinner;

  @override
  State<ArenaSpriteActor> createState() => _ArenaSpriteActorState();
}

class _ArenaSpriteActorState extends State<ArenaSpriteActor>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _shouldAnimate => !widget.disableMotion && widget.animate;

  @override
  void initState() {
    super.initState();
    _syncController(triggerBurst: _shouldAnimate);
  }

  @override
  void didUpdateWidget(covariant ArenaSpriteActor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool burst = _shouldAnimate &&
        (oldWidget.actionUsed != widget.actionUsed ||
            oldWidget.damageTaken != widget.damageTaken ||
            (!oldWidget.isWinner && widget.isWinner));
    _syncController(triggerBurst: burst);
  }

  void _syncController({required bool triggerBurst}) {
    if (_shouldAnimate) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 650),
      );
      if (triggerBurst) {
        _controller!.forward(from: 0.0);
      }
    } else {
      _controller?.stop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final Color fxColor = switch (widget.spec.id) {
      ChampionId.haNhan => mc.primary,
      ChampionId.tuyetDinh => mc.sunrise,
      ChampionId.hanBoiPhap => mc.error,
    };

    if (widget.assetFallbackMode) {
      return Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: mc.night,
          borderRadius: BorderRadius.circular(mc.radiusControl),
          border: Border.all(color: mc.outline),
        ),
        child: Text(
          widget.spec.nameVi.substring(0, 2).toUpperCase(),
          style: mc.sectionTitleStyle.copyWith(color: mc.nightText),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller ?? const AlwaysStoppedAnimation<double>(0),
      builder: (BuildContext context, _) {
        final double t = _shouldAnimate ? (_controller?.value ?? 0.0) : 0.0;
        final double bobY =
            _shouldAnimate ? math.sin(t * math.pi) * (widget.isWinner ? -6.0 : -3.0) : 0.0;
        final double lungeX = (!widget.disableMotion && widget.actionUsed != null)
            ? (widget.facingRight ? 6.0 : -6.0)
            : 0.0;

        return SizedBox(
          width: 92,
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              if (widget.actionUsed != null && !widget.disableMotion)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ArenaVfxOverlayPainter(
                      action: widget.actionUsed!,
                      facingRight: widget.facingRight,
                      fxColor: fxColor,
                      highlightColor: mc.nightText,
                      pulse: t,
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(lungeX, bobY),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mc.radiusControl),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: widget.facingRight
                        ? Matrix4.identity()
                        : Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                    child: Image.asset(
                      widget.spec.portraitAssetPath,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 74,
                        height: 74,
                        alignment: Alignment.center,
                        color: mc.night,
                        child: Text(
                          widget.spec.nameVi.substring(0, 2).toUpperCase(),
                          style: mc.bodyStrongStyle.copyWith(color: mc.nightText),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.damageTaken > 0)
                Positioned(
                  top: -2,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mc.space4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: mc.error,
                      borderRadius: BorderRadius.circular(mc.radiusChip),
                    ),
                    child: Text(
                      '-${widget.damageTaken}',
                      style: mc.chipLabelStyle.copyWith(color: mc.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ArenaVfxOverlayPainter extends CustomPainter {
  const _ArenaVfxOverlayPainter({
    required this.action,
    required this.facingRight,
    required this.fxColor,
    required this.highlightColor,
    required this.pulse,
  });

  final CombatActionType action;
  final bool facingRight;
  final Color fxColor;
  final Color highlightColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final double dir = facingRight ? 1.0 : -1.0;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Hào quang kích hoạt chiêu 1 / chiêu 2
    if (action != CombatActionType.basic) {
      final Paint aura = Paint()
        ..color = fxColor.withValues(alpha: action == CombatActionType.skill2 ? 0.42 : 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = action == CombatActionType.skill2 ? 4.0 : 2.5;
      canvas.drawCircle(center, 34 + pulse * 5, aura);
    }

    // Vệt chém / tia năng lượng theo hướng mặt
    final Paint slash = Paint()
      ..color = highlightColor.withValues(alpha: 0.85)
      ..strokeWidth = action == CombatActionType.skill2 ? 3.5 : 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Rect arcRect = Rect.fromCircle(
      center: Offset(center.dx + dir * 10, center.dy),
      radius: 30,
    );
    final double startAngle = facingRight ? -math.pi / 3 : math.pi * 2 / 3;
    canvas.drawArc(arcRect, startAngle, math.pi * 0.65, false, slash);
  }

  @override
  bool shouldRepaint(covariant _ArenaVfxOverlayPainter oldDelegate) =>
      oldDelegate.action != action ||
      oldDelegate.facingRight != facingRight ||
      oldDelegate.pulse != pulse ||
      oldDelegate.fxColor != fxColor;
}

/// Dải hiển thị bước tích Qi (trả lời 1 câu = Đánh thường +1 Qi -> đủ 1/2 Qi dùng Chiêu).
class ArenaQiGuideStrip extends StatelessWidget {
  const ArenaQiGuideStrip({
    super.key,
    required this.currentQi,
    required this.maxQi,
  });

  final int currentQi;
  final int maxQi;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      key: const ValueKey<String>('arena-qi-guide-strip'),
      width: double.infinity,
      padding: EdgeInsets.all(mc.space12),
      decoration: BoxDecoration(
        color: mc.nightSurface,
        borderRadius: BorderRadius.circular(mc.radiusChip),
        border: Border.all(color: mc.primary),
      ),
      child: Wrap(
        spacing: mc.space8,
        runSpacing: mc.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          MindClockStatusPill(
            label: 'Qi: $currentQi/$maxQi',
            accentWarm: currentQi == 0,
          ),
          Text(
            'Đúng 1 câu -> Đánh thường (+1 Qi) · 1 Qi mở Chiêu 1 · 2 Qi mở Chiêu 2',
            style: mc.captionStyle.copyWith(color: mc.nightText),
          ),
        ],
      ),
    );
  }
}
