import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildscore/data/house_rules_repository.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/house_rules.dart';
import 'package:wildscore/domain/sighting_context.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/profile/house_rules_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The three judgement calls we made on everybody's behalf, and the screen
/// where a car overrules them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('the jam tax', () {
    test('is a fifth unless the car says otherwise', () {
      expect(HouseRules.none.effectiveJamPenalty, 0.2);
      expect(HouseRules.none.jamMultiplier, closeTo(0.8, 0.0001));
    });

    test('can be switched off entirely', () {
      // A real choice, not a token one. Some cars will decide a sighting is a
      // sighting and the tax is us being clever at them.
      const HouseRules off = HouseRules(jamPenalty: 0);

      expect(off.jamMultiplier, 1);
      expect(
        SightingContext.jam.applyTo(100, jamMultiplier: off.jamMultiplier),
        100,
      );
    });

    test('reaches the score', () async {
      final List<Species> all = await const SpeciesRepository().loadAll();
      final Species leopard = all.firstWhere((Species s) => s.id == 'leopard');
      const HouseRules harsh = HouseRules(jamPenalty: 0.5);

      expect(
        leopard.scoreFor(
          context: SightingContext.jam,
          jamMultiplier: harsh.jamMultiplier,
        ),
        (leopard.points * 0.5).ceil(),
      );
    });

    test('leaves a lone sighting alone whatever it is set to', () {
      // The tax is on the jam, not on the animal. A car that sets it to half
      // must not find its ordinary sightings halved too.
      for (final double p in HouseRules.jamPenaltyChoices) {
        final HouseRules r = HouseRules(jamPenalty: p);
        expect(
          SightingContext.alone.applyTo(100, jamMultiplier: r.jamMultiplier),
          100,
          reason: '$p',
        );
        expect(
          SightingContext.normal.applyTo(100, jamMultiplier: r.jamMultiplier),
          100,
          reason: '$p',
        );
      }
    });
  });

  group('caps a car sets itself', () {
    test('override the catalogue', () async {
      final List<Species> all = await const SpeciesRepository().loadAll(
        rules: const HouseRules(
          caps: <String, SpeciesCap?>{
            'leopard': SpeciesCap(times: 1, scope: CapScope.trip),
          },
        ),
      );
      final Species leopard = all.firstWhere((Species s) => s.id == 'leopard');

      expect(leopard.cap?.times, 1);
      expect(leopard.cap?.scope, CapScope.trip);
      expect(leopard.isHouseRule, isTrue);
    });

    test('a present key holding null means "no limit, and I mean it"', () async {
      // Three states, not two. A car that wants unlimited impala has to be
      // able to say so, and that is not the same as never having asked — the
      // shipped default can still move under the second and must not under the
      // first.
      final List<Species> all = await const SpeciesRepository().loadAll(
        rules: const HouseRules(caps: <String, SpeciesCap?>{'impala': null}),
      );
      final Species impala = all.firstWhere((Species s) => s.id == 'impala');

      expect(impala.cap, isNull);
      expect(impala.houseCapSet, isTrue);
      expect(impala.catalogueCap?.times, 2, reason: 'ours is still recorded');
    });

    test('leaving it alone keeps the catalogue and stays changeable', () async {
      final List<Species> all = await const SpeciesRepository().loadAll();
      final Species impala = all.firstWhere((Species s) => s.id == 'impala');

      expect(impala.houseCapSet, isFalse);
      expect(impala.cap?.times, 2);
    });
  });

  group('storage', () {
    test('carries all three through a round trip', () async {
      const HouseRulesRepository repo = HouseRulesRepository();
      const HouseRules rules = HouseRules(
        points: <String, int>{'sable-antelope': 150},
        caps: <String, SpeciesCap?>{
          'leopard': SpeciesCap(times: 1, scope: CapScope.trip),
          'impala': null,
        },
        jamPenalty: 0.4,
      );

      await repo.save(rules);
      final HouseRules back = await repo.load();

      expect(back.points, rules.points);
      expect(
        back.caps['leopard'],
        const SpeciesCap(times: 1, scope: CapScope.trip),
      );
      expect(back.caps.containsKey('impala'), isTrue);
      expect(back.caps['impala'], isNull);
      expect(back.jamPenalty, 0.4);
    });

    test('an older points-only table is picked up, not lost', () async {
      // The first version of this stored points under their own key. Somebody
      // who revalued an animal before the settings screen existed keeps it.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'wildscore.house_rules.points': '{"sable-antelope":150}',
      });

      final HouseRules rules = await const HouseRulesRepository().load();

      expect(rules.points, <String, int>{'sable-antelope': 150});
    });

    test('the old key is cleared on the next save', () async {
      // Left behind, it would resurrect an old points table the next time the
      // new key failed to parse.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'wildscore.house_rules.points': '{"sable-antelope":150}',
      });
      const HouseRulesRepository repo = HouseRulesRepository();

      await repo.save(const HouseRules(jamPenalty: 0));
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('wildscore.house_rules.points'), isNull);
      expect((await repo.load()).points, isEmpty);
    });
  });

  group('the screen', () {
    Future<HouseRules?> pump(WidgetTester tester, HouseRules rules) async {
      HouseRules? saved;
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HouseRulesScreen(
            rules: rules,
            onChanged: (HouseRules r) => saved = r,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return saved;
    }

    testWidgets('offers switching the tax off', (WidgetTester tester) async {
      await pump(tester, HouseRules.none);
      expect(find.text('No tax'), findsOneWidget);
      expect(find.text('−20%'), findsOneWidget);
      expect(find.text('−50%'), findsOneWidget);
    });

    testWidgets('shows the sum rather than the setting', (
      WidgetTester tester,
    ) async {
      // A percentage is a rule; "a 100-point leopard pays 80" is the game.
      await pump(tester, HouseRules.none);
      expect(find.textContaining('pays 80'), findsOneWidget);
    });

    testWidgets('choosing our own number clears the setting', (
      WidgetTester tester,
    ) async {
      // Otherwise a car that agreed with us in August is pinned to that number
      // when we change our minds in September.
      HouseRules? saved;
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HouseRulesScreen(
            rules: const HouseRules(jamPenalty: 0.5),
            onChanged: (HouseRules r) => saved = r,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('−20%'));
      await tester.pumpAndSettle();

      expect(saved?.jamPenalty, isNull);
      expect(saved?.isDefault, isTrue);
    });

    testWidgets('owns up to how much has been changed', (
      WidgetTester tester,
    ) async {
      await pump(tester, HouseRules.none);
      expect(find.text('You have not changed anything yet.'), findsOneWidget);
      expect(find.text('Put everything back'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HouseRulesScreen(
            rules: const HouseRules(
              points: <String, int>{'sable-antelope': 150},
              jamPenalty: 0,
            ),
            onChanged: (HouseRules _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You have changed 2 things.'), findsOneWidget);
      expect(find.text('Put everything back'), findsOneWidget);
    });
  });
}
