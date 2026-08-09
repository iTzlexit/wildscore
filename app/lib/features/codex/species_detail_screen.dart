import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/attribution_repository.dart';
import '../../domain/population.dart';
import '../../domain/rarity_tier.dart';
import '../../domain/species.dart';
import '../../domain/species_tag.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/species_image.dart';
import 'photo_viewer_screen.dart';
import 'widgets/region_strip.dart';

/// The species card, full screen.
///
/// Structure: **the animal owns the top of the screen**, whole and uncropped,
/// with its name over the foot of the photograph and everything else in the
/// sheet below.
///
/// It took three goes. First the portrait sat in the bottom-right corner,
/// straddling the seam into the sheet, where it looked like an afterthought and
/// got clipped on a narrow phone. Then a centred medallion with concentric
/// halos — prettier, and still wrong: a disc crops an animal to a disc, the
/// black rhino lost its horn to the curve, and most of the header was coloured
/// space around a small picture. Then a single full-bleed `cover` photograph,
/// which showed far more animal and cut the sides off the wide ones.
///
/// What settles every one of those arguments is what this screen is *for*.
/// Somebody is holding the phone up next to an animal standing in the road. The
/// photograph is the product and the whole of it has to be there, so the
/// portrait is `contain`ed and the header is filled behind it with a blurred
/// copy of the same image. Rarity is said by the colour it sits on rather than
/// by a ring around it.
///
/// This layout is also the skeleton of the Phase 2 reveal. When you photograph
/// a pangolin, this is the card that turns over.
class SpeciesDetailScreen extends StatefulWidget {
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
  ///
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
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  /// Tracked here as well as by the caller.
  ///
  /// The button used to tell its owner and then **close the screen**, because
  /// this widget was stateless and had no way to show the new value. That made
  /// adding something feel like an error — the card vanished — and it made
  /// changing your mind impossible without reopening the animal. Holding the
  /// state locally lets the button just change, which is what a toggle is
  /// supposed to do.
  late bool _spotted = widget.spotted;

  @override
  void didUpdateWidget(SpeciesDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.spotted != widget.spotted) {
      _spotted = widget.spotted;
    }
  }

  void _toggle() {
    setState(() => _spotted = !_spotted);
    widget.onToggleSpotted!();
  }

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = widget.species.rarityTier.style;

    return Scaffold(
      backgroundColor: style.headerInk,
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: <Widget>[
            _Header(species: widget.species, credit: widget.photoCredit),
            Expanded(
              child: _Sheet(
                species: widget.species,
                spotted: _spotted,
                onToggleSpotted: widget.onToggleSpotted == null
                    ? null
                    : _toggle,
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
    // the number.
    final double height = (screen.height * 0.50).clamp(340.0, 500.0);

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // The tier colour underneath, so a silhouette species still gets a
          // coloured field rather than a grey hole.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[style.headerTop, style.headerInk],
              ),
            ),
          ),
          // The photograph twice: blurred and cropped to fill the box, then
          // whole and sharp on top of itself.
          //
          // Filling the header with a single `cover` copy was the obvious thing
          // and it was wrong. Sixty-three of the seventy-seven photographs are
          // landscape — the median is 4:3 and one is 2.43:1 — and this box is
          // portrait, so covering it threw away a third of the width, and well
          // over half on the wide ones. Animals came out with their heads or
          // hindquarters missing, which in a *field guide* is the one failure
          // that matters.
          //
          // So the sharp copy is `contain`: every photograph is whole, always,
          // whatever shape it is. The blurred copy exists only so that the
          // bands `contain` leaves are made of the animal's own colours rather
          // than a flat rectangle.
          if (species.photoVerified)
            Positioned.fill(
              child: ClipRect(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                  // Overscaled because a blur samples past the edges of what it
                  // is given, which leaves a pale fringe on all four sides.
                  child: Transform.scale(
                    scale: 1.2,
                    child: SpeciesImage(species: species),
                  ),
                ),
              ),
            ),
          if (species.photoVerified)
            Positioned.fill(
              child: ColoredBox(color: style.headerInk.withValues(alpha: 0.45)),
            ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(PhotoViewerScreen.route(species, credit: credit)),
              child: Hero(
                tag: 'species-photo-${species.id}',
                child: SpeciesImage(
                  // Named so tests can tell the sharp copy from the blurred
                  // one behind it.
                  key: const Key('species-portrait'),
                  species: species,
                  fit: BoxFit.contain,
                  onDark: true,
                  // Sat above centre so the band a landscape photograph leaves
                  // falls at the bottom, under the name, instead of splitting
                  // evenly and putting the animal behind it.
                  alignment: const Alignment(0, -0.45),
                ),
              ),
            ),
          ),
          // Scrim, top and bottom. The top one only has to carry a back arrow
          // and a number; the bottom one has to carry a name at 31pt over
          // whatever the photographer happened to have behind the animal, so it
          // is deep and lands on the tier's own ink.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0x73000000),
                      Colors.transparent,
                      style.headerInk.withValues(alpha: 0.72),
                      style.headerInk,
                    ],
                    stops: const <double>[0, 0.28, 0.68, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          color: Colors.white,
                          fontFeatures: AppText.tabular,
                          shadows: _inkShadow,
                        ),
                      ),
                    ],
                  ),
                ),
                // Left-aligned now, not centred. Centred text belongs over a
                // centred subject; over a photograph it floats, and a long name
                // centred across three lines is harder to read than the same
                // name ranged left.
                //
                // FittedBox around a width-pinned block: the name still wraps
                // at the real screen width, and only shrinks when it genuinely
                // will not fit — "Southern Ground Hornbill" at 1.5× text on a
                // 360pt phone overflowed the header by six pixels otherwise.
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        width: screen.width,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Space.screen,
                            0,
                            Space.screen,
                            Space.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                species.commonName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.title1.copyWith(
                                  color: Colors.white,
                                  fontSize: species.commonName.length > 20
                                      ? 27
                                      : 33,
                                  height: 1.1,
                                  shadows: _inkShadow,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                species.scientificName,
                                style: AppText.caption.copyWith(
                                  color: const Color(0xC7FFFFFF),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  shadows: _inkShadow,
                                ),
                              ),
                              const SizedBox(height: Space.md),
                              Wrap(
                                spacing: Space.sm,
                                runSpacing: 6,
                                children: <Widget>[
                                  _HeaderPill(
                                    label: species.rarityTier.label,
                                    solid: true,
                                  ),
                                  // Two at most. Every tag is also on the tile and in
                                  // the sheet, and a third row of pills eats into the
                                  // photograph to say something nobody came here to
                                  // read.
                                  for (final SpeciesTag tag
                                      in species.tags.take(2))
                                    _HeaderPill(label: tag.label, solid: false),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Says the photograph opens. Bottom right, clear of the name.
          Positioned(
            right: Space.screen,
            bottom: Space.lg,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0x59000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.zoom_out_map_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Just enough shadow to keep white text legible over a pale sky, without the
/// text looking like it has been embossed.
const List<Shadow> _inkShadow = <Shadow>[
  Shadow(color: Color(0x8C000000), blurRadius: 12, offset: Offset(0, 1)),
];

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
        if (species.population != null) ...<Widget>[
          const SizedBox(height: Space.screen),
          _PopulationCard(
            population: species.population!,
            tier: species.rarityTier,
          ),
        ],
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
                  style: AppText.title1.copyWith(
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

/// How many are left, under the description.
///
/// Placed here rather than in the Field notes list on purpose. Habitat and best
/// time are reference — you read them once, when planning. This is the line
/// somebody reads out to the rest of the car, and it belongs where the eye
/// already is: directly under the paragraph about the animal, before the
/// Afrikaans name and the tidy little label rows.
///
/// The number is the headline and the provenance is underneath it in small
/// type, because "40 – 75" without "aerial survey, 2023" beside it is a claim
/// rather than a fact.
class _PopulationCard extends StatelessWidget {
  const _PopulationCard({required this.population, required this.tier});

  final Population population;
  final RarityTier tier;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = tier.style;
    final bool known = population.isKnown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                known ? Icons.groups_2_rounded : Icons.visibility_off_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'HOW MANY ARE IN THE PARK',
                  style: AppText.overline.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            population.display,
            style: AppText.display.copyWith(
              color: known ? style.accent : AppColors.textPrimary,
              fontVariations: AppFonts.weight(800),
            ),
          ),
          if (population.note != null) ...<Widget>[
            const SizedBox(height: Space.sm),
            Text(population.note!, style: AppText.body),
          ],
          if (known) ...<Widget>[
            const SizedBox(height: Space.xs),
            Text(
              population.attribution,
              style: AppText.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
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
              'Protected species. Sightings of this animal never record a '
              'location — not in your sightings, not on a scorecard, and not '
              'in a backup. The phone does not even look it up.',
              style: AppText.caption.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
