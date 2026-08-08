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
    await _pump(tester, size: const Size(390, 3000));

    // Split from one list of eight rules, which read as a wall. These two
    // answer different questions — "does that count" and "what is it worth" —
    // and a car asks them at different moments.
    expect(find.text('PLAYING A DRIVE'), findsOneWidget);
    expect(find.text('DOES IT COUNT?'), findsOneWidget);
    expect(find.text('WHAT PAYS MORE'), findsOneWidget);
    expect(find.text('WHAT EVERYTHING IS WORTH'), findsOneWidget);
  });

  testWidgets('the opt-out is near the top, not buried at the bottom', (
    WidgetTester tester,
  ) async {
    // Somebody who does not want a competition has to hear that before they
    // read four screens of scoring rules and decide the app is not for them.
    await _pump(tester, size: const Size(390, 3000));

    final double optOut = tester
        .getTopLeft(find.text('Not one for keeping score?'))
        .dy;
    final double firstRule = tester.getTopLeft(find.text('DOES IT COUNT?')).dy;

    expect(optOut, lessThan(firstRule));
  });

  testWidgets('the points table is generated from the tiers', (
    WidgetTester tester,
  ) async {
    await _pump(tester, size: const Size(390, 3000));

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

  testWidgets('the walkthrough is three steps, not four', (
    WidgetTester tester,
  ) async {
    // It was four, and the second one — "every animal has a scarcity level" —
    // was not a step at all. It is a fact about scoring, and it is already the
    // table at the bottom of this screen.
    await _pump(tester);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });
}
