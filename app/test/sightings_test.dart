import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/sightings.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/visit.dart';

/// The sightings feed is the tab people will open to settle an argument about
/// what happened on a trip two years ago. It has to be right about who found
/// what, and it must never say where a rhino was.
late final List<Species> _catalogue;

/// A finished day. [scores] maps a player name to `(speciesId, road)` pairs.
Visit _day(
  DateTime ended,
  Map<String, List<(String, String?)>> scores, {
  String owner = 'Alex',
}) {
  final Scorecard card = Scorecard.start(
    scores.keys.toList(),
    owner: owner,
    now: ended,
  );
  Scorecard filled = card;
  scores.forEach((String name, List<(String, String?)> claims) {
    final Player player = card.players.firstWhere((Player p) => p.name == name);
    for (final (String species, String? road) in claims) {
      filled = filled.withClaim(
        Claim(
          speciesId: species,
          playerId: player.id,
          at: ended,
          points: 0,
          road: road,
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

  Species byId(String id) => _catalogue.firstWhere((Species s) => s.id == id);

  group('what counts as notable', () {
    test('Rare and up is in', () {
      // eland is 100, cheetah 300, caracal 2000.
      expect(Sightings.notable(byId('eland')), isTrue);
      expect(Sightings.notable(byId('cheetah')), isTrue);
      expect(Sightings.notable(byId('caracal')), isTrue);
    });

    test('the Big Five are in on reputation alone', () {
      // An elephant is 15 points and would never clear the bar on scoring. It
      // is still the thing somebody rings their mother about.
      expect(
        byId('african-elephant').points,
        lessThan(Sightings.minimumPoints),
      );
      expect(Sightings.notable(byId('african-elephant')), isTrue);
      expect(Sightings.notable(byId('lion')), isTrue);
    });

    test('the everyday stuff is out', () {
      // A feed with every impala on it is a feed nobody scrolls.
      expect(Sightings.notable(byId('impala')), isFalse);
      expect(Sightings.notable(byId('klipspringer')), isFalse);
    });
  });

  group('building the feed', () {
    test('an empty history produces nothing', () {
      expect(Sightings.from(const <Visit>[], _catalogue), isEmpty);
    });

    test('only the notable finds appear', () {
      final Visit day = _day(
        DateTime(2026, 3, 4),
        <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[
            ('impala', 'S100'),
            ('leopard', 'S100 · Nkaya'),
            ('blue-wildebeest', null),
          ],
        },
      );

      final List<Sighting> feed = Sightings.from(<Visit>[day], _catalogue);

      expect(feed.map((Sighting s) => s.species.id), <String>['leopard']);
    });

    test('it keeps who actually called it', () {
      final Visit day = _day(
        DateTime(2026, 3, 4),
        <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('cheetah', null)],
          'Sam': <(String, String?)>[('eland', null)],
        },
      );

      final List<Sighting> feed = Sightings.from(<Visit>[day], _catalogue);
      final Sighting cheetah = feed.firstWhere(
        (Sighting s) => s.species.id == 'cheetah',
      );
      final Sighting eland = feed.firstWhere(
        (Sighting s) => s.species.id == 'eland',
      );

      expect(cheetah.finder, 'Alex');
      expect(cheetah.byOwner, isTrue);
      expect(eland.finder, 'Sam');
      expect(eland.byOwner, isFalse);
    });

    test('newest first', () {
      final List<Sighting> feed = Sightings.from(<Visit>[
        _day(DateTime(2024, 1, 1), <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('eland', null)],
        }),
        _day(DateTime(2026, 7, 9), <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('cheetah', null)],
        }),
      ], _catalogue);

      expect(feed.first.species.id, 'cheetah');
      expect(feed.last.species.id, 'eland');
    });

    test('the drive in play is in the feed before it is banked', () {
      // A leopard found twenty minutes ago is the single most likely reason
      // somebody opens this tab.
      final DateTime now = DateTime(2026, 8, 3, 9);
      Scorecard live = Scorecard.start(
        <String>['Alex'],
        owner: 'Alex',
        now: now,
      );
      live = live.withClaim(
        Claim(
          speciesId: 'leopard',
          playerId: live.players.single.id,
          at: now,
          points: 300,
          road: 'S100',
        ),
      );

      final List<Sighting> feed = Sightings.from(
        const <Visit>[],
        _catalogue,
        live: live,
      );

      expect(feed.single.species.id, 'leopard');
      expect(feed.single.live, isTrue);
    });

    test('a banked find is not marked live', () {
      final Visit day = _day(
        DateTime(2026, 3, 4),
        <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('cheetah', null)],
        },
      );

      expect(Sightings.from(<Visit>[day], _catalogue).single.live, isFalse);
    });
  });

  group('what needs a photograph behind it', () {
    test('Very rare and Legendary do', () {
      final Visit day = _day(
        DateTime(2026, 3, 4),
        <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[
            ('roan-antelope', null),
            ('caracal', null),
            ('cheetah', null),
            ('eland', null),
            ('lion', null),
          ],
        },
      );

      final Map<String, bool> flags = <String, bool>{
        for (final Sighting s in Sightings.from(<Visit>[day], _catalogue))
          s.species.id: s.needsVerifying,
      };

      expect(flags['roan-antelope'], isTrue);
      expect(flags['caracal'], isTrue);
      // Worth showing in the feed, not worth demanding evidence for. Cheetah
      // is on this side of the line now — Alex moved it down to Rare, on the
      // grounds that a diurnal cat on an open plain is not a claim anybody
      // would doubt.
      expect(flags['cheetah'], isFalse);
      expect(flags['eland'], isFalse);
      expect(flags['lion'], isFalse);
    });
  });

  group('where things were found', () {
    test('roads are tallied busiest first', () {
      final Visit day = _day(
        DateTime(2026, 3, 4),
        <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[
            ('cheetah', 'S100'),
            ('eland', 'S100'),
            ('leopard', 'H1-1 · Napi Road'),
          ],
        },
      );

      final List<RoadTally> roads = Sightings.roads(
        Sightings.from(<Visit>[day], _catalogue),
      );

      expect(roads.first.road, 'S100');
      expect(roads.first.count, 2);
      expect(roads.last.short, 'H1-1');
    });

    test('a find with no road is simply absent from the tally', () {
      final Visit day = _day(
        DateTime(2026, 3, 4),
        <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('cheetah', null)],
        },
      );

      expect(
        Sightings.roads(Sightings.from(<Visit>[day], _catalogue)),
        isEmpty,
      );
    });

    test('a rhino never carries a road, whatever the stored claim says', () {
      // LocationService refuses to look one up, so this can only arrive from
      // restored data written by another build. The feed is the one screen
      // where publishing it would put an animal in danger, so it is refused
      // here too rather than trusted.
      final Visit day = _day(
        DateTime(2026, 3, 4),
        <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[
            ('white-rhinoceros', 'S28'),
            ('pangolin', 'S100'),
          ],
        },
      );

      final List<Sighting> feed = Sightings.from(<Visit>[day], _catalogue);

      expect(feed, isNotEmpty);
      expect(feed.every((Sighting s) => s.road == null), isTrue);
      expect(Sightings.roads(feed), isEmpty);
    });
  });

  group('grouping into trips', () {
    test('consecutive days are one trip', () {
      final List<Sighting> feed = Sightings.from(<Visit>[
        _day(DateTime(2026, 7, 1), <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('eland', null)],
        }),
        _day(DateTime(2026, 7, 2), <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('cheetah', null)],
        }),
      ], _catalogue);

      final List<TripGroup> trips = Sightings.byTrip(feed);

      expect(trips, hasLength(1));
      expect(trips.single.sightings, hasLength(2));
      expect(trips.single.first, DateTime(2026, 7, 1));
      expect(trips.single.last, DateTime(2026, 7, 2));
    });

    test('a long gap starts a new trip', () {
      final List<Sighting> feed = Sightings.from(<Visit>[
        _day(DateTime(2025, 12, 20), <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('eland', null)],
        }),
        _day(DateTime(2026, 7, 2), <String, List<(String, String?)>>{
          'Alex': <(String, String?)>[('cheetah', null)],
        }),
      ], _catalogue);

      final List<TripGroup> trips = Sightings.byTrip(feed);

      expect(trips, hasLength(2));
      // Newest trip at the top.
      expect(trips.first.sightings.single.species.id, 'cheetah');
    });
  });
}
