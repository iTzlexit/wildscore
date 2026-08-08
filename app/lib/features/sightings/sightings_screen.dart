import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/sightings.dart';
import '../../domain/species.dart';
import '../../domain/visit.dart';
import '../../shared/date_format.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../../shared/widgets/species_image.dart';
import '../codex/species_detail_screen.dart';

/// Latest Sightings — every notable find, newest first, with where it happened.
///
/// This replaced the Records tab, which was three statistics nobody opened
/// twice. What people actually want back out of a season of drives is the
/// **story**: the leopard on the S100 in March, who called it, and how long ago
/// that was now.
///
/// The roads make it. A sighting that says "Leopard · S100" is a memory in a
/// way that "Leopard" is not, and because the road network is bundled it costs
/// no signal and no server to say so. The strip at the top is the honest
/// version of a map for now — real tiles are a separate, much larger job, and a
/// grey rectangle saying "map coming soon" would be worth less than nothing.
///
/// See docs/MAPS.md for what a real map costs, and why the community version of
/// this feed is a different product rather than the next commit.
class SightingsScreen extends StatelessWidget {
  const SightingsScreen({
    required this.visits,
    required this.species,
    this.live,
    super.key,
  });

  final List<Visit> visits;
  final List<Species> species;

  /// The drive in play, so today's leopard appears the moment it is claimed
  /// rather than at the end of the day.
  final Scorecard? live;

  @override
  Widget build(BuildContext context) {
    final List<Sighting> sightings = Sightings.from(
      visits,
      species,
      live: live,
    );
    final List<TripGroup> trips = Sightings.byTrip(sightings);
    final List<RoadTally> roads = Sightings.roads(sightings);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const AppHeader(),
            Expanded(
              child: sightings.isEmpty
                  ? const _Empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.screen,
                        Space.sm,
                        Space.screen,
                        110,
                      ),
                      children: <Widget>[
                        Text('Latest sightings', style: AppText.title1),
                        const SizedBox(height: Space.xs),
                        Text(
                          '${sightings.length} '
                          '${sightings.length == 1 ? 'find' : 'finds'} worth '
                          'talking about.',
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (roads.isNotEmpty) ...<Widget>[
                          const SizedBox(height: Space.lg),
                          _RoadStrip(roads: roads),
                        ],
                        const SizedBox(height: Space.xl),
                        for (final TripGroup trip in trips) ...<Widget>[
                          _TripHeading(trip: trip),
                          const SizedBox(height: Space.md),
                          for (final Sighting s in trip.sightings)
                            _SightingRow(sighting: s),
                          const SizedBox(height: Space.lg),
                        ],
                        const _VerificationNote(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the finds happened, busiest road first.
///
/// Not a map, and not pretending to be one. It is the question a map would be
/// asked anyway — *where do we keep getting lucky* — answered with the data
/// already on the phone.
class _RoadStrip extends StatelessWidget {
  const _RoadStrip({required this.roads});

  final List<RoadTally> roads;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.route_rounded,
                size: 15,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'YOUR LUCKY ROADS',
                style: AppText.label.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final RoadTally r in roads.take(8))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Radii.chip - 2),
                    border: Border.all(color: AppColors.outlineStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        r.short,
                        style: AppText.caption.copyWith(
                          fontSize: 11.5,
                          fontVariations: AppFonts.weight(700),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${r.count}',
                        style: AppText.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontVariations: AppFonts.weight(800),
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripHeading extends StatelessWidget {
  const _TripHeading({required this.trip});

  final TripGroup trip;

  /// "2 August 2026", or "28 July – 2 August 2026" for a trip that ran a while.
  String get _dates {
    if (isSameDay(trip.first, trip.last)) {
      return formatLongDate(trip.last);
    }
    return '${formatShortDate(trip.first)} – ${formatLongDate(trip.last)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _dates,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (trip.live) ...<Widget>[
            const SizedBox(width: Space.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentWash,
                borderRadius: BorderRadius.circular(Radii.chip - 4),
              ),
              child: Text(
                'IN PLAY',
                style: AppText.label.copyWith(
                  fontSize: 9.5,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One find. Tapping it opens the animal — the commonest thing anyone wants
/// from a name they half remember.
class _SightingRow extends StatelessWidget {
  const _SightingRow({required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final Species species = sighting.species;
    final RarityStyle style = species.rarityTier.style;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          onTap: () => SpeciesDetailScreen.open(context, species),
          borderRadius: BorderRadius.circular(Radii.card),
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.chip),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: style.fill,
                    child: SpeciesImage(species: species),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              species.commonName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyStrong.copyWith(
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: Space.xs),
                          Text(
                            '${species.points}',
                            style: AppText.title3.copyWith(
                              fontSize: 15,
                              color: style.accent,
                              fontFeatures: AppText.tabular,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          AvatarBadge(
                            avatar: sighting.avatar,
                            size: 18,
                            ring: sighting.byOwner,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              sighting.byOwner ? 'You' : sighting.finder,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontVariations: AppFonts.weight(600),
                              ),
                            ),
                          ),
                          if (sighting.road case final String road) ...<Widget>[
                            const SizedBox(width: 6),
                            Flexible(
                              flex: 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.place_rounded,
                                    size: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  Flexible(
                                    child: Text(
                                      road,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (sighting.needsVerifying) ...<Widget>[
                        const SizedBox(height: 6),
                        const _UnverifiedChip(),
                      ],
                    ],
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

/// Marks a find that a photograph will eventually have to back up.
///
/// Says "on your word" rather than "unverified", because right now it *is* on
/// your word and there is no mechanism that could say otherwise. Calling it
/// unverified would imply a check exists and this one failed it.
class _UnverifiedChip extends StatelessWidget {
  const _UnverifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.chip - 4),
        border: Border.all(color: AppColors.outlineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.photo_camera_outlined,
            size: 11,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            'ON YOUR WORD',
            style: AppText.label.copyWith(
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationNote extends StatelessWidget {
  const _VerificationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('What is coming', style: AppText.title3),
          const SizedBox(height: Space.sm),
          Text(
            'Your rarest finds are marked "on your word" for now. Later you '
            'will be able to photograph one and have it checked, and after '
            'that, a proper map with your sightings pinned on it.',
            style: AppText.caption.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.visibility_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: Space.lg),
            Text(
              'Nothing here yet',
              style: AppText.title2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Your best finds land here — anything Rare and up, plus the Big '
              'Five. Where you found them too, when your location is on.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
