/// How hard a species actually is to find in Kruger — not how famous it is.
///
/// Lions are easier to see than sable antelope, and the tiers reflect that.
/// Points are the base value of a first verified sighting; modifiers (night
/// drives, repeat sightings) arrive in Phase 3.
enum RarityTier {
  common(label: 'Common', points: 5),
  frequent(label: 'Frequent', points: 10),
  uncommon(label: 'Uncommon', points: 25),
  scarce(label: 'Scarce', points: 50),
  rare(label: 'Rare', points: 100),
  veryRare(label: 'Very Rare', points: 250),
  legendary(label: 'Legendary', points: 500);

  const RarityTier({required this.label, required this.points});

  final String label;
  final int points;
}
