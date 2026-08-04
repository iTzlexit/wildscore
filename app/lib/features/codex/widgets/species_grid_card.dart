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
    this.onLongPress,
    this.chancesLeft,
    this.bonusPoints,
    this.bonusSpent = false,
    super.key,
  });

  /// The first-sighting bonus, when this claim would earn it. Shown instead of
  /// the tier value, because the number on the tile has to be the number the
  /// player is about to get.
  final int? bonusPoints;

  /// A wild card whose bonus has already gone. Still claimable, just ordinary
  /// now — and worth saying so, because somebody who saw 50 on this tile an
  /// hour ago will want to know where it went.
  final bool bonusSpent;

  /// Marks the species seen from the tile. Null hides the control.
  final VoidCallback? onToggleSpotted;

  /// Opens the field-guide entry while a game is running, since a plain tap is
  /// then a claim.
  final VoidCallback? onLongPress;

  /// Claims remaining today. Null when unlimited or no game is running; 0 means
  /// the tile is spent and locked.
  final int? chancesLeft;

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
    // `locked` now means only "not in your collection". The photograph is shown
    // in full colour either way — see SpeciesImage for why.
    final bool spotted = !widget.locked;
    final RarityStyle style = species.rarityTier.style;
    final Color frame = style.border;
    final double frameWidth = style.borderWidth;

    /// Chances used up — claimed as many times as it can be today.
    final bool spent = widget.chancesLeft == 0;

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
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: spent ? null : widget.onTap,
              onLongPress: widget.onLongPress,
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
                        SpeciesImage(species: species),
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
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    const Color(0x00FFFFFF),
                                    style.foilTint,
                                    const Color(0x40FFFFFF),
                                    style.foilTint,
                                    const Color(0x00FFFFFF),
                                  ],
                                  stops: const <double>[
                                    0.1,
                                    0.3,
                                    0.42,
                                    0.54,
                                    0.8,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _PointsBadge(
                            species: species,
                            bonus: widget.bonusPoints,
                          ),
                        ),
                        if (widget.bonusPoints != null)
                          const Positioned(
                            bottom: 6,
                            left: 6,
                            child: _WildCardBadge(),
                          )
                        else if (widget.bonusSpent)
                          const Positioned(
                            bottom: 6,
                            left: 6,
                            child: _BonusSpentBadge(),
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
                        // Spotted is a *status*, not a button. Adding from the
                        // tile is quick because in a moving car nobody opens a
                        // species just to tick it — but removing from here was
                        // one mis-tap away from silently deleting something
                        // out of a collection, so that moved to the species
                        // screen where it can be deliberate.
                        if (spotted)
                          const Positioned(
                            bottom: 6,
                            right: 6,
                            child: _SpottedMark(),
                          )
                        else if (widget.onToggleSpotted != null)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: _AddButton(onTap: widget.onToggleSpotted!),
                          ),
                        // Spent tiles stay visible and greyed rather than
                        // disappearing — who got the impala at the gate is part
                        // of the fun and must not vanish from the board.
                        if (spent)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ColoredBox(
                                color: const Color(0xB3FFFFFF),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.textPrimary,
                                      borderRadius: BorderRadius.circular(
                                        Radii.chip,
                                      ),
                                    ),
                                    child: Text(
                                      'CLAIMED',
                                      style: AppText.overline.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (widget.chancesLeft != null)
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: _ChancesBadge(left: widget.chancesLeft!),
                          ),
                      ],
                    ),
                  ),
                  _Label(species: species, style: style, spotted: spotted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How many claims this species has left today.
class _ChancesBadge extends StatelessWidget {
  const _ChancesBadge({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(Radii.chip - 4),
      ),
      child: Text(
        left == 1 ? 'LAST ONE' : '$left LEFT',
        style: AppText.overline.copyWith(
          fontSize: 8.5,
          letterSpacing: 0.6,
          color: left == 1 ? AppColors.danger : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// "You have found this one." Not interactive.
///
/// Has to survive being read at arm's length in sunlight over a photograph that
/// might be any colour, which is why it is a filled disc with a white tick and
/// a white ring rather than a tint or a border.
class _SpottedMark extends StatelessWidget {
  const _SpottedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.verified,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
    );
  }
}

/// Adds a species to the collection, straight from the tile.
///
/// This is the honest "I saw it" — a *verified* catch needs a photograph taken
/// in the park, and conflating the two visually would undermine the trust
/// model.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6FFFFFF),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            Icons.add_rounded,
            size: 17,
            color: AppColors.textSecondary,
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
    required this.spotted,
  });

  final Species species;
  final RarityStyle style;
  final bool spotted;

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
              color: spotted ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.species, this.bonus});

  final Species species;

  /// Wins over the tier value when a first-sighting bonus is on offer.
  ///
  /// Not named `override` — a field by that name shadows the `@override`
  /// annotation for the whole class, and the compiler reports it against a
  /// line that has nothing to do with the cause.
  final int? bonus;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bonus == null ? style.accent : AppColors.accent,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Text(
        '${bonus ?? species.points}',
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

/// "This one is worth extra, right now."
///
/// Only ever visible while the bonus is unclaimed, which is what makes it worth
/// shouting about — a badge that is always there is wallpaper.
class _WildCardBadge extends StatelessWidget {
  const _WildCardBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(Radii.chip - 4),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Text(
        'FIRST ONE',
        style: AppText.overline.copyWith(
          fontSize: 8,
          letterSpacing: 0.7,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// The bonus on this species is gone. Padlocked rather than hidden, because a
/// badge that simply disappears looks like a bug to somebody who saw it earlier.
class _BonusSpentBadge extends StatelessWidget {
  const _BonusSpentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC161C19),
        borderRadius: BorderRadius.circular(Radii.chip - 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.lock_rounded, size: 10, color: Color(0xB3FFFFFF)),
          const SizedBox(width: 3),
          Text(
            'BONUS GONE',
            style: AppText.overline.copyWith(
              fontSize: 8,
              letterSpacing: 0.6,
              color: const Color(0xB3FFFFFF),
            ),
          ),
        ],
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
