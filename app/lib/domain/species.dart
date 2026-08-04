import 'conservation_status.dart';
import 'park_region.dart';
import 'rarity_tier.dart';
import 'species_category.dart';
import 'species_tag.dart';

/// How often a wild-card bonus comes back.
enum WildCardScope { day, trip }

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
    this.photoVerified = true,
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
      // Absent means trusted. Only the handful we know to be wrong carry the
      // flag, so a new species is not silently hidden by a forgotten field.
      photoVerified: json['photoVerified'] as bool? ?? true,
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

  /// Whether the photograph on file is confidently *this* species.
  ///
  /// False for the small cats, where the sourcing API cannot reliably tell a
  /// caracal from a serval or an African wildcat from someone's tabby. A
  /// misidentified photograph in a field guide is worse than no photograph:
  /// somebody will learn the wrong animal from it and claim the wrong points.
  /// Those fall back to a silhouette until a photograph is chosen by eye.
  final bool photoVerified;

  /// What a claim is normally worth. The wild-card bonus is applied on top by
  /// whoever creates the claim — see [wildCardBonus].
  int get points => rarityTier.points;

  /// What the *first* sighting of a wild-card species pays.
  ///
  /// A bonus, not a replacement, and not a lock. The first zebra of the morning
  /// is worth 50; the second is worth 5 like any other zebra, until the day's
  /// chances run out. Enough to matter on the first sighting and nowhere near
  /// enough to decide a trip — half a Notable, a twentieth of a leopard.
  static const int wildCardBonus = 50;

  bool get isWildCard => tags.contains(SpeciesTag.wildCard);

  /// How many times this can be claimed in a day.
  ///
  /// Daily wild cards get three, because "the first one is worth more" says
  /// nothing at all if there is only ever one. Impala does not: it is the most
  /// common animal in the park and three impala a day is three shouts about
  /// impala. Its bonus is trip-scoped anyway, so day two's single impala is
  /// already an ordinary five-point impala.
  int? get chancesPerDay => isWildCard && wildCardScope == WildCardScope.day
      ? 3
      : rarityTier.chancesPerDay;

  /// Whether the bonus resets daily or only once a trip.
  ///
  /// Impala is the trip one: it is *the* arrival animal, and paying out every
  /// morning would make it a tax on whoever wakes up first. Zebra, giraffe and
  /// wildebeest reset daily — "there's one!" is a fresh moment each morning.
  WildCardScope get wildCardScope =>
      id == 'impala' ? WildCardScope.trip : WildCardScope.day;

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
      photoVerified: photoVerified,
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
