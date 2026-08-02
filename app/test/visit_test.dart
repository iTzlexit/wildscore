import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/visit.dart';

/// A finished day is the only thing that becomes permanent, so what it carries
/// forward — and what it refuses to — is worth pinning down.
Scorecard _card() => Scorecard.start(
  <String>['Alex', 'Sam', 'Jo'],
  owner: 'Alex',
  now: DateTime(2026, 8, 2, 6),
);

Claim _claim(String species, String player, int points) => Claim(
  speciesId: species,
  playerId: player,
  at: DateTime(2026, 8, 2, 9),
  points: points,
);

void main() {
  test('carries the whole car forward, not just the owner', () {
    // "Who was in the car with me" is the thing anyone wants to remember about
    // a trip, and once the day is thrown away nothing brings it back.
    final Scorecard card = _card();
    final Visit visit = Visit.from(card, endedAt: DateTime(2026, 8, 2, 18));

    expect(visit.players.length, 3);
    expect(visit.players.map((Player p) => p.name), contains('Sam'));
  });

  group('what the owner banks', () {
    test('is only their own points', () {
      final Scorecard card = _card();
      final Visit visit = Visit.from(
        card
            .withClaim(_claim('leopard', card.players[0].id, 100))
            .withClaim(_claim('cheetah', card.players[1].id, 250)),
      );

      expect(visit.totalPoints, 350, reason: 'the car scored 350');
      expect(visit.ownerPoints, 100, reason: 'but only 100 was mine');
    });

    test('is only their own species', () {
      final Scorecard card = _card();
      final Visit visit = Visit.from(
        card
            .withClaim(_claim('leopard', card.players[0].id, 100))
            .withClaim(_claim('cheetah', card.players[1].id, 250)),
      );

      expect(visit.ownerSpecies, <String>{'leopard'});
    });

    test('but the collection gets everything the car saw', () {
      // If Sam shouts "pangolin" and you look up and see a pangolin, you have
      // seen a pangolin. Points are for who called it first; the collection is
      // for what you have seen. Different questions.
      final Scorecard card = _card();
      final Visit visit = Visit.from(
        card
            .withClaim(_claim('leopard', card.players[0].id, 100))
            .withClaim(_claim('ground-pangolin', card.players[1].id, 2500)),
      );

      expect(visit.collectedSpecies, <String>{'leopard', 'ground-pangolin'});
      expect(
        visit.ownerPoints,
        100,
        reason: 'seeing it is not the same as calling it',
      );
    });

    test('the collection stays empty when the owner was not in the car', () {
      // The phone can be handed to a friend for the day. A collection should
      // not grow while its owner is at home.
      final Scorecard card = Scorecard.start(<String>[
        'Sam',
        'Jo',
      ], now: DateTime(2026, 8, 2, 6));
      final Visit visit = Visit.from(
        card.withClaim(_claim('ground-pangolin', card.players[0].id, 2500)),
      );

      expect(visit.collectedSpecies, isEmpty);
    });

    test('is nothing when they were not playing', () {
      // The phone can be handed to a friend for the day.
      final Scorecard card = Scorecard.start(<String>[
        'Sam',
        'Jo',
      ], now: DateTime(2026, 8, 2, 6));
      final Visit visit = Visit.from(
        card.withClaim(_claim('leopard', card.players[0].id, 100)),
      );

      expect(visit.ownerPoints, 0);
      expect(visit.ownerSpecies, isEmpty);
    });
  });

  test('a lifetime total is the sum of the days', () {
    // Derived, never stored — which is the whole reason undo and restart no
    // longer need to reverse anything.
    final Scorecard card = _card();
    final String me = card.players[0].id;
    final List<Visit> history = <Visit>[
      Visit.from(card.withClaim(_claim('leopard', me, 100))),
      Visit.from(card.withClaim(_claim('ground-pangolin', me, 2500))),
    ];

    expect(history.fold(0, (int s, Visit v) => s + v.ownerPoints), 2600);
  });

  test('knows a solo drive from a carful', () {
    expect(
      Visit.from(Scorecard.start(<String>['Alex'], owner: 'Alex')).wasSolo,
      isTrue,
    );
    expect(Visit.from(_card()).wasSolo, isFalse);
  });

  test('survives a JSON round trip', () {
    final Scorecard card = _card();
    final Visit visit = Visit.from(
      card.withClaim(_claim('leopard', card.players[0].id, 100)),
      endedAt: DateTime(2026, 8, 2, 18),
    );
    final Visit restored = Visit.fromJson(visit.toJson());

    expect(restored.endedAt, DateTime(2026, 8, 2, 18));
    expect(restored.players.length, 3);
    expect(restored.ownerPoints, 100);
    expect(restored.owner?.name, 'Alex');
    expect(restored.claims.single.speciesId, 'leopard');
  });
}
