import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/tracker_profile.dart';

/// Stores the tracker profile on the device.
///
/// `shared_preferences` is the first third-party package in the project, and it
/// earns its place: this is a handful of bytes that must survive an app
/// restart, which is exactly what it is for. It wraps SharedPreferences on
/// Android and NSUserDefaults on iOS — the platform's own small-settings store.
///
/// Sightings will *not* live here. Those go in sqflite in Phase 2, because they
/// grow without limit and need querying.
class ProfileRepository {
  const ProfileRepository();

  static const String _key = 'tracker_profile_v1';

  Future<TrackerProfile?> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }
    try {
      return TrackerProfile.fromJson(json.decode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Corrupt or from an incompatible older build. Losing a name is
      // recoverable — the user types it again — so drop it rather than
      // wedging the app on a launch it can never complete.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> save(TrackerProfile profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(profile.toJson()));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
