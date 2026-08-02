/// One person in the car, for one day. Not an account — just a name.
class Player {
  const Player({required this.id, required this.name});

  factory Player.fromJson(Map<String, dynamic> json) =>
      Player(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name};
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

  factory Scorecard.start(List<String> names, {DateTime? now}) {
    final DateTime at = now ?? DateTime.now();
    return Scorecard(
      startedAt: at,
      players: <Player>[
        for (int i = 0; i < names.length; i++)
          Player(id: 'p$i-${at.millisecondsSinceEpoch}', name: names[i].trim()),
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'startedAt': startedAt.toIso8601String(),
    'players': <Map<String, dynamic>>[
      for (final Player p in players) p.toJson(),
    ],
    'claims': <Map<String, dynamic>>[for (final Claim c in claims) c.toJson()],
  };
}
