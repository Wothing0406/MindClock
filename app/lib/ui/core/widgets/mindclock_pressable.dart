import 'package:flutter/widgets.dart';

import '../theme/mindclock_theme.dart';

/// Điều khiển chạm chuẩn của MindClock thay thế hoàn toàn InkWell / Material ripple.
class MindClockPressable extends StatefulWidget {
  const MindClockPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.selected = false,
    this.semanticLabel,
    this.minSize,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool selected;
  final String? semanticLabel;
  final double? minSize;
  final BorderRadius? borderRadius;

  @override
  State<MindClockPressable> createState() => _MindClockPressableState();
}

class _MindClockPressableState extends State<MindClockPressable> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool interactive = widget.enabled && widget.onPressed != null;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Duration duration = reduceMotion ? Duration.zero : mc.pressDuration;
    final double targetMin = widget.minSize ?? mc.minTouchTarget;
    final bool isPressed = _pressed && interactive;

    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: targetMin,
        minHeight: targetMin,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
    );

    if (_focused && interactive) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(mc.radiusControl),
          border: Border.all(color: mc.primary, width: 2),
        ),
        child: content,
      );
    }

    content = AnimatedOpacity(
      duration: duration,
      opacity: interactive ? 1.0 : 0.55,
      child: AnimatedScale(
        duration: duration,
        scale: isPressed ? 0.975 : 1.0,
        child: content,
      ),
    );

    if (widget.semanticLabel != null) {
      content = Semantics(
        button: true,
        enabled: interactive,
        selected: widget.selected,
        label: widget.semanticLabel,
        child: content,
      );
    }

    return FocusableActionDetector(
      enabled: interactive,
      onShowFocusHighlight: (bool focused) {
        if (_focused != focused) {
          setState(() => _focused = focused);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            interactive ? () => setState(() => _pressed = false) : null,
        onTap: interactive ? widget.onPressed : null,
        child: content,
      ),
    );
  }
}
