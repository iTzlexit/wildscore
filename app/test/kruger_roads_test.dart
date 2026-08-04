import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/kruger_roads.dart';

/// The road lookup runs on a GPS fix taken in a moving car, and its output goes
/// into a permanent record. Naming the wrong road is worse than naming none.
late final KrugerRoads _roads;

void main() {
  setUpAll(() {
    final Map<String, dynamic> decoded =
        json.decode(File('assets/data/kruger-roads.json').readAsStringSync())
            as Map<String, dynamic>;
    _roads = KrugerRoads(<KrugerRoad>[
      for (final dynamic r in decoded['roads'] as List<dynamic>)
        KrugerRoad.fromJson(r as Map<String, dynamic>),
    ]);
  });

  test('the network is the whole park', () {
    final Set<String> refs = _roads.roads.map((KrugerRoad r) => r.ref).toSet();

    // The tar spine runs the length of Kruger and every one of these is a road
    // somebody will drive on a first trip.
    expect(refs, containsAll(<String>['H1-1', 'H1-9', 'H3', 'H4-1', 'H10']));
    // And the gravel roads people actually go looking for cats on.
    expect(refs, containsAll(<String>['S100', 'S114', 'S28']));
    expect(_roads.roads.length, greaterThan(100));
  });

  test('the tar roads carry the names people use', () {
    final KrugerRoad napi = _roads.roads.firstWhere(
      (KrugerRoad r) => r.ref == 'H1-1',
    );

    expect(napi.name, 'Napi Road');
    expect(napi.label, 'H1-1 · Napi Road');
  });

  test('an unnamed road is just its number', () {
    // Plenty of the gravel roads have no name in OSM, and "S46" is what the
    // signpost says anyway.
    final KrugerRoad unnamed = _roads.roads.firstWhere(
      (KrugerRoad r) => r.name == null,
    );

    expect(unnamed.label, unnamed.ref);
    expect(unnamed.label, isNot(contains('·')));
  });

  group('finding the nearest road', () {
    test('a point on a road finds that road', () {
      // Taken straight off the S100's own centreline, so the answer is not in
      // doubt.
      final KrugerRoad s100 = _roads.roads.firstWhere(
        (KrugerRoad r) => r.ref == 'S100',
      );
      final List<double> onIt = s100.points[s100.points.length ~/ 2];

      expect(_roads.nearest(onIt[0], onIt[1])?.ref, 'S100');
    });

    test('every road can find itself', () {
      // A road whose own midpoint resolves to a different road is a road that
      // will mislabel real sightings.
      int wrong = 0;
      for (final KrugerRoad road in _roads.roads) {
        final List<double> mid = road.points[road.points.length ~/ 2];
        if (_roads.nearest(mid[0], mid[1])?.ref != road.ref) {
          wrong++;
        }
      }

      // A handful genuinely share tarmac — junctions and shared stretches — so
      // this is not zero, but it must stay small.
      expect(wrong, lessThan(_roads.roads.length ~/ 10));
    });

    test('the middle of the bush is nowhere', () {
      // Deep in a wilderness area, far from any road in the dataset.
      expect(_roads.nearest(-24.2, 31.05), isNull);
    });
  });

  group('outside the park', () {
    test('Johannesburg is not on the H1-3', () {
      expect(KrugerRoads.inKruger(-26.20, 28.04), isFalse);
      expect(_roads.nearest(-26.20, 28.04), isNull);
    });

    test('Cape Town is not either', () {
      expect(_roads.nearest(-33.92, 18.42), isNull);
    });

    test('but Skukuza is', () {
      expect(KrugerRoads.inKruger(-24.99, 31.59), isTrue);
    });
  });

  test('an empty network never claims to know anything', () {
    // The road file failing to load must degrade to silence, not to a guess.
    const KrugerRoads empty = KrugerRoads(<KrugerRoad>[]);

    expect(empty.nearest(-24.99, 31.59), isNull);
  });
}
