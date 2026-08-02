import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../domain/species.dart';
import '../../domain/species_collection.dart';
import '../../shared/theme.dart';
import 'species_detail_screen.dart';
import 'widgets/species_grid_card.dart';

/// Everything you have found, or everything you have not.
///
/// Reached by tapping the SPOTTED or TO FIND numbers on the profile. Those
/// numbers were previously dead text, which is a small betrayal: a count on a
/// dashboard reads as a link, and a player who taps it and gets nothing learns
/// that the app's numbers are decoration.
///
/// This is the lifetime record specifically — it never shows the day's
/// scorecard. A trophy shelf does not empty itself at sunset.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({
    required this.species,
    required this.caughtIds,
    this.mode,
    this.group,
    super.key,
  }) : assert(
         mode != null || group != null,
         'a collection screen shows either spotted/to-find or a named set',
       );

  final List<Species> species;
  final Set<String> caughtIds;

  /// Spotted or still to find, across the whole catalogue.
  final CollectionMode? mode;

  /// A named set — Big Five, Antelope, and so on. Shows both spotted and
  /// unspotted members, because the question is "how far off am I", and a list
  /// with the missing ones removed cannot answer it.
  final SpeciesCollection? group;

  static Future<void> open(
    BuildContext context, {
    required List<Species> species,
    required Set<String> caughtIds,
    CollectionMode? mode,
    SpeciesCollection? group,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CollectionScreen(
          species: species,
          caughtIds: caughtIds,
          mode: mode,
          group: group,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SpeciesCollection? group = this.group;
    final List<Species> visible =
        <Species>[
            if (group != null)
              ...group.membersOf(species)
            else
              for (final Species s in species)
                if (caughtIds.contains(s.id) ==
                    (mode == CollectionMode.spotted))
                  s,
          ]
          // Rarest first. On the spotted list that puts your best find at the
          // top, which is the reason anyone opens it. On the to-find list it
          // puts the pangolin at the top, which is the reason anyone goes back
          // to the park.
          ..sort(byRarityThenName);

    final int found = visible
        .where((Species s) => caughtIds.contains(s.id))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(group?.label ?? mode!.title, style: AppText.title2),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.xs,
                Space.screen,
                Space.md,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    group == null ? mode!.icon : group.icon,
                    size: 17,
                    color: group == null ? mode!.tint : AppColors.accent,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      group == null
                          ? '${visible.length} ${mode!.subtitle}'
                          : '$found of ${visible.length} · ${group.blurb}',
                      style: AppText.label,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _Empty(mode: mode ?? CollectionMode.spotted)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: SpeciesGridCard.aspectRatio,
                          ),
                      itemCount: visible.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Species s = visible[index];
                        return SpeciesGridCard(
                          species: s,
                          locked: !caughtIds.contains(s.id),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  SpeciesDetailScreen(species: s),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icons live here rather than in the domain, which has no Flutter import.
extension SpeciesCollectionIcon on SpeciesCollection {
  IconData get icon => switch (this) {
    SpeciesCollection.bigFive => Icons.workspace_premium_rounded,
    SpeciesCollection.smallFive => Icons.zoom_in_rounded,
    SpeciesCollection.bigSixBirds => Icons.flutter_dash_rounded,
    SpeciesCollection.endangered => Icons.heart_broken_rounded,
    SpeciesCollection.antelope => Icons.grass_rounded,
    SpeciesCollection.predators => Icons.pets_rounded,
    SpeciesCollection.snakes => Icons.gesture_rounded,
    SpeciesCollection.nocturnal => Icons.nightlight_round,
  };
}

enum CollectionMode {
  spotted(
    title: 'Your collection',
    subtitle: 'species spotted, rarest first',
    icon: Icons.check_circle_rounded,
    tint: AppColors.verified,
  ),
  toFind(
    title: 'Still to find',
    subtitle: 'species you have never spotted',
    icon: Icons.visibility_outlined,
    tint: AppColors.textSecondary,
  );

  const CollectionMode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
}

/// Rarest first, then alphabetical within a tier.
int byRarityThenName(Species a, Species b) {
  final int byTier = RarityTier.values
      .indexOf(b.rarityTier)
      .compareTo(RarityTier.values.indexOf(a.rarityTier));
  return byTier != 0 ? byTier : a.commonName.compareTo(b.commonName);
}

class _Empty extends StatelessWidget {
  const _Empty({required this.mode});

  final CollectionMode mode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(mode.icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: Space.lg),
            Text(
              mode == CollectionMode.spotted
                  ? 'Nothing spotted yet'
                  : 'You have found every one',
              style: AppText.title3,
            ),
            const SizedBox(height: Space.sm),
            Text(
              mode == CollectionMode.spotted
                  ? 'Mark an animal in the Animal Dex, or start a scorecard and '
                        'claim one.'
                  : 'Every species in the park. That is the whole book.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
