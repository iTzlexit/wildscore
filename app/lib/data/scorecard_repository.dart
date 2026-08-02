import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/scorecard.dart';

/// Stores the day's game on the device.
///
/// Entirely local and entirely offline, which is the point — most of Kruger has
/// no signal, and the whole game must work with the phone in aeroplane mode for
/// days. Submitting to a leaderboard is a separate, later act back at camp.
class ScorecardRepository {
  const ScorecardRepository();

  static const String _key = 'active_scorecard_v1';

  Future<Scorecard?> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }
    try {
      return Scorecard.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or from an older build. Losing a scorecard is bad, but wedging
      // the app on a launch it can never complete is worse.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> save(Scorecard card) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(card.toJson()));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
