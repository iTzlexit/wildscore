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

  /// Desaturated and slightly lifted. Not a silhouette — you can still see the
  /// animal, which keeps the free field guide usable, but it is visibly *not
  /// yours yet*. Colour returning on a catch is the reward.
  static const ColorFilter _grey = ColorFilter.matrix(<double>[
    0.28, 0.50, 0.10, 0, 26, //
    0.24, 0.55, 0.10, 0, 26, //
    0.24, 0.50, 0.15, 0, 26, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final Widget photo = Image.asset(
      species.imageAsset,
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return _MonogramPlate(species: species);
      },
    );

    if (!locked) {
      return photo;
    }
    return ColorFiltered(colorFilter: _grey, child: photo);
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
