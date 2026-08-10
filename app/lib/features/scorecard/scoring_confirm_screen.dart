import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../domain/species.dart';
import '../../shared/emphasis.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/species_image.dart';

/// The prices, agreed before anybody drives off.
///
/// **Alex's rule: the car confirms the table before a game starts.** Our
/// numbers are one opinion, and an argument about what a sable is worth is
/// funny at the gate and sour at four in the afternoon when somebody has
/// already scored one. Settling it first costs a single tap for the car that
/// agrees with us, and gives the car that does not somewhere to say so.
///
/// Prices set here are saved, so this is a one-off for most people: the second
/// morning opens the same screen showing the same numbers, already theirs.
class ScoringConfirmScreen extends StatefulWidget {
  const ScoringConfirmScreen({
    required this.species,
    required this.players,
    required this.onSetPoints,
    super.key,
  });

  /// The catalogue with the car's own prices already folded in.
  final List<Species> species;

  /// Who is playing, purely so the button can say so.
  final List<String> players;

  /// Persist one price, or null to hand the animal back to our number.
  final void Function(String id, int? points) onSetPoints;

  /// Returns true if the car started the game.
  static Future<bool> show(
    BuildContext context, {
    required List<Species> species,
    required List<String> players,
    required void Function(String id, int? points) onSetPoints,
  }) async {
    final bool? started = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ScoringConfirmScreen(
          species: species,
          players: players,
          onSetPoints: onSetPoints,
        ),
      ),
    );
    return started ?? false;
  }

  @override
  State<ScoringConfirmScreen> createState() => _ScoringConfirmScreenState();
}

class _ScoringConfirmScreenState extends State<ScoringConfirmScreen> {
  /// Prices changed since this screen opened.
  ///
  /// Saved immediately, but held here as well: the catalogue is rebuilt above
  /// us and this route keeps the list it was handed, so without the overlay a
  /// row would still show the old number after being changed.
  final Map<String, int> _edited = <String, int>{};

  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// Sorted once, on the way in.
  ///
  /// Deliberately not re-sorted as prices change. Somebody moving the sable up
  /// two bands does not want the row to leap out from under their thumb, and
  /// they are very likely about to change the animal next to it as well.
  late final List<Species> _ordered = <Species>[...widget.species]
    ..sort((Species a, Species b) {
      final int byPoints = b.points.compareTo(a.points);
      return byPoints != 0 ? byPoints : a.commonName.compareTo(b.commonName);
    });

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _priceOf(Species s) => _edited[s.id] ?? s.points;

  bool _isOurs(Species s) => _priceOf(s) == s.cataloguePoints;

  Future<void> _edit(Species s) async {
    final (int,)? chosen = await showModalBottomSheet<(int,)>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          _PriceSheet(species: s, current: _priceOf(s)),
    );
    if (chosen == null) {
      return;
    }
    final int value = chosen.$1;
    setState(() => _edited[s.id] = value);
    // Back to our number clears the override rather than storing a copy of it,
    // or a car that agreed with us today would be pinned to today's number
    // when we revalue the animal.
    widget.onSetPoints(s.id, value == s.cataloguePoints ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final String query = _query.trim().toLowerCase();
    final List<Species> shown = query.isEmpty
        ? _ordered
        : <Species>[
            for (final Species s in _ordered)
              if (s.commonName.toLowerCase().contains(query) ||
                  s.scientificName.toLowerCase().contains(query))
                s,
          ];
    final int changed = _ordered.where((Species s) => !_isOurs(s)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('The prices', style: AppText.title2),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              0,
              Space.screen,
              Space.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                emphasised(
                  'Points say how hard an animal is to find, nothing more. '
                  '**Disagree with one? Tap it.**',
                  style: AppText.body.copyWith(height: 1.5),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  changed == 0
                      ? 'Whatever you set is remembered for next time.'
                      : 'You have your own price on $changed '
                            '${changed == 1 ? 'animal' : 'animals'}.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.md),
                TextField(
                  controller: _search,
                  onChanged: (String v) => setState(() => _query = v),
                  style: AppText.body,
                  textInputAction: TextInputAction.search,
                  decoration: searchFieldDecoration('Find an animal').copyWith(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      'Nothing by that name.',
                      style: AppText.caption,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      Space.screen,
                      0,
                      Space.screen,
                      Space.xxl,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Species s = shown[i];
                      final Species? above = i == 0 ? null : shown[i - 1];
                      return Column(
                        children: <Widget>[
                          if (above == null ||
                              above.rarityTier != s.rarityTier) ...<Widget>[
                            if (above != null) const SizedBox(height: Space.md),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Space.sm,
                                top: Space.xs,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  s.rarityTier.label.toUpperCase(),
                                  style: AppText.overline.copyWith(
                                    color: s.rarityTier.style.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          _PriceRow(
                            species: s,
                            points: _priceOf(s),
                            isOurs: _isOurs(s),
                            onTap: () => _edit(s),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.sm,
                Space.screen,
                Space.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                  ),
                  child: Text(
                    'Agreed  ·  start the day',
                    style: AppText.bodyStrong.copyWith(
                      color: AppColors.accentInk,
                    ),
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

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.species,
    required this.points,
    required this.isOurs,
    required this.onTap,
  });

  final Species species;
  final int points;
  final bool isOurs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = species.rarityTier.style.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.card),
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: isOurs ? AppColors.outline : accent),
            ),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.chip),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: SpeciesImage(species: species),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        species.commonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong,
                      ),
                      if (!isOurs)
                        Text(
                          'yours · ours is ${species.cataloguePoints}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(color: accent),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text(
                  '$points',
                  style: AppText.title3.copyWith(
                    color: accent,
                    fontFeatures: AppText.tabular,
                  ),
                ),
                const SizedBox(width: Space.xs),
                const Icon(
                  Icons.tune_rounded,
                  size: 17,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What one animal is worth, on the ladder every other animal already sits on.
///
/// A slider over fixed rungs rather than a number field: it is operated with a
/// thumb, and a free number lets somebody put an impala on 999 and quietly
/// wreck their own game.
class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.species, required this.current});

  final Species species;
  final int current;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  static final List<int> _rungs = RarityTier.allRungs;

  late int _value = widget.current;

  int get _index {
    int best = 0;
    for (int i = 1; i < _rungs.length; i++) {
      if ((_rungs[i] - _value).abs() < (_rungs[best] - _value).abs()) {
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final Species s = widget.species;
    final Color accent = s.rarityTier.style.accent;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(Space.md),
        padding: const EdgeInsets.all(Space.screen),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sheet),
          boxShadow: AppColors.shadowMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'What is a ${s.commonName.toLowerCase()} worth?',
              style: AppText.title3,
            ),
            const SizedBox(height: Space.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'IN YOUR GAME',
                    style: AppText.overline.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  '$_value',
                  style: AppText.title2.copyWith(
                    color: accent,
                    fontFeatures: AppText.tabular,
                    fontVariations: AppFonts.weight(800),
                  ),
                ),
              ],
            ),
            Slider(
              value: _index.toDouble(),
              max: (_rungs.length - 1).toDouble(),
              divisions: _rungs.length - 1,
              activeColor: accent,
              label: '$_value',
              onChanged: (double v) =>
                  setState(() => _value = _rungs[v.round()]),
            ),
            Text(_describe(_value), style: AppText.caption),
            const SizedBox(height: Space.lg),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((_value,)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentInk,
                  ),
                  child: const Text('Use this'),
                ),
                if (_value != s.cataloguePoints)
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop((s.cataloguePoints,)),
                    child: Text('Back to ours · ${s.cataloguePoints}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _describe(int value) {
    for (final RarityTier t in RarityTier.values) {
      if (value <= t.high) {
        return 'About as hard to find as a ${t.label.toLowerCase()} animal.';
      }
    }
    return '';
  }
}
