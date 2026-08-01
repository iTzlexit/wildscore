import 'conservation_status.dart';
import 'park_region.dart';
import 'rarity_tier.dart';
import 'species_category.dart';
import 'species_tag.dart';

/// One animal in the Codex.
///
/// Immutable, and deliberately free of any Flutter import — this is the shape
/// of the data, not the shape of the screen. The backend in Phase 4 will speak
/// this same model.
class Species {
  const Species({
    required this.id,
    required this.dexNumber,
    required this.commonName,
    required this.scientificName,
    required this.afrikaansName,
    required this.category,
    required this.rarityTier,
    required this.tags,
    required this.isSensitive,
    required this.description,
    required this.habitat,
    required this.bestTimeToSpot,
    required this.parkRegions,
    required this.conservationStatus,
    this.discovered = true,
  });

  /// Parses one entry of `assets/data/species.json`.
  ///
  /// Throws [FormatException] with the offending species id when an enum value
  /// in the JSON does not match the Dart enum. You will typo one of these
  /// eventually; the message tells you which.
  factory Species.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String;

    return Species(
      id: id,
      dexNumber: json['dexNumber'] as int,
      commonName: json['commonName'] as String,
      scientificName: json['scientificName'] as String,
      afrikaansName: json['afrikaansName'] as String,
      category: _byName(
        SpeciesCategory.values,
        json['category'] as String,
        'category',
        id,
      ),
      rarityTier: _byName(
        RarityTier.values,
        json['rarityTier'] as String,
        'rarityTier',
        id,
      ),
      tags: (json['tags'] as List<dynamic>)
          .map(
            (dynamic tag) =>
                _byName(SpeciesTag.values, tag as String, 'tag', id),
          )
          .toList(),
      isSensitive: json['isSensitive'] as bool,
      description: json['description'] as String,
      habitat: json['habitat'] as String,
      bestTimeToSpot: json['bestTimeToSpot'] as String,
      parkRegions: (json['parkRegions'] as List<dynamic>)
          .map(
            (dynamic region) =>
                _byName(ParkRegion.values, region as String, 'parkRegion', id),
          )
          .toList(),
      conservationStatus: _byName(
        ConservationStatus.values,
        json['conservationStatus'] as String,
        'conservationStatus',
        id,
      ),
    );
  }

  final String id;

  /// Permanent catalogue number, as on a Pokédex entry. Assigned once —
  /// mammals, then birds, then reptiles, alphabetical within each — and never
  /// reshuffled, because a dex number is an identity. New species are appended.
  final int dexNumber;

  final String commonName;
  final String scientificName;
  final String afrikaansName;
  final SpeciesCategory category;
  final RarityTier rarityTier;
  final List<SpeciesTag> tags;

  /// Rhino and pangolin. Sightings of these species must never expose location
  /// anywhere in the app — see docs/SPEC.md. Enforced from Phase 3.
  final bool isSensitive;

  final String description;
  final String habitat;
  final String bestTimeToSpot;
  final List<ParkRegion> parkRegions;
  final ConservationStatus conservationStatus;

  /// Whether the player has logged a verified sighting.
  ///
  /// Always true in Phase 1 — the Codex is a field guide before it is a
  /// collection. Phase 2 sets this from the local sightings table and the UI
  /// already renders locked species as silhouettes.
  final bool discovered;

  int get points => rarityTier.points;

  /// Photographs live at `assets/species/<id>.jpg`. Missing files fall back to
  /// a generated placeholder, so the app runs before any art exists.
  String get imageAsset => 'assets/species/$id.jpg';

  /// PhyloPic silhouette for the undiscovered state, black on transparent.
  /// Missing files fall back to the darkened photograph.
  String get silhouetteAsset => 'assets/silhouettes/$id.png';

  bool get isBigFive => tags.contains(SpeciesTag.bigFive);
  bool get isNocturnal => tags.contains(SpeciesTag.nocturnal);
  bool get occursParkWide => parkRegions.length == ParkRegion.values.length;

  /// Zero-padded for display: `001`, `042`, `071`.
  String get dexLabel => dexNumber.toString().padLeft(3, '0');

  Species copyWith({bool? discovered}) {
    return Species(
      id: id,
      dexNumber: dexNumber,
      commonName: commonName,
      scientificName: scientificName,
      afrikaansName: afrikaansName,
      category: category,
      rarityTier: rarityTier,
      tags: tags,
      isSensitive: isSensitive,
      description: description,
      habitat: habitat,
      bestTimeToSpot: bestTimeToSpot,
      parkRegions: parkRegions,
      conservationStatus: conservationStatus,
      discovered: discovered ?? this.discovered,
    );
  }

  /// Free-text match across every name a visitor might type, including the
  /// Afrikaans one — plenty of your users grew up calling it a rooibok.
  bool matchesQuery(String query) {
    if (query.isEmpty) {
      return true;
    }
    final String needle = query.toLowerCase().trim();
    return commonName.toLowerCase().contains(needle) ||
        scientificName.toLowerCase().contains(needle) ||
        afrikaansName.toLowerCase().contains(needle);
  }

  static T _byName<T extends Enum>(
    List<T> values,
    String name,
    String field,
    String speciesId,
  ) {
    for (final T value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw FormatException(
      'Unknown $field "$name" on species "$speciesId". '
      'Valid values: ${values.map((T v) => v.name).join(', ')}',
    );
  }
}
