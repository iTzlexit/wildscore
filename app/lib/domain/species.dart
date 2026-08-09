import 'conservation_status.dart';
import 'park_region.dart';
import 'population.dart';
import 'rarity_tier.dart';
import 'species_category.dart';
import 'sighting_context.dart';
import 'species_tag.dart';

/// How often a wild-card bonus comes back.
enum WildCardScope { day, trip }

/// A version of an animal that is worth more than the animal.
///
/// One species has one at the moment and it is the obvious one: **a male
/// lion**. A lioness is a lion sighting; a black-maned male standing in the
/// road is the photograph on the front of every Kruger brochure, and scoring
/// them identically is the kind of thing a car will argue about for an hour.
///
/// Deliberately a bonus on top rather than a second dex entry. A separate
/// "Male Lion" species would double the animal in the collection, in the
/// filters and in every count, to record one fact about one sighting.
class SpeciesVariant {
  const SpeciesVariant({
    required this.label,
    required this.question,
    required this.bonus,
  });

  factory SpeciesVariant.fromJson(Map<String, dynamic> json) => SpeciesVariant(
    label: json['label'] as String,
    question: json['question'] as String,
    bonus: json['bonus'] as int,
  );

  /// Shown on the tag: "Lion · MALE".
  final String label;

  /// Asked once, right after the animal is picked. Phrased so that yes is the
  /// interesting answer — nobody should have to think about it at the moment
  /// somebody is shouting from the back seat.
  final String question;

  /// Added to the claim. Sixty on a forty-point lion, so a male is worth 100 —
  /// the same as a honey badger, and about right for how a car reacts to one.
  final int bonus;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'question': question,
    'bonus': bonus,
  };
}

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
    this.variant,
    this.population,
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
      variant: json['variant'] == null
          ? null
          : SpeciesVariant.fromJson(json['variant']! as Map<String, dynamic>),
      population: json['population'] == null
          ? null
          : Population.fromJson(json['population']! as Map<String, dynamic>),
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

  /// A version of this animal worth more than the animal — a male lion. Null
  /// for almost everything.
  final SpeciesVariant? variant;

  /// Roughly how many are in the park. Null where no figure has been sourced,
  /// which is most of the birds and everything smaller than a mongoose.
  final Population? population;

  /// What a claim is normally worth. The wild-card bonus, the variant bonus and
  /// the crowd multiplier are all applied on top by whoever creates the claim —
  /// see [wildCardBonus], [SpeciesVariant] and [SightingContext].
  int get points => rarityTier.points;

  /// What one sighting of this animal is worth, all in.
  ///
  /// **The only place the scoring formula exists.** It used to be a ternary at
  /// the call site, which was fine with one modifier and would not have stayed
  /// fine with three.
  ///
  /// Order matters and is deliberate: the wild-card bonus *replaces* the tier
  /// value rather than adding to it (the first zebra is worth 50, not 55), the
  /// variant adds on top, and the crowd multiplier applies to the lot. So a
  /// male lion found on an empty road is (40 + 60) × 2 = 200, and the same lion
  /// at a jam of eleven cars is 50.
  int scoreFor({
    bool wildCardBonusEarned = false,
    bool variantApplied = false,
    SightingContext context = SightingContext.normal,
    Set<SightingExtra> extras = const <SightingExtra>{},
  }) {
    final int base = wildCardBonusEarned ? wildCardBonus : points;
    double total =
        (base + (variantApplied && variant != null ? variant!.bonus : 0))
            .toDouble();
    for (final SightingExtra e in extras) {
      total *= e.multiplier;
    }
    return context.applyTo(total.round());
  }

  /// Which "what was it doing" questions make sense for this animal.
  ///
  /// A baby is only asked about for mammals, and a kill only for predators.
  /// Asking whether a puff adder was on a kill is the kind of question that
  /// makes people stop trusting the rest of them.
  Set<SightingExtra> get possibleExtras => <SightingExtra>{
    if (category == SpeciesCategory.mammal) SightingExtra.withYoung,
    if (tags.contains(SpeciesTag.predator)) SightingExtra.onAKill,
  };

  /// Whether to ask who else was there.
  ///
  /// **Not on everything.** A prompt after every claim is a tax on the fun part
  /// of the game, and for an impala the answer changes nothing anybody cares
  /// about. Jams only form around animals worth stopping for, so the question
  /// is only asked about those — the same bar the sightings feed uses, which is
  /// Rare and up plus the Big Five.
  bool get crowdMatters =>
      rarityTier.points >= 100 || tags.contains(SpeciesTag.bigFive);

  /// What the *first* sighting of a wild-card species pays.
  ///
  /// A bonus, not a replacement, and not a lock. The first zebra of the morning
  /// is worth 40; the second is worth 5 like any other zebra, until the day's
  /// chances run out. Enough to matter on the first sighting and nowhere near
  /// enough to decide a trip.
  static const int wildCardBonus = 40;

  bool get isWildCard => tags.contains(SpeciesTag.wildCard);

  /// How many times this can be claimed in a day.
  ///
  /// Daily wild cards get three, because "the first one is worth more" says
  /// nothing at all if there is only ever one. Impala does not: it is the most
  /// common animal in the park and three impala a day is three shouts about
  /// impala. Its bonus is trip-scoped anyway, so day two's single impala is
  /// already an ordinary five-point impala.
  int? get chancesPerDay {
    // Impala is its own case and always has been. It is the commonest animal in
    // the park by a distance, so the tier's four would mean four shouts about
    // impala — two is the point being made: the first one is the arrival
    // moment and pays a bonus, the second is an ordinary impala, and then it is
    // done for the day.
    if (id == 'impala') {
      return 2;
    }
    return isWildCard && wildCardScope == WildCardScope.day
        ? 4
        : rarityTier.chancesPerDay;
  }

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
      // Both were being dropped. Only a test calls this today, so nothing was
      // visibly broken — but a copy of a lion that has lost its male-lion
      // bonus is a scoring bug lying in wait for whoever uses it next.
      variant: variant,
      population: population,
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
