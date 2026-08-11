import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/features/scorecard/rules_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The rule book, which is now **only** a rule book.
///
/// Teaching moved to the tour on 10 August 2026. This page is what somebody
/// lands on mid-argument at 40km/h, so the tests are about the rules being
/// findable and correct rather than about a walkthrough being complete.
Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const RulesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('it is called Rules, and teaches nothing', (
    WidgetTester tester,
  ) async {
    // Tall surface: the list is lazy, and a section below the fold is simply
    // not built rather than being absent from the screen.
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('Rules'), findsOneWidget);
    // The four-step walkthrough is the tour's job now. Somebody who wants it
    // gets a button, not a third copy of it.
    expect(find.text('HOW TO PLAY'), findsNothing);
    expect(find.text('Start a Drive'), findsNothing);
    expect(find.textContaining('quick tour'), findsOneWidget);
  });

  testWidgets('the sections say what is in them', (WidgetTester tester) async {
    await _pump(tester, size: const Size(390, 6000));

    for (final String section in <String>[
      'THE RULES',
      'SPECIAL RULES',
      'BONUS ANIMALS',
      'POINTS',
      "CHANGE AN ANIMAL'S VALUE",
    ]) {
      expect(find.text(section), findsOneWidget, reason: section);
    }
  });

  testWidgets('a group counts once, and so does the same group later', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('A group counts as one sighting'), findsOneWidget);
    expect(find.textContaining('Herd of elephants = 1 sighting'), findsOne);
    expect(find.text('The same sighting counts once'), findsOneWidget);
    expect(
      find.textContaining('does not create a new sighting'),
      findsOneWidget,
    );
    // Examples only. The sentence that used to sit above them said the
    // same thing in longer words.
    expect(find.textContaining('no matter how many'), findsNothing);
    // Jargon. Everybody in the car knows what a herd is.
    expect(find.textContaining('breeding'), findsNothing);
  });

  testWidgets('the jam costs a fifth and says so plainly', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('Traffic jam'), findsOneWidget);
    expect(find.textContaining('20% fewer points'), findsOneWidget);
  });

  testWidgets('the daily limits match what the catalogue actually does', (
    WidgetTester tester,
  ) async {
    // The page said "only two animals have a daily limit" while 124 birds were
    // capped at one a day. A rule book that is wrong in the car is worse than
    // no rule book — somebody hits the limit and stops trusting the rest.
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('Daily limits'), findsOneWidget);
    expect(find.textContaining('Impala: 2 per day'), findsOneWidget);
    expect(find.textContaining('Vervet monkey: 4 per day'), findsOneWidget);
    expect(find.textContaining('Every bird: once a day'), findsOneWidget);
    expect(find.textContaining('unlimited'), findsOneWidget);
  });

  testWidgets('the quiz is explained here too', (WidgetTester tester) async {
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('Trivia questions'), findsOneWidget);
  });

  testWidgets('the points table is generated from the tiers', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(390, 6000));

    for (final RarityTier tier in RarityTier.values) {
      expect(find.text(tier.label), findsWidgets, reason: tier.name);
    }
    // The new names, which are the point of them: they say what the animal
    // does rather than restating "rare" six ways.
    expect(find.text('Ghost'), findsOneWidget);
    expect(find.text('Bush Staples'), findsOneWidget);
  });

  testWidgets('the player is told they can change the scores', (
    WidgetTester tester,
  ) async {
    // The feature is worthless if nobody knows it is there.
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text("Don't agree with a score? Change it"), findsOneWidget);
    expect(find.textContaining('the prices'), findsOneWidget);
    // And that it sticks, which is the half people do not assume.
    expect(find.textContaining('We remember it'), findsOneWidget);
    // Twice: the jam tax and the daily limits both live there.
    expect(find.textContaining('House rules'), findsWidgets);
  });

  testWidgets('nothing overflows on a small screen at 1.5x text', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(360, 640), textScale: 1.5);
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
