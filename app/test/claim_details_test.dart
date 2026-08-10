import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/sighting_context.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/scorecard/claim_details_sheet.dart';
import 'package:wildscore/shared/theme.dart';

/// This sheet sits between somebody shouting and the points landing, so it has
/// to be fast, and it must never appear for an animal where the answer changes
/// nothing.
late final List<Species> _catalogue;

Species _byId(String id) => _catalogue.firstWhere((Species s) => s.id == id);

Future<ClaimDetails?> _open(
  WidgetTester tester,
  Species species, {
  Size size = const Size(430, 950),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  ClaimDetails? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await ClaimDetailsSheet.ask(context, species);
            },
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('an ordinary animal is never asked about', (
    WidgetTester tester,
  ) async {
    // The whole point of the bar. Tapping through a sheet for every impala
    // would make the game slower than a pen and paper.
    expect(ClaimDetailsSheet.needed(_byId('impala')), isFalse);

    final ClaimDetails? result = await _open(tester, _byId('impala'));

    expect(find.text('Claim it'), findsNothing);
    expect(result?.context, SightingContext.normal);
    expect(result?.variant, isFalse);
  });

  testWidgets('a leopard is asked who else was there, and nothing else', (
    WidgetTester tester,
  ) async {
    await _open(tester, _byId('leopard'));

    expect(find.text('Who else was there?'), findsOneWidget);
    expect(find.text('Lone sighting'), findsOneWidget);
    expect(find.text('Part of a jam'), findsOneWidget);
    // Two marks, not a three-way choice: the ordinary sighting is the absence
    // of both and needs no answer.
    expect(find.text('We spotted it'), findsNothing);
    // No variant on a leopard, so no second question.
    expect(find.textContaining('Was it a male'), findsNothing);
  });

  testWidgets('a lion is asked both questions', (WidgetTester tester) async {
    await _open(tester, _byId('lion'));

    expect(find.text('Was it a male?'), findsOneWidget);
    expect(find.text('Who else was there?'), findsOneWidget);
  });

  /// The running total in the header, told apart from the numbers the crowd
  /// buttons now carry.
  Finder total() => find.descendant(
    of: find.byType(AnimatedSwitcher),
    matching: find.byType(Text),
  );

  testWidgets('the total moves as the answers change', (
    WidgetTester tester,
  ) async {
    // Watching the number move is what teaches the rule — nobody reads a rules
    // screen, and this is the moment the rule is relevant.
    await _open(tester, _byId('lion'));
    expect(tester.widget<Text>(total()).data, '115');

    await tester.tap(find.text('Yes — male'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(total()).data, '173');

    // Lone is a mark, not a multiplier: the total holds at what the card says.
    await tester.tap(find.text('Lone sighting'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(total()).data, '173');

    await tester.tap(find.text('Part of a jam'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(total()).data, '139');
  });

  testWidgets('each crowd button shows what it would pay', (
    WidgetTester tester,
  ) async {
    // The buttons used to read "Lone sighting … Double" side by side at half
    // the sheet's width, which ellipsed the label — the owner could not read
    // his own buttons. They are full width now and carry the arithmetic, so
    // the choice is made against real numbers rather than a total that moves
    // after you commit.
    await _open(tester, _byId('lion'));
    await tester.tap(find.text('Yes — male'));
    await tester.pumpAndSettle();

    // 173 on the lone button, and the jam button showing its working.
    expect(find.text('173 − 20%'), findsOneWidget);
    expect(find.text('139'), findsOneWidget);
    expect(find.text('You spotted it yourself'), findsOneWidget);
    expect(find.text('Cars were already there'), findsOneWidget);
  });

  testWidgets('neither crowd label is truncated on a small phone', (
    WidgetTester tester,
  ) async {
    // The bug this replaces was invisible to every existing test: the widget
    // was present and findable, it just rendered as "Lone sig…".
    await _open(tester, _byId('leopard'), size: const Size(360, 780));

    for (final String label in <String>['Lone sighting', 'Part of a jam']) {
      final Text text = tester.widget<Text>(find.text(label));
      expect(text.overflow, isNot(TextOverflow.ellipsis), reason: label);
      expect(text.maxLines, isNull, reason: label);
      expect(
        tester.getSize(find.text(label)).width,
        lessThan(tester.getSize(find.byType(Scaffold)).width),
        reason: label,
      );
    }
  });

  testWidgets('the answers come back to the caller', (
    WidgetTester tester,
  ) async {
    ClaimDetails? result;
    await tester.binding.setSurfaceSize(const Size(430, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await ClaimDetailsSheet.ask(context, _byId('lion'));
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yes — male'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lone sighting'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claim it'));
    await tester.pumpAndSettle();

    expect(result?.variant, isTrue);
    expect(result?.context, SightingContext.alone);
  });

  testWidgets('dismissing it cancels rather than scoring an ordinary one', (
    WidgetTester tester,
  ) async {
    // Backing out of a half-finished claim must not quietly bank points, which
    // is why `ask` returns null rather than ClaimDetails.ordinary.
    ClaimDetails? result;
    bool returned = false;
    await tester.binding.setSurfaceSize(const Size(430, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await ClaimDetailsSheet.ask(context, _byId('leopard'));
                returned = true;
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.text('Claim it'))).pop();
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(result, isNull);
  });
}
