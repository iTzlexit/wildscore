/// How hard a question is meant to be.
///
/// The first bank was all one level and Alex's note on it was fair: a car of
/// adults gets most of them without thinking, so nobody is *pleased* to get one
/// right. Three levels means the bank can hold "what colour is a zebra's skin"
/// and "which Kruger river never dries" without either one feeling out of place.
enum TriviaDifficulty {
  /// Anybody in the car, first trip or thirtieth.
  easy,

  /// A regular visitor, or a good guess from somebody paying attention.
  medium,

  /// You either know it or you do not.
  hard;

  static TriviaDifficulty byName(String? name) {
    for (final TriviaDifficulty d in values) {
      if (d.name == name) {
        return d;
      }
    }
    return TriviaDifficulty.medium;
  }

  String get label => switch (this) {
    TriviaDifficulty.easy => 'Easy',
    TriviaDifficulty.medium => 'Tricky',
    TriviaDifficulty.hard => 'Hard',
  };

  /// What a right answer pays.
  ///
  /// A hard question worth the same as an easy one is a reason to hope for easy
  /// ones, which is backwards.
  int get reward => switch (this) {
    TriviaDifficulty.easy => 20,
    TriviaDifficulty.medium => 40,
    TriviaDifficulty.hard => 70,
  };
}

/// One question, four answers, one of them right.
class TriviaQuestion {
  const TriviaQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.correct,
    this.difficulty = TriviaDifficulty.medium,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) => TriviaQuestion(
    id: json['id'] as String,
    question: json['question'] as String,
    answers: <String>[
      for (final dynamic a in json['answers'] as List<dynamic>) a as String,
    ],
    correct: json['correct'] as int,
    difficulty: TriviaDifficulty.byName(json['difficulty'] as String?),
  );

  final String id;
  final String question;

  /// Always four. Shuffled for display, never in storage — the right answer's
  /// index has to stay meaningful.
  final List<String> answers;
  final int correct;
  final TriviaDifficulty difficulty;

  String get answer => answers[correct];

  int get reward => difficulty.reward;

  bool isCorrect(int index) => index == correct;
}

/// What a player has unlocked, what is waiting, and what they have won.
///
/// **Unlocked by finding new animals, not by the clock and not by score.**
/// Alex's rule, third revision and the best of the three: every *unique* spot a
/// player makes earns them a question. It rewards the thing the game is about —
/// finding an animal you have not found yet today — and it cannot be farmed by
/// tapping the same impala twenty times.
///
/// On top of that, one question is handed out roughly every half hour to
/// somebody in the car, so a quiet stretch of road still produces something.
class TriviaState {
  const TriviaState({
    this.asked = const <String, List<String>>{},
    this.answered = const <String, int>{},
    this.pending = const <String, String>{},
    this.won = const <String, int>{},
  });

  factory TriviaState.fromJson(Map<String, dynamic> json) => TriviaState(
    asked: <String, List<String>>{
      for (final MapEntry<String, dynamic> e
          in (json['asked'] as Map<String, dynamic>? ?? const {}).entries)
        e.key: <String>[
          for (final dynamic q in e.value as List<dynamic>) q as String,
        ],
    },
    answered: <String, int>{
      for (final MapEntry<String, dynamic> e
          in (json['answered'] as Map<String, dynamic>? ?? const {}).entries)
        if (e.value is int) e.key: e.value as int,
    },
    pending: <String, String>{
      for (final MapEntry<String, dynamic> e
          in (json['pending'] as Map<String, dynamic>? ?? const {}).entries)
        if (e.value is String) e.key: e.value as String,
    },
    won: <String, int>{
      for (final MapEntry<String, dynamic> e
          in (json['won'] as Map<String, dynamic>? ?? const {}).entries)
        if (e.value is int) e.key: e.value as int,
    },
  );

  static const TriviaState empty = TriviaState();

  /// Every question this player has **finished**, oldest first. Keeps anybody
  /// from being asked the same thing twice in a drive.
  final Map<String, List<String>> asked;

  /// How many they have got right, per player. Kept for the tally on the tile.
  final Map<String, int> answered;

  /// The question opened and not yet answered, per player.
  ///
  /// **This is what stops the badge vanishing when somebody presses back.** It
  /// used to record the question as asked the moment the sheet opened, which
  /// meant closing it burned the question — Alex found that within a minute of
  /// picking the app up. Holding it here does the one job that behaviour was
  /// for as well: come back and you get *the same question*, so backing out
  /// cannot shop for an easier one.
  final Map<String, String> pending;

  /// Points won, per player. Stored rather than derived, because a right answer
  /// is worth what the question was worth and the bank is not in scope here.
  final Map<String, int> won;

  /// How long a drive runs before it hands somebody a question anyway.
  ///
  /// A car can go half an hour on the H1-2 without seeing a thing. That is real
  /// Kruger and it should not be a dead half hour in the game.
  static const Duration timedQuestion = Duration(minutes: 30);

  /// Legacy: the old bank paid a flat thirty for any question.
  static const int reward = 30;

  /// Questions this player has earned in total.
  ///
  /// One per unique spot, plus their share of the timed ones.
  static int earnedBy(int uniqueSpots, {int timed = 0}) => uniqueSpots + timed;

  /// Whether a question is waiting — either already opened and abandoned, or
  /// newly earned.
  bool hasWaiting(String playerId, int uniqueSpots, {int timed = 0}) =>
      pending.containsKey(playerId) ||
      earnedBy(uniqueSpots, timed: timed) > seenBy(playerId).length;

  List<String> seenBy(String playerId) => asked[playerId] ?? const <String>[];

  String? pendingFor(String playerId) => pending[playerId];

  int scoreFor(String playerId) => won[playerId] ?? 0;

  int rightFor(String playerId) => answered[playerId] ?? 0;

  /// Everything everybody has won. The number on the trivia tile.
  int get totalWon => won.values.fold(0, (int sum, int v) => sum + v);

  int get totalRight => answered.values.fold(0, (int sum, int v) => sum + v);

  /// Opens a question without consuming it.
  TriviaState withPending(String playerId, String questionId) => TriviaState(
    asked: asked,
    answered: answered,
    pending: <String, String>{...pending, playerId: questionId},
    won: won,
  );

  /// Finishes the pending question: it joins the seen list either way, and pays
  /// only if it was right.
  TriviaState withAnswer(String playerId, {required int points}) {
    final String? open = pending[playerId];
    return TriviaState(
      asked: <String, List<String>>{
        ...asked,
        if (open != null) playerId: <String>[...seenBy(playerId), open],
      },
      answered: <String, int>{
        ...answered,
        if (points > 0) playerId: rightFor(playerId) + 1,
      },
      pending: <String, String>{...pending}..remove(playerId),
      won: <String, int>{
        ...won,
        if (points > 0) playerId: scoreFor(playerId) + points,
      },
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (asked.isNotEmpty) 'asked': asked,
    if (answered.isNotEmpty) 'answered': answered,
    if (pending.isNotEmpty) 'pending': pending,
    if (won.isNotEmpty) 'won': won,
  };
}
