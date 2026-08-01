import 'package:flutter/material.dart';

import '../../domain/species.dart';
import '../theme.dart';

/// Renders a species photograph, falling back to a generated monogram plate
/// when the asset is missing.
///
/// There are no photographs in the repo yet (see assets/species/README.md), so
/// in practice the fallback is what you will see. It is designed to look
/// deliberate rather than broken — the app should be presentable to a tester
/// before a single image has been licensed.
class SpeciesImage extends StatelessWidget {
  const SpeciesImage({
    required this.species,
    this.locked = false,
    this.fit = BoxFit.cover,
    super.key,
  });

  final Species species;

  /// Phase 2: species the player has not yet photographed render as
  /// silhouettes. Wired up now so the layout never has to change.
  final bool locked;

  /// `cover` for thumbnails and heroes; `contain` in the full-screen viewer,
  /// where cropping the animal out of its own photograph would be absurd.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // Only the rare tiers hide behind a silhouette. Hiding an impala teaches
    // nobody anything and makes the free field guide useless; hiding a pangolin
    // is the entire point of a collection game. `notched` is exactly the four
    // tiers from Rare upward.
    if (locked && species.rarityTier.style.notched) {
      return _LockedPlate(species: species);
    }

    return Image.asset(
      species.imageAsset,
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return _MonogramPlate(species: species);
      },
    );
  }
}

class _MonogramPlate extends StatelessWidget {
  const _MonogramPlate({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[style.fill, AppColors.surfaceAlt],
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              _monogram(species.commonName),
              style: TextStyle(
                color: style.accent,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _monogram(String name) {
    final List<String> words = name
        .split(RegExp(r"[\s\-']+"))
        .where((String w) => w.isNotEmpty)
        .toList();
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return words
        .take(2)
        .map((String w) => w.substring(0, 1).toUpperCase())
        .join();
  }
}

/// Uncaught species: a true silhouette, from PhyloPic.
///
/// Falls back to the reference photograph desaturated and crushed to near-black
/// when no silhouette exists for that species. The fallback works, but it leaks
/// the background and the animal's pose — a silhouette teases the *shape* and
/// nothing else, which is the stronger hook.
///
/// The empty slot is what makes a collection worth filling.
class _LockedPlate extends StatelessWidget {
  const _LockedPlate({required this.species});

  final Species species;

  /// Greyscale, then lifted and flattened toward the plate colour, so a
  /// fallback photograph reads as a ghost rather than a picture. Fallback only.
  static const ColorFilter _crush = ColorFilter.matrix(<double>[
    0.09, 0.30, 0.05, 0, 118, //
    0.09, 0.30, 0.05, 0, 120, //
    0.09, 0.30, 0.05, 0, 116, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.surfaceAlt),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            species.silhouetteAsset,
            fit: BoxFit.contain,
            // PhyloPic silhouettes are black on transparent; tint to a mid
            // grey-green so the shape reads on a light plate without going
            // heavy enough to look like a solid block.
            color: const Color(0xFFA8B0A9),
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) =>
                    ColorFiltered(
                      colorFilter: _crush,
                      child: Image.asset(
                        species.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stack,
                            ) => const SizedBox.shrink(),
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}
