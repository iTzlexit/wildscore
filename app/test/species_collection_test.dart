import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/conservation_status.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/species_category.dart';
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
    final List<String> snakes = _names(SpeciesCollection.snakes);

    // Asserted as a property rather than as an exact list. The catalogue is
    // still growing — this went from two snakes to five in one sitting — and a
    // test that has to be edited every time a species is added stops being a
    // check and becomes a chore.
    expect(
      snakes,
      containsAll(<String>['Black Mamba', 'Boomslang', 'Puff Adder']),
    );
    for (final String notASnake in <String>[
      'Nile Crocodile',
      'Leopard Tortoise',
      'Water Monitor',
    ]) {
      expect(snakes, isNot(contains(notASnake)));
    }
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

  group('the photo guard', () {
    test('flags the species whose photograph cannot be trusted', () {
      // The sourcing API cannot tell a caracal from a serval, or an African
      // wildcat from somebody's tabby. A misidentified photograph in a field
      // guide teaches the wrong animal, which is worse than showing none.
      final List<String> unverified = <String>[
        for (final Species s in _all)
          if (!s.photoVerified) s.id,
      ]..sort();

      expect(unverified, <String>['african-wildcat', 'caracal']);
    });

    test('everything else is trusted by default', () {
      // Absence of the field means trusted, so a new species is never silently
      // hidden by one somebody forgot to add.
      expect(
        _all.where((Species s) => s.photoVerified).length,
        _all.length - 2,
      );
    });

    test('the flagged ones have a silhouette to fall back to', () async {
      for (final Species s in _all.where((Species s) => !s.photoVerified)) {
        expect(
          File(s.silhouetteAsset).existsSync(),
          isTrue,
          reason: '${s.id} has no silhouette, so it would show a monogram',
        );
      }
    });
  });

  group('the bird list is curated, not exhaustive', () {
    test('carries the ones people actually want to find', () {
      // Kruger has around 500 bird species. This is a game, not a checklist —
      // the list is the birds somebody would point at, not every bird present.
      final List<String> birds = <String>[
        for (final Species s in _all)
          if (s.category == SpeciesCategory.bird) s.commonName,
      ];

      expect(birds, contains('Common Ostrich'));
      expect(birds, contains('Secretarybird'));
      expect(birds, contains('Egyptian Goose'));
    });

    test('stays inside a quarter of the park list', () {
      final int birds = _all
          .where((Species s) => s.category == SpeciesCategory.bird)
          .length;

      // This bound has moved twice — 40, then 100, now 130 — both times on the
      // owner's instruction and both times for the same reason: the list he
      // wanted is the list a car actually calls out, and a shorter one kept
      // leaving out birds people shout about.
      //
      // At 124 the bird tab is no longer a shortlist, and pretending otherwise
      // in a test would be theatre. What is worth holding is the real ceiling:
      // Kruger has around 500 recorded species, and a guide that carries every
      // one of them is a field list, not a scorecard. A quarter of the park is
      // the line.
      //
      // The pressure this puts on the *dex* is real and is not solved here —
      // browsing 124 birds needs grouping, not a longer scroll.
      expect(
        birds,
        lessThan(130),
        reason: 'past this it stops being a scorecard and becomes a field list',
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
