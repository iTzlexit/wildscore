import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/features/onboarding/intro_tour.dart';
import 'package:wildscore/shared/theme.dart';

/// The tour is the first thing anybody sees, on every phone there is. A slide
/// that overflows on a small screen or at a large text scale is a broken first
/// impression, and this project has shipped that bug twice already.
Future<void> _pump(
  WidgetTester tester, {
  required Size size,
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
        child: Scaffold(
          body: SafeArea(child: IntroTour(onDone: () {})),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _walkAllSlides(WidgetTester tester) async {
  for (int i = 0; i < 2; i++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
}

void main() {
  // A small Android phone, a typical one, and a tall modern one.
  const Map<String, Size> phones = <String, Size>{
    'small (360×640)': Size(360, 640),
    'typical (390×844)': Size(390, 844),
    'large (430×932)': Size(430, 932),
  };

  phones.forEach((String label, Size size) {
    testWidgets('every slide fits on a $label screen', (
      WidgetTester tester,
    ) async {
      await _pump(tester, size: size);
      await _walkAllSlides(tester);

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the slides survive a large accessibility text scale', (
    WidgetTester tester,
  ) async {
    // 1.5× is within what Android's font-size slider offers, so this is a real
    // user rather than a stress test.
    await _pump(tester, size: const Size(360, 640), textScale: 1.5);
    await _walkAllSlides(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping works as well as the button', (
    WidgetTester tester,
  ) async {
    // Buttons are blocked in the rest of onboarding because a half-swipe there
    // looks broken. A tour is different — everybody swipes a tour.
    await _pump(tester, size: const Size(390, 844));

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('take the points'), findsOneWidget);
  });

  testWidgets('the standalone tour closes on Done', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () => IntroTour.open(context),
              child: const Text('tour'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tour'));
    await tester.pumpAndSettle();
    await _walkAllSlides(tester);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('tour'), findsOneWidget);
    expect(find.textContaining('Ultimate Spotter'), findsNothing);
  });
}
