import 'avatar_seed.dart';
import 'sighting_context.dart';
import 'trivia.dart';

/// One person in the car, for one day. Not an account — just a name.
///
/// Except for one of them. [isOwner] marks the player who is also the phone's
/// account holder, and that flag is what lets a day's claims land in a
/// permanent collection instead of evaporating when the game ends.
class Player {
  const Player({
    required this.id,
    required this.name,
    this.avatar = 0,
    this.isOwner = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    // Older saved games predate avatars. Fall back to the name-derived one so
    // a scorecard in progress does not suddenly show everyone as a lion.
    avatar: json['avatar'] as int? ?? 0,
    isOwner: json['isOwner'] as bool? ?? false,
  );

  final String id;
  final String name;

  /// Index into the avatar set. See shared/widgets/avatar_badge.dart — the
  /// domain stores a number so the artwork can change without a migration.
  final int avatar;

  final bool isOwner;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'avatar': avatar,
    'isOwner': isOwner,
  };
}

/// A single claimed sighting: who called it, what, and when.
///
/// Points are stored **on the claim**, not looked up live. A day scored months
/// ago must stay explicable — "why did I get 100 for that leopard" cannot
/// depend on what the tier is worth today.
class Claim {
  const Claim({
    required this.speciesId,
    required this.playerId,
    required this.at,
    required this.points,
    this.road,
    this.context = SightingContext.normal,
    this.variants = const <String>{},
    this.extras = const <SightingExtra>{},
  });

  factory Claim.fromJson(Map<String, dynamic> json) => Claim(
    speciesId: json['speciesId'] as String,
    playerId: json['playerId'] as String,
    at: DateTime.parse(json['at'] as String),
    points: json['points'] as int,
    road: json['road'] as String?,
    // Absent on every claim written before August 2026. Defaulting to normal
    // leaves old drives scoring exactly as they did, which matters — a
    // lifetime total that shifts when the app updates is a bug people notice
    // and cannot explain.
    context: json['context'] == null
        ? SightingContext.normal
        : SightingContext.byName(json['context']! as String),
    // 'variant: true' is how a male lion was stored before an animal could be
    // several things at once. Read as the label it meant, so old drives keep
    // their marks.
    variants: <String>{
      if (json['variant'] == true) 'Male',
      for (final dynamic v
          in (json['variants'] as List<dynamic>?) ?? const <dynamic>[])
        v as String,
    },
    extras: <SightingExtra>{
      for (final dynamic e in (json['extras'] as List<dynamic>?) ?? const [])
        if (SightingExtra.byName(e as String) case final SightingExtra found)
          found,
    },
  );

  final String speciesId;
  final String playerId;
  final DateTime at;

  /// What this was worth, worked out when it was claimed and then frozen.
  ///
  /// Every modifier is already baked in: the tier, the wild-card bonus, the
  /// variant, the crowd multiplier. Nothing recomputes it later. A tier
  /// revalued next season must not silently rewrite last winter's card.
  final int points;

  /// Who else was there. Only ever asked about animals worth stopping for —
  /// see [Species.crowdMatters].
  final SightingContext context;

  /// Which of the species' own variants applied — a male lion, a big tusker
  /// that was also in musth. Empty for almost every claim.
  final Set<String> variants;

  /// What it was doing: with young, on a kill. Empty for almost everything.
  final Set<SightingExtra> extras;

  /// Which road it was called on — `S100`, `H1-3 · Napi Road`.
  ///
  /// Null whenever the app cannot be certain: location off or refused, no fix
  /// yet, outside the park, or nowhere near a known road. Null is also the
  /// **only** value ever stored for rhino and pangolin, no matter what the GPS
  /// says — see docs/MAPS.md. Nothing downstream has to remember that rule,
  /// because the coordinate never exists in the first place.
  ///
  /// A road name, never a coordinate. "S100" is thirty kilometres of road, and
  /// that is precisely the point: enough to remember the morning by, useless
  /// to anybody hunting.
  final String? road;

  /// A mis-tap is fixable for five minutes. Long enough to correct the wrong
  /// name; short enough that nobody relitigates the morning at dinner.
  static const Duration editWindow = Duration(minutes: 5);

  bool canEditAt(DateTime now) => now.difference(at) < editWindow;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'speciesId': speciesId,
    'playerId': playerId,
    'at': at.toIso8601String(),
    'points': points,
    if (road != null) 'road': road,
    // Omitted when ordinary, so the common claim stays the size it was and a
    // backup code does not grow for saying nothing.
    if (context != SightingContext.normal) 'context': context.name,
    if (variants.isNotEmpty) 'variants': variants.toList(),
    if (extras.isNotEmpty)
      'extras': <String>[for (final SightingExtra e in extras) e.name],
  };
}

/// One day's game, for one vehicle.
class Scorecard {
  const Scorecard({
    required this.startedAt,
    required this.players,
    required this.claims,
    this.trivia = TriviaState.empty,
  });

  factory Scorecard.fromJson(Map<String, dynamic> json) => Scorecard(
    startedAt: DateTime.parse(json['startedAt'] as String),
    players: <Player>[
      for (final dynamic p in json['players'] as List<dynamic>)
        Player.fromJson(p as Map<String, dynamic>),
    ],
    claims: <Claim>[
      for (final dynamic c in json['claims'] as List<dynamic>)
        Claim.fromJson(c as Map<String, dynamic>),
    ],
    trivia: json['trivia'] == null
        ? TriviaState.empty
        : TriviaState.fromJson(json['trivia']! as Map<String, dynamic>),
  );

  /// Starts a day.
  ///
  /// [owner] is the account holder's name. Whichever entered name matches it
  /// is flagged [Player.isOwner] and keeps their permanent avatar — everyone
  /// else is dealt a fresh one for the day.
  factory Scorecard.start(List<String> names, {DateTime? now, String? owner}) {
    final DateTime at = now ?? DateTime.now();
    final String? ownerKey = owner?.trim().toLowerCase();
    final int ownerAvatar = owner == null ? -1 : AvatarSeed.forName(owner);
    final List<int> dealt = AvatarSeed.deal(
      names.length,
      at.millisecondsSinceEpoch,
      taken: ownerAvatar < 0 ? const <int>{} : <int>{ownerAvatar},
    );

    return Scorecard(
      startedAt: at,
      players: <Player>[
        for (int i = 0; i < names.length; i++)
          if (names[i].trim().toLowerCase() == ownerKey)
            Player(
              id: 'p$i-${at.millisecondsSinceEpoch}',
              name: names[i].trim(),
              avatar: ownerAvatar,
              isOwner: true,
            )
          else
            Player(
              id: 'p$i-${at.millisecondsSinceEpoch}',
              name: names[i].trim(),
              avatar: dealt[i],
            ),
      ],
      claims: const <Claim>[],
    );
  }

  final DateTime startedAt;
  final List<Player> players;
  final List<Claim> claims;

  /// The car's quiz: who has been asked what, and who got it right.
  ///
  /// Lives on the scorecard rather than in its own store because it is
  /// per-drive and dies with the drive — the day ends, the card is cleared,
  /// and nobody carries yesterday's questions into this morning.
  final TriviaState trivia;

  /// Sightings only. What the trivia has added is deliberately separate —
  /// see [scoreFor], and the note on why questions unlock off this number.
  int sightingPointsFor(String playerId) => claims
      .where((Claim c) => c.playerId == playerId)
      .fold(0, (int sum, Claim c) => sum + c.points);

  /// What a player has, all in.
  int pointsFor(String playerId) =>
      sightingPointsFor(playerId) + trivia.scoreFor(playerId);

  int get totalPoints => claims.fold(0, (int s, Claim c) => s + c.points);

  /// How many *different* animals this player has claimed today.
  ///
  /// What a question costs. Alex's rule and the right one: it pays for the
  /// thing the game is about — finding something you have not found yet — and
  /// it cannot be farmed, because the twentieth impala adds nothing to it.
  int uniqueSpotsFor(String playerId) => <String>{
    for (final Claim c in claims)
      if (c.playerId == playerId) c.speciesId,
  }.length;

  int timesClaimed(String speciesId) =>
      claims.where((Claim c) => c.speciesId == speciesId).length;

  /// Every species anyone has claimed today. Drives the Codex colouring.
  Set<String> get claimedSpecies =>
      claims.map((Claim c) => c.speciesId).toSet();

  /// The account holder, if they are playing. Their claims are the ones that
  /// count towards a permanent collection — everyone else in the car is a guest
  /// on this phone, and crediting a guest's leopard to the owner's lifetime
  /// record would make that record a lie.
  Player? get owner {
    for (final Player p in players) {
      if (p.isOwner) {
        return p;
      }
    }
    return null;
  }

  Set<String> speciesClaimedBy(String playerId) => <String>{
    for (final Claim c in claims)
      if (c.playerId == playerId) c.speciesId,
  };

  /// Players ordered for the standings board. Ties keep entry order, so the
  /// list does not jitter as scores level.
  List<Player> get standings {
    final List<Player> sorted = <Player>[...players];
    sorted.sort(
      (Player a, Player b) => pointsFor(b.id).compareTo(pointsFor(a.id)),
    );
    return sorted;
  }

  Scorecard withClaim(Claim claim) => Scorecard(
    startedAt: startedAt,
    players: players,
    claims: <Claim>[...claims, claim],
    trivia: trivia,
  );

  /// The quiz moved on: a question asked, or one answered correctly.
  Scorecard withTrivia(TriviaState next) => Scorecard(
    startedAt: startedAt,
    players: players,
    claims: claims,
    trivia: next,
  );

  /// Removes the most recent claim for a species. Used by the undo affordance —
  /// a wrongly assigned animal should be one tap to fix, not a menu.
  Scorecard withoutLastClaimOf(String speciesId) {
    final int index = claims.lastIndexWhere(
      (Claim c) => c.speciesId == speciesId,
    );
    if (index < 0) {
      return this;
    }
    return Scorecard(
      startedAt: startedAt,
      players: players,
      claims: <Claim>[...claims]..removeAt(index),
      trivia: trivia,
    );
  }

  /// Takes one claim of a species back off a specific player.
  ///
  /// [withoutLastClaimOf] undoes whatever happened most recently, which is the
  /// right tool immediately after a mis-tap. This is the other case: an hour
  /// later, someone notices the kudu went to the wrong name. Removing the most
  /// recent claim would then take it off the wrong person twice over.
  ///
  /// Removes the player's *latest* claim of that species, so a duplicate count
  /// comes down by one rather than vanishing.
  Scorecard withoutClaimBy(String playerId, String speciesId) {
    final int index = claims.lastIndexWhere(
      (Claim c) => c.playerId == playerId && c.speciesId == speciesId,
    );
    if (index < 0) {
      return this;
    }
    return Scorecard(
      startedAt: startedAt,
      players: players,
      claims: <Claim>[...claims]..removeAt(index),
      trivia: trivia,
    );
  }

  /// Same car, clean slate.
  ///
  /// Separate from ending the day because they are different intentions. A
  /// restart is "we mis-scored the first hour"; ending the day is "we are done
  /// and it counts". Making a player re-enter four names to fix a mistake is
  /// how you lose them to paper.
  Scorecard get restarted => Scorecard(
    startedAt: startedAt,
    players: players,
    claims: const <Claim>[],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'startedAt': startedAt.toIso8601String(),
    'players': <Map<String, dynamic>>[
      for (final Player p in players) p.toJson(),
    ],
    'claims': <Map<String, dynamic>>[for (final Claim c in claims) c.toJson()],
    if (trivia.toJson().isNotEmpty) 'trivia': trivia.toJson(),
  };
}
