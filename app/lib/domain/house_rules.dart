/// How often one animal can be claimed before its tile goes quiet.
enum CapScope {
  /// Back tomorrow morning. Impala's case: the first is the arrival moment,
  /// the second is an ordinary impala, and then it is done for the day.
  day('a day'),

  /// Gone for the whole trip once you have it.
  ///
  /// Alex's addition, and it is a different game rather than a stricter one:
  /// with everything locked after one sighting the scorecard becomes a
  /// checklist — find each animal once, and the winner is whoever found the
  /// most different things. Some cars will want exactly that.
  trip('this trip');

  const CapScope(this.label);

  final String label;

  static CapScope byName(String name) => values.firstWhere(
    (CapScope s) => s.name == name,
    orElse: () => CapScope.day,
  );
}

/// A limit on one species.
class SpeciesCap {
  const SpeciesCap({required this.times, required this.scope});

  factory SpeciesCap.fromJson(Map<String, dynamic> json) => SpeciesCap(
    times: json['times'] as int,
    scope: CapScope.byName(json['scope'] as String? ?? 'day'),
  );

  final int times;
  final CapScope scope;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'times': times,
    'scope': scope.name,
  };

  @override
  bool operator ==(Object other) =>
      other is SpeciesCap && other.times == times && other.scope == scope;

  @override
  int get hashCode => Object.hash(times, scope);
}

/// Everything a car has decided to do differently.
///
/// **The answer to a question we cannot answer for them.** Our table is one
/// opinion taken nationally, the jam tax is a guess at how much a hint is
/// worth, and the caps are a guess at when counting stops being fun. All three
/// are defensible and none is right for everybody — a car that spends a week
/// at Punda Maria is playing a different game from one at Berg-en-Dal.
///
/// Holds **only what differs from the defaults**, so the common case is empty
/// and an update that revalues an animal still reaches everybody who never had
/// an opinion about it.
class HouseRules {
  const HouseRules({
    this.points = const <String, int>{},
    this.caps = const <String, SpeciesCap?>{},
    this.jamPenalty,
  });

  factory HouseRules.fromJson(Map<String, dynamic> json) => HouseRules(
    points: <String, int>{
      for (final MapEntry<String, dynamic> e
          in (json['points'] as Map<String, dynamic>? ?? const {}).entries)
        if (e.value is int) e.key: e.value as int,
    },
    caps: <String, SpeciesCap?>{
      for (final MapEntry<String, dynamic> e
          in (json['caps'] as Map<String, dynamic>? ?? const {}).entries)
        e.key: e.value == null
            ? null
            : SpeciesCap.fromJson(e.value as Map<String, dynamic>),
    },
    jamPenalty: (json['jamPenalty'] as num?)?.toDouble(),
  );

  static const HouseRules none = HouseRules();

  /// What the jam tax is by default. Twenty per cent, because it is the sum
  /// anybody can do in their head at a gate: 100 becomes 80.
  static const double defaultJamPenalty = 0.2;

  /// What the editor offers. Zero is a real choice — some cars will decide a
  /// sighting is a sighting.
  static const List<double> jamPenaltyChoices = <double>[
    0,
    0.1,
    0.2,
    0.3,
    0.4,
    0.5,
  ];

  /// Species id to points. Empty for almost everybody.
  final Map<String, int> points;

  /// Species id to limit, where a **present key holding null** means "this car
  /// has decided there is no limit".
  ///
  /// Three states, not two, and the distinction earns its keep: a car that
  /// wants unlimited impala has to be able to say so, and that is not the same
  /// as never having had an opinion — the shipped default can still move under
  /// the second one and must not move under the first.
  final Map<String, SpeciesCap?> caps;

  /// Null means "whatever the game ships with", which is the only value that
  /// keeps working when we change our minds.
  final double? jamPenalty;

  double get effectiveJamPenalty => jamPenalty ?? defaultJamPenalty;

  /// What a sighting keeps after arriving at a jam. 1.0 when the tax is off.
  double get jamMultiplier => 1 - effectiveJamPenalty;

  bool get isDefault => points.isEmpty && caps.isEmpty && (jamPenalty == null);

  /// How many things this car has changed, for the settings screen to own up
  /// to in one line.
  int get changeCount =>
      points.length + caps.length + (jamPenalty == null ? 0 : 1);

  HouseRules copyWith({
    Map<String, int>? points,
    Map<String, SpeciesCap?>? caps,
    double? jamPenalty,
    bool clearJamPenalty = false,
  }) => HouseRules(
    points: points ?? this.points,
    caps: caps ?? this.caps,
    jamPenalty: clearJamPenalty ? null : (jamPenalty ?? this.jamPenalty),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (points.isNotEmpty) 'points': points,
    if (caps.isNotEmpty)
      'caps': <String, dynamic>{
        for (final MapEntry<String, SpeciesCap?> e in caps.entries)
          e.key: e.value?.toJson(),
      },
    if (jamPenalty != null) 'jamPenalty': jamPenalty,
  };
}
