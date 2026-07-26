enum SpeciesCategory {
  mammal(label: 'Mammals', singular: 'Mammal'),
  bird(label: 'Birds', singular: 'Bird'),
  reptile(label: 'Reptiles', singular: 'Reptile');

  const SpeciesCategory({required this.label, required this.singular});

  final String label;
  final String singular;
}
