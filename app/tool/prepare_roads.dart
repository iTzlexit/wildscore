// Turns a raw Overpass dump of Kruger's roads into the small dataset the app
// bundles.
//
//   dart run tool/prepare_roads.dart <raw.json>
//
// The raw dump is ~6 MB of JSON with full node geometry. The app needs far
// less: a road reference, a name, and enough points to work out which road you
// are nearest to. Simplifying to roughly 200 m between points keeps a road
// identifiable while dropping most of the file.
//
// OpenStreetMap data is ODbL. Attribution is required and lives on the credits
// screen. Not part of the app build.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Points closer together than this add nothing — Kruger roads are long and
/// gently curved, and a sighting only needs to know *which* road.
const double _simplifyMetres = 200;

/// Coordinates are stored to five decimal places, which is about a metre. Any
/// more is storing GPS noise.
const int _precision = 5;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/prepare_roads.dart <raw.json>');
    exitCode = 64;
    return;
  }

  final Map<String, dynamic> raw =
      json.decode(File(args.first).readAsStringSync()) as Map<String, dynamic>;
  final List<dynamic> elements = raw['elements'] as List<dynamic>;

  // Group by reference: OSM splits one road into dozens of ways, and "S100" is
  // one road to a person no matter how many segments it is to a database.
  final Map<String, _Road> byRef = <String, _Road>{};

  for (final dynamic e in elements) {
    final Map<String, dynamic> way = e as Map<String, dynamic>;
    final Map<String, dynamic>? tags = way['tags'] as Map<String, dynamic>?;
    final List<dynamic>? geometry = way['geometry'] as List<dynamic>?;
    if (tags == null || geometry == null || geometry.length < 2) {
      continue;
    }

    final String? ref = (tags['ref'] as String?)?.trim();
    if (ref == null || ref.isEmpty) {
      continue;
    }
    // Kruger's internal roads are H (tar) and S (gravel) followed by digits.
    // Everything else in the box is a provincial road outside the fence.
    if (!RegExp(r'^[HS]\d').hasMatch(ref.toUpperCase())) {
      continue;
    }

    final _Road road = byRef.putIfAbsent(
      ref.toUpperCase(),
      () => _Road(ref.toUpperCase(), tags['name'] as String?),
    );
    road.name ??= tags['name'] as String?;
    road.segments.add(<List<double>>[
      for (final dynamic p in geometry)
        <double>[
          (p as Map<String, dynamic>)['lat'] as double,
          p['lon'] as double,
        ],
    ]);
  }

  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  int pointsBefore = 0;
  int pointsAfter = 0;

  for (final _Road road in byRef.values) {
    final List<List<double>> points = <List<double>>[];
    for (final List<List<double>> segment in road.segments) {
      pointsBefore += segment.length;
      points.addAll(_thin(segment));
    }
    if (points.length < 2) {
      continue;
    }
    pointsAfter += points.length;
    out.add(<String, dynamic>{
      'ref': road.ref,
      if (road.name != null && road.name != road.ref) 'name': road.name,
      'points': <List<double>>[
        for (final List<double> p in points)
          <double>[_round(p[0]), _round(p[1])],
      ],
    });
  }

  out.sort(
    (Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a['ref'] as String).compareTo(b['ref'] as String),
  );

  final File target = File('assets/data/kruger-roads.json');
  target.writeAsStringSync(
    json.encode(<String, dynamic>{
      'note':
          'Kruger road centrelines, simplified. Data © OpenStreetMap '
          'contributors, ODbL.',
      'source': 'https://www.openstreetmap.org/copyright',
      'roads': out,
    }),
  );

  stdout
    ..writeln('roads:  ${out.length}')
    ..writeln('points: $pointsBefore -> $pointsAfter')
    ..writeln(
      'size:   ${(target.lengthSync() / 1024).toStringAsFixed(0)} KB',
    );
}

/// Drops points closer than [_simplifyMetres] to the last one kept. Crude
/// compared to Douglas–Peucker and entirely good enough: the question this data
/// answers is "which road", not "draw this road".
List<List<double>> _thin(List<List<double>> points) {
  final List<List<double>> kept = <List<double>>[points.first];
  for (final List<double> p in points.skip(1)) {
    if (_metres(kept.last, p) >= _simplifyMetres) {
      kept.add(p);
    }
  }
  if (kept.length == 1) {
    kept.add(points.last);
  }
  return kept;
}

/// Equirectangular approximation. Exact enough over a few hundred metres at
/// Kruger's latitude, and far cheaper than haversine when it runs per point.
double _metres(List<double> a, List<double> b) {
  const double metresPerDegree = 111320;
  final double dLat = (a[0] - b[0]) * metresPerDegree;
  final double dLon =
      (a[1] - b[1]) * metresPerDegree * math.cos(a[0] * math.pi / 180);
  return math.sqrt(dLat * dLat + dLon * dLon);
}

double _round(double v) {
  final num factor = math.pow(10, _precision);
  return (v * factor).round() / factor;
}

class _Road {
  _Road(this.ref, this.name);

  final String ref;
  String? name;
  final List<List<List<double>>> segments = <List<List<double>>>[];
}
