import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildscore/data/house_rules_repository.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/house_rules.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/domain/sighting_context.dart';
import 'package:wildscore/domain/species.dart';

/// Letting a car set its own prices.
///
/// Our table is one opinion taken nationally, and Kruger is not one place —
/// sable is the sighting of the trip in the south and a Tuesday in the far
/// north. The feature exists because no single table can be right for both.
void main() {
  // Reading the bundled catalogue is real asset I/O, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('the ladder', () {
    test('every score in the catalogue is a rung on it', () async {
      // Ties are the feature. Ranking 190 animals produced 190 distinct
      // numbers, which claims we can tell the seventeenth-hardest Notable from
      // the eighteenth — snapping to a coarse ladder says the true thing.
      final List<Species> all = await const SpeciesRepository().loadAll();
      final Set<int> rungs = RarityTier.allRungs.toSet();

      for (final Species s in all) {
        expect(rungs, contains(s.points), reason: s.commonName);
        expect(
          s.rarityTier.rungs,
          contains(s.points),
          reason: '${s.commonName} is off its own band',
        );
      }
    });

    test('collapses the catalogue to a couple of dozen scores', () async {
      final List<Species> all = await const SpeciesRepository().loadAll();
      final Set<int> distinct = all.map((Species s) => s.points).toSet();

      expect(all.length, greaterThan(150));
      expect(distinct.length, lessThan(30));
    });

    test('ascends, with no rung repeated', () {
      final List<int> rungs = RarityTier.allRungs;

      expect(rungs.toSet().length, rungs.length);
      for (int i = 1; i < rungs.length; i++) {
        expect(rungs[i], greaterThan(rungs[i - 1]));
      }
    });
  });

  group('storage', () {
    test('nothing saved means nothing overridden', () async {
      expect((await const HouseRulesRepository().load()).isDefault, isTrue);
    });

    test('survives a round trip', () async {
      const HouseRulesRepository repo = HouseRulesRepository();
      await repo.save(
        const HouseRules(points: <String, int>{'sable-antelope': 150}),
      );

      expect((await repo.load()).points, <String, int>{'sable-antelope': 150});
    });

    test('an empty table is removed rather than stored', () async {
      const HouseRulesRepository repo = HouseRulesRepository();
      await repo.save(
        const HouseRules(points: <String, int>{'sable-antelope': 150}),
      );
      await repo.save(HouseRules.none);

      expect((await repo.load()).isDefault, isTrue);
    });

    test('corrupt preferences fall back to the catalogue', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'wildscore.house_rules': 'not json',
      });

      // The catalogue's own numbers are a perfectly good game, and crashing on
      // launch over a preference is not a trade anybody would make.
      expect((await const HouseRulesRepository().load()).isDefault, isTrue);
    });
  });

  group('applied to the catalogue', () {
    test('replaces the score and says it was changed', () async {
      final List<Species> all = await const SpeciesRepository().loadAll(
        rules: const HouseRules(points: <String, int>{'sable-antelope': 150}),
      );
      final Species sable = all.firstWhere(
        (Species s) => s.id == 'sable-antelope',
      );

      expect(sable.points, 150);
      expect(sable.isHouseRule, isTrue);
      // The catalogue's own figure is kept beside it, so the card can offer to
      // put it back. An edit you cannot undo is a trap.
      expect(sable.cataloguePoints, isNot(150));
    });

    test('leaves everything else alone', () async {
      final List<Species> all = await const SpeciesRepository().loadAll(
        rules: const HouseRules(points: <String, int>{'sable-antelope': 150}),
      );

      for (final Species s in all.where(
        (Species s) => s.id != 'sable-antelope',
      )) {
        expect(s.isHouseRule, isFalse, reason: s.id);
      }
    });

    test('an edited score is what a claim scores', () async {
      // The reason this is applied at load rather than at each call site: the
      // claim sheet, the standings and the feed all get it without knowing the
      // feature exists.
      final List<Species> all = await const SpeciesRepository().loadAll(
        rules: const HouseRules(points: <String, int>{'sable-antelope': 150}),
      );
      final Species sable = all.firstWhere(
        (Species s) => s.id == 'sable-antelope',
      );

      expect(sable.scoreFor(), 150);
      expect(sable.scoreFor(context: SightingContext.jam), 120);
    });

    test('the multipliers still ride on top of an edited score', () async {
      final List<Species> all = await const SpeciesRepository().loadAll(
        rules: const HouseRules(points: <String, int>{'lion': 500}),
      );
      final Species lion = all.firstWhere((Species s) => s.id == 'lion');

      // Half again of 500, not of the catalogue's 120. Every modifier is a
      // proportion for exactly this reason.
      expect(lion.scoreFor(variantApplied: true), 750);
    });
  });

  group('decay', () {
    test('elephant and buffalo are worth less after the second', () async {
      final List<Species> all = await const SpeciesRepository().loadAll();
      final Species elephant = all.firstWhere(
        (Species s) => s.id == 'african-elephant',
      );

      expect(elephant.scoreFor(sightingsToday: 1), elephant.points);
      expect(elephant.scoreFor(sightingsToday: 2), elephant.points);
      expect(
        elephant.scoreFor(sightingsToday: 3),
        lessThan(elephant.points),
        reason: 'the fourteenth elephant is not the second one',
      );
    });

    test('neither is capped — a Big Five tile must never lock', () async {
      final List<Species> all = await const SpeciesRepository().loadAll();

      for (final Species s in all.where((Species s) => s.isBigFive)) {
        expect(s.chancesPerDay, isNull, reason: s.id);
      }
    });

    test('follows an edited score rather than a fixed number', () async {
      final List<Species> all = await const SpeciesRepository().loadAll(
        rules: const HouseRules(points: <String, int>{'african-elephant': 200}),
      );
      final Species elephant = all.firstWhere(
        (Species s) => s.id == 'african-elephant',
      );

      expect(elephant.scoreFor(sightingsToday: 1), 200);
      expect(elephant.scoreFor(sightingsToday: 3), 80);
    });

    test('almost nothing decays', () async {
      final List<Species> all = await const SpeciesRepository().loadAll();
      final List<String> decaying = <String>[
        for (final Species s in all)
          if (s.decay != null) s.id,
      ]..sort();

      expect(decaying, <String>['african-elephant', 'cape-buffalo']);
    });
  });

  group('caps', () {
    test('are only on what somebody would tap fifty times', () async {
      final List<Species> all = await const SpeciesRepository().loadAll();
      final Map<String, int> capped = <String, int>{
        for (final Species s in all)
          if (s.chancesPerDay != null) s.id: s.chancesPerDay!,
      };

      // It used to be every Common and Frequent animal at four a day, which
      // meant a real morning's zebra ran out — and so did elephant, in Kruger.
      expect(capped, <String, int>{'impala': 2, 'vervet-monkey': 4});
    });
  });
}
