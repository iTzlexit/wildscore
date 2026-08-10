import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/scorecard/standings_board.dart';
import 'package:wildscore/shared/theme.dart';

/// Tapping an animal in somebody's haul used to go straight to "Take it back?".
/// Two things were wrong with that: on a finished drive the tag did nothing at
/// all, and on a live one the only thing you could do to the leopard you had
/// just found was delete it.
late final List<Species> _catalogue;

Scorecard _card({String species = 'leopard'}) {
  final Scorecard card = Scorecard.start(
    <String>['Alex', 'Sam'],
    owner: 'Alex',
    now: DateTime(2026, 8, 3),
  );
  final Player sam = card.players.firstWhere((Player p) => p.name == 'Sam');
  return card.withClaim(
    Claim(
      speciesId: species,
      playerId: sam.id,
      at: DateTime(2026, 8, 3, 8),
      points: 300,
      road: 'S100',
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  void Function(Player, Species)? onRemove,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StandingsBoard(
            card: _card(),
            species: _catalogue,
            expanded: true,
            onRemoveClaim: onRemove,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('the haul tag offers both viewing and removing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, onRemove: (Player _, Species _) {});

    await tester.tap(find.text('Leopard'));
    await tester.pumpAndSettle();

    expect(find.text('View this animal'), findsOneWidget);
    expect(find.text('Remove from Sam'), findsOneWidget);
  });

  testWidgets('choosing to view opens the species card', (
    WidgetTester tester,
  ) async {
    await _pump(tester, onRemove: (Player _, Species _) {});

    await tester.tap(find.text('Leopard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View this animal'));
    await tester.pumpAndSettle();

    // The card, not the standings: the binomial only exists on the detail
    // screen.
    expect(find.text('Panthera pardus'), findsOneWidget);
  });

  testWidgets('choosing to remove hands the claim back to the caller', (
    WidgetTester tester,
  ) async {
    final List<String> removed = <String>[];
    await _pump(
      tester,
      onRemove: (Player p, Species s) => removed.add('${p.name}/${s.id}'),
    );

    await tester.tap(find.text('Leopard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from Sam'));
    await tester.pumpAndSettle();

    expect(removed, <String>['Sam/leopard']);
  });

  testWidgets('on a finished drive the tag opens the animal directly', (
    WidgetTester tester,
  ) async {
    // History is not editable, so there is no choice to offer — and a menu
    // with one item is not a menu.
    await _pump(tester);

    await tester.tap(find.text('Leopard'));
    // Twice: the card waits on the photo credits before it pushes, and that
    // load completes off the frame loop rather than on it.
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.text('View this animal'), findsNothing);
    expect(find.text('Panthera pardus'), findsOneWidget);
  });
}
