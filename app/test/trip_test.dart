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
      expect(Species.wildCardBonus, 40);
      expect(
        impala.points,
        5,
        reason: 'the second impala of the day is an ordinary impala',
      );
    });

    test('a wild card has more than one chance, or the rule says nothing', () {
      final Species zebra = _catalogue.firstWhere(
        (Species s) => s.id == 'plains-zebra',
      );

      expect(zebra.chancesPerDay, 4);
      expect(
        zebra.chancesPerDay,
        greaterThan(1),
        reason: '"the first is worth more" says nothing if there is only one',
      );
    });

    test('the arrival animals are the wild cards', () {
      final List<String> wild = <String>[
        for (final Species s in _catalogue)
          if (s.isWildCard) s.id,
      ]..sort();

      expect(wild, <String>[
        'blue-wildebeest',
        'giraffe',
        'impala',
        'plains-zebra',
      ]);
    });

    test('the bonus cannot outrank a real find', () {
      final Species leopard = _catalogue.firstWhere(
        (Species s) => s.id == 'leopard',
      );

      expect(Species.wildCardBonus, lessThan(leopard.points));
    });
  });
}
