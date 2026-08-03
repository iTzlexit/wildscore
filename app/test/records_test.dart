import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/records.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/visit.dart';

/// Records replaced the leaderboard, so this is the only competitive surface
/// left. A head-to-head that says the wrong person is winning is the kind of
/// bug a family notices immediately and loudly.
late final List<Species> _catalogue;

/// A finished day. [scores] maps a player name to the species they called.
Visit _day(
  DateTime ended,
  Map<String, List<(String, int)>> scores, {
  String owner = 'Alex',
}) {
  final Scorecard card = Scorecard.start(
    scores.keys.toList(),
    owner: owner,
    now: ended,
  );
  Scorecard filled = card;
  scores.forEach((String name, List<(String, int)> claims) {
    final Player player = card.players.firstWhere((Player p) => p.name == name);
    for (final (String species, int points) in claims) {
      filled = filled.withClaim(
        Claim(
          speciesId: species,
          playerId: player.id,
          at: ended,
          points: points,
        ),
      );
    }
  });
  return Visit.from(filled, endedAt: ended);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  test('an empty history says so rather than showing zeroes', () {
    final Records records = Records.from(const <Visit>[], _catalogue);

    expect(records.isEmpty, isTrue);
    expect(records.bestDrive, isNull);
    expect(records.rarest, isNull);
    expect(records.rivals, isEmpty);
  });

  group('personal bests', () {
    test('the best day is the owner best, not the car best', () {
      // Sam had a huge day on the 1st. That is not Alex's record.
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'Sam': <(String, int)>[('ground-pangolin', 2500)],
        }),
        _day(DateTime(2026, 8, 2), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('leopard', 100)],
          'Sam': <(String, int)>[('impala', 5)],
        }),
      ];

      final Records records = Records.from(history, _catalogue);

      expect(records.bestDrive?.endedAt, DateTime(2026, 8, 2));
      expect(records.bestDrive?.ownerPoints, 100);
    });

    test('the rarest find is one you called yourself', () {
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('leopard', 100)],
          'Sam': <(String, int)>[('ground-pangolin', 2500)],
        }),
      ];

      final Records records = Records.from(history, _catalogue);

      expect(
        records.rarest?.species.id,
        'leopard',
        reason: "Sam's pangolin is not Alex's record",
      );
    });

    test('counts only the owner sightings', () {
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('leopard', 100), ('impala', 5)],
          'Sam': <(String, int)>[('lion', 40)],
        }),
      ];

      expect(Records.from(history, _catalogue).sightings, 2);
      expect(Records.from(history, _catalogue).lifetimePoints, 105);
    });

    test('a day the phone was lent out counts for nobody', () {
      final Visit borrowed = _day(
        DateTime(2026, 8, 1),
        <String, List<(String, int)>>{
          'Sam': <(String, int)>[('leopard', 100)],
        },
        owner: 'Nobody',
      );

      final Records records = Records.from(<Visit>[borrowed], _catalogue);

      expect(records.bestDrive, isNull);
      expect(records.rarest, isNull);
      expect(records.rivals, isEmpty);
    });
  });

  group('head to head', () {
    test('tracks wins and losses per person across drives', () {
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('leopard', 100)],
          'Sam': <(String, int)>[('impala', 5)],
        }),
        _day(DateTime(2026, 8, 2), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'Sam': <(String, int)>[('cheetah', 250)],
        }),
        _day(DateTime(2026, 8, 3), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('lion', 40)],
          'Sam': <(String, int)>[('impala', 5)],
        }),
      ];

      final Rival sam = Records.from(history, _catalogue).rivals.single;

      expect(sam.name, 'Sam');
      expect(sam.drives, 3);
      expect(sam.wins, 2);
      expect(sam.losses, 1);
      expect(sam.ahead, isTrue);
    });

    test('a dead heat is a draw, not a win', () {
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'Sam': <(String, int)>[('steenbok', 5)],
        }),
      ];

      final Rival sam = Records.from(history, _catalogue).rivals.single;

      expect(sam.draws, 1);
      expect(sam.wins, 0);
      expect(sam.losses, 0);
      expect(sam.level, isTrue);
    });

    test('the same person across drives is one rival, not several', () {
      // Player ids are minted per drive, so matching on id would make every
      // day a brand new brother.
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'Sam': <(String, int)>[('lion', 40)],
        }),
        _day(DateTime(2026, 8, 2), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'sam': <(String, int)>[('lion', 40)],
        }),
      ];

      final List<Rival> rivals = Records.from(history, _catalogue).rivals;

      expect(rivals.length, 1);
      expect(rivals.single.drives, 2);
    });

    test('solo drives create no rivals', () {
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('leopard', 100)],
        }),
      ];

      final Records records = Records.from(history, _catalogue);

      expect(records.rivals, isEmpty);
      expect(records.bestDrive?.ownerPoints, 100);
    });

    test('the most-played rival comes first', () {
      final List<Visit> history = <Visit>[
        _day(DateTime(2026, 8, 1), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'Jo': <(String, int)>[('lion', 40)],
        }),
        _day(DateTime(2026, 8, 2), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'Sam': <(String, int)>[('lion', 40)],
        }),
        _day(DateTime(2026, 8, 3), <String, List<(String, int)>>{
          'Alex': <(String, int)>[('impala', 5)],
          'Sam': <(String, int)>[('lion', 40)],
        }),
      ];

      expect(Records.from(history, _catalogue).rivals.first.name, 'Sam');
    });
  });
}
