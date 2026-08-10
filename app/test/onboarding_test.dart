import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/domain/tracker_profile.dart';
import 'package:wildscore/features/onboarding/onboarding_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The first twenty seconds of the app. If this breaks, nobody reaches
/// anything else, so it is worth covering properly.
void main() {
  late TrackerProfile? completed;

  Future<void> pumpOnboarding(WidgetTester tester) async {
    completed = null;
    await tester.binding.setSurfaceSize(const Size(430, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: OnboardingScreen(onComplete: (TrackerProfile p) => completed = p),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Straight past the tour to the part every other test is about.
  Future<void> skipTour(WidgetTester tester) async {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the tour, not on a form', (WidgetTester tester) async {
    await pumpOnboarding(tester);

    // The opening line asks a question rather than diagnosing a problem. It
    // used to lead with "six hours of driving, and nothing to show for it",
    // which greets somebody at a gate at six in the morning by telling them
    // their last holiday was a disappointment.
    // Twice on the slide — the heading asks it, the body answers it. That is
    // the owner's copy and the repetition is the callback.
    expect(find.textContaining('Ultimate Kruger Spotter'), findsWidgets);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    // Nobody is asked for anything before they know what this is.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the tour walks all four slides to the name step', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('How it works'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    // The quiz, taught rather than discovered: without this slide the first
    // reaction to a badge appearing on a name is "what is that".
    expect(find.text('Score well, earn a question'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ultimate Spotter'), findsOneWidget);
    // Last slide swaps Next for the way in, and drops Skip.
    expect(find.text('Next'), findsNothing);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Let\'s go'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('the rarity table is generated, not typed', (
    WidgetTester tester,
  ) async {
    // Every tier and its real value, so a revalued tier cannot leave the sales
    // pitch promising something the game no longer pays.
    await pumpOnboarding(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    for (final RarityTier tier in RarityTier.values) {
      expect(find.text(tier.label), findsOneWidget, reason: tier.name);
      // A band, not one number — every animal in a tier stopped scoring the
      // same the moment the catalogue was ranked by hand.
      expect(
        find.text('${tier.low}–${tier.high}'),
        findsWidgets,
        reason: tier.name,
      );
    }
  });

  testWidgets('Skip moves to the name step', (WidgetTester tester) async {
    await pumpOnboarding(tester);

    await skipTour(tester);

    expect(find.textContaining('call you'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('an empty name is rejected and does not advance', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);
    await skipTour(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Every tracker needs a name.'), findsOneWidget);
    expect(find.text('Enter the park'), findsNothing);
    expect(completed, isNull);
  });

  testWidgets('a one-character name is rejected', (WidgetTester tester) async {
    await pumpOnboarding(tester);
    await skipTour(tester);

    await tester.enterText(find.byType(TextField), 'A');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('at least'), findsOneWidget);
    expect(completed, isNull);
  });

  testWidgets('the error clears as soon as you type again', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);
    await skipTour(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Every tracker needs a name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Al');
    await tester.pumpAndSettle();
    expect(find.text('Every tracker needs a name.'), findsNothing);
  });

  testWidgets('a valid name reveals the tracker card', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);
    await skipTour(tester);

    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('TRACKER'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('SPECIES'), findsOneWidget);
    expect(find.text('Enter the park'), findsOneWidget);
  });

  testWidgets('entering the park hands back the finished profile', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);
    await skipTour(tester);
    await tester.enterText(find.byType(TextField), '  Alex  ');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter the park'));
    await tester.pumpAndSettle();

    expect(completed, isNotNull);
    expect(completed!.name, 'Alex', reason: 'name should be sanitised');
    expect(completed!.seasonYear, DateTime.now().year);
  });
}
