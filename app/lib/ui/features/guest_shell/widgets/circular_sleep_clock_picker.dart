import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_icon.dart';

enum _DragTarget { none, bedtime, wake }

/// Đồng hồ xoay 24 giờ chọn Giờ đi ngủ & Giờ báo thức dậy đồng bộ [MindClockTheme].
class CircularSleepClockPicker extends StatefulWidget {
  const CircularSleepClockPicker({
    super.key,
    required this.bedtimeMinutes,
    required this.wakeMinutes,
    required this.onBedtimeChanged,
    required this.onWakeChanged,
    this.size = 256,
  });

  /// Tổng số phút trong ngày [0, 1439] của giờ đi ngủ.
  final int bedtimeMinutes;

  /// Tổng số phút trong ngày [0, 1439] của giờ báo thức dậy.
  final int wakeMinutes;

  final ValueChanged<int> onBedtimeChanged;
  final ValueChanged<int> onWakeChanged;
  final double size;

  /// Tính thời lượng ngủ (phút) theo vòng 24 giờ.
  static int sleepDurationMinutes(int bedtimeMinutes, int wakeMinutes) {
    final int diff = (wakeMinutes - bedtimeMinutes) % 1440;
    return diff < 0 ? diff + 1440 : diff;
  }

  /// Định dạng `HH:mm`.
  static String formatHm(int totalMinutes) {
    final int normalized = ((totalMinutes % 1440) + 1440) % 1440;
    final int h = normalized ~/ 60;
    final int m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  State<CircularSleepClockPicker> createState() =>
      _CircularSleepClockPickerState();
}

class _CircularSleepClockPickerState extends State<CircularSleepClockPicker> {
  _DragTarget _activeTarget = _DragTarget.none;

  static const double _trackWidth = 26;
  static const double _handleRadius = 18;

  double _minutesToAngle(int minutes) {
    final int normalized = ((minutes % 1440) + 1440) % 1440;
    return (normalized / 1440.0) * 2 * math.pi - math.pi / 2;
  }

  int _offsetToSnappedMinutes(Offset localPosition, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset delta = localPosition - center;
    double angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final int rawMinutes = ((angle / (2 * math.pi)) * 1440).round();
    return ((rawMinutes / 5).round() * 5) % 1440;
  }

  Offset _handleCenter(int minutes, Size size) {
    final double radius = (math.min(size.width, size.height) / 2) - 22;
    final double angle = _minutesToAngle(minutes);
    return Offset(
      size.width / 2 + radius * math.cos(angle),
      size.height / 2 + radius * math.sin(angle),
    );
  }

  void _handlePointerDown(PointerDownEvent event, Size size) {
    final Offset bedPos = _handleCenter(widget.bedtimeMinutes, size);
    final Offset wakePos = _handleCenter(widget.wakeMinutes, size);
    final double distBed = (event.localPosition - bedPos).distance;
    final double distWake = (event.localPosition - wakePos).distance;

    if (distWake <= 44 || distBed <= 44) {
      setState(() {
        _activeTarget =
            distWake <= distBed ? _DragTarget.wake : _DragTarget.bedtime;
      });
      return;
    }

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double touchDist = (event.localPosition - center).distance;
    final double ringRadius = (math.min(size.width, size.height) / 2) - 22;
    if ((touchDist - ringRadius).abs() <= 36) {
      setState(() {
        _activeTarget =
            distWake <= distBed ? _DragTarget.wake : _DragTarget.bedtime;
      });
      _emitUpdatedMinutes(event.localPosition, size);
    }
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    if (_activeTarget == _DragTarget.none) return;
    _emitUpdatedMinutes(event.localPosition, size);
  }

  void _emitUpdatedMinutes(Offset localPosition, Size size) {
    final int next = _offsetToSnappedMinutes(localPosition, size);
    if (_activeTarget == _DragTarget.wake) {
      if (next != widget.wakeMinutes) {
        widget.onWakeChanged(next);
      }
    } else if (_activeTarget == _DragTarget.bedtime) {
      if (next != widget.bedtimeMinutes) {
        widget.onBedtimeChanged(next);
      }
    }
  }

  void _handlePointerUpOrCancel() {
    if (_activeTarget != _DragTarget.none) {
      setState(() => _activeTarget = _DragTarget.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final int sleepMins = CircularSleepClockPicker.sleepDurationMinutes(
      widget.bedtimeMinutes,
      widget.wakeMinutes,
    );
    final int sleepHours = sleepMins ~/ 60;
    final int sleepRemMins = sleepMins % 60;
    final String durationLabel = sleepRemMins == 0
        ? '$sleepHours giờ'
        : '$sleepHours giờ $sleepRemMins phút';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : widget.size;
        final double dialSize = math.min(widget.size, maxW).clamp(200.0, 290.0);
        final Size canvasSize = Size(dialSize, dialSize);
        final Offset bedCenter = _handleCenter(widget.bedtimeMinutes, canvasSize);
        final Offset wakeCenter = _handleCenter(widget.wakeMinutes, canvasSize);

        return Center(
          child: Semantics(
            label:
                'Đồng hồ lịch ngủ 24 giờ. Đi ngủ ${CircularSleepClockPicker.formatHm(widget.bedtimeMinutes)}, báo thức ${CircularSleepClockPicker.formatHm(widget.wakeMinutes)}, thời gian ngủ $durationLabel.',
            child: Listener(
              key: const ValueKey<String>('circular-sleep-clock'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (PointerDownEvent e) =>
                  _handlePointerDown(e, canvasSize),
              onPointerMove: (PointerMoveEvent e) =>
                  _handlePointerMove(e, canvasSize),
              onPointerUp: (_) => _handlePointerUpOrCancel(),
              onPointerCancel: (_) => _handlePointerUpOrCancel(),
              child: SizedBox(
                width: dialSize,
                height: dialSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CustomPaint(
                      size: canvasSize,
                      painter: _SleepClockPainter(
                        mc: mc,
                        bedtimeMinutes: widget.bedtimeMinutes,
                        wakeMinutes: widget.wakeMinutes,
                        trackWidth: _trackWidth,
                      ),
                    ),
                    // Tâm đồng hồ: thời lượng ngủ co giãn an toàn ở 320dp 200%
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: dialSize * 0.46,
                        maxHeight: dialSize * 0.40,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              durationLabel,
                              key: const ValueKey<String>(
                                  'circular-sleep-duration-text'),
                              textAlign: TextAlign.center,
                              style: mc.sectionTitleStyle.copyWith(
                                color: mc.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: mc.space4),
                            Text(
                              'Thời gian ngủ',
                              textAlign: TextAlign.center,
                              style: mc.captionStyle.copyWith(
                                color: mc.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nút kéo Giờ đi ngủ
                    Positioned(
                      left: bedCenter.dx - _handleRadius,
                      top: bedCenter.dy - _handleRadius,
                      child: _DialHandle(
                        key: const ValueKey<String>('circular-bedtime-handle'),
                        color: mc.primary,
                        borderColor: mc.nightText,
                        icon: MindClockIconKind.clock,
                        iconColor: mc.onPrimary,
                        radius: _handleRadius,
                        active: _activeTarget == _DragTarget.bedtime,
                      ),
                    ),
                    // Nút kéo Giờ báo thức
                    Positioned(
                      left: wakeCenter.dx - _handleRadius,
                      top: wakeCenter.dy - _handleRadius,
                      child: _DialHandle(
                        key: const ValueKey<String>('circular-wake-handle'),
                        color: mc.sunrise,
                        borderColor: mc.nightText,
                        icon: MindClockIconKind.bell,
                        iconColor: mc.night,
                        radius: _handleRadius,
                        active: _activeTarget == _DragTarget.wake,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialHandle extends StatelessWidget {
  const _DialHandle({
    super.key,
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.radius,
    required this.active,
  });

  final Color color;
  final Color borderColor;
  final MindClockIconKind icon;
  final Color iconColor;
  final double radius;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: active ? 2.5 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: MindClockIcon(icon, size: 17, color: iconColor),
    );
  }
}

class _SleepClockPainter extends CustomPainter {
  _SleepClockPainter({
    required this.mc,
    required this.bedtimeMinutes,
    required this.wakeMinutes,
    required this.trackWidth,
  });

  final MindClockTheme mc;
  final int bedtimeMinutes;
  final int wakeMinutes;
  final double trackWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double ringRadius = (math.min(size.width, size.height) / 2) - 22;

    // 1. Vòng nền 24h đồng bộ nền trang vở sáng
    final Paint trackPaint = Paint()
      ..color = mc.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, ringRadius, trackPaint);

    // 2. Vạch chia 24 giờ
    final Paint tickPaint = Paint()
      ..color = mc.outline
      ..strokeWidth = 1.2;
    for (int hour = 0; hour < 24; hour++) {
      final double a = (hour / 24.0) * 2 * math.pi - math.pi / 2;
      final bool major = hour % 2 == 0;
      final double rIn = ringRadius - (major ? trackWidth * 0.44 : trackWidth * 0.28);
      final double rOut = ringRadius + (major ? trackWidth * 0.44 : trackWidth * 0.28);
      canvas.drawLine(
        Offset(center.dx + rIn * math.cos(a), center.dy + rIn * math.sin(a)),
        Offset(center.dx + rOut * math.cos(a), center.dy + rOut * math.sin(a)),
        tickPaint,
      );
    }

    // 3. Cung thời gian ngủ từ bedtime -> wake
    final double startAngle = (bedtimeMinutes / 1440.0) * 2 * math.pi - math.pi / 2;
    final int sleepMins =
        CircularSleepClockPicker.sleepDurationMinutes(bedtimeMinutes, wakeMinutes);
    final double sweepAngle = (sleepMins / 1440.0) * 2 * math.pi;

    if (sweepAngle > 0.01) {
      final Rect arcRect = Rect.fromCircle(center: center, radius: ringRadius);
      final Paint arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: <Color>[mc.primary, mc.sunrise, mc.primary],
          transform: GradientRotation(startAngle),
        ).createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);
    }

    // 4. Số giờ 0, 2, 4, ..., 22 bên trong vòng
    final double labelRadius = ringRadius - trackWidth * 0.95;
    for (int hour = 0; hour < 24; hour += 2) {
      final double a = (hour / 24.0) * 2 * math.pi - math.pi / 2;
      final Offset pos = Offset(
        center.dx + labelRadius * math.cos(a),
        center.dy + labelRadius * math.sin(a),
      );
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: TextStyle(
            color: hour % 6 == 0 ? mc.ink : mc.inkMuted,
            fontSize: hour % 6 == 0 ? 12 : 11,
            fontWeight: hour % 6 == 0 ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // 5. Ký hiệu vector trăng (0h) & nắng (12h) tinh gọn bên trong mặt đồng hồ
    final double iconRingRadius = labelRadius - 15;
    // 0h (trên đỉnh): trăng khuyết
    final Offset moonPos = Offset(center.dx, center.dy - iconRingRadius);
    canvas.drawCircle(
      moonPos,
      4.5,
      Paint()..color = mc.primary.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      moonPos + const Offset(2.2, -1.2),
      3.8,
      Paint()..color = mc.surface,
    );

    // 12h (đáy): mặt trời nhỏ
    final Offset sunPos = Offset(center.dx, center.dy + iconRingRadius);
    canvas.drawCircle(
      sunPos,
      4.2,
      Paint()..color = mc.sunrise,
    );
  }

  @override
  bool shouldRepaint(covariant _SleepClockPainter oldDelegate) {
    return oldDelegate.bedtimeMinutes != bedtimeMinutes ||
        oldDelegate.wakeMinutes != wakeMinutes ||
        oldDelegate.mc != mc;
  }
}
