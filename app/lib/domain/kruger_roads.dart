import 'dart:math' as math;

/// One road in the park, as a chain of points along its centreline.
class KrugerRoad {
  const KrugerRoad({
    required this.ref,
    required this.name,
    required this.points,
  });

  factory KrugerRoad.fromJson(Map<String, dynamic> json) => KrugerRoad(
    ref: json['ref'] as String,
    name: json['name'] as String?,
    points: <List<double>>[
      for (final dynamic p in json['points'] as List<dynamic>)
        <double>[
          ((p as List<dynamic>)[0] as num).toDouble(),
          (p[1] as num).toDouble(),
        ],
    ],
  );

  /// `H1-3`, `S100`. What everybody actually calls it and what is painted on
  /// the signpost.
  final String ref;

  /// `Napi Road`. Present for the tar roads, mostly absent for the S roads.
  final String? name;

  final List<List<double>> points;

  /// `S100` on its own, or `H1-1 · Napi Road` when there is a name worth having.
  String get label => name == null ? ref : '$ref · $name';
}

/// Works out which Kruger road a position is on, entirely offline.
///
/// GPS needs no signal, which is the whole reason this is possible in a park
/// with none. The road network is bundled — 127 roads, about 230 KB — because
/// downloading it would defeat the point, and because a real tile map would
/// have cost 40 MB and a licence.
///
/// What this buys: a sighting that says **"Leopard — S100"** instead of
/// "Leopard". That is the detail people actually remember about a find, and it
/// costs one small file and no server.
class KrugerRoads {
  const KrugerRoads(this.roads);

  final List<KrugerRoad> roads;

  /// Beyond this from the nearest known road, the answer is "no idea".
  ///
  /// Generous on purpose: GPS in thick bush drifts, and roads are simplified to
  /// 200 m between points so a genuine position can sit a little off the line.
  /// Being silent is much better than naming the wrong road.
  static const double maxMetres = 350;

  /// The park's bounding box, drawn a little wide.
  ///
  /// Outside it, no road is reported at all — somebody logging a sighting from
  /// their lounge in Pretoria should not be told they are on the H1-3, and the
  /// rules are clear that only what happens inside the gate counts.
  static const double _minLat = -25.60;
  static const double _maxLat = -22.20;
  static const double _minLon = 30.80;
  static const double _maxLon = 32.10;

  static bool inKruger(double lat, double lon) =>
      lat >= _minLat && lat <= _maxLat && lon >= _minLon && lon <= _maxLon;

  /// The nearest road, or null when there is not one close enough to be sure.
  KrugerRoad? nearest(double lat, double lon) {
    if (!inKruger(lat, lon)) {
      return null;
    }

    KrugerRoad? best;
    double bestMetres = double.infinity;

    for (final KrugerRoad road in roads) {
      for (final List<double> point in road.points) {
        final double d = _metres(lat, lon, point[0], point[1]);
        if (d < bestMetres) {
          bestMetres = d;
          best = road;
          // Nothing will beat this and the loop is over ten thousand points.
          if (d < 25) {
            return best;
          }
        }
      }
    }

    return bestMetres <= maxMetres ? best : null;
  }
}

/// Equirectangular approximation. At Kruger's latitude the error over a few
/// hundred metres is centimetres, and it is far cheaper than haversine when it
/// runs across eleven thousand points per lookup.
double _metres(double lat1, double lon1, double lat2, double lon2) {
  const double metresPerDegree = 111320;
  final double dLat = (lat1 - lat2) * metresPerDegree;
  final double dLon =
      (lon1 - lon2) * metresPerDegree * math.cos(lat1 * math.pi / 180);
  return math.sqrt(dLat * dLat + dLon * dLon);
}
