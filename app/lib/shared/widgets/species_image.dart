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
    if (locked) {
      return const _LockedPlate();
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
          colors: <Color>[style.fill, AppColors.surfaceRaised],
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

class _LockedPlate extends StatelessWidget {
  const _LockedPlate();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF111714)),
      child: Center(
        child: Icon(
          Icons.question_mark_rounded,
          color: AppColors.textMuted,
          size: 26,
        ),
      ),
    );
  }
}
