import 'conservation_status.dart';
import 'species.dart';
import 'species_tag.dart';

/// The sets people actually try to complete.
///
/// A category breakdown answers "how much of the book have I filled in", which
/// is a completionist's question. These answer a different and better one: *have
/// I got the Big Five yet.* Nobody sets out to see 54 mammals; plenty of people
/// set out to see five specific ones.
///
/// Membership is a predicate rather than a stored list, so adding a species to
/// species.json puts it in the right collections without a second edit.
enum SpeciesCollection {
  bigFive(label: 'Big Five', blurb: 'Lion, leopard, elephant, buffalo, rhino'),
  smallFive(
    label: 'Small Five',
    blurb: 'The five nobody looks for. Four are at every picnic site',
  ),
  bigSixBirds(
    label: 'Big Six Birds',
    blurb: "Kruger's six hardest birds, and much harder than the Big Five",
  ),
  endangered(
    label: 'Under threat',
    blurb: 'Vulnerable, Endangered and Critically Endangered',
  ),
  antelope(label: 'Antelope', blurb: 'Every antelope in the park'),
  predators(label: 'Predators', blurb: 'Everything that hunts or scavenges'),
  snakes(label: 'Snakes', blurb: 'Seen from inside the car, ideally'),
  nocturnal(label: 'Night shift', blurb: 'Only out after the gates close');

  const SpeciesCollection({required this.label, required this.blurb});

  final String label;

  /// One line under the name. Says what the set *is*, since "Small Five" means
  /// nothing to someone on their first trip.
  final String blurb;

  bool contains(Species species) => switch (this) {
    SpeciesCollection.bigFive => species.tags.contains(SpeciesTag.bigFive),
    SpeciesCollection.smallFive => species.tags.contains(SpeciesTag.smallFive),
    SpeciesCollection.bigSixBirds => species.tags.contains(
      SpeciesTag.bigSixBirds,
    ),
    SpeciesCollection.antelope => species.tags.contains(SpeciesTag.antelope),
    SpeciesCollection.predators => species.tags.contains(SpeciesTag.predator),
    SpeciesCollection.snakes => species.tags.contains(SpeciesTag.snake),
    SpeciesCollection.nocturnal => species.tags.contains(SpeciesTag.nocturnal),
    // Derived from the IUCN status rather than tagged, so it stays correct when
    // a listing changes and nobody remembers there was a tag to update.
    SpeciesCollection.endangered => species.conservationStatus.isThreatened,
  };

  List<Species> membersOf(List<Species> all) => <Species>[
    for (final Species s in all)
      if (contains(s)) s,
  ];
}

extension ConservationThreat on ConservationStatus {
  /// The IUCN threatened categories. Near Threatened is deliberately excluded —
  /// it is the category for species that are *not* threatened yet, and
  /// including it would make the set mean less.
  bool get isThreatened => switch (this) {
    ConservationStatus.vulnerable ||
    ConservationStatus.endangered ||
    ConservationStatus.criticallyEndangered => true,
    ConservationStatus.leastConcern ||
    ConservationStatus.nearThreatened => false,
  };
}
