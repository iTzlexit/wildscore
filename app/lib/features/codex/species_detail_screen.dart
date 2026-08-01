import 'package:flutter/material.dart';

import '../../domain/species.dart';
import '../../domain/species_tag.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/species_image.dart';
import 'photo_viewer_screen.dart';
import 'widgets/region_strip.dart';

/// The species card, full screen.
///
/// Structure: the rarity colour **owns the top of the screen**, with the
/// photograph straddling the boundary into a rounded sheet below. That is the
/// single change that stops a detail screen reading as a form — a timid
/// coloured border says "database row"; a full-bleed colour field says "card".
///
/// This layout is also the skeleton of the Phase 2 reveal. When you photograph
/// a pangolin, this is the card that turns over, so the hierarchy is worth
/// getting right now: colour, then who it is, then what it is worth.
class SpeciesDetailScreen extends StatelessWidget {
  const SpeciesDetailScreen({
    required this.species,
    this.photoCredit,
    super.key,
  });

  final Species species;

  /// Photographer and licence, shown in the full-screen viewer. Required by
  /// CC-BY; null when the species has no sourced photograph.
  final String? photoCredit;

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
            Expanded(child: _Sheet(species: species)),
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

    return SizedBox(
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // The colour field. A vertical gradient rather than a flat fill so
          // the photograph has somewhere darker to sit against.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[style.headerTop, style.headerInk],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.sm,
                Space.sm,
                Space.screen,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
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
                  Padding(
                    padding: const EdgeInsets.only(left: Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          species.commonName,
                          style: AppText.title1.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          species.scientificName,
                          style: AppText.caption.copyWith(
                            color: const Color(0xB3FFFFFF),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.sm,
                          children: <Widget>[
                            _HeaderPill(
                              label: species.rarityTier.label,
                              solid: true,
                            ),
                            for (final SpeciesTag tag in species.tags)
                              _HeaderPill(label: tag.label, solid: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The photograph straddles the header/sheet boundary. Overflowing the
          // seam is what makes the card feel layered rather than stacked.
          Positioned(
            right: Space.screen,
            bottom: -34,
            child: GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(PhotoViewerScreen.route(species, credit: credit)),
              child: Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x40FFFFFF), width: 3),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x59000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
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
            ),
          ),
        ],
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
  const _Sheet({required this.species});

  final Species species;

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
          // Room for the photograph overhanging from the header.
          const SizedBox(height: Space.section),
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
                _AboutTab(species: species),
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

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.screen,
        Space.screen,
        Space.xxl,
      ),
      children: <Widget>[
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
        const SizedBox(height: Space.xl),
        _LogSightingTeaser(accent: style.accent),
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

class _LogSightingTeaser extends StatelessWidget {
  const _LogSightingTeaser({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Space.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.photo_camera_rounded, size: 22, color: accent),
          const SizedBox(height: Space.sm),
          Text(
            'Log a sighting',
            style: AppText.bodyStrong.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(
            'Camera capture arrives in the next update',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
