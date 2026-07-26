import 'package:flutter/material.dart';

import '../../../domain/species.dart';
import '../../../domain/species_tag.dart';
import '../../../shared/theme.dart';
import '../../../shared/widgets/pill.dart';
import '../../../shared/widgets/species_image.dart';

/// One row in the Codex.
///
/// The single most important visual decision in the app: a Pangolin card must
/// be obviously different from an Impala card at a glance, before you have
/// read a word of it. Four things carry that — the rail width, the border, the
/// background wash and the glow — and they escalate together with rarity.
///
/// Fixed height on purpose. It lets the list use `itemExtent`, which keeps
/// scrolling smooth across seventy-odd cards on a cheap phone.
class SpeciesCard extends StatelessWidget {
  const SpeciesCard({
    required this.species,
    required this.onTap,
    this.locked = false,
    super.key,
  });

  static const double cardHeight = 100;
  static const double listExtent = 110;

  final Species species;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: cardHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: style.border, width: style.borderWidth),
            boxShadow: style.glow == null
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: style.glow!,
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[style.fill, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: style.isExalted ? 6 : 4,
                        height: cardHeight,
                        color: style.accent,
                      ),
                      const SizedBox(width: 10),
                      _Thumbnail(species: species, locked: locked),
                      const SizedBox(width: 12),
                      Expanded(child: _Details(species: species)),
                      _Points(species: species),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.species, required this.locked});

  final Species species;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 72,
        height: 72,
        child: SpeciesImage(species: species, locked: locked),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          species.commonName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          species.scientificName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontStyle: FontStyle.italic,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: <Widget>[
            Flexible(
              child: Pill(
                label: species.rarityTier.label,
                color: style.isExalted ? const Color(0xFF14100A) : style.accent,
                background: style.isExalted ? style.accent : style.fill,
                borderColor: style.border,
                dense: true,
              ),
            ),
            for (final SpeciesTag tag in species.tags.take(1)) ...<Widget>[
              const SizedBox(width: 5),
              Pill(
                label: tag.shortLabel,
                color: tag == SpeciesTag.nocturnal
                    ? const Color(0xFF7FA6D8)
                    : AppColors.accent,
                dense: true,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Points extends StatelessWidget {
  const _Points({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          '${species.points}',
          style: TextStyle(
            color: style.accent,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'PTS',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            height: 1,
          ),
        ),
      ],
    );
  }
}
