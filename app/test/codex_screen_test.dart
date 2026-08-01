import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/codex/codex_screen.dart';
import 'package:wildscore/features/codex/species_detail_screen.dart';
import 'package:wildscore/features/codex/widgets/species_grid_card.dart';
import 'package:wildscore/shared/theme.dart';

/// Behaviour tests for the Codex.
///
/// These are the regression net: run them before merging anything. They assert
/// what a user can actually do, not how it is implemented.
///
/// The catalogue is read from disk exactly once, in `setUpAll`, which runs in
/// real async. Each test then gets it from memory. Reading the asset inside
/// `testWidgets` does not work reliably — that code runs in a fake-async zone
/// where real file I/O may never complete.
///
/// Note on finding a specific species: the Codex is a grid in dex order, so
/// only the first dozen or so tiles are built. Tests that need a particular
/// animal search for it first rather than assuming it is on screen.
class _InMemoryRepository implements SpeciesRepository {
  const _InMemoryRepository(this.species);

  final List<Species> species;

  @override
  Future<List<Species>> loadAll() async => species;
}

late final List<Species> _catalogue;

Future<void> _pumpCodex(WidgetTester tester, {double width = 430}) async {
  await tester.binding.setSurfaceSize(Size(width, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: CodexScreen(repository: _InMemoryRepository(_catalogue)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Filters the grid down to one species, so it is guaranteed to be built.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

/// Taps a chip in the horizontal quick-filter row.
///
/// Tests that use this pump a **wide** surface. The row is a lazy [ListView],
/// so a chip past the right edge has not been built at all — no finder can see
/// it, and both `ensureVisible` and `dragUntilVisible` throw rather than
/// scrolling to it. Widening the surface sidesteps that, and is honest: these
/// tests are about whether filtering works, not about whether a chip is
/// reachable on a phone. It is reachable — the row scrolls.
Future<void> _tapQuickFilter(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('renders the Codex grid with a species count', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    // No screen title — the tab already says "Animal Dex".
    expect(find.text('Codex'), findsNothing);
    expect(find.byType(SpeciesGridCard), findsWidgets);
    // Rarity is a first-class filter row now, not buried in the panel.
    expect(find.text('Any rarity'), findsOneWidget);
  });

  testWidgets('lists species in dex order, starting at No. 001', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    // Dex numbers are permanent identities — mammals, then birds, then
    // reptiles, alphabetical within each. Aardvark is and stays 001.
    expect(find.text('001'), findsOneWidget);
    expect(find.text('Aardvark'), findsOneWidget);
  });

  testWidgets('every tile shows a dex number, tier name and points', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    await _search(tester, 'Smutsia');

    expect(find.text('Ground Pangolin'), findsOneWidget);
    expect(find.text('025'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    // The tier name is the most explicit rarity channel — the other five
    // require the player to have learned the system first.
    expect(find.text('LEGENDARY'), findsOneWidget);
  });

  testWidgets('filters by collection group', (WidgetTester tester) async {
    await _pumpCodex(tester, width: 1400);

    await tester.tap(find.text('Big Five'));
    await tester.pumpAndSettle();

    expect(find.text('African Elephant'), findsOneWidget);
    expect(find.text('Aardvark'), findsNothing);
  });

  testWidgets('predators filter excludes herbivores', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester, width: 1400);

    // The group row scrolls horizontally and Predators sits past the right
    // edge on a 430pt screen, so it has to be scrolled to first.
    await tester.ensureVisible(find.text('Predators'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predators'));
    await tester.pumpAndSettle();
    await _search(tester, 'rooibok');

    expect(find.text('Impala'), findsNothing);
  });

  testWidgets('searches by Afrikaans name', (WidgetTester tester) async {
    await _pumpCodex(tester);
    await _search(tester, 'rooibok');

    expect(find.text('Impala'), findsOneWidget);
    expect(find.text('Aardvark'), findsNothing);
  });

  testWidgets('searches by scientific name', (WidgetTester tester) async {
    await _pumpCodex(tester);
    await _search(tester, 'Panthera');

    expect(find.text('Lion'), findsOneWidget);
    expect(find.text('Leopard'), findsOneWidget);
  });

  testWidgets('search is case-insensitive', (WidgetTester tester) async {
    await _pumpCodex(tester);
    await _search(tester, 'CHEETAH');

    expect(find.text('Cheetah'), findsOneWidget);
  });

  testWidgets('filters by category', (WidgetTester tester) async {
    await _pumpCodex(tester, width: 1400);

    await _tapQuickFilter(tester, 'Birds');

    // Birds occupy No. 056–066; African Fish Eagle is the first alphabetically.
    expect(find.text('African Fish Eagle'), findsOneWidget);
    expect(find.text('Aardvark'), findsNothing);
  });

  testWidgets('shows an empty state when nothing matches', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    await _search(tester, 'zzzznotananimal');

    expect(find.text('Nothing matches'), findsOneWidget);
    expect(find.byType(SpeciesGridCard), findsNothing);
  });

  testWidgets('clear filters restores the full list', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester, width: 1400);

    await _tapQuickFilter(tester, 'Birds');
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('Clear filters'), findsNothing);
    expect(find.text('Aardvark'), findsOneWidget);
  });

  testWidgets('the filter panel exposes region and rarity', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    expect(find.text('PARK REGION'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('PARK REGION'), findsOneWidget);
    expect(find.text('Anywhere'), findsOneWidget);
  });

  testWidgets('filtering by northern region excludes southern-only species', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Northern'));
    await tester.pumpAndSettle();
    await _search(tester, 'rhino');

    // Both rhino concentrate in the south and centre. This is the app's core
    // promise: telling you where to actually drive.
    expect(find.text('White Rhinoceros'), findsNothing);
    expect(find.text('Black Rhinoceros'), findsNothing);
  });

  testWidgets('tapping a species opens its detail screen', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    await _search(tester, 'Smutsia');
    await tester.tap(find.text('Ground Pangolin'));
    await tester.pumpAndSettle();

    expect(find.byType(SpeciesDetailScreen), findsOneWidget);
    expect(find.text('Smutsia temminckii'), findsWidgets);
    expect(find.text('Ietermagog'), findsOneWidget);
    // Tier appears twice: as a header pill and in the points banner.
    expect(find.text('LEGENDARY'), findsOneWidget);
    expect(find.text('Legendary'), findsOneWidget);
    // Field notes and distribution are tabs now, not stacked sections.
    expect(find.text('Where to find'), findsOneWidget);
    expect(find.text('Field notes'), findsOneWidget);
  });

  testWidgets('sensitive species show the protection notice', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    await _search(tester, 'Smutsia');
    await tester.tap(find.text('Ground Pangolin'));
    await tester.pumpAndSettle();

    // docs/VISION.md non-negotiable.
    expect(find.textContaining('never show a location'), findsOneWidget);
  });

  testWidgets('non-sensitive species show no protection notice', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    // Search the Afrikaans name so the query text does not itself match
    // 'Impala' — otherwise the finder hits both the tile and the search field.
    await _search(tester, 'rooibok');
    await tester.tap(find.text('Impala'));
    await tester.pumpAndSettle();

    expect(find.textContaining('never show a location'), findsNothing);
    expect(find.text('Rooibok'), findsOneWidget);
  });
}
