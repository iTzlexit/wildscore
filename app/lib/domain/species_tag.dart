/// Collectable groupings. These drive completion bonuses in Phase 3 — they do
/// not change a species' base points.
enum SpeciesTag {
  bigFive(label: 'Big Five', shortLabel: 'BIG 5', isFilter: true),
  bigSixBirds(label: 'Big Six Birds', shortLabel: 'BIG 6', isFilter: true),

  /// The joke played on every first-time visitor: elephant shrew, ant lion,
  /// rhinoceros beetle, buffalo weaver, leopard tortoise. Four of the five are
  /// in front of you at any picnic site and nobody ever looks.
  smallFive(label: 'Small Five', shortLabel: 'SMALL 5', isFilter: true),

  /// Not a scientific grouping — "antelope" excludes buffalo, which is a bovid
  /// but is not what anyone means. It matches how people actually talk in a
  /// car, which is the only test that matters here.
  ///
  /// Filterable because it is the largest natural group in the park and the one
  /// people most often want to narrow to: seventeen species that all look
  /// broadly similar and are genuinely hard to tell apart.
  antelope(label: 'Antelope', shortLabel: 'ANTELOPE', isFilter: true),

  snake(label: 'Snakes', shortLabel: 'SNAKE', isFilter: true),

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
