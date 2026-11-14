import 'package:flutter/widgets.dart';

import '../theme/mindclock_theme.dart';
import 'mindclock_icon.dart';
import 'mindclock_pressable.dart';

class MindClockCard extends StatelessWidget {
  const MindClockCard({
    super.key,
    required this.child,
    this.padding,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(mc.space16),
      decoration: BoxDecoration(
        color: highlighted ? mc.primarySoft : mc.surface,
        borderRadius: BorderRadius.circular(mc.radiusCard),
        border: Border.all(
          color: highlighted ? mc.primary : mc.outline,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

enum MindClockButtonVariant {
  primary,
  secondary,
  subtle,
}

class MindClockButton extends StatelessWidget {
  const MindClockButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MindClockButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MindClockButtonVariant variant;
  final MindClockIconKind? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final Color bg;
    final Color fg;
    final Color borderColor;

    switch (variant) {
      case MindClockButtonVariant.primary:
        bg = mc.primary;
        fg = mc.onPrimary;
        borderColor = mc.primary;
      case MindClockButtonVariant.secondary:
        bg = mc.surface;
        fg = mc.primary;
        borderColor = mc.primary;
      case MindClockButtonVariant.subtle:
        bg = mc.paper;
        fg = mc.ink;
        borderColor = mc.outline;
    }

    final Widget inner = Container(
      width: expand ? double.infinity : null,
      constraints: BoxConstraints(minHeight: mc.minTouchTarget),
      padding: EdgeInsets.symmetric(
        horizontal: mc.space16,
        vertical: mc.space12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(mc.radiusControl),
        border: Border.all(color: borderColor, width: 1.25),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            MindClockIcon(icon!, color: fg, size: 20),
            SizedBox(width: mc.space8),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: mc.bodyStrongStyle.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );

    return MindClockPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(mc.radiusControl),
      child: inner,
    );
  }
}

class MindClockNoticeBanner extends StatelessWidget {
  const MindClockNoticeBanner({
    super.key,
    required this.message,
    this.isWarm = true,
  });

  final String message;
  final bool isWarm;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mc.space12),
      decoration: BoxDecoration(
        color: isWarm ? mc.sunriseSoft : mc.primarySoft,
        borderRadius: BorderRadius.circular(mc.radiusControl),
        border: Border.all(color: isWarm ? mc.sunrise : mc.primary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: mc.space4 / 2),
            child: MindClockIcon(
              MindClockIconKind.info,
              color: mc.ink,
              size: 20,
            ),
          ),
          SizedBox(width: mc.space8),
          Expanded(
            child: Text(
              message,
              style: mc.captionStyle.copyWith(
                color: mc.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MindClockStatusPill extends StatelessWidget {
  const MindClockStatusPill({
    super.key,
    required this.label,
    this.accentWarm = false,
  });

  final String label;
  final bool accentWarm;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mc.space12,
        vertical: mc.space4 + 2,
      ),
      decoration: BoxDecoration(
        color: accentWarm ? mc.sunriseSoft : mc.primarySoft,
        borderRadius: BorderRadius.circular(mc.radiusChip),
        border: Border.all(color: accentWarm ? mc.sunrise : mc.primary),
      ),
      child: Text(
        label,
        style: mc.chipLabelStyle.copyWith(color: mc.ink),
      ),
    );
  }
}
