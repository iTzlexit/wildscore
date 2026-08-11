import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../domain/species_category.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../codex/species_detail_screen.dart';
import '../codex/widgets/species_grid_card.dart';

/// "What did Sam spot?" — the claim screen, opened from a player's row.
///
/// Claiming used to happen in the Animal Dex, which put that screen in two
/// minds: a tap was a claim during a game and a field-guide entry otherwise,
/// and the same grid meant two different things depending on state you could
/// not see. Worse, it asked the question backwards — you know who shouted
/// before you know what it was, because they shouted a name.
///
/// So the flow is player first: tap a name, pick the animal, done. One tap
/// fewer than before, no "who spotted it" sheet, and the Dex goes back to being
/// only a field guide.
class SpotPickerScreen extends StatefulWidget {
  const SpotPickerScreen({
    required this.player,
    required this.species,
    required this.card,
    super.key,
  });

  final Player player;
  final List<Species> species;
  final Scorecard card;

  /// Returns the chosen species, or null if dismissed.
  static Future<Species?> open(
    BuildContext context, {
    required Player player,
    required List<Species> species,
    required Scorecard card,
  }) {
    return Navigator.of(context).push<Species>(
      MaterialPageRoute<Species>(
        builder: (BuildContext context) =>
            SpotPickerScreen(player: player, species: species, card: card),
      ),
    );
  }

  @override
  State<SpotPickerScreen> createState() => _SpotPickerScreenState();
}

class _SpotPickerScreenState extends State<SpotPickerScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  SpeciesCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Chances remaining today, or null when unlimited.
  int? _chancesLeft(Species species) {
    final int? total = species.chancesPerDay;
    if (total == null) {
      return null;
    }
    return (total - widget.card.timesClaimed(species.id))
        .clamp(0, total)
        .toInt();
  }

  List<Species> get _visible {
    final List<Species> matched = <Species>[
      for (final Species s in widget.species)
        if (s.matchesQuery(_query) &&
            (_category == null || s.category == _category))
          s,
    ];
    // Spent tiles sink rather than disappear. The record of who got the impala
    // at the gate is part of the fun, and a tile that vanishes reads as a bug.
    matched.sort((Species a, Species b) {
      final bool aSpent = _chancesLeft(a) == 0;
      final bool bSpent = _chancesLeft(b) == 0;
      if (aSpent != bSpent) {
        return aSpent ? 1 : -1;
      }
      final int byTier = RarityTier.values
          .indexOf(b.rarityTier)
          .compareTo(RarityTier.values.indexOf(a.rarityTier));
      return byTier != 0 ? byTier : a.commonName.compareTo(b.commonName);
    });
    return matched;
  }

  @override
  Widget build(BuildContext context) {
    final List<Species> visible = _visible;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            AvatarBadge(
              avatar: widget.player.avatar,
              size: 30,
              ring: widget.player.isOwner,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'What did ${widget.player.name} spot?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title3,
                  ),
                  Text(
                    '${widget.card.pointsFor(widget.player.id)} points so far',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                controller: _search,
                autofocus: false,
                onChanged: (String v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: searchFieldDecoration(
                  'Search — impala, rooibok…',
                ).copyWith(helperText: 'Tap to claim · hold to look it up'),
              ),
            ),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                children: <Widget>[
                  _Chip(
                    label: 'All',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final SpeciesCategory c in SpeciesCategory.values)
                    _Chip(
                      label: c.label,
                      selected: _category == c,
                      onTap: () =>
                          setState(() => _category = _category == c ? null : c),
                    ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(child: Text('Nothing matches', style: AppText.label))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
                        final int? left = _chancesLeft(s);
                        return SpeciesGridCard(
                          species: s,
                          // Coloured by what the car has claimed today, not by
                          // the lifetime record — the question here is "have we
                          // got it yet", and it is a different question.
                          locked: !widget.card.claimedSpecies.contains(s.id),
                          chancesLeft: left,
                          onTap: left == 0
                              ? () {}
                              : () => Navigator.of(context).pop(s),
                          // Long-press to look it up without claiming it.
                          //
                          // The one place in the app where you had the animal
                          // in front of you and no way to check what it was —
                          // which is exactly when somebody in the back seat
                          // says "are you sure that's a steenbok". A tap still
                          // claims, because that is what this screen is for.
                          onLongPress: () =>
                              SpeciesDetailScreen.open(context, s),
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.outline,
              ),
            ),
            child: Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 12,
                color: selected ? AppColors.accentInk : AppColors.textSecondary,
                fontVariations: AppFonts.weight(selected ? 700 : 500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
