import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/trivia_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/trivia.dart';
import 'package:wildscore/features/scorecard/trivia_sheet.dart';
import 'package:wildscore/shared/theme.dart';

/// The quiz that runs alongside the drive.
///
/// Unlocked by **scoring**, not by the clock — a timer rewards sitting still,
/// this rewards playing well, and it self-paces because a quiet hour asks
/// nothing of anybody.
late final List<TriviaQuestion> _bank;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _bank = await const TriviaRepository().loadAll();
  });

  group('the question bank', () {
    test('is big enough for a long day and then some', () {
      expect(_bank.length, greaterThanOrEqualTo(70));
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
  });

  group('unlocking', () {
    test('nothing is waiting until a player has scored enough', () {
      const TriviaState s = TriviaState.empty;

      expect(s.hasWaiting('p1', 0), isFalse);
      expect(s.hasWaiting('p1', TriviaState.pointsPerQuestion - 1), isFalse);
      expect(s.hasWaiting('p1', TriviaState.pointsPerQuestion), isTrue);
    });

    test('a second question needs a second threshold', () {
      TriviaState s = TriviaState.empty.withAsked('p1', 'q1');

      expect(s.hasWaiting('p1', TriviaState.pointsPerQuestion), isFalse);
      expect(s.hasWaiting('p1', TriviaState.pointsPerQuestion * 2), isTrue);

      s = s.withAsked('p1', 'q2');
      expect(s.hasWaiting('p1', TriviaState.pointsPerQuestion * 2), isFalse);
    });

    test('players unlock independently', () {
      final TriviaState s = TriviaState.empty.withAsked('p1', 'q1');

      expect(s.hasWaiting('p1', TriviaState.pointsPerQuestion), isFalse);
      expect(s.hasWaiting('p2', TriviaState.pointsPerQuestion), isTrue);
    });

    test('unlocking counts sightings only, not trivia already won', () {
      // Otherwise a right answer pays for the next question, which pays for
      // the next: thirty points a tap, forever, without seeing an animal.
      final Scorecard card = Scorecard.start(<String>[
        'Alex',
      ], now: DateTime(2026, 8, 10, 6));
      final String alex = card.players.first.id;
      final Scorecard scored = card
          .withClaim(
            Claim(
              speciesId: 'leopard',
              playerId: alex,
              at: DateTime(2026, 8, 10, 7),
              points: TriviaState.pointsPerQuestion,
            ),
          )
          .withTrivia(TriviaState.empty.withCorrect(alex));

      expect(scored.pointsFor(alex), TriviaState.pointsPerQuestion + 30);
      expect(scored.sightingPointsFor(alex), TriviaState.pointsPerQuestion);
    });
  });

  group('picking one', () {
    const TriviaRepository repo = TriviaRepository();

    test('never repeats within a drive', () {
      TriviaState s = TriviaState.empty;
      final Set<String> seen = <String>{};

      for (int i = 0; i < _bank.length; i++) {
        final TriviaQuestion? q = repo.next(_bank, s, 'p1');
        expect(q, isNotNull, reason: 'ran dry after $i');
        expect(seen.add(q!.id), isTrue, reason: 'repeated ${q.id}');
        s = s.withAsked('p1', q.id);
      }

      // And then, honestly, nothing left.
      expect(repo.next(_bank, s, 'p1'), isNull);
    });

    test('is stable, so backing out cannot shop for an easier one', () {
      const TriviaState s = TriviaState.empty;

      expect(repo.next(_bank, s, 'p1')!.id, repo.next(_bank, s, 'p1')!.id);
    });

    test('different players get different questions', () {
      const TriviaState s = TriviaState.empty;
      final Set<String> picked = <String>{
        for (final String p in <String>['p1', 'p2', 'p3', 'p4'])
          repo.next(_bank, s, p)!.id,
      };

      expect(picked.length, greaterThan(1));
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
      bool? result;

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
      expect(result, isFalse);
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

  test('a right answer is worth what the rules say', () {
    final TriviaState s = TriviaState.empty.withCorrect('p1').withCorrect('p1');

    expect(TriviaState.reward, 30);
    expect(s.scoreFor('p1'), 60);
    expect(s.scoreFor('p2'), 0);
  });

  test('survives a round trip on the scorecard', () {
    final Scorecard card = Scorecard.start(<String>[
      'Alex',
    ], now: DateTime(2026, 8, 10, 6));
    final String alex = card.players.first.id;
    final Scorecard with_ = card.withTrivia(
      TriviaState.empty.withAsked(alex, 'collective-hippo').withCorrect(alex),
    );

    final Scorecard back = Scorecard.fromJson(with_.toJson());

    expect(back.trivia.seenBy(alex), <String>['collective-hippo']);
    expect(back.trivia.scoreFor(alex), 30);
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
