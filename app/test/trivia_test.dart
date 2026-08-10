import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/trivia_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/trivia.dart';
import 'package:wildscore/features/scorecard/trivia_sheet.dart';
import 'package:wildscore/shared/theme.dart';

/// The quiz that runs alongside the drive.
///
/// **Unlocked by finding new animals**, which is Alex's third and best rule for
/// it: a question per *unique* spot rewards the thing the game is about and
/// cannot be farmed by tapping the same impala twenty times. One more is handed
/// out every half hour so a quiet stretch of road still produces something.
late final List<TriviaQuestion> _bank;

Scorecard _card({List<String> players = const <String>['Alex']}) =>
    Scorecard.start(players, now: DateTime(2026, 8, 10, 6));

Claim _claim(String playerId, String speciesId, {int hour = 7}) => Claim(
  speciesId: speciesId,
  playerId: playerId,
  at: DateTime(2026, 8, 10, hour),
  points: 10,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _bank = await const TriviaRepository().loadAll();
  });

  group('the question bank', () {
    test('is big enough for a long day and then some', () {
      expect(_bank.length, greaterThanOrEqualTo(100));
    });

    test('every question is well formed', () {
      for (final TriviaQuestion q in _bank) {
        expect(q.answers, hasLength(4), reason: q.id);
        expect(q.answers.toSet(), hasLength(4), reason: '${q.id} repeats');
        expect(q.correct, inInclusiveRange(0, 3), reason: q.id);
        expect(q.question.trim(), isNotEmpty, reason: q.id);
        for (final String a in q.answers) {
          expect(a.trim(), isNotEmpty, reason: q.id);
        }
      }
    });

    test('ids are unique, because they are what stops a repeat', () {
      expect(
        _bank.map((TriviaQuestion q) => q.id).toSet(),
        hasLength(_bank.length),
      );
    });

    test('difficulty actually varies, and pays accordingly', () {
      // The first bank was one level throughout and played easy — a car of
      // adults got most of them, so nobody was pleased to get one right.
      final Map<TriviaDifficulty, int> spread = <TriviaDifficulty, int>{};
      for (final TriviaQuestion q in _bank) {
        spread[q.difficulty] = (spread[q.difficulty] ?? 0) + 1;
      }

      for (final TriviaDifficulty d in TriviaDifficulty.values) {
        expect(spread[d] ?? 0, greaterThan(10), reason: d.name);
      }
      expect(
        TriviaDifficulty.hard.reward,
        greaterThan(TriviaDifficulty.easy.reward),
        reason: 'a hard question worth the same is a reason to hope for easy',
      );
    });
  });

  group('unlocking', () {
    test('nothing is waiting until a player has found something new', () {
      const TriviaState s = TriviaState.empty;

      expect(s.hasWaiting('p1', 0), isFalse);
      expect(s.hasWaiting('p1', 1), isTrue);
    });

    test('a second question needs a second *different* animal', () {
      final Scorecard card = _card();
      final String alex = card.players.first.id;
      final Scorecard twoImpala = card
          .withClaim(_claim(alex, 'impala'))
          .withClaim(_claim(alex, 'impala', hour: 8));

      expect(
        twoImpala.uniqueSpotsFor(alex),
        1,
        reason: 'the twentieth impala earns nothing',
      );

      final Scorecard andAZebra = twoImpala.withClaim(
        _claim(alex, 'burchells-zebra', hour: 9),
      );
      expect(andAZebra.uniqueSpotsFor(alex), 2);
    });

    test('spots by other people do not unlock your question', () {
      final Scorecard card = _card(players: <String>['Alex', 'Sam']);
      final String alex = card.players.first.id;
      final String sam = card.players[1].id;
      final Scorecard scored = card.withClaim(_claim(sam, 'leopard'));

      expect(scored.uniqueSpotsFor(alex), 0);
      expect(scored.uniqueSpotsFor(sam), 1);
    });

    test('one question is handed out every half hour, going round the car', () {
      // A car can spend thirty minutes on the H1-2 seeing nothing at all. That
      // is real Kruger and should not be a dead half hour in the game.
      final Scorecard card = _card(players: <String>['Alex', 'Sam']);
      final String alex = card.players.first.id;
      final String sam = card.players[1].id;
      final DateTime start = DateTime(2026, 8, 10, 6);

      expect(
        card.timedQuestionsFor(
          alex,
          now: start.add(const Duration(minutes: 29)),
        ),
        0,
      );
      expect(
        card.timedQuestionsFor(
          alex,
          now: start.add(const Duration(minutes: 30)),
        ),
        1,
      );
      // The second half hour goes to the next seat, not to the same person.
      expect(
        card.timedQuestionsFor(
          sam,
          now: start.add(const Duration(minutes: 30)),
        ),
        0,
      );
      expect(
        card.timedQuestionsFor(
          sam,
          now: start.add(const Duration(minutes: 60)),
        ),
        1,
      );
      expect(
        card.timedQuestionsFor(alex, now: start.add(const Duration(hours: 2))),
        2,
      );
    });

    test('unlocking counts spots, never the points they were worth', () {
      // Otherwise a right answer pays for the next question, which pays for
      // the next: points a tap, forever, without seeing an animal.
      final Scorecard card = _card();
      final String alex = card.players.first.id;
      final Scorecard scored = card
          .withClaim(_claim(alex, 'leopard'))
          .withTrivia(
            TriviaState.empty
                .withPending(alex, 'q1')
                .withAnswer(alex, points: 40),
          );

      expect(scored.uniqueSpotsFor(alex), 1);
      expect(scored.pointsFor(alex), 50);
      expect(scored.sightingPointsFor(alex), 10);
    });
  });

  group('picking one', () {
    const TriviaRepository repo = TriviaRepository();

    test('never repeats within a drive', () {
      TriviaState s = TriviaState.empty;
      final Set<String> seen = <String>{};

      for (int i = 0; i < _bank.length; i++) {
        final TriviaQuestion? q = repo.next(_bank, s, 'p1', random: Random(i));
        expect(q, isNotNull, reason: 'ran dry after $i');
        expect(seen.add(q!.id), isTrue, reason: 'repeated ${q.id}');
        s = s.withPending('p1', q.id).withAnswer('p1', points: 0);
      }

      // And then, honestly, nothing left.
      expect(repo.next(_bank, s, 'p1'), isNull);
    });

    test('is random rather than dealt in a fixed order', () {
      // Two cars playing the same way used to get the same questions in the
      // same order, because the pick was a hash of the player id.
      const TriviaState s = TriviaState.empty;
      final Set<String> picked = <String>{
        for (int i = 0; i < 25; i++) repo.next(_bank, s, 'p1')!.id,
      };

      expect(picked.length, greaterThan(3));
    });

    test('an opened question comes back, so backing out changes nothing', () {
      // The anti-shopping rule, now done by holding the question rather than
      // by burning it.
      final TriviaState s = TriviaState.empty.withPending('p1', 'lion-sleep');

      expect(repo.next(_bank, s, 'p1')!.id, 'lion-sleep');
      expect(repo.next(_bank, s, 'p1')!.id, 'lion-sleep');
    });

    test('a pending question from a bank that no longer has it is replaced', () {
      // An app update can drop a question out from under a saved card. A badge
      // that opens nothing would be worse than a different question.
      final TriviaState s = TriviaState.empty.withPending('p1', 'gone-in-v2');

      expect(repo.next(_bank, s, 'p1'), isNotNull);
    });
  });

  group('answering', () {
    testWidgets('the answers are shuffled, or the game is "tap the top one"', (
      WidgetTester tester,
    ) async {
      // Every question in the bank stores its right answer first, because that
      // is far easier to write and to check. The shuffle is the only thing
      // standing between that and a quiz nobody can lose.
      final Player p = Scorecard.start(<String>['Alex']).players.first;
      int topWasCorrect = 0;

      for (final TriviaQuestion q in _bank.take(20)) {
        // Keyed, or Flutter reuses the State across pumps and the order is
        // computed once from the first question — which would make this test
        // pass or fail on an accident rather than on the shuffle.
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: TriviaSheet(
                key: ValueKey<String>(q.id),
                player: p,
                question: q,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final String first = tester
            .widgetList<Text>(find.byType(Text))
            .map((Text t) => t.data ?? '')
            .firstWhere((String s) => q.answers.contains(s));
        if (first == q.answer) {
          topWasCorrect++;
        }
      }

      expect(
        topWasCorrect,
        lessThan(20),
        reason: 'the right answer is always on top — nothing is shuffled',
      );
    });

    testWidgets('a wrong answer shows the right one and pays nothing', (
      WidgetTester tester,
    ) async {
      final Player p = Scorecard.start(<String>['Alex']).players.first;
      final TriviaQuestion q = _bank.first;
      int? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await TriviaSheet.ask(
                    context,
                    player: p,
                    question: q,
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final String wrong = q.answers.firstWhere((String a) => a != q.answer);
      await tester.tap(find.text(wrong));
      await tester.pumpAndSettle();

      expect(find.textContaining('It was ${q.answer}'), findsOneWidget);

      await tester.tap(find.text('Back to the drive'));
      await tester.pumpAndSettle();
      expect(result, 0, reason: 'answered and wrong is zero, not null');
    });

    testWidgets('a right answer pays what the question is worth', (
      WidgetTester tester,
    ) async {
      final Player p = Scorecard.start(<String>['Alex']).players.first;
      final TriviaQuestion q = _bank.firstWhere(
        (TriviaQuestion q) => q.difficulty == TriviaDifficulty.hard,
      );
      int? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await TriviaSheet.ask(
                    context,
                    player: p,
                    question: q,
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(q.answer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to the drive'));
      await tester.pumpAndSettle();

      expect(result, q.reward);
      expect(result, TriviaDifficulty.hard.reward);
    });

    testWidgets('there is no second guess', (WidgetTester tester) async {
      // A quiz you can retry is a quiz everybody scores full marks on.
      final Player p = Scorecard.start(<String>['Alex']).players.first;
      final TriviaQuestion q = _bank.first;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: TriviaSheet(player: p, question: q),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final String wrong = q.answers.firstWhere((String a) => a != q.answer);
      await tester.tap(find.text(wrong));
      await tester.pumpAndSettle();

      await tester.tap(find.text(q.answer));
      await tester.pumpAndSettle();

      // Still showing the wrong outcome — the second tap did nothing.
      expect(find.textContaining('It was ${q.answer}'), findsOneWidget);
    });
  });

  group('closing it without answering', () {
    test('leaves the question pending, so the badge stays', () {
      // Alex found this in about a minute: pressing back made the question
      // disappear, because opening the sheet spent it.
      final TriviaState s = TriviaState.empty.withPending('p1', 'lion-sleep');

      expect(s.hasWaiting('p1', 0), isTrue, reason: 'even with no new spots');
      expect(s.seenBy('p1'), isEmpty);
      expect(s.pendingFor('p1'), 'lion-sleep');
    });

    test('answering it is what spends it', () {
      final TriviaState s = TriviaState.empty
          .withPending('p1', 'lion-sleep')
          .withAnswer('p1', points: 0);

      expect(s.pendingFor('p1'), isNull);
      expect(s.seenBy('p1'), <String>['lion-sleep']);
      expect(s.hasWaiting('p1', 0), isFalse);
      expect(s.scoreFor('p1'), 0);
    });
  });

  test('what a player has won is what the tile shows', () {
    final TriviaState s = TriviaState.empty
        .withPending('p1', 'a')
        .withAnswer('p1', points: 40)
        .withPending('p1', 'b')
        .withAnswer('p1', points: 70)
        .withPending('p2', 'c')
        .withAnswer('p2', points: 20);

    expect(s.scoreFor('p1'), 110);
    expect(s.rightFor('p1'), 2);
    expect(s.totalWon, 130);
    expect(s.totalRight, 3);
  });

  test('survives a round trip on the scorecard', () {
    final Scorecard card = _card();
    final String alex = card.players.first.id;
    final Scorecard with_ = card.withTrivia(
      TriviaState.empty
          .withPending(alex, 'collective-hippo')
          .withAnswer(alex, points: 40)
          .withPending(alex, 'lion-sleep'),
    );

    final Scorecard back = Scorecard.fromJson(with_.toJson());

    expect(back.trivia.seenBy(alex), <String>['collective-hippo']);
    expect(back.trivia.scoreFor(alex), 40);
    expect(back.trivia.pendingFor(alex), 'lion-sleep');
  });

  test('a card written before the quiz existed still loads', () {
    final Scorecard old = Scorecard.fromJson(<String, dynamic>{
      'startedAt': '2026-07-01T06:00:00.000',
      'players': <dynamic>[
        <String, dynamic>{'id': 'p0', 'name': 'Alex', 'avatar': 0},
      ],
      'claims': <dynamic>[],
    });

    expect(old.trivia.asked, isEmpty);
    expect(old.pointsFor('p0'), 0);
  });
}
