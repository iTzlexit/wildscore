/// Kruger runs roughly 350km north to south and is conventionally split into
/// three regions by its two major rivers. Distribution differs sharply between
/// them — sable and roan are northern animals, white rhino are southern.
///
/// Declared north-to-south so a list of regions renders in map order.
enum ParkRegion {
  northern(
    label: 'Northern',
    bounds: 'Olifants River to Pafuri',
    knownFor: 'Mopane and sandveld — sable, roan, Pafuri specials',
  ),
  central(
    label: 'Central',
    bounds: 'Sabie River to the Olifants River',
    knownFor: 'Open grassland — the best cat country in the park',
  ),
  southern(
    label: 'Southern',
    bounds: 'Crocodile Bridge to the Sabie River',
    knownFor: 'Densest game and the highest rhino numbers',
  );

  const ParkRegion({
    required this.label,
    required this.bounds,
    required this.knownFor,
  });

  final String label;
  final String bounds;
  final String knownFor;
}
