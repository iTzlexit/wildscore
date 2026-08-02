import 'package:flutter/material.dart';

import '../theme.dart';

/// The app's name and park, on every tab.
///
/// The park line is not decoration. Wild Score is Kruger-only today and other
/// reserves are the stated growth path — saying so up front sets the
/// expectation honestly, and turns "why isn't Addo here" from a complaint into
/// anticipation.
class AppHeader extends StatelessWidget {
  const AppHeader({this.trailing, super.key});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.md,
        Space.screen,
        Space.sm,
      ),
      child: Row(
        children: <Widget>[
          const _Mark(),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Wild Score',
                  style: AppText.title3.copyWith(
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                Text('Kruger National Park', style: AppText.caption),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A placeholder mark until there is a real logo — a paw print in the accent
/// colour. Deliberately simple: a bad logo is worse than an obvious stand-in,
/// and this reads as intentional rather than unfinished.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: const Icon(Icons.pets_rounded, size: 19, color: Colors.white),
    );
  }
}

/// Shown at the foot of the Animal Dex.
class ComingSoonParks extends StatelessWidget {
  const ComingSoonParks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Space.screen),
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.travel_explore_rounded,
            size: 19,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Kruger only, for now',
                  style: AppText.label.copyWith(
                    color: AppColors.textPrimary,
                    fontVariations: AppFonts.weight(700),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Okavango Delta, Masai Mara and Addo are coming. Each park '
                  'gets its own dex and its own rarity — a cheetah is a prize '
                  'here and routine in the Mara.',
                  style: AppText.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
