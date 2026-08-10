import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/features/scorecard/rules_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The screen somebody skims at a gate with the engine running. It is the one
/// that has been rewritten most, and the one where length is the failure mode.
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
  testWidgets('the sections say what is in them', (WidgetTester tester) async {
    // Tall surface: the list is lazy, and a section below the fold is simply
    // not built rather than being absent from the screen.
    await _pump(tester, size: const Size(390, 5200));

    // Split from one list of eight rules, which read as a wall. These two
    // answer different questions — "does that count" and "what is it worth" —
    // and a car asks them at different moments.
    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('THE RULES'), findsOneWidget);
    // Split in two. Wild cards are about *how* you spotted it and change with
    // the crowd; bonuses are about what the animal was doing. One heading over
    // both made them look like the same mechanic.
    expect(find.text('WILD CARDS'), findsOneWidget);
    expect(find.text('BONUS CARDS'), findsOneWidget);
    expect(find.text('WHAT EVERYTHING IS WORTH'), findsOneWidget);
  });

  testWidgets('the points table is generated from the tiers', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(390, 5200));

    for (final RarityTier tier in RarityTier.values) {
      expect(find.text(tier.label), findsWidgets, reason: tier.name);
    }
  });

  testWidgets('nothing overflows on a small screen at 1.5x text', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(360, 640), textScale: 1.5);
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the walkthrough is four numbered steps and no more', (
    WidgetTester tester,
  ) async {
    // Four things actually happen: start, add the car, claim, end the day. An
    // earlier version had "every animal has a scarcity level" as a step, which
    // is not a step — it is a fact about scoring, and it is already the table
    // at the bottom of this screen.
    await _pump(tester, size: const Size(390, 5200));

    // By title, not by digit — the points table further down the same screen
    // contains a bare "5" for the Common tier, which an earlier version of this
    // test mistook for a fifth step.
    for (final String title in <String>[
      'Start a Drive',
      'Add Players',
      'Claim a Spot',
      'End the Day',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('the caps are stated as the exception they now are', (
    WidgetTester tester,
  ) async {
    // Caps used to be tier-wide, and the card had to explain a system. Two
    // species are capped now, so the card names them and stops.
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('Almost nothing runs out'), findsOneWidget);
    expect(find.textContaining('vervet monkey'), findsOneWidget);
    expect(find.textContaining('unlimited'), findsOneWidget);
  });

  testWidgets('the two Big Five that taper off say so', (
    WidgetTester tester,
  ) async {
    // Never capped, because a locked Big Five tile reads as a bug — but the
    // fourteenth elephant is not the event the second one was.
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('Elephant and buffalo taper off'), findsOneWidget);
    expect(find.textContaining('third of the day'), findsOneWidget);
  });

  testWidgets('the player is told they can change the scores', (
    WidgetTester tester,
  ) async {
    // The feature is worthless if nobody knows it is there, and the reason for
    // it — that Kruger is not one place — is the interesting part.
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('YOUR GAME, YOUR RULES'), findsOneWidget);
    expect(find.textContaining('Animal Dex'), findsOneWidget);
    // All three, because a setting nobody knows about is a setting nobody uses.
    expect(find.text('Decide what runs out'), findsOneWidget);
    expect(find.text('Set your own jam tax'), findsOneWidget);
    expect(find.textContaining('House rules'), findsOneWidget);
  });

  testWidgets(
    'the jam is one rule, and it does not pretend to be enforceable',
    (WidgetTester tester) async {
      // "No asking at a jam" and "arriving costs 20%" were two cards saying two
      // halves of one thing, and the first was a rule nobody can check phrased
      // as though somebody could. Together they describe what actually happens.
      await _pump(tester, size: const Size(390, 6000));

      expect(find.text('Spot it yourself'), findsOneWidget);
      expect(find.text('No asking at a jam'), findsNothing);
      expect(find.textContaining('Try not to ask'), findsOneWidget);
      expect(find.textContaining('race to call it first'), findsOneWidget);
      expect(find.textContaining('20% fewer points'), findsOneWidget);
    },
  );

  testWidgets('the 1st timers get their own section, impala included', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(390, 6000));

    expect(find.text('WILD CARDS'), findsOneWidget);
    expect(find.text('The 1st timers'), findsOneWidget);
    expect(find.text('Especially the impala'), findsOneWidget);
    expect(find.textContaining('250'), findsWidgets);
  });

  testWidgets('a herd of elephants is not a breeding herd', (
    WidgetTester tester,
  ) async {
    // Jargon. Everybody in the car knows what a herd is.
    await _pump(tester, size: const Size(390, 6000));

    expect(find.textContaining('breeding'), findsNothing);
    expect(find.textContaining('A herd of elephants'), findsOneWidget);
  });
}
