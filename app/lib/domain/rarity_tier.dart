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

  /// How many times this species can be claimed in a day before the tile locks.
  /// `null` is unlimited. Without this, forty impala means forty shouts.
  ///
  /// **More chances the commoner the animal**, which sounds backwards until you
  /// say it out loud: the cap exists so nobody taps every impala from Malelane
  /// to Satara, not to ration the good stuff. Four is enough that a real
  /// morning's zebra sightings all count, and few enough that it stops being a
  /// chore.
  ///
  /// Common and Frequent were **one each**, which was far too tight — one
  /// elephant sighting a day, in Kruger, is not a rule anybody would accept.
  int? get chancesPerDay => switch (this) {
    RarityTier.common => 4,
    RarityTier.frequent => 4,
    RarityTier.uncommon => 3,
    // Nothing rare is capped. Find six leopards and all six count.
    _ => null,
  };
}
