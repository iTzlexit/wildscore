/// Who else was there when you found it.
///
/// The single biggest thing wrong with the scorecard was that arriving at a
/// traffic jam and being *shown* a leopard scored exactly the same as finding
/// one yourself on an empty road at six in the morning. Those are not the same
/// achievement and everybody in the car knows it — the rules already banned
/// asking other drivers what they were looking at, which was the same instinct
/// enforced with a rule nobody could check.
///
/// This is that instinct in the scoring instead. A jam still counts, because
/// pretending you did not see the leopard is silly and refusing the points
/// invites people to lie. It just counts for less.
///
/// **Spotting it yourself is the baseline, not a bonus.** It used to double,
/// and the owner changed it: the points printed on the animal card are what a
/// sighting is worth, and arriving at a jam takes 20% off. That makes the card
/// tell the truth — a leopard says 100 and pays 100 — at the cost of narrowing
/// the gap between the two, which used to be 2.67× and is now 1.25×. Less of a
/// reason to be at the gate at five, more of a number anybody can predict.
enum SightingContext {
  /// You found it. Worth exactly what the animal card says.
  ///
  /// Still worth marking even though it no longer changes the score: the LONE
  /// tag is what the haul and the sightings feed show, and "we had it to
  /// ourselves" is the part people retell.
  alone(label: 'Lone sighting', short: 'LONE', multiplier: 1),

  /// The ordinary case, and the reason this is two options rather than three.
  ///
  /// It was a three-way choice — alone, we spotted it, a jam — which made every
  /// claim a decision even when the honest answer was "nothing special". Two
  /// optional marks with an unremarkable default is the same information and no
  /// question to answer.
  normal(label: '', short: '', multiplier: 1),

  /// Cars already stopped and looking when you arrived.
  ///
  /// A fifth off. It has come down twice — half, then a quarter, now 20% —
  /// each time for the same reason: you *did* see the leopard, and a penalty
  /// heavy enough to sting is a penalty people lie to avoid. A fifth is a nudge
  /// that leaves a jam sighting well worth logging.
  ///
  /// Twenty rather than twenty-five also because it is the number a person can
  /// do in their head at a gate. 100 becomes 80.
  jam(label: 'Part of a jam', short: 'JAM', multiplier: 0.8);

  const SightingContext({
    required this.label,
    required this.short,
    required this.multiplier,
  });

  final String label;

  /// For the tag on a haul. Empty for [normal], which needs no marking — the
  /// ordinary case should not be labelled.
  final String short;

  final double multiplier;

  /// What a find is worth in this company.
  ///
  /// [jamMultiplier] is what a car has decided a jam sighting keeps — 0.8 by
  /// default, 1.0 for a car that has switched the tax off entirely. Passed in
  /// rather than read from a global, because scoring is pure here and the whole
  /// test suite depends on it staying that way.
  ///
  /// Rounded up, so the tax never takes anything to zero: even a jam sighting
  /// of a 5-point impala is worth 4. A rule that can zero a real sighting is a
  /// rule people argue with.
  int applyTo(int points, {double? jamMultiplier}) {
    final double m = this == SightingContext.jam
        ? (jamMultiplier ?? multiplier)
        : multiplier;
    return (points * m).ceil();
  }

  static SightingContext byName(String name) => values.firstWhere(
    (SightingContext c) => c.name == name,
    orElse: () => SightingContext.normal,
  );
}

/// Things about a particular sighting that make it better than the same animal
/// standing on its own.
///
/// These are about the *moment*, not the species, which is why they are not
/// [SpeciesVariant]s. A lioness with cubs and a leopard on a kill are the two
/// sightings people talk about for years, and scoring them the same as a lion
/// asleep under a tree is the thing the game gets most obviously wrong.
///
/// Multipliers rather than flat bonuses, so they scale honestly: half again on
/// an impala is small and half again on a wild dog is a lot, which is the right
/// shape.
enum SightingExtra {
  /// Only offered for mammals. A crocodile with young is a real thing and not
  /// one anybody is going to argue about at dinner.
  withYoung(
    label: 'With young',
    short: 'YOUNG',
    question: 'Was there a baby with it?',
    multiplier: 1.5,
  ),

  /// Only offered for predators. Everybody remembers the kill.
  onAKill(
    label: 'On a kill',
    short: 'KILL',
    question: 'Was it on a kill?',
    multiplier: 1.5,
  ),

  /// A kill hauled into a tree.
  ///
  /// The leopard sighting everybody wants and most people never get — and
  /// worth marking separately from a kill on the ground, which is a lion
  /// thing and far more common.
  killInATree(
    label: 'Kill in a tree',
    short: 'TREE KILL',
    question: 'Was the kill up a tree?',
    multiplier: 2,
  ),

  /// Two of them, at it.
  ///
  /// Rare enough to be a story for almost everything and genuinely
  /// unmistakable, which is what makes it a fair thing to score.
  matingPair(
    label: 'Mating pair',
    short: 'MATING',
    question: 'Were they mating?',
    multiplier: 1.5,
  ),

  /// A night animal, out in daylight.
  ///
  /// **Rarity is not a property of the animal, it is a property of the
  /// sighting** — which is the thing a tier list cannot say. A bushpig is not
  /// rare; a bushpig at eleven in the morning is. Same for a porcupine, a
  /// genet, a civet. Guides talk about those sightings for years and the
  /// scorecard had no way to tell them apart from the same animal caught in a
  /// spotlight at nine at night, which is an ordinary Tuesday.
  ///
  /// Two and a half times, which is a whole tier's worth: a 305-point bushpig
  /// becomes 760, up past the serval. That is the right size — it should feel
  /// like catching a different animal.
  ///
  /// Only offered on species tagged nocturnal, and not on the two of those
  /// that are routinely seen by day anyway (see [Species.possibleExtras]).
  inDaylight(
    label: 'Seen in daylight',
    short: 'DAY',
    question: 'Did you see it in daylight?',
    multiplier: 2.5,
  );

  const SightingExtra({
    required this.label,
    required this.short,
    required this.question,
    required this.multiplier,
  });

  final String label;
  final String short;
  final String question;
  final double multiplier;

  static SightingExtra? byName(String name) {
    for (final SightingExtra e in values) {
      if (e.name == name) {
        return e;
      }
    }
    return null;
  }
}
