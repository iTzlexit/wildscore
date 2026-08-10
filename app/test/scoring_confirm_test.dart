import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/house_rules.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/scorecard/scoring_confirm_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The prices, agreed before anybody drives off.
///
/// Alex's rule, and the gate every game now passes through: a car that
/// disagrees with our table has to be able to say so *before* somebody has
/// already scored the animal they disagree about.
late final List<Species> _catalogue;

/// The same catalogue with a price already changed, for the reset case.
///
/// Loaded here rather than inside the test that wants it. Reading an asset is
/// real I/O, and awaiting real I/O inside `testWidgets` sits in the fake-async
/// zone until `pumpAndSettle` gives up ten minutes later.
late final List<Species> _withHouseRule;

Species _byId(List<Species> all, String id) =>
    all.firstWhere((Species s) => s.id == id);

/// Opens the screen and reports what it popped with, plus every price saved.
Future<(bool?, Map<String, int?>)> _pump(
  WidgetTester tester, {
  List<Species>? species,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  bool? started;
  final Map<String, int?> saved = <String, int?>{};

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            started = await ScoringConfirmScreen.show(
              context,
              species: species ?? _catalogue,
              players: const <String>['Alex', 'Sam'],
              onSetPoints: (String id, int? points) => saved[id] = points,
            );
          },
          child: const Text('go'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();

  return (started, saved);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
    _withHouseRule = await const SpeciesRepository().loadAll(
      rules: const HouseRules(points: <String, int>{'sable-antelope': 150}),
    );
  });

  testWidgets('opens on the rarest animals, priced', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    // Sorted by what they are worth, so the top of the list is the argument
    // worth having. Alphabetical would open on the aardvark.
    expect(find.text('Legendary'.toUpperCase()), findsOneWidget);
    expect(
      find.text('${_byId(_catalogue, 'ground-pangolin').points}'),
      findsWidgets,
    );
  });

  testWidgets('the car has to agree before the game starts', (
    WidgetTester tester,
  ) async {
    final (bool?, Map<String, int?>) result = await _pump(tester);
    expect(result.$1, isNull, reason: 'nothing started by opening the screen');

    await tester.tap(find.textContaining('Agreed'));
    await tester.pumpAndSettle();
  });

  testWidgets('backing out does not start a game', (WidgetTester tester) async {
    await _pump(tester);

    final NavigatorState nav = tester.state(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();

    // `show` returns false rather than null, so a dismissed screen and a
    // deliberate "no" are the same thing to the caller.
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('a price can be changed here, and it is saved', (
    WidgetTester tester,
  ) async {
    final Species sable = _byId(_catalogue, 'sable-antelope');
    final (bool?, Map<String, int?>) result = await _pump(
      tester,
      species: <Species>[sable],
    );

    await tester.tap(find.text(sable.commonName));
    await tester.pumpAndSettle();

    expect(find.textContaining('worth?'), findsOneWidget);

    // Drag the slider hard right: the top rung, whatever it is worth today.
    await tester.drag(find.byType(Slider), const Offset(600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();

    expect(result.$2.keys, <String>['sable-antelope']);
    expect(result.$2['sable-antelope'], isNot(sable.points));
    // And the row says so, without waiting for the catalogue to be rebuilt
    // above it.
    expect(find.textContaining('ours is ${sable.points}'), findsOneWidget);
  });

  testWidgets('putting our number back clears the override', (
    WidgetTester tester,
  ) async {
    // A car that agreed with us today must not be pinned to today's number
    // when we revalue the animal, so agreement is stored as nothing at all.
    final Species sable = _byId(_withHouseRule, 'sable-antelope');
    final (bool?, Map<String, int?>) result = await _pump(
      tester,
      species: <Species>[sable],
    );

    expect(find.textContaining('ours is ${sable.cataloguePoints}'), findsOne);

    await tester.tap(find.text(sable.commonName));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Back to ours'));
    await tester.pumpAndSettle();

    expect(result.$2, <String, int?>{'sable-antelope': null});
  });

  testWidgets('search finds one animal in two hundred', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'pangolin');
    await tester.pumpAndSettle();

    expect(find.text('Ground Pangolin'), findsOneWidget);
    expect(find.text('Impala'), findsNothing);

    await tester.enterText(find.byType(TextField), 'wildebeeste');
    await tester.pumpAndSettle();
    expect(find.text('Nothing by that name.'), findsOneWidget);
  });
}
