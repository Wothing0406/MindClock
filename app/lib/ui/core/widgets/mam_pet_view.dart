import 'package:flutter/widgets.dart';

enum MamPetReaction { idle, happy, sleep, snack, reading, celebrate }

/// Illustration only. Group progression must supply the server-confirmed stage.
class MamPetView extends StatelessWidget {
  const MamPetView({super.key, this.stage = 1, this.reaction, this.size = 128});
  final int stage;
  final MamPetReaction? reaction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final state = reaction?.name ?? 'stage-${stage.clamp(1, 4)}';
    return Image.asset('assets/companions/pet-mam/$state.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'Pet Mầm',
        errorBuilder: (_, __, ___) => SizedBox(
            width: size,
            height: size,
            child: const Center(child: Text('Mầm'))));
  }
}
