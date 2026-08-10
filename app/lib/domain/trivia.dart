/// One question, four answers, one of them right.
class TriviaQuestion {
  const TriviaQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.correct,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) => TriviaQuestion(
    id: json['id'] as String,
    question: json['question'] as String,
    answers: <String>[
      for (final dynamic a in json['answers'] as List<dynamic>) a as String,
    ],
    correct: json['correct'] as int,
  );

  final String id;
  final String question;

  /// Always four. Shuffled for display, never in storage — the right answer's
  /// index has to stay meaningful.
  final List<String> answers;
  final int correct;

  String get answer => answers[correct];

  bool isCorrect(int index) => index == correct;
}

/// What a player has unlocked and what they have done with it.
///
/// **Unlocked by scoring, not by the clock.** Alex's second idea and much the
/// better one: a timer rewards sitting still, and this rewards playing well —
/// a car finding good animals earns questions faster, which is the right way
/// round. It also self-paces, because a quiet hour asks nothing of anybody.
class TriviaState {
  const TriviaState({
    this.asked = const <String, List<String>>{},
    this.answered = const <String, int>{},
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
  );

  static const TriviaState empty = TriviaState();

  /// Every question this player has been shown today, oldest first. Keeps
  /// anybody from being asked the same thing twice in a drive.
  final Map<String, List<String>> asked;

  /// How many they have got right, per player. What the points are worth is a
  /// scoring decision that lives with the scoring.
  final Map<String, int> answered;

  /// Points between questions.
  ///
  /// 400 is roughly a good hour: a couple of decent sightings, or a lot of
  /// small ones. Low enough that everybody in the car gets a turn on a normal
  /// morning, high enough that it is not a second game running alongside the
  /// first.
  static const int pointsPerQuestion = 400;

  /// What a right answer pays.
  static const int reward = 30;

  /// How many questions this player has earned in total, from their score.
  static int earnedBy(int points) => points ~/ pointsPerQuestion;

  /// Whether there is a question waiting to be answered.
  bool hasWaiting(String playerId, int points) =>
      earnedBy(points) > (asked[playerId]?.length ?? 0);

  List<String> seenBy(String playerId) => asked[playerId] ?? const <String>[];

  int scoreFor(String playerId) => (answered[playerId] ?? 0) * reward;

  TriviaState withAsked(String playerId, String questionId) => TriviaState(
    asked: <String, List<String>>{
      ...asked,
      playerId: <String>[...seenBy(playerId), questionId],
    },
    answered: answered,
  );

  TriviaState withCorrect(String playerId) => TriviaState(
    asked: asked,
    answered: <String, int>{
      ...answered,
      playerId: (answered[playerId] ?? 0) + 1,
    },
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (asked.isNotEmpty) 'asked': asked,
    if (answered.isNotEmpty) 'answered': answered,
  };
}
