import 'package:flutter/widgets.dart';

enum MindClockIconKind {
  clock,
  book,
  user,
  bell,
  calendar,
  check,
  info,
  lock,
  plus,
  minus,
  trash,
  edit,
  sunrise,
}

/// Icon vector nét mảnh thống nhất (24×24 dp, nét 2 px bo tròn theo `docs/55 §5`).
class MindClockIcon extends StatelessWidget {
  const MindClockIcon(
    this.kind, {
    super.key,
    required this.color,
    this.size = 24,
    this.semanticLabel,
  });

  final MindClockIconKind kind;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget painted = CustomPaint(
      size: Size.square(size),
      painter: _MindClockIconPainter(kind: kind, color: color),
    );
    if (semanticLabel == null) {
      return ExcludeSemantics(child: painted);
    }
    return Semantics(label: semanticLabel, child: painted);
  }
}

class _MindClockIconPainter extends CustomPainter {
  const _MindClockIconPainter({
    required this.kind,
    required this.color,
  });

  final MindClockIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24.0;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case MindClockIconKind.clock:
        canvas.drawCircle(Offset(12 * s, 12 * s), 9 * s, paint);
        canvas.drawLine(Offset(12 * s, 7 * s), Offset(12 * s, 12 * s), paint);
        canvas.drawLine(Offset(12 * s, 12 * s), Offset(15.5 * s, 14 * s), paint);
      case MindClockIconKind.book:
        final Path path = Path()
          ..moveTo(4 * s, 6 * s)
          ..lineTo(11 * s, 6 * s)
          ..lineTo(12 * s, 7.5 * s)
          ..lineTo(13 * s, 6 * s)
          ..lineTo(20 * s, 6 * s)
          ..lineTo(20 * s, 19 * s)
          ..lineTo(12 * s, 18 * s)
          ..lineTo(4 * s, 19 * s)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawLine(Offset(12 * s, 7.5 * s), Offset(12 * s, 18 * s), paint);
      case MindClockIconKind.user:
        canvas.drawCircle(Offset(12 * s, 8 * s), 3.5 * s, paint);
        final Path body = Path()
          ..moveTo(5 * s, 19.5 * s)
          ..quadraticBezierTo(12 * s, 14.5 * s, 19 * s, 19.5 * s);
        canvas.drawPath(body, paint);
      case MindClockIconKind.bell:
        final Path bell = Path()
          ..moveTo(6 * s, 16 * s)
          ..lineTo(18 * s, 16 * s)
          ..lineTo(16.8 * s, 10 * s)
          ..quadraticBezierTo(16.3 * s, 5.5 * s, 12 * s, 5.5 * s)
          ..quadraticBezierTo(7.7 * s, 5.5 * s, 7.2 * s, 10 * s)
          ..close();
        canvas.drawPath(bell, paint);
        canvas.drawLine(Offset(10 * s, 19 * s), Offset(14 * s, 19 * s), paint);
      case MindClockIconKind.calendar:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4 * s, 5 * s, 16 * s, 15 * s),
            Radius.circular(2.5 * s),
          ),
          paint,
        );
        canvas.drawLine(Offset(8 * s, 3 * s), Offset(8 * s, 6.5 * s), paint);
        canvas.drawLine(Offset(16 * s, 3 * s), Offset(16 * s, 6.5 * s), paint);
        canvas.drawLine(Offset(4 * s, 9.5 * s), Offset(20 * s, 9.5 * s), paint);
      case MindClockIconKind.check:
        final Path tick = Path()
          ..moveTo(5.5 * s, 12.5 * s)
          ..lineTo(10 * s, 17 * s)
          ..lineTo(18.5 * s, 7.5 * s);
        canvas.drawPath(tick, paint);
      case MindClockIconKind.info:
        canvas.drawCircle(Offset(12 * s, 12 * s), 9 * s, paint);
        canvas.drawLine(Offset(12 * s, 11 * s), Offset(12 * s, 16 * s), paint);
        canvas.drawLine(Offset(12 * s, 8 * s), Offset(12 * s, 8.2 * s), paint);
      case MindClockIconKind.lock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(5.5 * s, 10.5 * s, 13 * s, 9 * s),
            Radius.circular(2 * s),
          ),
          paint,
        );
        final Path shackle = Path()
          ..moveTo(8.5 * s, 10.5 * s)
          ..lineTo(8.5 * s, 8 * s)
          ..arcToPoint(
            Offset(15.5 * s, 8 * s),
            radius: Radius.circular(3.5 * s),
          )
          ..lineTo(15.5 * s, 10.5 * s);
        canvas.drawPath(shackle, paint);
      case MindClockIconKind.plus:
        canvas.drawLine(Offset(12 * s, 5 * s), Offset(12 * s, 19 * s), paint);
        canvas.drawLine(Offset(5 * s, 12 * s), Offset(19 * s, 12 * s), paint);
      case MindClockIconKind.minus:
        canvas.drawLine(Offset(5 * s, 12 * s), Offset(19 * s, 12 * s), paint);
      case MindClockIconKind.trash:
        canvas.drawLine(Offset(5 * s, 7 * s), Offset(19 * s, 7 * s), paint);
        canvas.drawLine(Offset(9.5 * s, 4.5 * s), Offset(14.5 * s, 4.5 * s), paint);
        canvas.drawRect(
          Rect.fromLTWH(7 * s, 7 * s, 10 * s, 12.5 * s),
          paint,
        );
      case MindClockIconKind.edit:
        final Path pen = Path()
          ..moveTo(5 * s, 19 * s)
          ..lineTo(6 * s, 14.5 * s)
          ..lineTo(15.5 * s, 5 * s)
          ..lineTo(19 * s, 8.5 * s)
          ..lineTo(9.5 * s, 18 * s)
          ..close();
        canvas.drawPath(pen, paint);
      case MindClockIconKind.sunrise:
        canvas.drawLine(Offset(4 * s, 17 * s), Offset(20 * s, 17 * s), paint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(12 * s, 17 * s), radius: 5 * s),
          3.14159,
          3.14159,
          false,
          paint,
        );
        canvas.drawLine(Offset(12 * s, 5 * s), Offset(12 * s, 8 * s), paint);
    }
  }

  @override
  bool shouldRepaint(_MindClockIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
