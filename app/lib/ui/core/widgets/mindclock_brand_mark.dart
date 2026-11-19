import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mindclock_theme.dart';

/// Biểu tượng thương hiệu MindClock vẽ theo tỷ lệ chuẩn 512x512 (`assets/brand/mindclock-mark.svg`).
class MindClockBrandMark extends StatelessWidget {
  const MindClockBrandMark({
    super.key,
    this.size = 72,
    this.showBackground = true,
  });

  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: 'Biểu tượng MindClock',
        image: true,
        child: CustomPaint(
          painter: _MindClockMarkPainter(
            backgroundColor: mc.night,
            ringColor: mc.primary,
            sunriseColor: mc.sunrise,
            handAndCornerColor: mc.paper,
            showBackground: showBackground,
          ),
        ),
      ),
    );
  }
}

class _MindClockMarkPainter extends CustomPainter {
  const _MindClockMarkPainter({
    required this.backgroundColor,
    required this.ringColor,
    required this.sunriseColor,
    required this.handAndCornerColor,
    required this.showBackground,
  });

  final Color backgroundColor;
  final Color ringColor;
  final Color sunriseColor;
  final Color handAndCornerColor;
  final bool showBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height) / 512.0;
    canvas.save();
    canvas.scale(s, s);

    if (showBackground) {
      final Paint bgPaint = Paint()..color = backgroundColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 512, 512),
          const Radius.circular(112),
        ),
        bgPaint,
      );
    }

    final Paint ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 31
      ..strokeCap = StrokeCap.round;

    final Path arc1 = Path()
      ..moveTo(354, 111)
      ..cubicTo(322, 92, 286, 82, 249, 82)
      ..cubicTo(150, 82, 76, 158, 76, 256)
      ..cubicTo(76, 352, 154, 430, 251, 430)
      ..cubicTo(283, 430, 310, 424, 334, 411);
    canvas.drawPath(arc1, ringPaint);

    final Path arc2 = Path()
      ..moveTo(411, 185)
      ..cubicTo(435, 234, 436, 289, 413, 337);
    canvas.drawPath(arc2, ringPaint);

    canvas.drawCircle(
      const Offset(385, 143),
      17,
      Paint()..color = sunriseColor,
    );

    final Paint handPaint = Paint()
      ..color = handAndCornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path hands = Path()
      ..moveTo(171, 257)
      ..lineTo(250, 257)
      ..lineTo(226, 322);
    canvas.drawPath(hands, handPaint);
    canvas.drawCircle(
      const Offset(250, 257),
      16,
      Paint()..color = handAndCornerColor,
    );

    final Path pageCorner = Path()
      ..moveTo(329, 412)
      ..cubicTo(346, 365, 372, 351, 415, 335)
      ..cubicTo(408, 375, 377, 410, 329, 412)
      ..close();
    canvas.drawPath(pageCorner, Paint()..color = handAndCornerColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MindClockMarkPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.sunriseColor != sunriseColor ||
        oldDelegate.handAndCornerColor != handAndCornerColor ||
        oldDelegate.showBackground != showBackground;
  }
}

/// Thanh tiến trình tải chuẩn hóa dùng chung cho Boot Screen và Đấu trường Loading.
class MindClockLoadingProgressBar extends StatelessWidget {
  const MindClockLoadingProgressBar({
    super.key,
    this.value,
    this.onNightSurface = true,
  });

  final double? value;
  final bool onNightSurface;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double? effectiveValue =
        (value == null && reduceMotion) ? 0.65 : value;
    final Color trackColor = onNightSurface ? mc.nightSurface : mc.outline;
    final Color fillColor = onNightSurface ? mc.sunrise : mc.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(mc.radiusChip),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: effectiveValue,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      ),
    );
  }
}
