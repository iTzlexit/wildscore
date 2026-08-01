/// Collectable groupings. These drive completion bonuses in Phase 3 — they do
/// not change a species' base points.
enum SpeciesTag {
  bigFive(label: 'Big Five', shortLabel: 'BIG 5', isFilter: true),
  bigSixBirds(label: 'Big Six Birds', shortLabel: 'BIG 6', isFilter: true),

  /// What a safari-goer means by "we saw a predator": things that hunt or
  /// scavenge other animals. Deliberately excludes the insectivores nobody
  /// calls a predator — pangolin, aardvark, bushbabies — even though they are
  /// technically carnivorous.
  predator(label: 'Predators', shortLabel: 'PREDATOR', isFilter: true),

  nocturnal(label: 'Nocturnal', shortLabel: 'NIGHT', isFilter: true);

  const SpeciesTag({
    required this.label,
    required this.shortLabel,
    required this.isFilter,
  });

  final String label;
  final String shortLabel;

  /// Whether this tag appears as a filter chip in the Codex.
  final bool isFilter;
}
