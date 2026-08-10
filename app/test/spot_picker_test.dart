import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/scorecard/spot_picker_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The claim path. This is the one interaction the whole game runs on, so it is
/// worth proving rather than eyeballing.
late final List<Species> _catalogue;

Scorecard _card() => Scorecard.start(
  <String>['Alex', 'Sam'],
  owner: 'Alex',
  now: DateTime(2026, 8, 2, 6),
);

/// Opens the picker and returns whatever it popped with.
Future<Species?> _pump(
  WidgetTester tester, {
  required Scorecard card,
  int player = 1,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  Species? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            result = await SpotPickerScreen.open(
              context,
              player: card.players[player],
              species: _catalogue,
              card: card,
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('asks the question in the player\'s name', (
    WidgetTester tester,
  ) async {
    // Player first, not animal first. In a car somebody shouts a name before
    // anyone knows what they are looking at.
    await _pump(tester, card: _card());

    expect(find.text('What did Sam spot?'), findsOneWidget);
    expect(find.text('0 points so far'), findsOneWidget);
  });

  testWidgets('shows what the player already has', (WidgetTester tester) async {
    final Scorecard card = _card();
    await _pump(
      tester,
      card: card.withClaim(
        Claim(
          speciesId: 'leopard',
          playerId: card.players[1].id,
          at: DateTime(2026, 8, 2, 7),
          points: 100,
        ),
      ),
    );

    expect(find.text('100 points so far'), findsOneWidget);
  });

  testWidgets('picking an animal returns it to the caller', (
    WidgetTester tester,
  ) async {
    Species? picked;
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final Scorecard card = _card();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              picked = await SpotPickerScreen.open(
                context,
                player: card.players[1],
                species: _catalogue,
                card: card,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Search first: the grid is lazy and only builds what is on screen.
    await tester.enterText(find.byType(TextField), 'Smutsia');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ground Pangolin'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'ground-pangolin');
    expect(picked?.points, 1000);
  });

  testWidgets('a spent species cannot be claimed again', (
    WidgetTester tester,
  ) async {
    // Greater Kudu is Common: four chances a day. Tapping it a fifth time must
    // do nothing rather than quietly score again.
    //
    // Deliberately not impala, which is its own case with two chances.
    Species? picked;
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final Scorecard card = _card();
    Scorecard spent = card;
    for (int i = 0; i < 4; i++) {
      spent = spent.withClaim(
        Claim(
          speciesId: 'greater-kudu',
          playerId: card.players[0].id,
          at: DateTime(2026, 8, 2, 7 + i),
          points: 5,
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              picked = await SpotPickerScreen.open(
                context,
                player: spent.players[1],
                species: _catalogue,
                card: spent,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'strepsiceros');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Greater Kudu'));
    await tester.pumpAndSettle();

    expect(picked, isNull, reason: 'the screen should still be open');
    expect(find.text('What did Sam spot?'), findsOneWidget);
  });
}
