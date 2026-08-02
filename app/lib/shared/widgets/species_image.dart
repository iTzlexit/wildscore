import 'package:flutter/material.dart';

import '../../domain/species.dart';
import '../theme.dart';

/// Renders a species photograph, with a silhouette behind it as a safety net.
///
/// Three states, in order of preference:
///
/// 1. **The photograph**, when one exists and is confidently the right animal.
/// 2. **A silhouette**, when the photograph is missing, fails to decode, or is
///    flagged `photoVerified: false` — the small cats, where the sourcing API
///    cannot tell a caracal from a serval.
/// 3. **A monogram plate**, when there is no silhouette either.
///
/// The middle step is the point. A misidentified photograph in a field guide is
/// worse than no photograph at all: somebody learns the wrong animal from it and
/// then claims the wrong points. A silhouette says "we know the shape, we are
/// not going to pretend about the markings", which is honest and still useful —
/// a caracal outline is unmistakable.
///
/// It is also the failure mode for everything else. If an asset is ever lost in
/// a bad build, tiles degrade to shapes rather than to grey boxes.
class SpeciesImage extends StatelessWidget {
  const SpeciesImage({
    required this.species,
    this.locked = false,
    this.fit = BoxFit.cover,
    super.key,
  });

  final Species species;

  /// Not yet spotted. Desaturates the photograph; silhouettes are already
  /// monochrome, so it only changes their tint.
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
    if (!species.photoVerified) {
      return _Silhouette(species: species);
    }

    final Widget photo = Image.asset(
      species.imageAsset,
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          _Silhouette(species: species),
    );

    if (!locked) {
      return photo;
    }
    return ColorFiltered(colorFilter: _grey, child: photo);
  }
}

/// The shape of the animal on a tinted plate. PhyloPic silhouettes are black on
/// transparent, so they are tinted rather than shown raw — raw black reads as a
/// rendering fault, and a soft charcoal on the tier's own wash reads as a
/// deliberate illustration.
class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.species});

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          species.silhouetteAsset,
          fit: BoxFit.contain,
          color: AppColors.textSecondary.withValues(alpha: 0.72),
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) =>
                  _MonogramPlate(species: species),
        ),
      ),
    );
  }
}

class _MonogramPlate extends StatelessWidget {
  const _MonogramPlate({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Center(
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
