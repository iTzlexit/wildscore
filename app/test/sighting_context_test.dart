import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/sighting_context.dart';
import 'package:wildscore/domain/species.dart';

/// Scoring is what the whole game is, and a car will notice a wrong number
/// within about four seconds. These are the three modifiers that stack.
late final List<Species> _catalogue;

Species _byId(String id) => _catalogue.firstWhere((Species s) => s.id == id);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  group('who else was there', () {
    test('finding it alone is worth double', () {
      expect(SightingContext.alone.applyTo(300), 600);
    });

    test('an ordinary sighting is worth what it says on the tin', () {
      expect(SightingContext.normal.applyTo(300), 300);
    });

    test('arriving at a jam still counts, for half', () {
      // Still counts on purpose. Refusing the points for an animal somebody
      // genuinely saw invites them to lie about it, and pretending you did not
      // see the leopard is silly.
      expect(SightingContext.jam.applyTo(300), 150);
    });

    test('halving never reaches zero', () {
      // A rule that can zero a real sighting is a rule people argue with.
      expect(SightingContext.jam.applyTo(5), 3);
      expect(SightingContext.jam.applyTo(1), 1);
    });

    test('an unknown stored value reads as ordinary', () {
      // Forward compatibility: a context added in a later version must not
      // crash an older build reading a restored backup.
      expect(SightingContext.byName('stampede'), SightingContext.normal);
      expect(SightingContext.byName('jam'), SightingContext.jam);
    });
  });

  group('the male lion', () {
    test('lion carries a variant and almost nothing else does', () {
      expect(_byId('lion').variant, isNotNull);
      expect(_byId('impala').variant, isNull);

      final int withVariants = _catalogue
          .where((Species s) => s.variant != null)
          .length;
      expect(withVariants, 1, reason: 'only the lion, for now');
    });

    test('a male is worth more than a lion', () {
      final Species lion = _byId('lion');

      expect(lion.scoreFor(), 40);
      expect(lion.scoreFor(variantApplied: true), 100);
    });

    test('the bonus is ignored for a species with no variant', () {
      // Nothing should be able to hand an impala a lion's bonus.
      expect(_byId('impala').scoreFor(variantApplied: true), 5);
    });
  });

  group('the modifiers stack', () {
    test('a male lion found on an empty road', () {
      // (40 + 60) x 2. The best possible lion, and worth shouting about.
      expect(
        _byId(
          'lion',
        ).scoreFor(variantApplied: true, context: SightingContext.alone),
        200,
      );
    });

    test('the same lion at a jam of eleven cars', () {
      expect(
        _byId(
          'lion',
        ).scoreFor(variantApplied: true, context: SightingContext.jam),
        50,
      );
    });

    test('the wild card replaces the tier value rather than adding to it', () {
      // The first zebra of the morning is worth 50, not 55.
      final Species zebra = _byId('plains-zebra');

      expect(zebra.scoreFor(), 5);
      expect(zebra.scoreFor(wildCardBonusEarned: true), 50);
    });
  });

  group('when the question gets asked', () {
    test('only for animals a jam would form around', () {
      // A prompt after every claim is a tax on the fun part of the game.
      expect(_byId('leopard').crowdMatters, isTrue);
      expect(_byId('lion').crowdMatters, isTrue, reason: 'Big Five');
      expect(
        _byId('african-elephant').crowdMatters,
        isTrue,
        reason: 'Big Five',
      );
      expect(_byId('eland').crowdMatters, isTrue, reason: '100 points');

      expect(_byId('impala').crowdMatters, isFalse);
      expect(_byId('helmeted-guineafowl').crowdMatters, isFalse);
      expect(_byId('klipspringer').crowdMatters, isFalse);
    });
  });

  group('storing it', () {
    test('an ordinary claim writes no extra fields', () {
      // The common claim must not grow, or every backup code grows with it.
      final Claim claim = Claim(
        speciesId: 'impala',
        playerId: 'p1',
        at: DateTime(2026, 8, 8),
        points: 5,
      );

      expect(claim.toJson().containsKey('context'), isFalse);
      expect(claim.toJson().containsKey('variant'), isFalse);
    });

    test('a modified claim survives a round trip', () {
      final Claim claim = Claim(
        speciesId: 'lion',
        playerId: 'p1',
        at: DateTime(2026, 8, 8),
        points: 200,
        context: SightingContext.alone,
        variant: true,
      );

      final Claim back = Claim.fromJson(claim.toJson());

      expect(back.context, SightingContext.alone);
      expect(back.variant, isTrue);
      expect(back.points, 200);
    });

    test('a claim written before any of this existed still scores', () {
      // Every drive already in somebody's history. A lifetime total that shifts
      // when the app updates is a bug people notice and cannot explain.
      final Claim old = Claim.fromJson(<String, dynamic>{
        'speciesId': 'leopard',
        'playerId': 'p1',
        'at': '2025-06-04T08:00:00.000',
        'points': 300,
      });

      expect(old.context, SightingContext.normal);
      expect(old.variant, isFalse);
      expect(old.points, 300);
    });
  });

  group('what it was doing', () {
    test('a baby is only asked about for mammals', () {
      expect(_byId('lion').possibleExtras, contains(SightingExtra.withYoung));
      expect(_byId('impala').possibleExtras, contains(SightingExtra.withYoung));
      // Asking whether a puff adder had a baby with it is the kind of question
      // that makes people stop trusting the rest of them.
      expect(
        _byId('puff-adder').possibleExtras,
        isNot(contains(SightingExtra.withYoung)),
      );
    });

    test('a kill is only asked about for predators', () {
      expect(_byId('leopard').possibleExtras, contains(SightingExtra.onAKill));
      expect(
        _byId('giraffe').possibleExtras,
        isNot(contains(SightingExtra.onAKill)),
      );
    });

    test('each one is worth half again', () {
      // Derived from the tier rather than typed, because the whole point of
      // the ranking exercise is that these numbers are going to move.
      final Species leopard = _byId('leopard');
      final int base = leopard.points;

      expect(
        leopard.scoreFor(extras: <SightingExtra>{SightingExtra.onAKill}),
        (base * 1.5).round(),
      );
    });

    test('they stack with each other and with the crowd', () {
      // A leopard on a kill with a cub, on an empty road. The best sighting
      // most people will ever have, and the score should say so.
      expect(
        _byId('leopard').scoreFor(
          extras: <SightingExtra>{
            SightingExtra.onAKill,
            SightingExtra.withYoung,
          },
          context: SightingContext.alone,
        ),
        (_byId('leopard').points * 1.5 * 1.5 * 2).round(),
      );
    });

    test('they survive a round trip and are absent when empty', () {
      final Claim plain = Claim(
        speciesId: 'impala',
        playerId: 'p1',
        at: DateTime(2026, 8, 9),
        points: 5,
      );
      expect(plain.toJson().containsKey('extras'), isFalse);

      final Claim rich = Claim(
        speciesId: 'leopard',
        playerId: 'p1',
        at: DateTime(2026, 8, 9),
        points: 450,
        extras: <SightingExtra>{SightingExtra.onAKill},
      );
      expect(Claim.fromJson(rich.toJson()).extras, <SightingExtra>{
        SightingExtra.onAKill,
      });
    });

    test('an unknown extra from a newer version is dropped, not fatal', () {
      final Claim old = Claim.fromJson(<String, dynamic>{
        'speciesId': 'leopard',
        'playerId': 'p1',
        'at': '2026-08-09T08:00:00.000',
        'points': 300,
        'extras': <String>['inATree'],
      });

      expect(old.extras, isEmpty);
    });
  });
}
