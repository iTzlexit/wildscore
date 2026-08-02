import 'package:shared_preferences/shared_preferences.dart';

/// The account holder's permanent record.
///
/// A day's scorecard is thrown away when the day ends — that is the point of a
/// day. But if *your* claims vanished with it, the app would have no memory,
/// and the whole product is built on the opposite promise: your sightings live
/// here so you can visit them when you miss the park.
///
/// So every claim the owner makes during a game is written twice: to the day's
/// scorecard, and to this. Guests' claims are not — a guest is not an account
/// on this phone, and crediting their leopard here would make the record false.
///
/// Points are stored as a running total rather than recomputed from a claim
/// history, because that history does not survive the day. When Phase 2 gives
/// sightings a real table this becomes a derived value and the stored total
/// becomes a cache.
class LifetimeRepository {
  const LifetimeRepository();

  static const String _pointsKey = 'lifetime_points_v1';

  Future<int> loadPoints() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  /// Returns the new total, so the caller can hold it in widget state without
  /// a second read.
  Future<int> addPoints(int points) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int next = (prefs.getInt(_pointsKey) ?? 0) + points;
    await prefs.setInt(_pointsKey, next);
    return next;
  }

  Future<void> setPoints(int points) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, points);
  }
}
