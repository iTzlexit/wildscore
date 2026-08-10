import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../domain/sighting_context.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';

/// What the claim was worth, decided by the two questions worth asking.
class ClaimDetails {
  const ClaimDetails({
    required this.context,
    required this.variants,
    this.extras = const <SightingExtra>{},
  });

  static const ClaimDetails ordinary = ClaimDetails(
    context: SightingContext.normal,
    variants: <String>{},
  );

  final SightingContext context;
  final Set<String> variants;
  final Set<SightingExtra> extras;
}

/// Asked immediately after the animal is picked, and only when the answer
/// changes something.
///
/// Two questions at most, both a single tap, both on one screen. The whole
/// claim has to stay fast enough to do while the animal is still there — this
/// sits between "who spotted it" and the points landing, and if it ever grows
/// a third question it has gone too far.
///
/// Returns null if dismissed, which the caller treats as cancelling the claim
/// rather than as an ordinary sighting. Backing out of a half-finished claim
/// should not silently score one.
class ClaimDetailsSheet extends StatefulWidget {
  const ClaimDetailsSheet({
    required this.species,
    this.jamMultiplier,
    super.key,
  });

  final Species species;

  /// What a jam sighting keeps, if the car has changed it. Null is our 0.8.
  final double? jamMultiplier;

  /// True when this species has anything worth asking about. Checked by the
  /// caller so that the common claim — an impala, a zebra — never sees a sheet
  /// at all.
  /// Deliberately does **not** include [Species.possibleExtras]. Every mammal
  /// can have young, so testing that here would put a sheet in front of every
  /// impala — the exact friction the bar exists to avoid. The extras are asked
  /// about only for animals that already clear it.
  static bool needed(Species species) =>
      species.crowdMatters ||
      species.variants.isNotEmpty ||
      // Anything worth a modifier at all, once it is past the everyday end of
      // the scale. It used to be crowd-or-variant only, which meant a kudu
      // could never be marked as having a calf with it — the sheet simply
      // never appeared. Common stays one tap, because a sheet in front of
      // every zebra is the friction this bar exists to prevent.
      (species.possibleExtras.isNotEmpty &&
          species.points >= RarityTier.frequent.low);

  static Future<ClaimDetails?> ask(
    BuildContext context,
    Species species, {
    double? jamMultiplier,
  }) {
    if (!needed(species)) {
      return Future<ClaimDetails?>.value(ClaimDetails.ordinary);
    }
    return showModalBottomSheet<ClaimDetails>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          ClaimDetailsSheet(species: species, jamMultiplier: jamMultiplier),
    );
  }

  @override
  State<ClaimDetailsSheet> createState() => _ClaimDetailsSheetState();
}

class _ClaimDetailsSheetState extends State<ClaimDetailsSheet> {
  SightingContext _context = SightingContext.normal;
  final Set<String> _variants = <String>{};
  final Set<SightingExtra> _extras = <SightingExtra>{};

  /// What the claim would be worth answered one way, everything else held.
  ///
  /// So the buttons can show their own consequence rather than only moving the
  /// total at the top, and so the two numbers stay honest when a male lion or a
  /// kill is already ticked.
  double get _jamPenalty =>
      1 - (widget.jamMultiplier ?? SightingContext.jam.multiplier);

  int _pointsIn(SightingContext crowd) => widget.species.scoreFor(
    variantsApplied: _variants,
    context: crowd,
    extras: _extras,
    jamMultiplier: widget.jamMultiplier,
  );

  @override
  Widget build(BuildContext context) {
    final Species species = widget.species;
    final RarityStyle style = species.rarityTier.style;
    final int points = species.scoreFor(
      variantsApplied: _variants,
      context: _context,
      extras: _extras,
      jamMultiplier: widget.jamMultiplier,
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sheet),
          border: Border.all(color: AppColors.outline),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.lg,
                  Space.lg,
                  Space.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        species.commonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title2,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    // Live, because watching the number move as you answer is
                    // what teaches the rule. Nobody reads a rules screen.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        '$points',
                        key: ValueKey<int>(points),
                        style: AppText.title1.copyWith(
                          fontSize: 30,
                          color: style.accent,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Which one of these it was, and it can be several.
              //
              // A yes/no pair per variant would be four questions on an
              // elephant. Chips you tap are one question — "which of these was
              // it" — and they let a big tusker also be a lone bull in musth,
              // which is a real morning and not one anybody should have to
              // pick between.
              if (species.variants.isNotEmpty) ...<Widget>[
                const Divider(height: 1, color: AppColors.outline),
                const _Question(label: 'Which one was it?'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.lg,
                  ),
                  child: Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: <Widget>[
                      for (final SpeciesVariant v in species.variants)
                        _Choice(
                          label: v.label,
                          detail: '×${v.multiplier}',
                          selected: _variants.contains(v.label),
                          onTap: () => setState(() {
                            if (!_variants.remove(v.label)) {
                              _variants.add(v.label);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],

              // What it was doing. Only the questions that make sense for this
              // animal — a puff adder is never asked whether it was on a kill.
              if (species.possibleExtras.isNotEmpty) ...<Widget>[
                const Divider(height: 1, color: AppColors.outline),
                // "Anything special about it?" was the heading, which stopped
                // making sense the moment one of the answers took points away.
                // Being in a camp is not special, it is a discount.
                const _Question(label: 'Bonus points and deductions'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.lg,
                  ),
                  child: Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: <Widget>[
                      for (final SightingExtra e in species.possibleExtras)
                        _Choice(
                          label: e.label,
                          // Read from the extra rather than typed. It said
                          // ×1.5 on every chip, which was wrong for four of the
                          // six and actively misleading on the one that takes
                          // points away — "In camp ×1.5" reads as a bonus.
                          detail: e.effect,
                          selected: _extras.contains(e),
                          onTap: () => setState(() {
                            if (!_extras.remove(e)) {
                              _extras.add(e);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],

              // Two marks, not three choices. Neither selected is the ordinary
              // sighting and needs no answer — most of them are ordinary, and a
              // three-way radio made every claim a decision.
              //
              // **Stacked, not side by side.** Two half-width chips could not
              // fit "Lone sighting" next to what it was worth, so the label
              // ellipsed and the owner could not read his own buttons. Full
              // width also makes room for the arithmetic, which is the point:
              // the sheet should show what a jam costs, not leave somebody to
              // work it out from a total that moved.
              if (species.crowdMatters) ...<Widget>[
                const Divider(height: 1, color: AppColors.outline),
                const _Question(label: 'Who else was there?'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.lg,
                  ),
                  child: Column(
                    children: <Widget>[
                      _CrowdChoice(
                        label: SightingContext.alone.label,
                        note: 'You spotted it yourself',
                        total: _pointsIn(SightingContext.alone),
                        accent: style.accent,
                        selected: _context == SightingContext.alone,
                        onTap: () => setState(
                          () => _context = _context == SightingContext.alone
                              ? SightingContext.normal
                              : SightingContext.alone,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      _CrowdChoice(
                        label: SightingContext.jam.label,
                        note: 'Cars were already there',
                        // The sum, spelled out. "80" on its own looks like a
                        // different animal; "100 − 20%" is the rule.
                        // The percentage comes from the car's own rules, not a
                        // literal — a car that set the tax to 40% must not be
                        // shown a button that still says 20%.
                        working:
                            '${_pointsIn(SightingContext.normal)} '
                            '− ${(_jamPenalty * 100).round()}%',
                        total: _pointsIn(SightingContext.jam),
                        accent: style.accent,
                        selected: _context == SightingContext.jam,
                        onTap: () => setState(
                          () => _context = _context == SightingContext.jam
                              ? SightingContext.normal
                              : SightingContext.jam,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  0,
                  Space.lg,
                  Space.lg,
                ),
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      ClaimDetails(
                        context: _context,
                        variants: <String>{..._variants},
                        extras: <SightingExtra>{..._extras},
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.card),
                      ),
                    ),
                    child: Text(
                      'Claim it',
                      style: AppText.bodyStrong.copyWith(
                        color: AppColors.accentInk,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.md,
      ),
      child: Text(label, style: AppText.label),
    );
  }
}

/// One of the two crowd answers, full width, carrying its own score.
///
/// Deliberately not a [_Choice]. The other questions are chips where the label
/// is short and the effect is a suffix; this one is a row that has to hold a
/// phrase, a line of explanation and a number big enough to read at arm's
/// length in a moving car.
class _CrowdChoice extends StatelessWidget {
  const _CrowdChoice({
    required this.label,
    required this.note,
    required this.total,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.working,
  });

  final String label;

  /// One short line under the label. Says which of the two this is without
  /// making anybody parse "lone".
  final String note;

  /// The sum, where there is one: "100 − 20%". Null on the plain answer, which
  /// has no arithmetic to show.
  final String? working;

  final int total;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentWash : AppColors.surface,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.outlineStrong,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 15,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontVariations: AppFonts.weight(selected ? 700 : 600),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: AppText.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  if (working case final String w)
                    Text(
                      w,
                      style: AppText.caption.copyWith(
                        color: AppColors.textMuted,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                  Text(
                    '$total',
                    style: AppText.title2.copyWith(
                      fontSize: 22,
                      color: selected ? accent : AppColors.textPrimary,
                      fontFeatures: AppText.tabular,
                      fontVariations: AppFonts.weight(800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
  });

  final String label;

  /// "Double", "Half", "+60". What the answer does, said in words rather than
  /// left for people to work out from the total.
  final String? detail;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentWash : AppColors.surface,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.outlineStrong,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                    fontVariations: AppFonts.weight(selected ? 700 : 500),
                  ),
                ),
              ),
              if (detail case final String d) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  d,
                  style: AppText.caption.copyWith(
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontVariations: AppFonts.weight(700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
