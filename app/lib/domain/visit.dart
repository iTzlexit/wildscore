import 'scorecard.dart';

/// A finished day in the park.
///
/// A scorecard that has been ended stops being live and becomes this: the
/// permanent record of one visit, kept whole. Everyone who was in the car, what
/// each of them called, and what it was worth on the day.
///
/// Keeping the *whole* card rather than just the owner's total is deliberate.
/// "Who was in the car with me at Satara in July, and did Sam really get the
/// wild dog" is the thing anyone actually wants to remember about a trip — and
/// once the day is thrown away, no amount of later work brings it back.
class Visit {
  const Visit({
    required this.startedAt,
    required this.endedAt,
    required this.players,
    required this.claims,
  });

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: DateTime.parse(json['endedAt'] as String),
    players: <Player>[
      for (final dynamic p in json['players'] as List<dynamic>)
        Player.fromJson(p as Map<String, dynamic>),
    ],
    claims: <Claim>[
      for (final dynamic c in json['claims'] as List<dynamic>)
        Claim.fromJson(c as Map<String, dynamic>),
    ],
  );

  factory Visit.from(Scorecard card, {DateTime? endedAt}) => Visit(
    startedAt: card.startedAt,
    endedAt: endedAt ?? DateTime.now(),
    players: card.players,
    claims: card.claims,
  );

  final DateTime startedAt;
  final DateTime endedAt;
  final List<Player> players;
  final List<Claim> claims;

  /// The card as it stood when the day ended, for reusing the live widgets.
  Scorecard get asScorecard =>
      Scorecard(startedAt: startedAt, players: players, claims: claims);

  Player? get owner {
    for (final Player p in players) {
      if (p.isOwner) {
        return p;
      }
    }
    return null;
  }

  int pointsFor(String playerId) => claims
      .where((Claim c) => c.playerId == playerId)
      .fold(0, (int sum, Claim c) => sum + c.points);

  /// What this day added to the account holder's lifetime total. Zero if they
  /// were not playing, which is possible: the phone can be handed to a friend.
  int get ownerPoints {
    final Player? me = owner;
    return me == null ? 0 : pointsFor(me.id);
  }

  /// What the account holder personally called. Not what enters their
  /// collection — see [collectedSpecies].
  Set<String> get ownerSpecies {
    final Player? me = owner;
    if (me == null) {
      return const <String>{};
    }
    return <String>{
      for (final Claim c in claims)
        if (c.playerId == me.id) c.speciesId,
    };
  }

  /// Everything the account holder *saw*, which is everything anyone in the car
  /// called.
  ///
  /// Points and the collection answer different questions, and conflating them
  /// was a mistake. **Points are for who called it first** — a competition, and
  /// only the claimer scores. **The collection is for what you have seen**, and
  /// if Sam shouts "pangolin" and you look up and see a pangolin, you have seen
  /// a pangolin. Locking it out of your life list to protect a scoring rule
  /// makes the life list the thing that is wrong.
  ///
  /// Empty when the owner was not playing. The phone can be handed to a friend
  /// for the day, and a collection should not grow while its owner is at home.
  Set<String> get collectedSpecies =>
      owner == null ? const <String>{} : claimedSpecies;

  Set<String> get claimedSpecies => <String>{
    for (final Claim c in claims) c.speciesId,
  };

  int get totalPoints => claims.fold(0, (int s, Claim c) => s + c.points);

  /// Solo drives read differently from a carful — the copy and the layout both
  /// change, so the distinction is worth naming here rather than counting
  /// players at three call sites.
  bool get wasSolo => players.length <= 1;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'players': <Map<String, dynamic>>[
      for (final Player p in players) p.toJson(),
    ],
    'claims': <Map<String, dynamic>>[for (final Claim c in claims) c.toJson()],
  };
}
