import 'dart:convert';

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

  /// One this player has not had yet, or null when the bank runs dry.
  ///
  /// Seeded from the player and how many they have already had, so the same
  /// question comes back if the sheet is closed and reopened — being handed a
  /// different question for backing out by accident would be a way to shop for
  /// an easy one.
  TriviaQuestion? next(
    List<TriviaQuestion> all,
    TriviaState state,
    String playerId,
  ) {
    final Set<String> seen = state.seenBy(playerId).toSet();
    final List<TriviaQuestion> left = <TriviaQuestion>[
      for (final TriviaQuestion q in all)
        if (!seen.contains(q.id)) q,
    ];
    if (left.isEmpty) {
      return null;
    }
    final int seed = playerId.hashCode ^ (seen.length * 7919);
    return left[seed.abs() % left.length];
  }
}
