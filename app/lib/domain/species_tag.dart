/// Collectable groupings. These drive completion bonuses in Phase 3 — they do
/// not change a species' base points.
enum SpeciesTag {
  bigFive(label: 'Big Five', shortLabel: 'BIG 5'),
  bigSixBirds(label: 'Big Six Birds', shortLabel: 'BIG 6'),
  nocturnal(label: 'Nocturnal', shortLabel: 'NIGHT');

  const SpeciesTag({required this.label, required this.shortLabel});

  final String label;
  final String shortLabel;
}
