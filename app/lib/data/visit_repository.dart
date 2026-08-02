import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/visit.dart';

/// Every day this phone has played, newest first.
///
/// This replaces the running lifetime total that used to be stored on its own.
/// A stored total drifts: every undo, every restart, every future edit is
/// another place it can be wrong, and once it is wrong there is nothing to
/// check it against. **Deriving the total from the visits removes the entire
/// class of bug** — the history is the truth, the number is a view of it.
///
/// It also happens to be what the user wants to look at anyway.
///
/// `shared_preferences` is the wrong home for this once a season's worth of
/// days accumulates; it rewrites the whole list on every append. That is fine
/// for the tens of records a trip produces, and Phase 2 moves it to sqflite
/// alongside real sightings.
class VisitRepository {
  const VisitRepository();

  static const String _key = 'visit_history_v1';

  Future<List<Visit>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) {
      return const <Visit>[];
    }
    try {
      return <Visit>[
        for (final dynamic v in json.decode(raw) as List<dynamic>)
          Visit.fromJson(v as Map<String, dynamic>),
      ]..sort((Visit a, Visit b) => b.endedAt.compareTo(a.endedAt));
    } on FormatException {
      // Corrupt history is not worth wedging a launch over, but it *is* worth
      // keeping: leave the bad record in place rather than deleting it, so a
      // future build has a chance of recovering the days.
      return const <Visit>[];
    }
  }

  /// Returns the new history, newest first.
  Future<List<Visit>> add(Visit visit) async {
    final List<Visit> all = <Visit>[visit, ...await load()];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(<Map<String, dynamic>>[
        for (final Visit v in all) v.toJson(),
      ]),
    );
    return all;
  }

  /// Drops one drive, matched on when it ended.
  ///
  /// Because the lifetime total is derived, deleting a drive also removes its
  /// points. That is the honest behaviour — a total that survived the deletion
  /// of the day that produced it would be a number with no evidence behind it —
  /// but it does mean the confirmation has to say so out loud.
  Future<List<Visit>> remove(Visit visit) async {
    final List<Visit> all = <Visit>[
      for (final Visit v in await load())
        if (v.endedAt != visit.endedAt) v,
    ];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(<Map<String, dynamic>>[
        for (final Visit v in all) v.toJson(),
      ]),
    );
    return all;
  }

  /// Overwrites the history wholesale. Used by a restore, which has already
  /// merged; nothing else should call it.
  Future<void> replaceAll(List<Visit> all) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(<Map<String, dynamic>>[
        for (final Visit v in all) v.toJson(),
      ]),
    );
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
