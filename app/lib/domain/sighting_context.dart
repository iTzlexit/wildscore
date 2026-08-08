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
/// invites people to lie. It just counts for half.
enum SightingContext {
  /// Nobody else there. The purest version of the thing, and the one worth
  /// getting out of bed for.
  alone(label: 'Just us', short: 'ALONE', multiplier: 2),

  /// Other cars about, but you saw it first.
  normal(label: 'We spotted it', short: '', multiplier: 1),

  /// Cars already stopped and looking when you arrived.
  jam(label: 'Cars were already there', short: 'JAM', multiplier: 0.5);

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
  /// Rounded up, so halving never takes anything to zero: even a jam sighting
  /// of a 5-point impala is worth 3. A rule that can zero a real sighting is a
  /// rule people argue with.
  int applyTo(int points) => (points * multiplier).ceil();

  static SightingContext byName(String name) => values.firstWhere(
    (SightingContext c) => c.name == name,
    orElse: () => SightingContext.normal,
  );
}
