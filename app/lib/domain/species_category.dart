enum SpeciesCategory {
  mammal(label: 'Mammals', singular: 'Mammal'),
  bird(label: 'Birds', singular: 'Bird'),
  reptile(label: 'Reptiles', singular: 'Reptile'),

  /// Added for the Small Five, which is half insects. A dex that cannot hold an
  /// ant lion cannot hold the Small Five, and the Small Five is one of the few
  /// things a Kruger visitor is actively told to go and look for.
  invertebrate(label: 'Invertebrates', singular: 'Invertebrate'),

  /// One entry, and it earns it: the baobab. Nobody drives past their first one
  /// without stopping, they are the thing that tells you the north is different
  /// country, and a guide to Kruger that cannot hold one is being precious
  /// about the word "species". Last in dex order, so the animals stay together.
  plant(label: 'Trees', singular: 'Tree');

  const SpeciesCategory({required this.label, required this.singular});

  final String label;
  final String singular;
}
