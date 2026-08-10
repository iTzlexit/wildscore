import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/house_rules.dart';
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

  /// [housePoints] overrides the catalogue's values, keyed by species id.
  ///
  /// **Applied here rather than at every call site**, which is the whole
  /// reason it is cheap. The catalogue is read once at startup, so folding a
  /// player's own scoring in at load means the dex tiles, the claim sheet, the
  /// standings and the sightings feed all see the edited number without a
  /// single one of them knowing the feature exists.
  ///
  /// Past drives are unaffected: a claim stores the points it scored at the
  /// time, so a table edited in March cannot rewrite February.
  Future<List<Species>> loadAll({HouseRules rules = HouseRules.none}) async {
    final String raw = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> decoded =
        json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> entries = decoded['species'] as List<dynamic>;

    final List<Species> species = entries
        .map((dynamic entry) => Species.fromJson(entry as Map<String, dynamic>))
        .map(
          (Species s) => s.underHouseRules(
            points: rules.points[s.id],
            cap: rules.caps[s.id],
            capChanged: rules.caps.containsKey(s.id),
          ),
        )
        .toList();

    // Dex order, like a field guide or a Pokédex. Rarity is still obvious at a
    // glance because it drives the card's colour and frame — it does not need
    // to drive the ordering as well.
    species.sort((Species a, Species b) => a.dexNumber.compareTo(b.dexNumber));

    return species;
  }
}
