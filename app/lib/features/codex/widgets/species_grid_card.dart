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
    this.onToggleSpotted,
    super.key,
  });

  /// Marks the species seen from the tile. Null hides the control.
  final VoidCallback? onToggleSpotted;

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
    // A gold frame on an animal you have never seen gives away the surprise,
    // so the frame stays neutral until the species is caught.
    final Color frame = locked ? AppColors.outline : style.border;
    final double frameWidth = locked ? 1 : style.borderWidth;

    // A card that dips under the thumb feels like an object you picked up.
    // Cheap, and it does more for the "collectible" feeling than any amount
    // of decoration.
    // Notched corners from Rare upward — one of the five redundant channels
    // rarity escalates across, so the frame is distinguishable in greyscale
    // and in direct sun where hue washes out.
    final BorderRadius radius = style.notched
        ? const BorderRadius.only(
            topLeft: Radius.circular(Radii.card),
            topRight: Radius.circular(Space.xs),
            bottomLeft: Radius.circular(Space.xs),
            bottomRight: Radius.circular(Radii.card),
          )
        : BorderRadius.circular(Radii.card);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: Motion.press,
      curve: Motion.exit,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: frame, width: frameWidth),
          boxShadow: (locked || style.glow == null)
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
          borderRadius: radius,
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
                        if (style.foil)
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
                        // Mark-as-spotted. A tap target on the tile itself,
                        // because the alternative is opening a species just to
                        // tick it — and in a moving car nobody does that.
                        if (widget.onToggleSpotted != null)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: _SpotToggle(
                              spotted: !locked,
                              onTap: widget.onToggleSpotted!,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Label(species: species, style: style, locked: locked),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap to mark a species seen, or unmark it.
///
/// Deliberately reads as a checkbox rather than a camera. This is the honest
/// "I saw it" — a *verified* catch needs a photograph taken in the park, and
/// conflating the two visually would undermine the whole trust model.
class _SpotToggle extends StatelessWidget {
  const _SpotToggle({required this.spotted, required this.onTap});

  final bool spotted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: spotted ? AppColors.verified : const Color(0xE6FFFFFF),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            spotted ? Icons.check_rounded : Icons.add_rounded,
            size: 17,
            color: spotted ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.species,
    required this.style,
    required this.locked,
  });

  final Species species;
  final RarityStyle style;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
          Row(
            children: <Widget>[
              Text(
                species.dexLabel,
                style: AppText.caption.copyWith(
                  fontSize: 10,
                  height: 1,
                  fontFeatures: AppText.tabular,
                ),
              ),
              const SizedBox(width: Space.xs),
              Container(
                width: 2,
                height: 2,
                decoration: const BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Space.xs),
              Flexible(
                child: Text(
                  species.rarityTier.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    fontSize: 9,
                    height: 1,
                    letterSpacing: 0.7,
                    color: style.accent,
                    fontVariations: AppFonts.weight(800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            species.commonName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.title3.copyWith(
              fontSize: 14,
              height: 1.15,
              color: locked ? AppColors.textSecondary : AppColors.textPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.accent,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Text(
        '${species.points}',
        style: AppText.caption.copyWith(
          color: Colors.white,
          fontSize: 11.5,
          height: 1,
          fontVariations: AppFonts.weight(800),
          fontFeatures: AppText.tabular,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(Radii.chip - 4),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          fontSize: 8.5,
          height: 1,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
          fontVariations: AppFonts.weight(800),
        ),
      ),
    );
  }
}
