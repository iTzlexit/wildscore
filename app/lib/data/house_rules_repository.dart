import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// What this car has decided an animal is worth.
///
/// **The honest answer to a question we cannot answer.** Our ranking is one
/// opinion, taken nationally, and Kruger is not one place: sable and roan are
/// the sighting of the trip in the south and a Tuesday in the far north. A car
/// based at Punda Maria for a week has a different game from a car at Berg-en-
/// Dal, and no single table can be right for both.
///
/// So the table ships as a **default**, and anybody who disagrees can move a
/// number. Alex's idea, and it is better than arguing about the table.
///
/// Stored as `{speciesId: points}` and holding **only** what differs from the
/// catalogue, so the common case is an empty map and an upgrade that revalues
/// an animal reaches everybody who never touched it.
class HouseRulesRepository {
  const HouseRulesRepository();

  static const String _key = 'wildscore.house_rules.points';

  Future<Map<String, int>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const <String, int>{};
    }
    try {
      final Map<String, dynamic> decoded =
          json.decode(raw) as Map<String, dynamic>;
      return <String, int>{
        for (final MapEntry<String, dynamic> e in decoded.entries)
          if (e.value is int) e.key: e.value as int,
      };
    } on FormatException {
      // Corrupt preferences are not worth crashing over: the catalogue's own
      // numbers are a perfectly good game.
      return const <String, int>{};
    }
  }

  Future<void> save(Map<String, int> points) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (points.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, json.encode(points));
  }
}
