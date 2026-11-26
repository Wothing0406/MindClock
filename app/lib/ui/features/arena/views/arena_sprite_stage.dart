import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';

/// Xác định clip diễn hoạt hiện tại cho tướng dựa trên kết quả round (`T064`).
String resolveArenaSpriteClip({
  CombatActionType? actionUsed,
  int damageTaken = 0,
  int healAmount = 0,
  bool isStunned = false,
  bool isWinner = false,
}) {
  if (isWinner) return 'victory';
  if (isStunned) return 'stun';
  if (actionUsed != null) {
    return switch (actionUsed) {
      CombatActionType.basic => 'basic',
      CombatActionType.skill1 => 'skill1',
      CombatActionType.skill2 => 'skill2',
    };
  }
  if (damageTaken > 0) return 'hurt';
  if (healAmount > 0) return 'heal';
  return 'idle';
}

/// Hoạt cảnh 2D theo chuỗi frame gốc của từng tướng trong Đấu trường (`T061`/`T064`).
///
/// - Tự động dùng `runtime/idle.webp` khi ở trạng thái chờ và `runtime/frames/<action>/f00..f05.webp`
///   cho các pha đánh thường, tung chiêu 1/2, trúng đòn, choáng, hồi phục và chiến thắng.
/// - Tôn trọng hướng vẽ gốc (`spec.nativeFacingRight`) để hai bên luôn nhìn về nhau.
/// - Khi `disableMotion == true` hoặc `!animate`: chỉ hiển thị pose tĩnh tương ứng, không giữ ticker lặp.
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
    this.healAmount = 0,
    this.isStunned = false,
    this.isWinner = false,
    this.size = 86.0,
    this.showAnimatedIdle = true,
  });

  final ChampionSpec spec;
  final bool facingRight;
  final bool isBot;
  final bool disableMotion;
  final bool assetFallbackMode;
  final bool animate;
  final CombatActionType? actionUsed;
  final int damageTaken;
  final int healAmount;
  final bool isStunned;
  final bool isWinner;
  final double size;
  final bool showAnimatedIdle;

  @override
  State<ArenaSpriteActor> createState() => _ArenaSpriteActorState();
}

class _ArenaSpriteActorState extends State<ArenaSpriteActor>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _shouldAnimate => !widget.disableMotion && widget.animate;

  String get _activeClip => resolveArenaSpriteClip(
        actionUsed: widget.actionUsed,
        damageTaken: widget.damageTaken,
        healAmount: widget.healAmount,
        isStunned: widget.isStunned,
        isWinner: widget.isWinner,
      );

  @override
  void initState() {
    super.initState();
    _syncController(
      triggerBurst: _shouldAnimate && _activeClip != 'idle',
      clip: _activeClip,
    );
  }

  @override
  void didUpdateWidget(covariant ArenaSpriteActor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String prevClip = resolveArenaSpriteClip(
      actionUsed: oldWidget.actionUsed,
      damageTaken: oldWidget.damageTaken,
      healAmount: oldWidget.healAmount,
      isStunned: oldWidget.isStunned,
      isWinner: oldWidget.isWinner,
    );
    final String nextClip = _activeClip;
    final bool stateChanged = prevClip != nextClip ||
        oldWidget.spec.id != widget.spec.id ||
        oldWidget.damageTaken != widget.damageTaken ||
        oldWidget.healAmount != widget.healAmount;
    final bool burst = _shouldAnimate && nextClip != 'idle' && stateChanged;
    _syncController(triggerBurst: burst, clip: nextClip);
  }

  void _syncController({required bool triggerBurst, required String clip}) {
    final Duration duration = Duration(
      milliseconds: widget.spec.durationMsForAction(clip),
    );
    if (_shouldAnimate && clip != 'idle') {
      _controller ??= AnimationController(vsync: this, duration: duration);
      if (_controller!.duration != duration) {
        _controller!.duration = duration;
      }
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

  String _resolveAssetPath(String clip, double progress, bool isAnimating) {
    if (!_shouldAnimate) {
      return widget.spec.poseAssetFor(clip);
    }
    if (clip == 'idle') {
      return widget.showAnimatedIdle
          ? widget.spec.animatedIdleAssetPath
          : widget.spec.portraitAssetPath;
    }
    final List<String> frames = widget.spec.framesForAction(clip);
    if (frames.isEmpty) {
      return widget.spec.poseAssetFor(clip);
    }
    if (isAnimating) {
      final int idx =
          (progress * frames.length).floor().clamp(0, frames.length - 1);
      return frames[idx];
    }
    if (clip == 'victory' || clip == 'stun') {
      return widget.spec.poseAssetFor(clip);
    }
    return widget.showAnimatedIdle
        ? widget.spec.animatedIdleAssetPath
        : widget.spec.poseAssetFor('idle');
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final double actorSize = widget.size;
    final String clip = _activeClip;
    final Color fxColor = switch (widget.spec.id) {
      ChampionId.haNhan => mc.primary,
      ChampionId.tuyetDinh => mc.sunrise,
      ChampionId.hanBoiPhap => mc.error,
    };

    if (widget.assetFallbackMode) {
      return Container(
        width: actorSize,
        height: actorSize,
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

    final bool flipHorizontal =
        widget.facingRight != widget.spec.nativeFacingRight;

    return AnimatedBuilder(
      animation: _controller ?? const AlwaysStoppedAnimation<double>(0),
      builder: (BuildContext context, _) {
        final bool isAnimating =
            _shouldAnimate && (_controller?.isAnimating ?? false);
        final double t = isAnimating ? (_controller?.value ?? 0.0) : 0.0;
        final String assetPath = _resolveAssetPath(clip, t, isAnimating);
        final double lungeX = (isAnimating && widget.actionUsed != null)
            ? math.sin(t * math.pi) * (widget.facingRight ? 8.0 : -8.0)
            : 0.0;
        final double hopY = (isAnimating && widget.isWinner)
            ? math.sin(t * math.pi) * -6.0
            : 0.0;

        return SizedBox(
          width: actorSize + 18,
          height: actorSize + 14,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              if (widget.actionUsed != null && isAnimating)
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
                offset: Offset(lungeX, hopY),
                child: Transform(
                  alignment: Alignment.center,
                  transform: flipHorizontal
                      ? Matrix4.diagonal3Values(-1.0, 1.0, 1.0)
                      : Matrix4.identity(),
                  child: Image.asset(
                    assetPath,
                    key: ValueKey<String>(
                      'arena-sprite-${widget.spec.assetSlug}-${widget.isBot ? "bot" : "self"}-$clip',
                    ),
                    width: actorSize,
                    height: actorSize,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Container(
                      width: actorSize,
                      height: actorSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mc.night,
                        borderRadius: BorderRadius.circular(mc.radiusControl),
                        border: Border.all(color: mc.outline),
                      ),
                      child: Text(
                        widget.spec.nameVi.substring(0, 2).toUpperCase(),
                        style: mc.bodyStrongStyle.copyWith(color: mc.nightText),
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
                )
              else if (widget.healAmount > 0)
                Positioned(
                  top: -2,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mc.space4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: mc.primary,
                      borderRadius: BorderRadius.circular(mc.radiusChip),
                    ),
                    child: Text(
                      '+${widget.healAmount}',
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
