import 'package:flutter/material.dart';

import '../../data/attribution_repository.dart';
import '../../domain/species.dart';
import '../../domain/species_tag.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/species_image.dart';
import 'photo_viewer_screen.dart';
import 'widgets/region_strip.dart';

/// The species card, full screen.
///
/// Structure: the rarity colour **owns the top of the screen**, with the animal
/// centred in it as a ringed portrait and its name directly beneath. That is
/// what stops a detail screen reading as a form — a timid coloured border says
/// "database row"; a lit colour field with a specimen plate in the middle of it
/// says "card".
///
/// The portrait used to sit in the bottom-right corner, straddling the seam
/// into the sheet. It looked like an afterthought and, on a narrow screen, it
/// was clipped by the edge. Centred is both prettier and correct.
///
/// This layout is also the skeleton of the Phase 2 reveal. When you photograph
/// a pangolin, this is the card that turns over, so the hierarchy is worth
/// getting right now: colour, then who it is, then what it is worth.
class SpeciesDetailScreen extends StatelessWidget {
  const SpeciesDetailScreen({
    required this.species,
    this.photoCredit,
    this.spotted = false,
    this.onToggleSpotted,
    super.key,
  });

  /// Opens the card from anywhere that has a species and no credits loaded.
  ///
  /// The Codex holds its credit map in state because it needs one per tile; the
  /// scorecard and the sightings feed have a single animal and no business
  /// owning that map. Loading it here — once, then cached — keeps attribution
  /// attached to the photograph wherever the card is opened from, which is the
  /// licence condition and not something to leave to whoever adds the next
  /// entry point.
  /// The resolved map rather than the Future that produced it. Holding the
  /// Future would mean every later caller awaits a Future created in whatever
  /// context the first one ran in, which is fine in an app with one event loop
  /// and not fine anywhere else.
  static Map<String, String>? _credits;

  static Future<void> open(BuildContext context, Species species) async {
    final Map<String, String> credits =
        _credits ?? (_credits = await const AttributionRepository().loadAll());
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SpeciesDetailScreen(
          species: species,
          photoCredit: credits[species.id],
        ),
      ),
    );
  }

  final Species species;

  /// Photographer and licence, shown in the full-screen viewer. Required by
  /// CC-BY; null when the species has no sourced photograph.
  final String? photoCredit;

  /// Already in the collection.
  final bool spotted;

  /// Adds or removes it. Null where the collection is not editable.
  ///
  /// Removing lives here rather than on the tile: a tick in a grid is one
  /// mis-tap away from silently deleting something out of a collection
  /// somebody has spent years building.
  final VoidCallback? onToggleSpotted;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Scaffold(
      backgroundColor: style.headerInk,
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: <Widget>[
            _Header(species: species, credit: photoCredit),
            Expanded(
              child: _Sheet(
                species: species,
                spotted: spotted,
                onToggleSpotted: onToggleSpotted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.species, this.credit});

  final Species species;
  final String? credit;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;
    final Size screen = MediaQuery.sizeOf(context);

    // Sized from the screen rather than fixed. A 300pt header is most of a
    // small phone and a third of a tablet; this keeps the proportion instead of
    // the number, and clamps so the portrait never gets silly at either end.
    final double height = (screen.height * 0.48).clamp(340.0, 460.0);
    // Sized against the *width* as well: on a narrow phone the limit on how big
    // the portrait can be is the screen edge, not the header height. Taking 62%
    // of the width fills the space that was previously just blue.
    final double medallion = <double>[
      height * 0.52,
      screen.width * 0.62,
      260.0,
    ].reduce((double a, double b) => a < b ? a : b);

    return SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.lerp(style.headerTop, Colors.white, 0.14)!,
                    style.headerTop,
                    style.headerInk,
                  ],
                  stops: const <double>[0, 0.45, 1],
                ),
              ),
            ),
          ),
          // Light pooling behind the animal. This is what makes the portrait
          // read as lit from behind rather than pasted onto a coloured
          // rectangle, and it costs one gradient.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.75,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.26),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const <double>[0, 0.55, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.sm,
                    Space.xs,
                    Space.screen,
                    0,
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                      ),
                      const Spacer(),
                      Text(
                        '#${species.dexLabel}',
                        style: AppText.title2.copyWith(
                          color: const Color(0x8CFFFFFF),
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                // The portrait yields space rather than the text, and scaleDown
                // never enlarges it past its intended diameter. A long name
                // with three tags on a short screen shrinks the animal a little
                // instead of overflowing the header, which is the right thing
                // to give up.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _Medallion(
                        species: species,
                        diameter: medallion,
                        onTap: () => Navigator.of(context).push(
                          PhotoViewerScreen.route(species, credit: credit),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                  child: Column(
                    children: <Widget>[
                      Text(
                        species.commonName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title1.copyWith(
                          color: Colors.white,
                          fontSize: species.commonName.length > 20 ? 26 : 31,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        species.scientificName,
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(
                          color: const Color(0xB3FFFFFF),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: Space.sm,
                        runSpacing: 6,
                        children: <Widget>[
                          _HeaderPill(
                            label: species.rarityTier.label,
                            solid: true,
                          ),
                          // Two at most. Every tag is also on the tile and in
                          // the sheet, and a third row of pills pushes the
                          // animal off a small screen to say something nobody
                          // came here to read.
                          for (final SpeciesTag tag in species.tags.take(2))
                            _HeaderPill(label: tag.label, solid: false),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The portrait, centred and ringed.
///
/// Concentric rings rather than a single border: the halo is what turns a
/// cropped photograph into a *specimen plate*, and it is the one piece of
/// ceremony this screen gets. Rarity drives how bright the ring is, so a
/// pangolin card is visibly more of an occasion than an impala one without
/// needing a different layout.
class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.species,
    required this.diameter,
    required this.onTap,
  });

  final Species species;
  final double diameter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;
    final bool exalted = style.isExalted;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: diameter + 34,
        height: diameter + 34,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Outer halo. Wide and faint — it reads as glow, not as a second
            // border.
            Container(
              width: diameter + 34,
              height: diameter + 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: exalted ? 0.16 : 0.09),
              ),
            ),
            Container(
              width: diameter + 16,
              height: diameter + 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: exalted ? 0.22 : 0.13),
              ),
            ),
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: exalted ? 0.9 : 0.55),
                  width: exalted ? 3.5 : 2.5,
                ),
                boxShadow: <BoxShadow>[
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                  if (exalted)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 26,
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: ClipOval(
                child: Hero(
                  tag: 'species-photo-${species.id}',
                  child: SpeciesImage(species: species),
                ),
              ),
            ),
            // A hint that the portrait opens. Small, low contrast — the tap
            // target is the whole circle, this only says so.
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xB3000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.zoom_out_map_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.solid});

  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? Colors.white : const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: solid ? null : Border.all(color: const Color(0x4DFFFFFF)),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          fontSize: 11.5,
          color: solid ? const Color(0xFF17201B) : Colors.white,
          fontVariations: AppFonts.weight(700),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.species,
    required this.spotted,
    this.onToggleSpotted,
  });

  final Species species;
  final bool spotted;
  final VoidCallback? onToggleSpotted;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: Space.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: style.accent,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppText.label.copyWith(
                fontVariations: AppFonts.weight(700),
              ),
              unselectedLabelStyle: AppText.label,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              tabs: const <Widget>[
                Tab(text: 'About'),
                Tab(text: 'Field notes'),
                Tab(text: 'Where to find'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _AboutTab(
                  species: species,
                  spotted: spotted,
                  onToggleSpotted: onToggleSpotted,
                ),
                _FieldNotesTab(species: species),
                _WhereTab(species: species),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Add to, or remove from, the collection.
class _CollectionButton extends StatelessWidget {
  const _CollectionButton({required this.spotted, required this.onTap});

  final bool spotted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: spotted
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.check_circle_rounded, size: 19),
              label: Text(
                'In your collection',
                style: AppText.bodyStrong.copyWith(color: AppColors.verified),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verified,
                side: BorderSide(
                  color: AppColors.verified.withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'I have seen this one',
                style: AppText.bodyStrong.copyWith(color: AppColors.accentInk),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
              ),
            ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.species,
    required this.spotted,
    this.onToggleSpotted,
  });

  final Species species;
  final bool spotted;
  final VoidCallback? onToggleSpotted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.screen,
        Space.screen,
        Space.xxl,
      ),
      children: <Widget>[
        if (onToggleSpotted != null) ...<Widget>[
          _CollectionButton(spotted: spotted, onTap: onToggleSpotted!),
          const SizedBox(height: Space.lg),
        ],
        _PointsBanner(species: species),
        if (species.isSensitive) ...<Widget>[
          const SizedBox(height: Space.lg),
          const _SensitiveNotice(),
        ],
        const SizedBox(height: Space.screen),
        Text(species.description, style: AppText.body),
        const SizedBox(height: Space.xl),
        _Row(label: 'Afrikaans', value: species.afrikaansName),
        _Row(label: 'Category', value: species.category.singular),
        _Row(
          label: 'Conservation',
          value: species.conservationStatus.label,
          valueColor: species.conservationStatus.color,
        ),
      ],
    );
  }
}

class _FieldNotesTab extends StatelessWidget {
  const _FieldNotesTab({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.screen,
        Space.screen,
        Space.xxl,
      ),
      children: <Widget>[
        _InfoTile(
          icon: Icons.park_rounded,
          label: 'Habitat',
          value: species.habitat,
        ),
        const SizedBox(height: Space.md),
        _InfoTile(
          icon: Icons.schedule_rounded,
          label: 'Best time to spot',
          value: species.bestTimeToSpot,
        ),
        const SizedBox(height: Space.md),
        _InfoTile(
          icon: Icons.shield_moon_rounded,
          label: 'Conservation status',
          value: species.conservationStatus.label,
          valueColor: species.conservationStatus.color,
        ),
      ],
    );
  }
}

class _WhereTab extends StatelessWidget {
  const _WhereTab({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.screen,
        Space.screen,
        Space.xxl,
      ),
      children: <Widget>[
        RegionStrip(regions: species.parkRegions),
        if (species.isSensitive) ...<Widget>[
          const SizedBox(height: Space.screen),
          const _SensitiveNotice(),
        ],
      ],
    );
  }
}

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: style.border, width: style.borderWidth),
        boxShadow: style.glow == null
            ? null
            : <BoxShadow>[
                BoxShadow(color: style.glow!, blurRadius: 24, spreadRadius: -6),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.card - 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[style.fill, Colors.transparent],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Space.screen),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        species.rarityTier.label.toUpperCase(),
                        style: AppText.overline.copyWith(color: style.accent),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Value of a verified sighting',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.md),
                Text(
                  '${species.points}',
                  style: AppText.display.copyWith(
                    color: style.accent,
                    fontSize: 40,
                    fontFeatures: AppText.tabular,
                  ),
                ),
                const SizedBox(width: Space.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'PTS',
                    style: AppText.overline.copyWith(color: style.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 116, child: Text(label, style: AppText.label)),
          Expanded(
            child: Text(
              value,
              style: AppText.bodyStrong.copyWith(
                fontSize: 14,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: AppText.caption),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 14.5,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensitiveNotice extends StatelessWidget {
  const _SensitiveNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: const Color(0x1AE0736B),
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: const Color(0x4DE0736B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.lock_rounded, size: 17, color: AppColors.danger),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              'Protected species. Sightings of this animal will never show a '
              'location — not on your profile, not on the leaderboard, and '
              'not in a shared card.',
              style: AppText.caption.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
