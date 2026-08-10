import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/house_rules.dart';

/// Where a car's own rules live.
///
/// One key holding one JSON object, because the three things it stores are
/// changed together on one screen and read together at startup. Splitting them
/// across preferences would buy nothing and cost a migration every time
/// another rule becomes adjustable.
class HouseRulesRepository {
  const HouseRulesRepository();

  static const String _key = 'wildscore.house_rules';

  /// The first version of this stored `{speciesId: points}` under its own key
  /// and nothing else. Read once and folded into the new shape, so anybody who
  /// revalued an animal before the settings screen existed keeps their table.
  static const String _legacyPointsKey = 'wildscore.house_rules.points';

  Future<HouseRules> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        return HouseRules.fromJson(json.decode(raw) as Map<String, dynamic>);
      } on Object {
        // Corrupt preferences are not worth crashing over: the game's own
        // numbers are a perfectly good game.
        return HouseRules.none;
      }
    }

    final String? legacy = prefs.getString(_legacyPointsKey);
    if (legacy == null || legacy.isEmpty) {
      return HouseRules.none;
    }
    try {
      final Map<String, dynamic> decoded =
          json.decode(legacy) as Map<String, dynamic>;
      return HouseRules(
        points: <String, int>{
          for (final MapEntry<String, dynamic> e in decoded.entries)
            if (e.value is int) e.key: e.value as int,
        },
      );
    } on Object {
      return HouseRules.none;
    }
  }

  Future<void> save(HouseRules rules) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Both keys, always: leaving the legacy one behind would resurrect an old
    // points table the next time the new key failed to parse.
    await prefs.remove(_legacyPointsKey);
    if (rules.isDefault) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, json.encode(rules.toJson()));
  }
}
