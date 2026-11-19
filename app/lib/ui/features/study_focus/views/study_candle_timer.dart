import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';

/// Đồng hồ "Đốt nến · Đếm giờ tự do" (`T059`, `docs/01-product/08`, `docs/02-engineering/07`).
///
/// - Không giới hạn trần 120 phút; chu kỳ nến tự cuộn mỗi 60 phút để ngọn lửa luôn sáng dịu.
/// - Tôn trọng `reduceMotion` và `animate` (tắt lặp AnimationController trong widget test tĩnh).
class StudyCandleTimer extends StatefulWidget {
  const StudyCandleTimer({
    super.key,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.reduceMotion,
    this.animate = true,
  });

  final int elapsedSeconds;
  final bool isRunning;
  final bool reduceMotion;
  final bool animate;

  @override
  State<StudyCandleTimer> createState() => _StudyCandleTimerState();
}

class _StudyCandleTimerState extends State<StudyCandleTimer>
    with SingleTickerProviderStateMixin {
  AnimationController? _flameController;

  bool get _shouldAnimate =>
      !widget.reduceMotion && widget.animate && widget.isRunning;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant StudyCandleTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController();
  }

  void _syncController() {
    if (_shouldAnimate) {
      _flameController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
      if (!_flameController!.isAnimating) {
        _flameController!.repeat(reverse: true);
      }
    } else {
      _flameController?.stop();
    }
  }

  @override
  void dispose() {
    _flameController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final int cycleNumber = (widget.elapsedSeconds ~/ 3600) + 1;
    final double cycleProgress =
        ((widget.elapsedSeconds % 3600) / 3600.0).clamp(0.0, 1.0);
    final int hours = widget.elapsedSeconds ~/ 3600;
    final int mins = (widget.elapsedSeconds % 3600) ~/ 60;

    return Semantics(
      key: const ValueKey<String>('study-candle-timer'),
      label:
          'Chế độ đốt nến đếm giờ tự do, đã học $hours giờ $mins phút, chu kỳ nến thứ $cycleNumber',
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 112,
            height: 124,
            child: AnimatedBuilder(
              animation: _flameController ?? const AlwaysStoppedAnimation<double>(0),
              builder: (BuildContext context, _) {
                final double pulse =
                    _shouldAnimate ? (_flameController?.value ?? 0.0) : 0.35;
                return CustomPaint(
                  painter: _CandlePainter(
                    cycleProgress: cycleProgress,
                    pulse: pulse,
                    isRunning: widget.isRunning,
                    waxColor: mc.paper,
                    waxShadowColor: mc.outline,
                    flameOuterColor: mc.sunrise,
                    flameInnerColor: mc.nightText,
                    holderColor: mc.nightSurface,
                    glowColor: mc.sunriseSoft,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: mc.space8),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space4,
            alignment: WrapAlignment.center,
            children: <Widget>[
              MindClockStatusPill(
                label: 'Nến chu kỳ #$cycleNumber',
                accentWarm: true,
              ),
              if (widget.elapsedSeconds >= 120 * 60)
                const MindClockStatusPill(
                  key: ValueKey<String>('study-candle-over-120-pill'),
                  label: 'Đã vượt 120 phút',
                  accentWarm: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  const _CandlePainter({
    required this.cycleProgress,
    required this.pulse,
    required this.isRunning,
    required this.waxColor,
    required this.waxShadowColor,
    required this.flameOuterColor,
    required this.flameInnerColor,
    required this.holderColor,
    required this.glowColor,
  });

  final double cycleProgress;
  final double pulse;
  final bool isRunning;
  final Color waxColor;
  final Color waxShadowColor;
  final Color flameOuterColor;
  final Color flameInnerColor;
  final Color holderColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double baseBottom = size.height - 10;

    // Đế nến
    final RRect saucer = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, baseBottom), width: 64, height: 10),
      const Radius.circular(5),
    );
    canvas.drawRRect(saucer, Paint()..color = holderColor);

    // Thân sáp cao từ 28dp..58dp (còn tối thiểu 28dp để luôn giữ lửa đẹp >120p)
    const double maxBodyHeight = 58;
    const double minBodyHeight = 28;
    final double bodyHeight =
        maxBodyHeight - (maxBodyHeight - minBodyHeight) * cycleProgress;
    final double waxTop = baseBottom - 5 - bodyHeight;
    const double bodyWidth = 34;

    final RRect waxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bodyWidth / 2, waxTop, bodyWidth, bodyHeight),
      const Radius.circular(7),
    );
    canvas.drawRRect(waxRect, Paint()..color = waxColor);

    // Đổ bóng cạnh phải nến
    final RRect waxShade = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 4, waxTop + 2, bodyWidth / 2 - 4, bodyHeight - 4),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      waxShade,
      Paint()..color = waxShadowColor.withValues(alpha: 0.45),
    );

    // Bấc nến
    canvas.drawLine(
      Offset(cx, waxTop),
      Offset(cx, waxTop - 7),
      Paint()
        ..color = holderColor
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    if (!isRunning) {
      return;
    }

    // Quầng sáng ấm quanh ngọn lửa
    final double flicker = math.sin(pulse * math.pi) * 2.2;
    final Offset flameCenter = Offset(cx, waxTop - 19 - flicker * 0.4);
    canvas.drawCircle(
      flameCenter,
      20 + flicker,
      Paint()..color = glowColor.withValues(alpha: 0.28),
    );

    // Ngọn lửa ngoài
    final Path outerFlame = Path()
      ..moveTo(cx, waxTop - 32 - flicker)
      ..quadraticBezierTo(cx + 10, waxTop - 16, cx, waxTop - 7)
      ..quadraticBezierTo(cx - 10, waxTop - 16, cx, waxTop - 32 - flicker)
      ..close();
    canvas.drawPath(outerFlame, Paint()..color = flameOuterColor);

    // Lõi lửa sáng
    final Path innerFlame = Path()
      ..moveTo(cx, waxTop - 24 - flicker * 0.5)
      ..quadraticBezierTo(cx + 4.5, waxTop - 15, cx, waxTop - 9)
      ..quadraticBezierTo(cx - 4.5, waxTop - 15, cx, waxTop - 24 - flicker * 0.5)
      ..close();
    canvas.drawPath(innerFlame, Paint()..color = flameInnerColor);
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) {
    return oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.waxColor != waxColor ||
        oldDelegate.flameOuterColor != flameOuterColor;
  }
}
