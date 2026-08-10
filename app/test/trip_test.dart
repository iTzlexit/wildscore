import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/trip.dart';
import 'package:wildscore/domain/visit.dart';

/// A trip is derived from the gaps between drives rather than declared, so the
/// gap arithmetic is the whole feature. Get it wrong and the wild card either
/// pays out every morning or never pays out again.
late final List<Species> _catalogue;

Scorecard _card(List<String> claimed, DateTime day) {
  final Scorecard card = Scorecard.start(
    <String>['Alex'],
    owner: 'Alex',
    now: day,
  );
  Scorecard filled = card;
  for (final String id in claimed) {
    filled = filled.withClaim(
      Claim(speciesId: id, playerId: card.players.first.id, at: day, points: 5),
    );
  }
  return filled;
}

Visit _drive(DateTime ended, {List<String> claimed = const <String>[]}) =>
    Visit.from(_card(claimed, ended), endedAt: ended);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  group('working out the current trip', () {
    test('no drives means no trip', () {
      expect(Trip.current(const <Visit>[]), isEmpty);
    });

    test('groups consecutive days together', () {
      final List<Visit> visits = <Visit>[
        _drive(DateTime(2026, 8, 1)),
        _drive(DateTime(2026, 8, 2)),
        _drive(DateTime(2026, 8, 3)),
      ];

      expect(Trip.current(visits, now: DateTime(2026, 8, 4)).length, 3);
    });

    test('a rest day at camp does not end the trip', () {
      // Nobody drives on the middle day. It is still one holiday.
      final List<Visit> visits = <Visit>[
        _drive(DateTime(2026, 8, 1)),
        _drive(DateTime(2026, 8, 3)),
      ];

      expect(Trip.current(visits, now: DateTime(2026, 8, 3)).length, 2);
    });

    test('a month later is a different holiday', () {
      final List<Visit> visits = <Visit>[
        _drive(DateTime(2026, 7, 1)),
        _drive(DateTime(2026, 8, 1)),
      ];

      final List<Visit> trip = Trip.current(
        visits,
        now: DateTime(2026, 8, 1, 20),
      );

      expect(trip.length, 1);
      expect(trip.single.endedAt, DateTime(2026, 8, 1));
    });

    test('an old history with nothing recent is not a live trip', () {
      expect(
        Trip.current(<Visit>[
          _drive(DateTime(2026, 1, 1)),
        ], now: DateTime(2026, 8, 1)),
        isEmpty,
      );
    });
  });

  group('the trip-scoped bonus', () {
    test('impala is spent once taken earlier in the trip', () {
      // Yesterday's impala used the bonus. Today's impala is worth 5.
      final List<Visit> visits = <Visit>[
        _drive(DateTime(2026, 8, 1), claimed: <String>['impala']),
      ];

      expect(
        Trip.bonusesSpent(
          _catalogue,
          visits: visits,
          now: DateTime(2026, 8, 2),
        ),
        contains('impala'),
      );
    });

    test('comes back on a new trip', () {
      // The point is the first impala of a *holiday*. Two months later that is
      // a different holiday and a different first impala.
      final List<Visit> visits = <Visit>[
        _drive(DateTime(2026, 6, 1), claimed: <String>['impala']),
      ];

      expect(
        Trip.bonusesSpent(
          _catalogue,
          visits: visits,
          now: DateTime(2026, 8, 1),
        ),
        isNot(contains('impala')),
      );
    });
  });

  group('the day-scoped bonus', () {
    test('zebra resets overnight', () {
      // Yesterday's first zebra does not spend today's. "There's one!" is a
      // fresh moment every morning.
      final List<Visit> visits = <Visit>[
        _drive(DateTime(2026, 8, 1), claimed: <String>['plains-zebra']),
      ];

      expect(
        Trip.bonusesSpent(
          _catalogue,
          visits: visits,
          live: _card(const <String>[], DateTime(2026, 8, 2)),
          now: DateTime(2026, 8, 2),
        ),
        isNot(contains('plains-zebra')),
      );
    });

    test('but is gone once taken today', () {
      expect(
        Trip.bonusesSpent(
          _catalogue,
          visits: const <Visit>[],
          live: _card(<String>['plains-zebra'], DateTime(2026, 8, 2)),
        ),
        contains('plains-zebra'),
      );
    });
  });

  group('what a wild card is worth', () {
    test('the bonus is a bonus, not the species value', () {
      final Species impala = _catalogue.firstWhere(
        (Species s) => s.id == 'impala',
      );

      expect(impala.isWildCard, isTrue);
      expect(impala.wildCard!.bonus, 100);
      expect(
        impala.points,
        10,
        reason: 'the second impala of the day is an ordinary impala',
      );
    });

    test('a wild card has more than one chance, or the rule says nothing', () {
      // Zebra is uncapped now, like almost everything. "The first is worth
      // more" needs a second one to be possible, and unlimited is the most
      // permissive answer there is.
      for (final Species s in _catalogue.where((Species s) => s.isWildCard)) {
        expect(s.chancesPerDay, anyOf(isNull, greaterThan(1)), reason: s.id);
      }
    });

    test('the arrival animals are the wild cards', () {
      final List<String> wild = <String>[
        for (final Species s in _catalogue)
          if (s.isWildCard) s.id,
      ]..sort();

      // Lion, leopard and white rhino joined the herd animals. They are the
      // case Alex named: seen often enough that rarity scores them modestly,
      // and exciting every single time. Buffalo and elephant are deliberately
      // absent — nobody's day is made by the fourteenth elephant.
      expect(wild, <String>[
        'blue-wildebeest',
        'giraffe',
        'impala',
        'leopard',
        'lion',
        'plains-zebra',
        'white-rhinoceros',
      ]);
    });

    test('a wild card always pays more first time than it does after', () {
      for (final Species s in _catalogue.where((Species s) => s.isWildCard)) {
        expect(s.wildCard!.bonus, greaterThan(s.points), reason: s.id);
      }
    });

    test('a herd-animal bonus cannot outrank a real find', () {
      // Scoped to the everyday wild cards. Lion, leopard and white rhino are
      // wild cards *because* the first one is a real find — theirs are meant
      // to be big, and are checked separately in sighting_context_test.
      final Species leopard = _catalogue.firstWhere(
        (Species s) => s.id == 'leopard',
      );

      for (final String id in <String>[
        'impala',
        'plains-zebra',
        'giraffe',
        'blue-wildebeest',
      ]) {
        final Species s = _catalogue.firstWhere((Species x) => x.id == id);
        expect(s.wildCard!.bonus, lessThan(leopard.points), reason: id);
      }
    });
  });
}
