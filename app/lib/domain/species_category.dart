enum SpeciesCategory {
  mammal(label: 'Mammals', singular: 'Mammal'),
  bird(label: 'Birds', singular: 'Bird'),
  reptile(label: 'Reptiles', singular: 'Reptile'),

  /// Added for the Small Five, which is half insects. A dex that cannot hold an
  /// ant lion cannot hold the Small Five, and the Small Five is one of the few
  /// things a Kruger visitor is actively told to go and look for.
  invertebrate(label: 'Invertebrates', singular: 'Invertebrate');

  const SpeciesCategory({required this.label, required this.singular});

  final String label;
  final String singular;
}
