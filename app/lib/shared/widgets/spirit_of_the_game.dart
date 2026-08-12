import 'package:flutter/material.dart';

import '../theme.dart';

/// The one thing this app always says the same way.
///
/// From the style doc: *"Points measure how difficult an animal is to find,
/// nothing more. Every animal in Kruger is equally special."* A scoring game
/// about wildlife has to say that out loud, and it is the one deliberate
/// repetition in the whole app.
///
/// It used to live in the rules screen, which no longer exists.
class SpiritOfTheGame extends StatelessWidget {
  const SpiritOfTheGame({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.accentWash,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.favorite_rounded, size: 18, color: AppColors.accent),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'It’s just a game',
                  style: AppText.label.copyWith(
                    color: AppColors.accent,
                    fontVariations: AppFonts.weight(800),
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Points measure how difficult an animal is to find, nothing '
                  'more. Every animal in Kruger is equally special.\n\n'
                  'Wild Score runs on honesty, just like the paper version. '
                  'Watch the animal first — the phone can wait.',
                  style: AppText.caption.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
