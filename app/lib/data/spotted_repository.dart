import 'package:shared_preferences/shared_preferences.dart';

/// Which species the Spotter has marked as seen.
///
/// A deliberate stand-in until Phase 2. Real sightings carry a photograph, a
/// GPS fix and a timestamp, and live in sqflite — this stores nothing but a set
/// of ids, so it can never be confused for a verified sighting and cannot score
/// points or earn a crown.
///
/// It exists because the app is unusable to demo without it: every screen reads
/// from "what have you caught", and with that permanently empty there is
/// nothing to show anyone.
class SpottedRepository {
  const SpottedRepository();

  static const String _key = 'spotted_species_v1';

  Future<Set<String>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> save(Set<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList()..sort());
  }

  /// Adds without removing. Used when a game credits the account holder — a
  /// second leopard must not un-spot the first one.
  Future<Set<String>> add(Set<String> current, String id) async {
    if (current.contains(id)) {
      return current;
    }
    final Set<String> next = <String>{...current, id};
    await save(next);
    return next;
  }

  /// Returns the new set, so callers can hold it in widget state without a
  /// second read.
  Future<Set<String>> toggle(Set<String> current, String id) async {
    final Set<String> next = <String>{...current};
    if (!next.remove(id)) {
      next.add(id);
    }
    await save(next);
    return next;
  }
}
