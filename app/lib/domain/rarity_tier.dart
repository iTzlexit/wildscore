/// How hard a species actually is to find in Kruger — not how famous it is.
///
/// Lions are easier to see than sable antelope, and the tiers reflect that.
/// Points are the base value of a first verified sighting; modifiers (night
/// drives, repeat sightings) arrive in Phase 3.
/// Seven tiers, by how hard the animal actually is to find in Kruger — not by
/// how famous it is. Lions are easier to find than sable.
///
/// Points follow a geometric curve, each tier roughly 2.5–3× the one below,
/// because sighting probability is wildly non-linear: thousands of people see
/// impala for every one who sees a pangolin. A flat 80× spread badly
/// under-rewarded the top end. See docs/SCORECARD.md.
///
/// **Names are still the old ones** pending the rename to Common / Frequent /
/// Notable / Rare / Very rare / Exceptional / Legendary, which waits on the
/// species re-tiering with a guide. Values are already correct.
enum RarityTier {
  common(label: 'Common', points: 5),
  frequent(label: 'Frequent', points: 15),
  uncommon(label: 'Notable', points: 40),
  scarce(label: 'Rare', points: 100),
  rare(label: 'Very rare', points: 250),
  veryRare(label: 'Exceptional', points: 750),
  legendary(label: 'Legendary', points: 2500);

  const RarityTier({required this.label, required this.points});

  final String label;
  final int points;

  /// How many times this species can be claimed in a day before the tile locks.
  /// `null` is unlimited. Without this, forty impala means forty shouts.
  int? get chancesPerDay => switch (this) {
    RarityTier.common => 1,
    RarityTier.frequent => 1,
    RarityTier.uncommon => 3,
    _ => null,
  };
}
