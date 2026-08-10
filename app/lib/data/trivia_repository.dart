import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/trivia.dart';

/// The question bank, bundled with the app.
///
/// Seventy-odd questions and no network, like everything else here. They are
/// read once and held, because a car in the far north has no signal and a quiz
/// that needs one is a quiz that does not work where it is played.
class TriviaRepository {
  const TriviaRepository();

  static const String _assetPath = 'assets/data/trivia.json';

  static List<TriviaQuestion>? _cache;

  Future<List<TriviaQuestion>> loadAll() async {
    if (_cache case final List<TriviaQuestion> cached) {
      return cached;
    }
    final Map<String, dynamic> decoded =
        json.decode(await rootBundle.loadString(_assetPath))
            as Map<String, dynamic>;
    return _cache = <TriviaQuestion>[
      for (final dynamic q in decoded['questions'] as List<dynamic>)
        TriviaQuestion.fromJson(q as Map<String, dynamic>),
    ];
  }

  /// The question this player should be looking at, or null when the bank runs
  /// dry.
  ///
  /// **Genuinely random now**, which is Alex's ask: the old version picked by
  /// hashing the player id and the number of questions they had answered, so
  /// two cars playing the same way got the same questions in the same order.
  ///
  /// Backing out still cannot shop for an easier one, but that is no longer
  /// this method's job. A question that has been opened is held in
  /// [TriviaState.pending] and handed straight back here, which does the same
  /// work without burning the question when somebody presses back by accident.
  TriviaQuestion? next(
    List<TriviaQuestion> all,
    TriviaState state,
    String playerId, {
    Random? random,
  }) {
    final String? open = state.pendingFor(playerId);
    if (open != null) {
      for (final TriviaQuestion q in all) {
        if (q.id == open) {
          return q;
        }
      }
      // The bank changed under a saved card — an app update, most likely. Fall
      // through and deal a new one rather than leaving a badge nothing opens.
    }

    final Set<String> seen = state.seenBy(playerId).toSet();
    final List<TriviaQuestion> left = <TriviaQuestion>[
      for (final TriviaQuestion q in all)
        if (!seen.contains(q.id)) q,
    ];
    if (left.isEmpty) {
      return null;
    }

    // Weighted so a drive is not all easy questions or all hard ones. Roughly
    // half medium, a quarter each side — the mix a pub quiz uses, for the same
    // reason: everybody gets one they can answer and one they cannot.
    final Random rng = random ?? Random();
    final TriviaDifficulty want = switch (rng.nextInt(4)) {
      0 => TriviaDifficulty.easy,
      3 => TriviaDifficulty.hard,
      _ => TriviaDifficulty.medium,
    };
    final List<TriviaQuestion> banded = <TriviaQuestion>[
      for (final TriviaQuestion q in left)
        if (q.difficulty == want) q,
    ];
    final List<TriviaQuestion> pool = banded.isEmpty ? left : banded;
    return pool[rng.nextInt(pool.length)];
  }
}
