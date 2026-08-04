import 'package:geolocator/geolocator.dart';

import '../domain/kruger_roads.dart';
import '../domain/species.dart';
import 'road_repository.dart';

/// Works out which road a sighting happened on.
///
/// GPS works with no cell signal, which is why this is possible at all in a
/// park that has none. Everything here runs on the phone: the fix comes from
/// the satellites, the road comes from a bundled file, and no coordinate is
/// ever stored or sent anywhere.
///
/// **Rhino and pangolin never get a road.** The check is here, at the source,
/// rather than in the screens that display it — a rule enforced once cannot be
/// forgotten by the next feature that reads a claim. See docs/MAPS.md.
class LocationService {
  const LocationService({this.roads = const RoadRepository()});

  final RoadRepository roads;

  /// Fixes older than this are somebody else's morning.
  static const Duration _maxAge = Duration(minutes: 5);

  /// A best-effort road label, or null.
  ///
  /// Null covers every uncertainty: permission refused, location switched off,
  /// no fix in time, outside the park, too far from a known road, or a species
  /// whose location must never be recorded. Callers do not need to distinguish
  /// them — there is nothing useful to say about any of them beyond leaving the
  /// field empty.
  Future<String?> roadFor(Species species) async {
    if (species.isSensitive) {
      return null;
    }

    final Position? position = await _position();
    if (position == null) {
      return null;
    }

    final KrugerRoads network = await roads.load();
    return network.nearest(position.latitude, position.longitude)?.label;
  }

  Future<Position?> _position() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // A recent fix is worth far more than a fresh one here: the phone has
      // been in a moving car with a clear sky and almost certainly has one, and
      // waiting on the satellites while an animal is in view is exactly the
      // wrong trade.
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null && DateTime.now().difference(last.timestamp) < _maxAge) {
        return last;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          // Naming a road needs tens of metres, not centimetres, and a long
          // wait costs the sighting.
          timeLimit: Duration(seconds: 6),
        ),
      );
    } on Object {
      // Every failure here is the same failure as far as the app is concerned:
      // no road on this claim. Nothing about scoring depends on it.
      return null;
    }
  }
}
