import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/species.dart';

/// Loads the species catalogue from the bundled JSON asset.
///
/// The whole catalogue is a few hundred kilobytes and read once at startup, so
/// there is no database here and no need for one. Phase 2 adds sqflite for
/// *sightings* — user-generated data that grows and needs querying. Reference
/// data that ships with the binary does not belong in a database.
class SpeciesRepository {
  const SpeciesRepository();

  static const String _assetPath = 'assets/data/species.json';

  Future<List<Species>> loadAll() async {
    final String raw = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> decoded =
        json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> entries = decoded['species'] as List<dynamic>;

    final List<Species> species = entries
        .map((dynamic entry) => Species.fromJson(entry as Map<String, dynamic>))
        .toList();

    // Dex order, like a field guide or a Pokédex. Rarity is still obvious at a
    // glance because it drives the card's colour and frame — it does not need
    // to drive the ordering as well.
    species.sort((Species a, Species b) => a.dexNumber.compareTo(b.dexNumber));

    return species;
  }
}
