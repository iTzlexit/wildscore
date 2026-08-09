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

  testWidgets('the everyday cap is explained without jargon', (
    WidgetTester tester,
  ) async {
    // The heading used to be "The common ones run out for the day", which
    // meant nothing until you had already read the card. It now says what it
    // is, and the two numbers a player actually needs are in the body.
    await _pump(tester, size: const Size(390, 5200));

    expect(find.text('Common animals have a daily limit'), findsOneWidget);
    expect(find.textContaining('Impala scores'), findsOneWidget);
    expect(
      find.textContaining('Rare animals are never capped'),
      findsOneWidget,
    );
  });

  testWidgets('the two crowd outcomes are stated as scoring, not as advice', (
    WidgetTester tester,
  ) async {
    // Spotting it yourself pays what the card says and a jam pays a fifth
    // less. Both halves have to be on this screen or the claim sheet is the
    // first place anybody learns there is a penalty at all.
    await _pump(tester, size: const Size(390, 5200));

    expect(find.textContaining('normal points'), findsOneWidget);
    expect(find.textContaining('20% fewer points'), findsOneWidget);
  });
}
