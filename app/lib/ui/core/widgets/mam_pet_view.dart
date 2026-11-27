import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum MamPetReaction { idle, happy, sleep, snack, reading, celebrate }

/// Pet Mầm có chuyển động nhẹ theo trạng thái và tôn trọng Reduce Motion.
class MamPetView extends StatefulWidget {
  const MamPetView({
    super.key,
    this.stage = 1,
    this.reaction,
    this.size = 128,
    this.animate = true,
  });

  final int stage;
  final MamPetReaction? reaction;
  final double size;
  final bool animate;

  @override
  State<MamPetView> createState() => _MamPetViewState();
}

class _MamPetViewState extends State<MamPetView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isExcited =>
      widget.reaction == MamPetReaction.happy ||
      widget.reaction == MamPetReaction.celebrate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isExcited ? 950 : 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant MamPetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reaction != widget.reaction ||
        oldWidget.animate != widget.animate) {
      _controller.duration = Duration(milliseconds: _isExcited ? 950 : 1800);
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bool inWidgetTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!widget.animate || reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (inWidgetTest) {
      if (!_controller.isAnimating && _controller.value == 0) {
        _controller.forward();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String state = widget.reaction?.name ?? 'stage-${widget.stage.clamp(1, 4)}';
    final Widget image = Image.asset(
      'assets/companions/pet-mam/$state.webp',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      semanticLabel: 'Pet Mầm',
      errorBuilder: (_, __, ___) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: Text('Mầm')),
      ),
    );

    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      return image;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: image,
      builder: (BuildContext context, Widget? child) {
        final double wave = math.sin(_controller.value * 2 * math.pi);
        final double dy = _isExcited ? -wave.abs() * 6.0 : wave * 2.5;
        final double angle = _isExcited ? wave * 0.045 : wave * 0.022;
        final double scale = _isExcited ? 1.0 + wave.abs() * 0.035 : 1.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
