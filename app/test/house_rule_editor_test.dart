import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/rarity_tier.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/codex/species_detail_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The control that lets a car set its own prices.
///
/// It sits on the species card, behind one tap, and it is the only place in the
/// app where a player changes a rule. That makes two things worth guarding: it
/// must not be reachable where the table is read-only, and an edit must always
/// be visible and undoable.
late final List<Species> _catalogue;

Species _byId(String id) => _catalogue.firstWhere((Species s) => s.id == id);

Future<void> _open(
  WidgetTester tester,
  Species species, {
  ValueChanged<int?>? onSetPoints,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: SpeciesDetailScreen(species: species, onSetPoints: onSetPoints),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('is absent where the table is read-only', (
    WidgetTester tester,
  ) async {
    // The sightings feed and the scorecard both open this card, and neither is
    // a place to be rewriting the rules mid-drive.
    await _open(tester, _byId('sable-antelope'));

    expect(find.textContaining('Worth something else'), findsNothing);
  });

  testWidgets('offers itself quietly, then opens on a tap', (
    WidgetTester tester,
  ) async {
    await _open(tester, _byId('sable-antelope'), onSetPoints: (int? _) {});

    expect(find.text('Worth something else to you?'), findsOneWidget);
    // Closed by default: a slider sitting open on every species card would
    // read as the main event on a screen that is mostly a field guide.
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.text('Worth something else to you?'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('WORTH IN YOUR GAME'), findsOneWidget);
  });

  testWidgets('moves in rungs, never to an arbitrary number', (
    WidgetTester tester,
  ) async {
    // Free numbers would let somebody put an impala on 999 and quietly wreck
    // their own game. These are the same rungs every animal already sits on.
    await _open(tester, _byId('sable-antelope'), onSetPoints: (int? _) {});
    await tester.tap(find.text('Worth something else to you?'));
    await tester.pumpAndSettle();

    final Slider slider = tester.widget<Slider>(find.byType(Slider));

    expect(slider.divisions, RarityTier.allRungs.length - 1);
    expect(slider.max, (RarityTier.allRungs.length - 1).toDouble());
  });

  testWidgets('hands back the chosen value', (WidgetTester tester) async {
    int? given;
    bool called = false;
    final Species sable = _byId('sable-antelope');

    await _open(
      tester,
      sable,
      onSetPoints: (int? v) {
        given = v;
        called = true;
      },
    );
    await tester.tap(find.text('Worth something else to you?'));
    await tester.pumpAndSettle();

    // Drag to the far left, which is the bottom rung of the whole ladder.
    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(given, RarityTier.allRungs.first);
    expect(given, isNot(sable.points));
  });

  testWidgets('choosing the catalogue value stores nothing', (
    WidgetTester tester,
  ) async {
    // An override equal to the default would survive a future revaluation and
    // silently pin the old number — so it is stored as "no opinion" instead.
    int? given = -1;
    await _open(
      tester,
      _byId('sable-antelope'),
      onSetPoints: (int? v) => given = v,
    );
    await tester.tap(find.text('Worth something else to you?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();

    expect(given, isNull);
  });

  testWidgets('an edited species says so, and offers the way back', (
    WidgetTester tester,
  ) async {
    final Species edited = _byId('sable-antelope').copyWith(housePoints: 150);
    int? given = -1;

    expect(edited.isHouseRule, isTrue);
    await _open(tester, edited, onSetPoints: (int? v) => given = v);

    // Visible without opening anything: an edit you cannot see is a trap.
    expect(
      find.text('You changed this from ${edited.cataloguePoints}'),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('You changed this'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset to ${edited.cataloguePoints}'));
    await tester.pumpAndSettle();

    expect(given, isNull);
  });
}
