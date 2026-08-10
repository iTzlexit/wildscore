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
/// **A tier is now a band, not a value.** Every animal in a tier used to score
/// the same, which said a leopard and a wild dog are equally hard to find, and
/// nobody in a car believed it. Each species carries its own number from Alex
/// ranking all 190 by hand; the tier says which range that number lives in.
///
/// The bands never overlap — the bottom of one sits above the top of the next —
/// so the worst Legendary always outscores the best Very rare. A tier that can
/// be beaten by the tier below it is not a tier.
///
/// Points still follow a steep curve, because sighting probability is wildly
/// non-linear: thousands of people see impala for every one who sees a
/// pangolin. It used to run 5 to 2,000 and the first hand-ranked pass came out
/// at 5 to 3,500, which Alex found too spread out. 5 to 1,000 keeps the shape
/// and stops anything but the ten Legendaries reaching four figures.
///
/// See docs/SCORECARD.md.
enum RarityTier {
  common(label: 'Common', low: 5, high: 15),
  frequent(label: 'Frequent', low: 20, high: 55),
  uncommon(label: 'Notable', low: 60, high: 140),
  scarce(label: 'Rare', low: 150, high: 320),
  rare(label: 'Very rare', low: 350, high: 550),
  legendary(label: 'Legendary', low: 600, high: 1000);

  const RarityTier({
    required this.label,
    required this.low,
    required this.high,
  });

  final String label;

  /// The band this tier's species are priced within, inclusive.
  final int low;
  final int high;

  /// What an unranked species falls back to — the middle of its band.
  ///
  /// Nothing in the catalogue uses this today; it exists so a species added
  /// tomorrow scores something sensible before anybody has placed it.
  int get points => low + (high - low) ~/ 2;

  /// The rungs inside this band.
  ///
  /// **Every score in the game is one of these**, and so is every value a
  /// player can choose when editing one. Ranking 190 animals produced 190
  /// distinct numbers, which claims we can tell the seventeenth-hardest
  /// Notable from the eighteenth. Nobody can. Snapping to a coarse ladder says
  /// the true thing instead — these six are about as hard as each other, and
  /// that lot are harder — and 190 animals collapse to 24 scores.
  ///
  /// Ties are the feature, not a rounding artefact.
  List<int> get rungs => switch (this) {
    RarityTier.common => const <int>[5, 10, 15],
    RarityTier.frequent => const <int>[20, 30, 40, 55],
    RarityTier.uncommon => const <int>[60, 80, 100, 120, 140],
    RarityTier.scarce => const <int>[150, 200, 250, 320],
    RarityTier.rare => const <int>[350, 425, 500, 550],
    RarityTier.legendary => const <int>[600, 750, 875, 1000],
  };

  /// Every rung in the game, lowest first.
  ///
  /// The editor offers the whole ladder rather than only the species' own
  /// band, because the case for editing at all is regional: sable and roan are
  /// the sighting of the trip in the south and a Tuesday in the far north, and
  /// a car based at Punda Maria needs to move them across a band, not within
  /// one.
  static List<int> get allRungs => <int>[
    for (final RarityTier t in RarityTier.values) ...t.rungs,
  ];

  // Caps used to live here — four a day for Common and Frequent, three for
  // Notable. They are per species now (`Species.chancesPerDay`) and there are
  // exactly two of them, because a tier-wide cap punished the wrong thing: a
  // real morning's zebra sightings ran out, and so did elephant.
  //
  // Alex's rule, and it is the right one: cap only what somebody would
  // otherwise tap fifty times. If a car wants to count a hundred giraffe, that
  // is their afternoon and not our business.
}
