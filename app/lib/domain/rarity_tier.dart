/// How hard a species actually is to find in Kruger — not how famous it is.
///
/// Lions are easier to see than sable antelope, and the tiers reflect that.
///
/// **Six tiers.** Exceptional and Legendary used to be separate at 750 and
/// 2,500, and the distinction was one nobody could hold in their head — an
/// aardvark and a pangolin are both "the sighting of the trip", and asking a
/// car to rank them against each other produced an argument rather than a
/// score. Merged into one Legendary at 2,000.
///
/// Points follow a geometric curve, each step roughly 2.5–3× the one below,
/// because sighting probability is wildly non-linear: thousands of people see
/// impala for every one who sees a pangolin. The final step is deliberately
/// steeper still — Legendary should end the competition, because in real life
/// it does.
///
/// See docs/SCORECARD.md.
enum RarityTier {
  common(label: 'Common', points: 5),
  frequent(label: 'Frequent', points: 15),
  uncommon(label: 'Notable', points: 40),
  scarce(label: 'Rare', points: 100),
  rare(label: 'Very rare', points: 300),
  legendary(label: 'Legendary', points: 2000);

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
