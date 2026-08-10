import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/house_rules.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/species_category.dart';
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
/// Note on finding a specific species: the Codex is a grid, so only the first
/// dozen or so tiles are built. Tests that need a particular animal search for
/// it first rather than assuming it is on screen.
class _InMemoryRepository implements SpeciesRepository {
  const _InMemoryRepository(this.species);

  final List<Species> species;

  @override
  Future<List<Species>> loadAll({HouseRules rules = HouseRules.none}) async =>
      species;
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

  testWidgets('opens on the rarest species, not the first one', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    // A catalogue that opens on impala says "here is a list of animals". One
    // that opens on pangolin says "here is what you are hunting for".
    expect(find.text('Rarest first'), findsOneWidget);
    expect(find.text('Ground Pangolin'), findsOneWidget);
    expect(
      find.text('Impala'),
      findsNothing,
      reason: 'the common end is at the bottom, unbuilt',
    );
  });

  testWidgets('sorting cycles back to dex order', (WidgetTester tester) async {
    await _pumpCodex(tester);

    await tester.tap(find.text('Rarest first'));
    await tester.pumpAndSettle();

    // Dex numbers are permanent identities — mammals, then birds, then
    // reptiles, alphabetical within each. Aardvark is and stays 001.
    expect(find.text('Dex order'), findsOneWidget);
    expect(find.text('001'), findsOneWidget);
    expect(find.text('Aardvark'), findsOneWidget);
  });

  testWidgets('the park boundary is stated at the foot of the dex', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    // Filtered to one tile so the footer is on screen without scrolling 70
    // cards.
    await _search(tester, 'Smutsia');

    expect(find.text('Kruger only, for now'), findsOneWidget);
    expect(find.textContaining('Okavango Delta'), findsOneWidget);
  });

  testWidgets('every tile shows a dex number, tier name and points', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    await _search(tester, 'Smutsia');

    expect(find.text('Ground Pangolin'), findsOneWidget);
    expect(find.textContaining('0'), findsWidgets);
    expect(find.text('1000'), findsOneWidget);
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
    // Wider than it looks like it needs to be: the quick-filter row is a lazy
    // ListView, so a chip past the right edge is never built and no finder can
    // reach it. Every tag that becomes filterable pushes the categories
    // further right.
    await _pumpCodex(tester, width: 2000);

    await _tapQuickFilter(tester, 'Birds');

    // Asserted as a property of everything on screen rather than by naming one
    // bird. It used to expect the fish eagle, on the grounds that it was the
    // first bird in the order — which stopped being true the moment the bird
    // list went from thirty-one to a hundred and twenty-four, and failed as a
    // *layout* accident rather than as a filtering bug. What the filter
    // promises is that nothing else gets through.
    final Iterable<SpeciesGridCard> shown = tester.widgetList<SpeciesGridCard>(
      find.byType(SpeciesGridCard),
    );

    expect(shown, isNotEmpty);
    for (final SpeciesGridCard card in shown) {
      expect(
        card.species.category,
        SpeciesCategory.bird,
        reason: card.species.commonName,
      );
    }
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
    await _pumpCodex(tester, width: 2000);

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

    // Tier appears twice: as a header pill and in the points banner.
    expect(find.text('LEGENDARY'), findsOneWidget);
    expect(find.text('Legendary'), findsOneWidget);
    // Field notes and distribution are tabs now, not stacked sections.
    expect(find.text('Where to find'), findsOneWidget);
    expect(find.text('Field notes'), findsOneWidget);

    // Pangolin is one of the four species with no published number, and the
    // card says so rather than leaving a gap.
    expect(find.text('Not published'), findsOneWidget);

    // Scrolled last, because the About tab is a ListView: the population card
    // pushes the Afrikaans name below the fold on a phone, and dragging takes
    // the points banner off the top.
    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Ietermagog'), findsOneWidget);
  });

  testWidgets('the catalogue is split into animals then birds', (
    WidgetTester tester,
  ) async {
    // One continuous grid was right at 127 species. At 191 — 124 of them birds
    // — rarest-first buried every ordinary mammal below a hundred birds.
    await _pumpCodex(tester);

    // Animals open the catalogue, and nothing on the first screen is a bird.
    expect(find.text('ANIMALS'), findsOneWidget);
    for (final SpeciesGridCard card in tester.widgetList<SpeciesGridCard>(
      find.byType(SpeciesGridCard),
    )) {
      expect(
        card.species.category,
        isNot(SpeciesCategory.bird),
        reason: '${card.species.commonName} is on the first screen',
      );
    }

    // Birds are down there, past sixty-odd animals. Scrolled to rather than
    // asserted by position: the list is lazy, so a heading below the fold is
    // not built at all.
    // Named explicitly: the quick-filter row is a Scrollable too, so an
    // unqualified scroll cannot tell which one is meant.
    await tester.scrollUntilVisible(
      find.text('BIRDS'),
      600,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('BIRDS'), findsOneWidget);
  });

  testWidgets('one group on its own needs no heading', (
    WidgetTester tester,
  ) async {
    // Filtering to Birds already says what you are looking at. A heading over
    // the only group on screen is furniture.
    await _pumpCodex(tester, width: 2000);
    await _tapQuickFilter(tester, 'Birds');

    expect(find.text('BIRDS'), findsNothing);
    expect(find.text('ANIMALS'), findsNothing);
  });

  group('the ranked list', () {
    testWidgets('is behind a toggle, and the grid is what opens', (
      WidgetTester tester,
    ) async {
      await _pumpCodex(tester);

      expect(find.byType(SpeciesGridCard), findsWidgets);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
    });

    testWidgets('swaps the grid for a numbered ranking', (
      WidgetTester tester,
    ) async {
      await _pumpCodex(tester);
      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pumpAndSettle();

      // The grid is gone, and the toggle now offers the way back.
      expect(find.byType(SpeciesGridCard), findsNothing);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // Numbered from one, rarest at the top.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Ground Pangolin'), findsOneWidget);
    });

    testWidgets('ignores the Animals and Birds split', (
      WidgetTester tester,
    ) async {
      // A ranking with two number ones is not a ranking. The grid groups
      // because it is for browsing; this is for comparing.
      await _pumpCodex(tester);
      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pumpAndSettle();

      expect(find.text('ANIMALS'), findsNothing);
      expect(find.text('BIRDS'), findsNothing);
    });

    testWidgets('stays rarest-first even when the grid is sorted otherwise', (
      WidgetTester tester,
    ) async {
      // Rarest-first is the only order in which a ranking means anything, so
      // the list ignores the sort rather than quietly renumbering by name.
      await _pumpCodex(tester);
      await tester.tap(find.text('Rarest first'));
      await tester.pumpAndSettle();
      expect(find.text('Dex order'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pumpAndSettle();

      // Compared by position rather than by presence: the aardvark is
      // Legendary, so it is near the top of the ranking too and an
      // absence check would pass for the wrong reason. In dex order it would
      // be number one.
      expect(
        tester.getTopLeft(find.text('Ground Pangolin')).dy,
        lessThan(tester.getTopLeft(find.text('Aardvark')).dy),
      );
    });
  });

  testWidgets('a species with a real figure shows it, and says where from', (
    WidgetTester tester,
  ) async {
    // The other half of the population card. The pangolin covers the withheld
    // branch; without this one, the branch that draws an actual number could
    // break and every test would still pass.
    await _pumpCodex(tester);
    await _search(tester, 'Alcelaphus');
    await tester.tap(find.text("Lichtenstein's Hartebeest"));
    await tester.pumpAndSettle();

    expect(find.text('HOW MANY ARE IN THE PARK'), findsOneWidget);
    expect(find.text('40 – 75'), findsOneWidget);
    // Provenance is not decoration: a number this small is a claim without it.
    expect(find.text('Aerial survey, 2023'), findsOneWidget);
  });

  testWidgets('sensitive species show the protection notice', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);
    await _search(tester, 'Smutsia');
    await tester.tap(find.text('Ground Pangolin'));
    await tester.pumpAndSettle();

    // docs/VISION.md non-negotiable.
    expect(find.textContaining('never record a location'), findsOneWidget);
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

    expect(find.textContaining('never record a location'), findsNothing);
    expect(find.text('Rooibok'), findsOneWidget);
  });
}
