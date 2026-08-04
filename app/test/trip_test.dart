import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/trip.dart';
import 'package:wildscore/domain/visit.dart';

/// A trip is derived from the gaps between drives rather than declared, so the
/// gap arithmetic is the whole feature. Get it wrong and the wild card either
/// pays out every morning or never pays out again.
Visit _drive(DateTime ended, {List<String> claimed = const <String>[]}) {
  final Scorecard card = Scorecard.start(
    <String>['Alex'],
    owner: 'Alex',
    now: ended,
  );
  Scorecard filled = card;
  for (final String id in claimed) {
    filled = filled.withClaim(
      Claim(
        speciesId: id,
        playerId: card.players.first.id,
        at: ended,
        points: 5,
      ),
    );
  }
  return Visit.from(filled, endedAt: ended);
}

void main() {
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

    test('a fortnight later is a different holiday', () {
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
      final List<Visit> visits = <Visit>[_drive(DateTime(2026, 1, 1))];

      expect(Trip.current(visits, now: DateTime(2026, 8, 1)), isEmpty);
    });
  });

  group('the wild card', () {
    test('is spent once it has been taken earlier in the trip', () {
      final List<Visit> visits = <Visit>[
        _drive(DateTime(2026, 8, 1), claimed: <String>['impala']),
      ];

      expect(
        Trip.wildCardsSpent(visits, now: DateTime(2026, 8, 2)),
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
        Trip.wildCardsSpent(visits, now: DateTime(2026, 8, 1)),
        isNot(contains('impala')),
      );
    });

    test('counts what today has already taken', () {
      final Scorecard card = Scorecard.start(
        <String>['Alex'],
        owner: 'Alex',
        now: DateTime(2026, 8, 2),
      );
      final Scorecard live = card.withClaim(
        Claim(
          speciesId: 'impala',
          playerId: card.players.first.id,
          at: DateTime(2026, 8, 2),
          points: 50,
        ),
      );

      expect(
        Trip.wildCardsSpent(const <Visit>[], live: live),
        contains('impala'),
      );
    });
  });

  group('what it is worth', () {
    late List<Species> catalogue;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      catalogue = await const SpeciesRepository().loadAll();
    });

    test('the impala is the wild card and pays 50, not 5', () {
      final Species impala = catalogue.firstWhere(
        (Species s) => s.id == 'impala',
      );

      expect(impala.isWildCard, isTrue);
      expect(impala.points, 50);
      expect(
        impala.rarityTier.points,
        5,
        reason: 'the tier is untouched — only the claim is worth more',
      );
    });

    test('nothing else is a wild card', () {
      expect(catalogue.where((Species s) => s.isWildCard).length, 1);
    });

    test('it cannot outrank a real find', () {
      final Species leopard = catalogue.firstWhere(
        (Species s) => s.id == 'leopard',
      );
      final Species impala = catalogue.firstWhere(
        (Species s) => s.id == 'impala',
      );

      expect(impala.points, lessThan(leopard.points));
    });
  });
}
