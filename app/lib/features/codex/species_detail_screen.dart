import 'package:flutter/material.dart';

import '../../domain/species.dart';
import '../../domain/species_tag.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/species_image.dart';
import 'widgets/region_strip.dart';

/// The species card, full screen.
///
/// This layout is the skeleton of the reveal moment in Phase 2 — when you
/// photograph a pangolin, this is the card that flips over. Worth getting the
/// hierarchy right now: image, then points, then who it is, then where to find
/// it.
class SpeciesDetailScreen extends StatelessWidget {
  const SpeciesDetailScreen({required this.species, super.key});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(species: species),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Names(species: species),
                  const SizedBox(height: 20),
                  _PointsBanner(species: species),
                  const SizedBox(height: 16),
                  _Badges(species: species),
                  if (species.isSensitive) ...<Widget>[
                    const SizedBox(height: 16),
                    const _SensitiveNotice(),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    species.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionLabel('FIELD NOTES'),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.park_rounded,
                    label: 'Habitat',
                    value: species.habitat,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Best time to spot',
                    value: species.bestTimeToSpot,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.shield_moon_rounded,
                    label: 'Conservation status',
                    value: species.conservationStatus.label,
                    valueColor: species.conservationStatus.color,
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('WHERE TO FIND IT'),
                  const SizedBox(height: 14),
                  RegionStrip(regions: species.parkRegions),
                  const SizedBox(height: 30),
                  _LogSightingTeaser(accent: style.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        SpeciesImage(species: species),
        // Scrim, so the app bar icons stay legible over any photograph.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xB30E1210),
                Color(0x330E1210),
                Color(0xFF0E1210),
              ],
              stops: <double>[0, 0.45, 1],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(height: 3, color: style.accent),
        ),
      ],
    );
  }
}

class _Names extends StatelessWidget {
  const _Names({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          species.commonName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          species.scientificName,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const Text(
              'AFRIKAANS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                species.afrikaansName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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

    // The solid fill and the gradient wash live on separate layers on purpose.
    // A BoxDecoration given both `color` and `gradient` paints only the
    // gradient — so the transparent end would fade to the scaffold background
    // instead of the card surface. Same two-layer structure as SpeciesCard.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border, width: style.borderWidth),
        boxShadow: style.glow == null
            ? null
            : <BoxShadow>[
                BoxShadow(color: style.glow!, blurRadius: 24, spreadRadius: -6),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[style.fill, Colors.transparent],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: <Widget>[
                // Expanded rather than a fixed Column plus a Spacer: at large
                // system font scales the label column would otherwise push the
                // points off the right edge. Accessibility text scaling is a
                // real setting real people use, not a theoretical case.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        species.rarityTier.label.toUpperCase(),
                        style: TextStyle(
                          color: style.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Value of a verified sighting',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${species.points}',
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.6,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'PTS',
                    style: TextStyle(
                      color: style.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
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

class _Badges extends StatelessWidget {
  const _Badges({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final SpeciesTag tag in species.tags)
          Pill(
            label: tag.label,
            color: tag == SpeciesTag.nocturnal
                ? const Color(0xFF7FA6D8)
                : AppColors.accent,
            icon: tag == SpeciesTag.nocturnal
                ? Icons.nightlight_round
                : Icons.workspace_premium_rounded,
          ),
        Pill(label: species.category.singular, color: AppColors.textSecondary),
        Pill(
          label:
              '${species.conservationStatus.code} · ${species.conservationStatus.label}',
          color: species.conservationStatus.color,
        ),
      ],
    );
  }
}

class _SensitiveNotice extends StatelessWidget {
  const _SensitiveNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1AE0736B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4DE0736B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lock_rounded, size: 17, color: AppColors.danger),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Protected species. Sightings of this animal will never show a '
              'location — not on your profile, not on the leaderboard, and '
              'not in a shared card.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
        color: AppColors.surface,
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.photo_camera_rounded, color: accent, size: 22),
          const SizedBox(height: 9),
          const Text(
            'Log a sighting',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Camera capture arrives in the next update',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
