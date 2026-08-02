import 'avatar_seed.dart';

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
  });

  factory Claim.fromJson(Map<String, dynamic> json) => Claim(
    speciesId: json['speciesId'] as String,
    playerId: json['playerId'] as String,
    at: DateTime.parse(json['at'] as String),
    points: json['points'] as int,
  );

  final String speciesId;
  final String playerId;
  final DateTime at;
  final int points;

  /// A mis-tap is fixable for five minutes. Long enough to correct the wrong
  /// name; short enough that nobody relitigates the morning at dinner.
  static const Duration editWindow = Duration(minutes: 5);

  bool canEditAt(DateTime now) => now.difference(at) < editWindow;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'speciesId': speciesId,
    'playerId': playerId,
    'at': at.toIso8601String(),
    'points': points,
  };
}

/// One day's game, for one vehicle.
class Scorecard {
  const Scorecard({
    required this.startedAt,
    required this.players,
    required this.claims,
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

  int pointsFor(String playerId) => claims
      .where((Claim c) => c.playerId == playerId)
      .fold(0, (int sum, Claim c) => sum + c.points);

  int get totalPoints => claims.fold(0, (int s, Claim c) => s + c.points);

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
  };
}
