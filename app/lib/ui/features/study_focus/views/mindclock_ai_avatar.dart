import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';

enum AiCompanionMood { neutral, listening, thinking, encouraging, focused }

/// Generated expression art. isSpeaking must mean audio is actually playing.
/// The generic mouth cadence is not phoneme-accurate lip sync.
class MindClockAiAnimatedAvatar extends StatefulWidget {
  const MindClockAiAnimatedAvatar(
      {super.key,
      this.size = 96,
      this.isThinking = false,
      this.isSpeaking = false,
      this.animate = true,
      this.audioLevel,
      this.mood = AiCompanionMood.neutral,
      this.onLightBackground = false,
      this.statusLabelVi = 'Sẵn sàng hỗ trợ khi bạn hỏi'});
  final double size;
  final bool isThinking;
  final bool isSpeaking;
  final bool animate;
  final double? audioLevel;
  final AiCompanionMood mood;
  final bool onLightBackground;
  final String statusLabelVi;

  static const assetRoot = 'assets/companions/mindclock-ai';
  static const mouthFrames = [
    'speaking-small',
    'speaking-medium',
    'speaking-wide',
    'speaking-medium',
    'speaking-small',
    'neutral'
  ];

  @override
  State<MindClockAiAnimatedAvatar> createState() =>
      _MindClockAiAnimatedAvatarState();
}

class _MindClockAiAnimatedAvatarState extends State<MindClockAiAnimatedAvatar> {
  Timer? _cadence;
  Timer? _blinkEnd;
  int _frame = 0;
  bool _blink = false;

  bool get _motion =>
      widget.animate &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.of(context);

  void _sync() {
    _cadence?.cancel();
    _blinkEnd?.cancel();
    _frame = 0;
    _blink = false;
    if (!_motion) return;
    if (widget.isSpeaking) {
      if (widget.audioLevel == null) {
        _cadence = Timer.periodic(const Duration(milliseconds: 140), (_) {
          if (mounted) {
            setState(() => _frame =
                (_frame + 1) % MindClockAiAnimatedAvatar.mouthFrames.length);
          }
        });
      }
    } else if (!widget.isThinking && widget.mood == AiCompanionMood.neutral) {
      _cadence = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _blink = true);
        _blinkEnd = Timer(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _blink = false);
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MindClockAiAnimatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.isThinking != widget.isThinking ||
        oldWidget.isSpeaking != widget.isSpeaking ||
        oldWidget.mood != widget.mood ||
        (oldWidget.audioLevel == null) != (widget.audioLevel == null)) {
      _sync();
    }
  }

  @override
  void dispose() {
    _cadence?.cancel();
    _blinkEnd?.cancel();
    super.dispose();
  }

  String _state() {
    if (widget.isThinking) return 'thinking';
    if (widget.isSpeaking && _motion) {
      final level = widget.audioLevel;
      if (level != null) {
        if (!level.isFinite || level < 0.05) return 'neutral';
        if (level < 0.3) return 'speaking-small';
        if (level < 0.65) return 'speaking-medium';
        return 'speaking-wide';
      }
      return MindClockAiAnimatedAvatar.mouthFrames[_frame];
    }
    if (_blink && _motion) return 'blink';
    return widget.mood.name;
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final state = _state();
    return Semantics(
        label: 'Nhân vật minh họa MindClock AI',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('${MindClockAiAnimatedAvatar.assetRoot}/$state.webp',
                key: ValueKey('ai-avatar-$state'),
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Center(
                        child: MindClockIcon(MindClockIconKind.user,
                            color: mc.primary, size: widget.size * .5)))),
            SizedBox(height: mc.space4),
            const MindClockStatusPill(
                key: ValueKey('ai-2d-avatar-badge'), label: 'MindClock AI'),
            SizedBox(height: mc.space4),
            Text(widget.statusLabelVi,
                textAlign: TextAlign.center,
                style: mc.captionStyle.copyWith(
                    color: widget.onLightBackground ? mc.ink : mc.nightText)),
          ],
        ));
  }
}
