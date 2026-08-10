import 'conservation_status.dart';
import 'house_rules.dart';
import 'park_region.dart';
import 'population.dart';
import 'rarity_tier.dart';
import 'species_category.dart';
import 'sighting_context.dart';
import 'species_tag.dart';

/// How often a wild-card bonus comes back.
enum WildCardScope { day, trip }

/// What the *first* one is worth, and how often that comes back.
///
/// **The mechanic Alex asked for by name.** A lion is seen on most trips, so
/// rarity scores it in the Notable band — and it is the most exciting thing
/// that happens on a game drive, every single time. Those two facts cannot
/// both live in one number. So the first lion of the day pays 400 and the
/// third pays what the card says.
///
/// Per species, because a flat bonus cannot serve both a lion and an impala.
/// It used to be one constant of 40 for everything, which was eight times an
/// impala and a third of a leopard.
///
/// Deliberately **not** on buffalo or elephant. Nobody's day is made by the
/// fourteenth elephant, and a bonus on something you pass every hour is just
/// a bigger number for the same event.
class WildCard {
  const WildCard({required this.bonus, required this.scope});

  factory WildCard.fromJson(Map<String, dynamic> json) => WildCard(
    bonus: json['bonus'] as int,
    scope: json['scope'] == 'trip' ? WildCardScope.trip : WildCardScope.day,
  );

  /// Replaces the card value on the first sighting. Never added to it — the
  /// first zebra is worth 60, not 70.
  final int bonus;

  /// Impala is the trip one: it is *the* arrival animal, and paying out every
  /// morning would make it a tax on whoever wakes up first.
  final WildCardScope scope;
}

/// Worth less once you have had a few of them today.
///
/// **Elephant and buffalo, and nothing else so far.** Both are Big Five, so
/// neither can be capped — you should always be able to claim one, and a
/// locked Big Five tile would read as a bug. But the fourteenth elephant is
/// not the event the second one was.
///
/// A cap says "stop counting". This says "keep counting, it is worth less",
/// which is both truer and less annoying. Alex's call, and the distinction is
/// a good one.
///
/// A multiplier rather than a replacement value, so it still means something
/// after the player has edited the base points.
class SpeciesDecay {
  const SpeciesDecay({required this.after, required this.multiplier});

  factory SpeciesDecay.fromJson(Map<String, dynamic> json) => SpeciesDecay(
    after: json['after'] as int,
    multiplier: (json['multiplier'] as num).toDouble(),
  );

  /// How many pay full price. The third elephant is the first cheap one.
  final int after;

  final double multiplier;

  /// What the `n`th sighting of the day is worth, `n` counting from one.
  int applyTo(int points, int n) =>
      n <= after ? points : (points * multiplier).ceil();
}

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
    this.variants = const <SpeciesVariant>[],
    this.population,
    this.wildCard,
    this.chancesPerDay,
    this.decay,
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
      variants: <SpeciesVariant>[
        for (final dynamic v
            in (json['variants'] as List<dynamic>? ?? const <dynamic>[]))
          SpeciesVariant.fromJson(v as Map<String, dynamic>),
      ],
      population: json['population'] == null
          ? null
          : Population.fromJson(json['population']! as Map<String, dynamic>),
      wildCard: json['wildCard'] == null
          ? null
          : WildCard.fromJson(json['wildCard']! as Map<String, dynamic>),
      points: json['points'] as int?,
      chancesPerDay: json['chancesPerDay'] as int?,
      decay: json['decay'] == null
          ? null
          : SpeciesDecay.fromJson(json['decay']! as Map<String, dynamic>),
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
  /// Order matters and is deliberate. The wild-card bonus **replaces** the card
  /// value rather than adding to it — the first lion of the day is worth 400,
  /// not 510 — and then everything else multiplies what is left.
  ///
  /// Every modifier is now a proportion. That is the whole point: the male lion
  /// used to be a flat +60 and the scale moved out from under it twice. A first
  /// male lion of the day, alone, is 400 × 1.5 = 600; the same lion at a jam is
  /// 480.
  int scoreFor({
    bool wildCardBonusEarned = false,
    Set<String> variantsApplied = const <String>{},
    SightingContext context = SightingContext.normal,
    Set<SightingExtra> extras = const <SightingExtra>{},
    int sightingsToday = 1,
    double? jamMultiplier,
  }) {
    double total =
        (wildCardBonusEarned && wildCard != null ? wildCard!.bonus : points)
            .toDouble();
    // Before everything else, because a decayed elephant should still get the
    // full benefit of a calf or an empty road.
    if (decay != null && !wildCardBonusEarned) {
      total = decay!.applyTo(total.round(), sightingsToday).toDouble();
    }
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

  /// Which "what was it doing" questions make sense for this animal.
  ///
  /// A baby is only asked about for mammals, a kill only for predators, and
  /// daylight only for the night shift. Asking whether a puff adder was on a
  /// kill is the kind of question that makes people stop trusting the rest of
  /// them.
  Set<SightingExtra> get possibleExtras => <SightingExtra>{
    if (category == SpeciesCategory.mammal) SightingExtra.withYoung,
    if (tags.contains(SpeciesTag.predator)) ...<SightingExtra>[
      SightingExtra.onAKill,
      SightingExtra.killInATree,
    ],
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

  /// What the first sighting pays, on the seven species that have one.
  final WildCard? wildCard;

  bool get isWildCard => wildCard != null;

  /// How many times this can be claimed in a day. **Null is unlimited, and
  /// almost everything is null.**
  ///
  /// Two species are capped: impala at two and vervet monkey at four. That is
  /// the entire list. It used to be tier-wide — four a day for anything Common
  /// or Frequent — which punished the wrong thing entirely: a real morning's
  /// zebra sightings ran out, and so did elephant, in Kruger.
  ///
  /// The cap exists so nobody taps every impala from Malelane to Satara. It
  /// was never meant to ration a good day, and Alex is right that a car
  /// counting a hundred giraffe is nobody's business but theirs.
  final int? chancesPerDay;

  /// Worth less once you have had a few. Null for almost everything.
  final SpeciesDecay? decay;

  /// Whether the bonus resets daily or only once a trip.
  WildCardScope get wildCardScope => wildCard?.scope ?? WildCardScope.day;

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
  Species copyWith({
    bool? discovered,
    int? housePoints,
    SpeciesCap? houseCap,
    bool? houseCapSet,
  }) {
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
      variants: variants,
      population: population,
      wildCard: wildCard,
      points: _points,
      chancesPerDay: chancesPerDay,
      decay: decay,
      housePoints: housePoints ?? this.housePoints,
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
