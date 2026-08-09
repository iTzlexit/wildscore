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

Future<ClaimDetails?> _open(WidgetTester tester, Species species) async {
  await tester.binding.setSurfaceSize(const Size(430, 950));
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

  testWidgets('the total moves as the answers change', (
    WidgetTester tester,
  ) async {
    // Watching the number move is what teaches the rule — nobody reads a rules
    // screen, and this is the moment the rule is relevant.
    await _open(tester, _byId('lion'));
    expect(find.text('40'), findsOneWidget);

    await tester.tap(find.text('Yes — male'));
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);

    await tester.tap(find.text('Lone sighting'));
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);

    await tester.tap(find.text('Part of a jam'));
    await tester.pumpAndSettle();
    expect(find.text('75'), findsOneWidget);
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
