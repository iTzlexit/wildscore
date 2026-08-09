import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/conservation_status.dart';
import 'package:wildscore/domain/park_region.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/species_tag.dart';

/// Guards the species catalogue.
///
/// `species.json` is hand-edited data and it will be edited often — new
/// species, corrected ranges, retuned rarity. These tests are what stops a
/// stray comma or a typo'd enum from shipping an app that crashes on launch.
/// Every one of them exists because it protects something a user would notice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Species> species;

  setUpAll(() async {
    species = await const SpeciesRepository().loadAll();
  });

  test('the whole catalogue parses', () {
    // If an enum string in the JSON is wrong, loadAll throws and the app shows
    // an error screen instead of the Codex. This is the single most valuable
    // assertion in the file.
    expect(species.length, greaterThanOrEqualTo(70));
  });

  test('ids are unique', () {
    final Set<String> ids = species.map((Species s) => s.id).toSet();
    expect(ids.length, species.length, reason: 'duplicate id in species.json');
  });

  test('sorted by dex number', () {
    for (int i = 1; i < species.length; i++) {
      expect(
        species[i - 1].dexNumber,
        lessThan(species[i].dexNumber),
        reason: '${species[i].commonName} is out of order',
      );
    }
  });

  test('dex numbers are unique and contiguous from 1', () {
    // A gap or a duplicate means the catalogue was edited by hand rather than
    // regenerated, and someone's collection would show two No. 042s.
    //
    // Contiguity is asserted; *grouping by category* is not, and used to be.
    // The original catalogue ran mammals, then birds, then reptiles, which is
    // a property no addition can preserve — restoring it would mean
    // renumbering, and a dex number is an identity. New species are appended
    // (see STATE.md) and browsing by category is the filter's job.
    final List<int> numbers = species.map((Species s) => s.dexNumber).toList()
      ..sort();

    expect(numbers.first, 1);
    expect(numbers.last, species.length);
    expect(numbers.toSet().length, species.length, reason: 'duplicate number');
  });

  test('points always derive from the rarity tier', () {
    // Including wild cards. Their bonus is added by whoever creates the claim,
    // not baked into the species — which is what keeps the scale honest and
    // stops it drifting one hand-tuned animal at a time.
    for (final Species s in species) {
      expect(s.points, s.rarityTier.points, reason: s.commonName);
    }
  });

  test('daily wild cards get more chances than their tier allows', () {
    // Otherwise "the first one is worth more" says nothing, because there is
    // only ever one.
    for (final Species s in species.where(
      (Species s) => s.isWildCard && s.wildCardScope == WildCardScope.day,
    )) {
      expect(s.chancesPerDay, 4, reason: s.commonName);
    }

    // Impala is its own case. The commonest animal in the park by a distance,
    // so it gets two: the first is the arrival moment and pays the bonus, the
    // second is an ordinary impala, and then it is done for the day.
    final Species impala = species.firstWhere((Species s) => s.id == 'impala');
    expect(impala.chancesPerDay, 2);
  });

  test('every species occurs in at least one park region', () {
    for (final Species s in species) {
      expect(s.parkRegions, isNotEmpty, reason: s.commonName);
    }
  });

  test('no empty text fields', () {
    for (final Species s in species) {
      expect(s.commonName.trim(), isNotEmpty, reason: s.id);
      expect(s.scientificName.trim(), isNotEmpty, reason: s.id);
      expect(s.afrikaansName.trim(), isNotEmpty, reason: s.id);
      expect(s.description.trim(), isNotEmpty, reason: s.id);
      expect(s.habitat.trim(), isNotEmpty, reason: s.id);
      expect(s.bestTimeToSpot.trim(), isNotEmpty, reason: s.id);
    }
  });

  test('the Big Five are all present and tagged', () {
    final Set<String> bigFive = species
        .where((Species s) => s.tags.contains(SpeciesTag.bigFive))
        .map((Species s) => s.commonName)
        .toSet();
    expect(
      bigFive,
      containsAll(<String>[
        'Lion',
        'Leopard',
        'African Elephant',
        'Cape Buffalo',
        'White Rhinoceros',
        'Black Rhinoceros',
      ]),
    );
  });

  test('the Big Six Birds are all present and tagged', () {
    final Set<String> bigSix = species
        .where((Species s) => s.tags.contains(SpeciesTag.bigSixBirds))
        .map((Species s) => s.commonName)
        .toSet();
    expect(bigSix.length, 6, reason: 'the Big Six must be exactly six birds');
    expect(
      bigSix,
      containsAll(<String>[
        'Martial Eagle',
        'Lappet-faced Vulture',
        'Saddle-billed Stork',
        'Kori Bustard',
        'Southern Ground Hornbill',
        "Pel's Fishing Owl",
      ]),
    );
  });

  // See docs/VISION.md — non-negotiable. If someone adds a species that should
  // be protected and forgets the flag, this is the thing that catches it.
  test('poaching-sensitive species are flagged', () {
    final Set<String> sensitive = species
        .where((Species s) => s.isSensitive)
        .map((Species s) => s.commonName)
        .toSet();
    expect(sensitive, <String>{
      'White Rhinoceros',
      'Black Rhinoceros',
      'Ground Pangolin',
    }, reason: 'rhino and pangolin locations must never be exposed');
  });

  test('every rarity tier is populated', () {
    for (final RarityTier tier in RarityTier.values) {
      expect(
        species.where((Species s) => s.rarityTier == tier),
        isNotEmpty,
        reason: 'no species in tier ${tier.label}',
      );
    }
  });

  test('every park region has species', () {
    for (final ParkRegion region in ParkRegion.values) {
      expect(
        species.where((Species s) => s.parkRegions.contains(region)),
        isNotEmpty,
        reason: 'no species in ${region.label}',
      );
    }
  });

  test('regional specials are not marked park-wide', () {
    // A regression here would be invisible on screen but would make the app
    // lie about where to drive — the single most useful thing it tells you.
    Species byId(String id) => species.firstWhere((Species s) => s.id == id);

    expect(byId('roan-antelope').parkRegions, <ParkRegion>[
      ParkRegion.northern,
    ]);
    expect(byId('suni').parkRegions, <ParkRegion>[ParkRegion.northern]);
    expect(
      byId('white-rhinoceros').parkRegions,
      isNot(contains(ParkRegion.northern)),
    );
  });

  test('threatened species carry a real IUCN status', () {
    Species byId(String id) => species.firstWhere((Species s) => s.id == id);

    expect(
      byId('black-rhinoceros').conservationStatus,
      ConservationStatus.criticallyEndangered,
    );
    expect(
      byId('african-wild-dog').conservationStatus,
      ConservationStatus.endangered,
    );
  });
}
