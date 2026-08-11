import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/trip.dart';
import 'package:wildscore/domain/visit.dart';

/// A trip is derived from the gaps between drives rather than declared, so the
/// gap arithmetic is the whole feature.
///
/// It used to carry the first-spot bonuses as well — whether this impala was
/// the first of the holiday. That mechanic is gone, and the tests for it with
/// it; what is left is the definition of a trip, which the drive history still
/// groups by.
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
}
