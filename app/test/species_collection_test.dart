import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/conservation_status.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/species_collection.dart';

/// The named sets are what people actually try to complete, so a set that is
/// silently missing a member is a bug someone only finds at the gate.
late final List<Species> _all;

List<String> _names(SpeciesCollection group) =>
    group.membersOf(_all).map((Species s) => s.commonName).toList()..sort();

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _all = await const SpeciesRepository().loadAll();
  });

  test('the Big Five is the Big Five', () {
    // Six entries, because Kruger has both rhino and the classic list names
    // only one. Leaving black rhino out would be wrong; so would counting it
    // twice against a total of five.
    expect(_names(SpeciesCollection.bigFive), <String>[
      'African Elephant',
      'Black Rhinoceros',
      'Cape Buffalo',
      'Leopard',
      'Lion',
      'White Rhinoceros',
    ]);
  });

  test('the Small Five is complete', () {
    expect(_names(SpeciesCollection.smallFive), <String>[
      'Ant Lion',
      'Eastern Rock Elephant Shrew',
      'Leopard Tortoise',
      'Red-billed Buffalo Weaver',
      'Rhinoceros Beetle',
    ]);
  });

  test('the Big Six Birds is six', () {
    expect(SpeciesCollection.bigSixBirds.membersOf(_all).length, 6);
  });

  test('snakes are snakes and not every reptile', () {
    expect(_names(SpeciesCollection.snakes), <String>[
      'Black Mamba',
      'Southern African Rock Python',
    ]);
  });

  group('antelope', () {
    test('includes the browsers and grazers people mean', () {
      final List<String> antelope = _names(SpeciesCollection.antelope);

      expect(antelope, contains('Impala'));
      expect(antelope, contains('Greater Kudu'));
      expect(antelope, contains('Sable Antelope'));
      expect(antelope, contains('Suni'));
    });

    test('excludes what nobody calls an antelope', () {
      final List<String> antelope = _names(SpeciesCollection.antelope);

      // All bovids or near enough, and none of them are what a person means.
      expect(antelope, isNot(contains('Cape Buffalo')));
      expect(antelope, isNot(contains('Giraffe')));
      expect(antelope, isNot(contains('Plains Zebra')));
    });
  });

  group('under threat', () {
    test('is derived from the IUCN status, not a tag', () {
      for (final Species s in SpeciesCollection.endangered.membersOf(_all)) {
        expect(
          s.conservationStatus,
          isNot(ConservationStatus.leastConcern),
          reason: s.commonName,
        );
      }
    });

    test('includes the ground hornbill', () {
      expect(
        _names(SpeciesCollection.endangered),
        contains('Southern Ground Hornbill'),
      );
    });

    test('excludes Near Threatened, which is the not-yet category', () {
      final List<Species> members = SpeciesCollection.endangered.membersOf(
        _all,
      );

      expect(
        members.map((Species s) => s.conservationStatus),
        isNot(contains(ConservationStatus.nearThreatened)),
      );
    });
  });

  test('every collection has at least one member', () {
    // An empty set on the profile reads as a bug, not as a challenge.
    for (final SpeciesCollection group in SpeciesCollection.values) {
      expect(group.membersOf(_all), isNotEmpty, reason: group.label);
    }
  });
}
