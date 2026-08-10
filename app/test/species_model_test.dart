import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/conservation_status.dart';
import 'package:wildscore/domain/park_region.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/species_category.dart';

Map<String, dynamic> _json({String rarityTier = 'legendary'}) {
  return <String, dynamic>{
    'id': 'test-beast',
    'dexNumber': 999,
    'commonName': 'Test Beast',
    'scientificName': 'Bestia probata',
    'afrikaansName': 'Toetsbees',
    'category': 'mammal',
    'rarityTier': rarityTier,
    'tags': <dynamic>['nocturnal'],
    'isSensitive': false,
    'description': 'A beast that exists only in tests.',
    'habitat': 'The test runner',
    'bestTimeToSpot': 'CI',
    'parkRegions': <dynamic>['northern'],
    'conservationStatus': 'leastConcern',
  };
}

void main() {
  group('Species.fromJson', () {
    test('maps every field', () {
      final Species s = Species.fromJson(_json());

      expect(s.id, 'test-beast');
      expect(s.commonName, 'Test Beast');
      expect(s.afrikaansName, 'Toetsbees');
      expect(s.category, SpeciesCategory.mammal);
      expect(s.rarityTier, RarityTier.legendary);
      expect(s.parkRegions, <ParkRegion>[ParkRegion.northern]);
      expect(s.conservationStatus, ConservationStatus.leastConcern);
      expect(s.isNocturnal, isTrue);
      expect(s.isBigFive, isFalse);
      // No explicit `points` in the fixture, so it falls back to the middle of
      // the tier's band. That fallback is what stops a species added tomorrow
      // scoring nothing before anybody has ranked it.
      expect(s.points, RarityTier.legendary.points);
      expect(s.dexNumber, 999);
      expect(s.dexLabel, '999');
      expect(s.imageAsset, 'assets/species/test-beast.jpg');
    });

    test('defaults discovered to true in Phase 1', () {
      expect(Species.fromJson(_json()).discovered, isTrue);
    });

    test('throws a useful message on an unknown enum value', () {
      final Map<String, dynamic> bad = _json(rarityTier: 'mythical');

      expect(
        () => Species.fromJson(bad),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            allOf(contains('mythical'), contains('test-beast')),
          ),
        ),
      );
    });
  });

  group('matchesQuery', () {
    final Species s = Species.fromJson(_json());

    test('empty query matches everything', () {
      expect(s.matchesQuery(''), isTrue);
    });

    test('matches on common name, case-insensitively', () {
      expect(s.matchesQuery('TEST bea'), isTrue);
    });

    test('matches on the Afrikaans name', () {
      // Plenty of users grew up calling it a rooibok, not an impala.
      expect(s.matchesQuery('toetsbees'), isTrue);
    });

    test('matches on the scientific name', () {
      expect(s.matchesQuery('bestia'), isTrue);
    });

    test('ignores surrounding whitespace', () {
      expect(s.matchesQuery('  beast '), isTrue);
    });

    test('rejects a non-match', () {
      expect(s.matchesQuery('elephant'), isFalse);
    });
  });

  group('rarity tiers', () {
    test('the bands are the ones the spec promises', () {
      // A tier is a range now, not a value: every species carries its own
      // number from the hand ranking and the tier says which band it lives in.
      // Steep, because sighting probability in Kruger spans roughly 1:1000 and
      // a flat spread under-rewards the top.
      expect((RarityTier.common.low, RarityTier.common.high), (5, 15));
      expect((RarityTier.frequent.low, RarityTier.frequent.high), (20, 55));
      expect((RarityTier.uncommon.low, RarityTier.uncommon.high), (60, 140));
      expect((RarityTier.scarce.low, RarityTier.scarce.high), (150, 320));
      expect((RarityTier.rare.low, RarityTier.rare.high), (350, 550));
      expect(
        (RarityTier.legendary.low, RarityTier.legendary.high),
        (600, 1000),
      );
    });

    test('the bands ascend and never overlap', () {
      // Scarcity has to mean something: the worst Legendary must outscore the
      // best Very rare, or the categories are decoration.
      for (int i = 1; i < RarityTier.values.length; i++) {
        expect(
          RarityTier.values[i].low,
          greaterThan(RarityTier.values[i - 1].high),
          reason: RarityTier.values[i].label,
        );
        expect(
          RarityTier.values[i].high,
          greaterThan(RarityTier.values[i].low),
        );
      }
    });
  });

  test('park regions are declared north to south, for map order', () {
    expect(ParkRegion.values, <ParkRegion>[
      ParkRegion.northern,
      ParkRegion.central,
      ParkRegion.southern,
    ]);
  });

  test('copyWith changes discovered and nothing else', () {
    final Species s = Species.fromJson(_json());
    final Species found = s.copyWith(discovered: false);

    expect(found.discovered, isFalse);
    expect(found.id, s.id);
    expect(found.points, s.points);
    expect(found.parkRegions, s.parkRegions);
  });
}
