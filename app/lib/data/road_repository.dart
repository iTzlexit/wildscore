import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/kruger_roads.dart';

/// Loads the bundled Kruger road network.
///
/// Read once and held, because the lookup runs over every point and re-parsing
/// 230 KB of JSON per sighting would be absurd.
class RoadRepository {
  const RoadRepository();

  static const String _assetPath = 'assets/data/kruger-roads.json';

  static KrugerRoads? _cached;

  Future<KrugerRoads> load() async {
    final KrugerRoads? cached = _cached;
    if (cached != null) {
      return cached;
    }

    try {
      final Map<String, dynamic> decoded =
          json.decode(await rootBundle.loadString(_assetPath))
              as Map<String, dynamic>;
      final KrugerRoads roads = KrugerRoads(<KrugerRoad>[
        for (final dynamic r in decoded['roads'] as List<dynamic>)
          KrugerRoad.fromJson(r as Map<String, dynamic>),
      ]);
      return _cached = roads;
    } on Object {
      // A missing or corrupt road file must not stop anybody scoring a drive.
      // Sightings simply lose their road, which is a degradation rather than a
      // failure.
      return _cached = const KrugerRoads(<KrugerRoad>[]);
    }
  }
}
