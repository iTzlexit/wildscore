import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/avatar_seed.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/domain/scorecard.dart';

/// The scoring engine. This is the number people compete over, and a scoring
/// bug found after a season has started cannot be quietly fixed — so it is
/// tested harder than anything else in the app.
Scorecard _card({List<String> names = const <String>['Alex', 'Sam']}) =>
    Scorecard.start(names, now: DateTime(2026, 8, 2, 6));

Claim _claim(String species, String player, int points, {int minute = 0}) =>
    Claim(
      speciesId: species,
      playerId: player,
      at: DateTime(2026, 8, 2, 6, minute),
      points: points,
    );

void main() {
  group('starting a day', () {
    test('creates a player per name, with unique ids', () {
      final Scorecard card = _card(names: <String>['Alex', 'Sam', 'Jo']);

      expect(card.players.length, 3);
      expect(card.players.map((Player p) => p.id).toSet().length, 3);
      expect(card.players.first.name, 'Alex');
    });

    test('trims whitespace from names', () {
      expect(_card(names: <String>['  Alex  ']).players.first.name, 'Alex');
    });

    test('starts with no claims and everyone on zero', () {
      final Scorecard card = _card();

      expect(card.claims, isEmpty);
      expect(card.totalPoints, 0);
      for (final Player p in card.players) {
        expect(card.pointsFor(p.id), 0);
      }
    });
  });

  group('the account holder in the car', () {
    test('is flagged, so their claims can reach a permanent collection', () {
      final Scorecard card = Scorecard.start(
        <String>['Alex', 'Sam'],
        owner: 'Alex',
        now: DateTime(2026, 8, 2, 6),
      );

      expect(card.owner?.name, 'Alex');
      expect(card.players[1].isOwner, isFalse);
    });

    test('is matched regardless of how the name was typed', () {
      final Scorecard card = Scorecard.start(
        <String>['  alex ', 'Sam'],
        owner: 'Alex',
        now: DateTime(2026, 8, 2, 6),
      );

      expect(card.owner?.name, 'alex');
    });

    test('keeps their permanent avatar', () {
      final Scorecard card = Scorecard.start(
        <String>['Alex', 'Sam'],
        owner: 'Alex',
        now: DateTime(2026, 8, 2, 6),
      );

      expect(card.owner?.avatar, AvatarSeed.forName('Alex'));
    });

    test('does not share a face with anyone else in the car', () {
      final Scorecard card = Scorecard.start(
        <String>['Alex', 'Sam', 'Jo', 'Thandi'],
        owner: 'Alex',
        now: DateTime(2026, 8, 2, 6),
      );

      expect(card.players.map((Player p) => p.avatar).toSet().length, 4);
    });

    test('is absent when nobody signed in — a guest-only game still works', () {
      final Scorecard card = _card();

      expect(card.owner, isNull);
      expect(card.players.every((Player p) => !p.isOwner), isTrue);
    });
  });

  group('claiming', () {
    test('adds points to the right player only', () {
      final Scorecard card = _card();
      final String alex = card.players[0].id;
      final String sam = card.players[1].id;

      final Scorecard after = card.withClaim(_claim('leopard', alex, 100));

      expect(after.pointsFor(alex), 100);
      expect(after.pointsFor(sam), 0);
      expect(after.totalPoints, 100);
    });

    test('accumulates across several claims', () {
      final Scorecard card = _card();
      final String alex = card.players[0].id;

      final Scorecard after = card
          .withClaim(_claim('impala', alex, 5))
          .withClaim(_claim('leopard', alex, 100))
          .withClaim(_claim('ground-pangolin', alex, 2500));

      expect(after.pointsFor(alex), 2605);
    });

    test('the original scorecard is not mutated', () {
      final Scorecard card = _card();
      card.withClaim(_claim('impala', card.players[0].id, 5));

      expect(card.claims, isEmpty);
    });

    test('points come from the claim, not from the tier', () {
      // A day scored months ago must stay explicable even if the tier is
      // revalued afterwards.
      final Scorecard card = _card();
      final Scorecard after = card.withClaim(
        _claim('leopard', card.players[0].id, 60),
      );

      expect(after.claims.single.points, 60);
      expect(after.pointsFor(card.players[0].id), 60);
    });
  });

  group('undo', () {
    test('removes only the most recent claim of that species', () {
      final Scorecard card = _card();
      final String alex = card.players[0].id;
      final String sam = card.players[1].id;

      final Scorecard after = card
          .withClaim(_claim('lion', alex, 40, minute: 1))
          .withClaim(_claim('lion', sam, 40, minute: 2))
          .withoutLastClaimOf('lion');

      expect(after.claims.length, 1);
      expect(after.pointsFor(alex), 40, reason: 'first claim survives');
      expect(after.pointsFor(sam), 0, reason: 'the mis-tap is undone');
    });

    test('leaves other species alone', () {
      final Scorecard card = _card();
      final String alex = card.players[0].id;

      final Scorecard after = card
          .withClaim(_claim('lion', alex, 40))
          .withClaim(_claim('impala', alex, 5))
          .withoutLastClaimOf('lion');

      expect(after.claims.single.speciesId, 'impala');
    });

    test('undoing something never claimed is a no-op', () {
      final Scorecard card = _card();
      expect(card.withoutLastClaimOf('nothing').claims, isEmpty);
    });
  });

  group('chances', () {
    test('common and frequent get one claim a day', () {
      expect(RarityTier.common.chancesPerDay, 1);
      expect(RarityTier.frequent.chancesPerDay, 1);
    });

    test('notable gets three', () {
      expect(RarityTier.uncommon.chancesPerDay, 3);
    });

    test('rare and above are unlimited — every leopard counts', () {
      expect(RarityTier.scarce.chancesPerDay, isNull);
      expect(RarityTier.rare.chancesPerDay, isNull);
      expect(RarityTier.veryRare.chancesPerDay, isNull);
      expect(RarityTier.legendary.chancesPerDay, isNull);
    });

    test('timesClaimed counts per species', () {
      final Scorecard card = _card();
      final String alex = card.players[0].id;

      final Scorecard after = card
          .withClaim(_claim('lion', alex, 40))
          .withClaim(_claim('lion', alex, 40))
          .withClaim(_claim('impala', alex, 5));

      expect(after.timesClaimed('lion'), 2);
      expect(after.timesClaimed('impala'), 1);
      expect(after.timesClaimed('leopard'), 0);
    });
  });

  group('standings', () {
    test('orders by points, highest first', () {
      final Scorecard card = _card(names: <String>['Alex', 'Sam', 'Jo']);
      final Scorecard after = card
          .withClaim(_claim('impala', card.players[0].id, 5))
          .withClaim(_claim('leopard', card.players[2].id, 100));

      expect(after.standings.map((Player p) => p.name).toList(), <String>[
        'Jo',
        'Alex',
        'Sam',
      ]);
    });

    test('everyone on zero keeps entry order', () {
      final Scorecard card = _card(names: <String>['Alex', 'Sam', 'Jo']);

      expect(card.standings.map((Player p) => p.name).toList(), <String>[
        'Alex',
        'Sam',
        'Jo',
      ]);
    });
  });

  group('the edit window', () {
    test('a fresh claim is editable', () {
      final Claim c = _claim('lion', 'p0', 40);
      expect(c.canEditAt(c.at.add(const Duration(minutes: 4))), isTrue);
    });

    test('locks after five minutes, so nobody relitigates at dinner', () {
      final Claim c = _claim('lion', 'p0', 40);
      expect(c.canEditAt(c.at.add(const Duration(minutes: 6))), isFalse);
    });
  });

  group('restarting', () {
    test('keeps the car and drops the claims', () {
      final Scorecard card = _card()
          .withClaim(_claim('lion', 'p0', 40))
          .withClaim(_claim('impala', 'p1', 5));

      final Scorecard after = card.restarted;

      expect(after.claims, isEmpty);
      expect(after.players, card.players);
      expect(after.startedAt, card.startedAt);
    });

    test('leaves the original alone', () {
      final Scorecard card = _card().withClaim(_claim('lion', 'p0', 40));
      card.restarted;

      expect(card.claims.length, 1);
    });
  });

  test('speciesClaimedBy is one player only', () {
    final Scorecard card = _card();
    final String alex = card.players[0].id;
    final String sam = card.players[1].id;

    final Scorecard after = card
        .withClaim(_claim('lion', alex, 40))
        .withClaim(_claim('lion', alex, 40))
        .withClaim(_claim('impala', sam, 5));

    expect(after.speciesClaimedBy(alex), <String>{'lion'});
    expect(after.speciesClaimedBy(sam), <String>{'impala'});
  });

  test('survives a JSON round trip', () {
    final Scorecard card = Scorecard.start(
      <String>['Alex', 'Sam'],
      owner: 'Alex',
      now: DateTime(2026, 8, 2, 6),
    ).withClaim(_claim('leopard', 'p0-x', 100, minute: 3));
    final Scorecard restored = Scorecard.fromJson(card.toJson());

    expect(restored.players.length, card.players.length);
    expect(restored.claims.length, 1);
    expect(restored.claims.single.points, 100);
    expect(restored.claims.single.speciesId, 'leopard');
    expect(restored.startedAt, card.startedAt);
    expect(restored.owner?.name, 'Alex', reason: 'the owner flag persists');
    expect(restored.players.first.avatar, card.players.first.avatar);
  });

  test('a game saved before avatars existed still loads', () {
    // Shipped builds have scorecards in shared_preferences. A field added
    // today must not wedge someone mid-trip.
    final Scorecard restored = Scorecard.fromJson(<String, dynamic>{
      'startedAt': '2026-08-02T06:00:00.000',
      'players': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'p0', 'name': 'Alex'},
      ],
      'claims': <Map<String, dynamic>>[],
    });

    expect(restored.players.single.name, 'Alex');
    expect(restored.players.single.isOwner, isFalse);
  });

  test('claimedSpecies is the set the Codex colours by', () {
    final Scorecard card = _card();
    final String alex = card.players[0].id;

    final Scorecard after = card
        .withClaim(_claim('lion', alex, 40))
        .withClaim(_claim('lion', alex, 40))
        .withClaim(_claim('impala', alex, 5));

    expect(after.claimedSpecies, <String>{'lion', 'impala'});
  });
}
