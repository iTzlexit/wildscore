import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/attribution_repository.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/species.dart';

/// Photo credits are a licence condition, not a nicety.
///
/// The Codex images are CC-BY, which legally requires attribution. Shipping one
/// without a credit is a copyright violation, so this is a real compliance
/// check rather than a tidiness test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Species> species;
  late Map<String, String> credits;

  setUpAll(() async {
    species = await const SpeciesRepository().loadAll();
    credits = await const AttributionRepository().loadAll();
  });

  test('the attributions file parses', () {
    expect(credits, isNotEmpty);
  });

  test('every species has a photo credit', () {
    final List<String> missing = <String>[
      for (final Species s in species)
        if (!credits.containsKey(s.id)) s.id,
    ];

    expect(
      missing,
      isEmpty,
      reason: 'CC-BY images without attribution are a licence violation',
    );
  });

  test('credits name a photographer and a licence', () {
    for (final MapEntry<String, String> entry in credits.entries) {
      expect(entry.value, contains('©'), reason: entry.key);
      expect(
        entry.value,
        anyOf(contains('CC-BY'), contains('CC0')),
        reason: entry.key,
      );
    }
  });

  test('no credit is attributed to an empty author', () {
    for (final MapEntry<String, String> entry in credits.entries) {
      expect(
        entry.value,
        isNot(matches(RegExp(r'©\s*—'))),
        reason: '${entry.key} has an empty photographer name',
      );
    }
  });

  test('no attribution exists for a species that is not in the catalogue', () {
    final Set<String> ids = species.map((Species s) => s.id).toSet();
    final List<String> orphans = <String>[
      for (final String id in credits.keys)
        if (!ids.contains(id)) id,
    ];

    expect(orphans, isEmpty, reason: 'stale credits after a species rename');
  });
}
