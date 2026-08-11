import 'conservation_status.dart';
import 'house_rules.dart';
import 'park_region.dart';
import 'population.dart';
import 'rarity_tier.dart';
import 'species_category.dart';
import 'sighting_context.dart';
import 'species_tag.dart';

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
    required this.multiplier,
  });

  factory SpeciesVariant.fromJson(Map<String, dynamic> json) => SpeciesVariant(
    label: json['label'] as String,
    question: json['question'] as String,
    multiplier: (json['multiplier'] as num).toDouble(),
  );

  /// Shown on the tag: "Lion · MALE".
  final String label;

  /// Asked once, right after the animal is picked. Phrased so that yes is the
  /// interesting answer — nobody should have to think about it at the moment
  /// somebody is shouting from the back seat.
  final String question;

  /// Half again, rather than a flat sixty.
  ///
  /// It **was** a flat sixty, which was +150% of a forty-point lion and would
  /// have quietly become +27% the moment the scale moved. A bonus expressed as
  /// a number has to be re-tuned every time anything else changes; one
  /// expressed as a proportion never does. Same lesson as the extras.
  final double multiplier;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'question': question,
    'multiplier': multiplier,
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
    required this.catalogueTier,
    required this.tags,
    required this.isSensitive,
    required this.description,
    required this.habitat,
    required this.bestTimeToSpot,
    required this.parkRegions,
    required this.conservationStatus,
    this.photoVerified = true,
    this.discovered = true,
    this.variants = const <SpeciesVariant>[],
    this.population,
    this.chancesPerDay,
    this.housePoints,
    this.houseCap,
    this.houseCapSet = false,
    int? points,
  }) : _points = points;

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
      catalogueTier: _byName(
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
      variants: <SpeciesVariant>[
        for (final dynamic v
            in (json['variants'] as List<dynamic>? ?? const <dynamic>[]))
          SpeciesVariant.fromJson(v as Map<String, dynamic>),
      ],
      population: json['population'] == null
          ? null
          : Population.fromJson(json['population']! as Map<String, dynamic>),
      points: json['points'] as int?,
      chancesPerDay: json['chancesPerDay'] as int?,
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

  /// The band **we** put it in. Use [rarityTier] for what to show.
  final RarityTier catalogueTier;

  /// The band it is actually in, which follows the price.
  ///
  /// Alex's rule: *"if that animal's points get changed by the user then that
  /// animal gets placed into that category as well."* Obviously right once you
  /// say it out loud — a car that decides sable is worth 700 has decided sable
  /// is a Ghost, and a tile reading "Cryptic · 700" beside a Ghost on 600 is
  /// the app arguing with them.
  ///
  /// It moves the filters and the collections with it, which is the point.
  RarityTier get rarityTier =>
      housePoints == null ? catalogueTier : RarityTier.forPoints(housePoints!);

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
  final List<SpeciesVariant> variants;

  /// Roughly how many are in the park. Null where no figure has been sourced,
  /// which is most of the birds and everything smaller than a mongoose.
  final Population? population;

  /// What a claim is normally worth.
  ///
  /// **Per species, not per tier.** Every animal in a tier used to score the
  /// same, which said a leopard and a wild dog are equally hard to find and
  /// nobody believed it. The number comes from Alex ordering all 190 by hand;
  /// the tier is now the *band* it sits in rather than the value itself.
  ///
  /// Falls back to the tier for anything unranked, so a species added tomorrow
  /// scores something sensible instead of nothing.
  final int? _points;

  /// What this car decided it is worth, overriding the catalogue.
  ///
  /// Null for almost everything, always, because it only holds what somebody
  /// actually changed. Kept **beside** the catalogue value rather than
  /// replacing it, so the card can say "you moved this" and offer to put it
  /// back — an edit you cannot see or undo is a trap.
  final int? housePoints;

  /// This car's own limit on how often it can be claimed.
  ///
  /// Distinguished from "no limit" by [houseCapSet], because *removing* a cap
  /// is itself an opinion — a car that wants unlimited impala has to be able
  /// to say so, and a null here would be indistinguishable from never having
  /// asked.
  final SpeciesCap? houseCap;
  final bool houseCapSet;

  bool get isHouseRule => housePoints != null || houseCapSet;

  /// One species with a car's own rules folded in.
  Species underHouseRules({
    int? points,
    SpeciesCap? cap,
    bool capChanged = false,
  }) {
    if (points == null && !capChanged) {
      return this;
    }
    return copyWith(
      housePoints: points,
      houseCap: cap,
      houseCapSet: capChanged,
    );
  }

  /// The catalogue's own limit, whatever the car has since decided.
  SpeciesCap? get catalogueCap => chancesPerDay == null
      ? null
      : SpeciesCap(times: chancesPerDay!, scope: CapScope.day);

  /// The limit actually in force.
  SpeciesCap? get cap => houseCapSet ? houseCap : catalogueCap;

  /// The catalogue's own figure, whatever the player has since decided.
  int get cataloguePoints => _points ?? rarityTier.points;

  int get points => housePoints ?? cataloguePoints;

  /// What one sighting of this animal is worth, all in.
  ///
  /// **The only place the scoring formula exists.** It used to be a ternary at
  /// the call site, which was fine with one modifier and would not have stayed
  /// fine with three.
  ///
  /// Every modifier is a proportion. That is the whole point: the male lion
  /// used to be a flat +60 and the scale moved out from under it twice. A male
  /// lion is 120 × 1.5 = 180; the same lion at a jam is 144.
  ///
  /// **Two mechanics were removed on 11 August 2026, on Alex's call.**
  ///
  /// *First-spot bonuses* — the wild cards — paid a fixed sum for the first
  /// impala of the trip or the first lion of the day. They were a second
  /// scoring system bolted to the side of this one: a number that was not on
  /// the animal's card, could not be edited by a car that prices its own
  /// animals, and needed the whole trip's history loaded to work out what a
  /// sighting was worth.
  ///
  /// *The elephant and buffalo taper* went the same way and for the same
  /// reason. "This animal is worth less the more you see it" is a rule nobody
  /// asked for and everybody had to be told, and a car that thinks the
  /// fourteenth elephant is worth less can simply price elephant lower.
  ///
  /// What survives is what a car actually argues about: the animal's price,
  /// who else was there, and what it was doing.
  int scoreFor({
    Set<String> variantsApplied = const <String>{},
    SightingContext context = SightingContext.normal,
    Set<SightingExtra> extras = const <SightingExtra>{},
    double? jamMultiplier,
  }) {
    double total = points.toDouble();
    for (final SpeciesVariant v in variants) {
      if (variantsApplied.contains(v.label)) {
        total *= v.multiplier;
      }
    }
    for (final SightingExtra e in extras) {
      total *= e.multiplier;
    }
    return context.applyTo(total.round(), jamMultiplier: jamMultiplier);
  }

  /// Tagged nocturnal, but out in daylight often enough that a bonus for it
  /// would be free points rather than a story.
  ///
  /// A water thick-knee stands on a riverbank in full sun all afternoon; scrub
  /// hare are up at dusk on every evening drive. Both are in the Night shift
  /// collection because that is where a visitor looks for them, and neither is
  /// a remarkable daytime sighting.
  static const Set<String> _dayActiveAnyway = <String>{
    'water-thick-knee',
    'scrub-hare',
  };

  /// Whose calves are unmistakable from a car, and whose herds you stop for.
  ///
  /// The question used to be asked of every mammal, which meant a steenbok
  /// lamb — a guess at fifty metres — scored the same bonus as an elephant
  /// calf in the middle of a breeding herd.
  static const Set<String> _youngWorthAsking = <String>{
    'african-elephant',
    'cape-buffalo',
    'lion',
    'leopard',
    'giraffe',
    'plains-zebra',
    'vervet-monkey',
    'samango-monkey',
    'chacma-baboon',
  };

  /// The camp animals: scarce out in the park, and living off the bins at
  /// Skukuza. One number cannot be both, so the sighting says which.
  static const Set<String> _campDwellers = <String>{
    'african-wildcat',
    'honey-badger',
    'lesser-bushbaby',
    'thick-tailed-bushbaby',
    'large-spotted-genet',
    'african-civet',
    'cape-porcupine',
    'scrub-hare',
    'chacma-baboon',
    'vervet-monkey',
    'tree-squirrel',
  };

  /// Which "what was it doing" questions make sense for this animal.
  ///
  /// A baby is only asked about for mammals, a kill only for predators, and
  /// daylight only for the night shift. Asking whether a puff adder was on a
  /// kill is the kind of question that makes people stop trusting the rest of
  /// them.
  Set<SightingExtra> get possibleExtras => <SightingExtra>{
    if (_youngWorthAsking.contains(id)) SightingExtra.withYoung,
    if (_campDwellers.contains(id)) SightingExtra.inCamp,
    if (tags.contains(SpeciesTag.predator)) SightingExtra.onAKill,
    // Mammals and birds. A mating pair of crocodiles is a thing nobody is
    // going to identify from a car, and a puff adder even less so.
    if (category == SpeciesCategory.mammal || category == SpeciesCategory.bird)
      SightingExtra.matingPair,
    if (isNocturnal && !_dayActiveAnyway.contains(id)) SightingExtra.inDaylight,
  };

  /// Whether to ask who else was there.
  ///
  /// **Not on everything.** A prompt after every claim is a tax on the fun part
  /// of the game, and for an impala the answer changes nothing anybody cares
  /// about. Jams only form around animals worth stopping for, so the question
  /// is only asked about those — the same bar the sightings feed uses, which is
  /// Rare and up plus the Big Five.
  ///
  /// The bar is the bottom of the Rare band rather than a typed constant. It
  /// used to be `rarityTier.points >= 100`, which quietly caught every Notable
  /// the moment a tier stopped being one number — including the klipspringer,
  /// which nobody has ever formed a jam around.
  bool get crowdMatters =>
      points >= RarityTier.scarce.low || tags.contains(SpeciesTag.bigFive);

  /// How many times this can be claimed in a day. **Null is unlimited, and
  /// almost everything is null.**
  ///
  /// Impala at two, vervet monkey at four, and every bird at one. A car can
  /// change or lift any of them from House rules. It used to be tier-wide — four a day for anything Common
  /// or Frequent — which punished the wrong thing entirely: a real morning's
  /// zebra sightings ran out, and so did elephant, in Kruger.
  ///
  /// The cap exists so nobody taps every impala from Malelane to Satara. It
  /// was never meant to ration a good day, and Alex is right that a car
  /// counting a hundred giraffe is nobody's business but theirs.
  final int? chancesPerDay;

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

  /// [points] is how a player's own scoring reaches the rest of the app: the
  /// repository applies overrides at load, so every screen, the claim sheet and
  /// the feed all see the edited number without knowing anything about it.
  /// This animal at a price the player just chose, or back at ours when null.
  ///
  /// For a screen that is already open and holding its own copy: the catalogue
  /// is rebuilt above it, but a pushed route keeps the species it was pushed
  /// with, so without this an edit only shows up once you go back.
  Species withHousePoints(int? points) =>
      copyWith(housePoints: points, clearHousePoints: points == null);

  Species copyWith({
    bool? discovered,
    int? housePoints,
    SpeciesCap? houseCap,
    bool? houseCapSet,

    /// Puts the animal back on the catalogue's number. Needed because a null
    /// `housePoints` means "leave it alone" everywhere else.
    bool clearHousePoints = false,
  }) {
    return Species(
      id: id,
      dexNumber: dexNumber,
      commonName: commonName,
      scientificName: scientificName,
      afrikaansName: afrikaansName,
      category: category,
      catalogueTier: catalogueTier,
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
      variants: variants,
      population: population,
      points: _points,
      chancesPerDay: chancesPerDay,
      housePoints: clearHousePoints ? null : (housePoints ?? this.housePoints),
      houseCap: houseCap ?? this.houseCap,
      houseCapSet: houseCapSet ?? this.houseCapSet,
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
