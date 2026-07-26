import 'package:flutter/material.dart';

import '../../../domain/species.dart';
import '../../../domain/species_tag.dart';
import '../../../shared/theme.dart';
import '../../../shared/widgets/species_image.dart';

/// One tile in the Codex grid — a guidebook entry.
///
/// Structure follows a Pokédex page deliberately: photograph on top, catalogue
/// number and name beneath. What is *not* borrowed is the flat white styling.
/// Rarity still drives the border, the wash and the glow, because a Pangolin
/// tile looking obviously different from an Impala tile is the single most
/// important visual decision in the app — and a uniform grid of white cards
/// would throw that away.
class SpeciesGridCard extends StatefulWidget {
  const SpeciesGridCard({
    required this.species,
    required this.onTap,
    this.locked = false,
    this.sightingCount = 0,
    super.key,
  });

  /// Tiles are sized by the grid delegate; this drives the image-to-label
  /// ratio within a tile.
  static const double aspectRatio = 0.80;

  final Species species;
  final VoidCallback onTap;
  final bool locked;

  /// Lifetime catches of this species. Zero until Phase 2 has a sightings
  /// table; the badge simply does not render at zero.
  final int sightingCount;

  @override
  State<SpeciesGridCard> createState() => _SpeciesGridCardState();
}

class _SpeciesGridCardState extends State<SpeciesGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Species species = widget.species;
    final bool locked = widget.locked;
    final RarityStyle style = species.rarityTier.style;

    // A card that dips under the thumb feels like an object you picked up.
    // Cheap, and it does more for the "collectible" feeling than any amount
    // of decoration.
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.border, width: style.borderWidth),
          boxShadow: style.glow == null
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: style.glow!,
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        SpeciesImage(species: species, locked: locked),
                        // Softens the join between photo and label strip so the
                        // tile reads as one object rather than two stacked.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Color(0x99161C19),
                              ],
                            ),
                          ),
                        ),
                        // Foil sheen on the exalted tiers only. A diagonal
                        // gloss is the oldest trading-card trick there is, and
                        // it makes a Legendary tile read as a *thing* rather
                        // than a database row. Static, not animated — eighteen
                        // shimmering cards in a scrolling grid would be both
                        // distracting and expensive.
                        if (style.isExalted)
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    Color(0x00FFFFFF),
                                    Color(0x1AFFFFFF),
                                    Color(0x00FFFFFF),
                                    Color(0x00FFFFFF),
                                  ],
                                  stops: <double>[0.18, 0.34, 0.52, 1],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _PointsBadge(species: species),
                        ),
                        if (species.tags.contains(SpeciesTag.bigFive))
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: _CornerBadge(label: 'BIG 5'),
                          )
                        else if (species.tags.contains(SpeciesTag.bigSixBirds))
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: _CornerBadge(label: 'BIG 6'),
                          ),
                        if (widget.sightingCount > 0)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: _CaughtTag(count: widget.sightingCount),
                          ),
                      ],
                    ),
                  ),
                  _Label(species: species, style: style),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How many times this species has been caught, ever.
///
/// Only shown once the count is at least one — a grid of "×0" badges would
/// read as failure, where an absent badge simply reads as "not yet". The
/// number matters because a second leopard is still worth having even though
/// it scores a tenth: this is the difference between a score and a collection.
class _CaughtTag extends StatelessWidget {
  const _CaughtTag({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xE60E1210),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF5AA46F), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            size: 10,
            color: Color(0xFF5AA46F),
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF5AA46F),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.species, required this.style});

  final Species species;
  final RarityStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[style.fill, Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'No. ${species.dexLabel}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            species.commonName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xCC0E1210),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: style.accent, width: 1.2),
      ),
      child: Text(
        '${species.points}',
        style: TextStyle(
          color: style.accent,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xCC0E1210),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.accent, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          height: 1,
        ),
      ),
    );
  }
}
