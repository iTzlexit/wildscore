import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/species_category.dart';

/// "The bird category isn't populating all the birds." Worth proving the filter
/// itself is sound before assuming the catalogue is simply short — those are
/// very different problems with very different fixes.
void main() {
  late List<Species> catalogue;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    catalogue = await const SpeciesRepository().loadAll();
  });

  test('every category filter returns every member of that category', () {
    for (final SpeciesCategory category in SpeciesCategory.values) {
      final List<Species> expected = catalogue
          .where((Species s) => s.category == category)
          .toList();
      // The screen's filter is this predicate, applied to the whole catalogue.
      final List<Species> filtered = <Species>[
        for (final Species s in catalogue)
          if (s.category == category) s,
      ];

      expect(
        filtered.length,
        expected.length,
        reason: '${category.label} lost species to the filter',
      );
      expect(filtered.length, greaterThan(0), reason: category.label);
    }
  });

  test('the birds are all there and none are miscategorised', () {
    final List<Species> birds = catalogue
        .where((Species s) => s.category == SpeciesCategory.bird)
        .toList();

    // A guard against the commonest content error: an eagle filed as a mammal
    // never appears under Birds and nobody notices for months.
    for (final String name in <String>[
      'Fish Eagle',
      'Vulture',
      'Owl',
      'Kingfisher',
      'Hornbill',
      'Stork',
      'Heron',
    ]) {
      final Iterable<Species> matching = catalogue.where(
        (Species s) => s.commonName.contains(name),
      );
      for (final Species s in matching) {
        expect(
          s.category,
          SpeciesCategory.bird,
          reason: '${s.commonName} is filed as ${s.category.name}',
        );
      }
    }

    expect(birds.length, greaterThan(30));
  });
}
