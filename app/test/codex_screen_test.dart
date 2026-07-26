import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/codex/codex_screen.dart';
import 'package:wildscore/features/codex/species_detail_screen.dart';
import 'package:wildscore/features/codex/widgets/species_card.dart';
import 'package:wildscore/shared/theme.dart';

/// Behaviour tests for the Codex.
///
/// These are the regression net: run them before merging anything. They assert
/// what a user can actually do, not how it is implemented, so they should
/// survive refactoring and only fail when something genuinely broke.
///
/// The catalogue is read from disk exactly once, in `setUpAll`, which runs in
/// real async. Each test then gets it from memory. Reading the asset inside
/// `testWidgets` does not work reliably — that code runs in a fake-async zone
/// where real file I/O may never complete, which made the suite pass one test
/// at a time and time out when run together.
class _InMemoryRepository implements SpeciesRepository {
  const _InMemoryRepository(this.species);

  final List<Species> species;

  @override
  Future<List<Species>> loadAll() async => species;
}

late final List<Species> _catalogue;

Future<void> _pumpCodex(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: CodexScreen(repository: _InMemoryRepository(_catalogue)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });
  testWidgets('renders the Codex with a species count', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    expect(find.text('Codex'), findsOneWidget);
    expect(find.text('KRUGER NATIONAL PARK'), findsOneWidget);
    expect(find.textContaining('species'), findsWidgets);
    expect(find.byType(SpeciesCard), findsWidgets);
  });

  testWidgets('shows the rarest species first', (WidgetTester tester) async {
    await _pumpCodex(tester);

    // Legendary tier sorts to the top. If someone changes the sort, the first
    // thing a new user sees becomes forty impala — worth catching.
    expect(find.text('Ground Pangolin'), findsOneWidget);
    expect(find.text('500'), findsWidgets);
    expect(find.text('Impala'), findsNothing);
  });

  testWidgets('searches by Afrikaans name', (WidgetTester tester) async {
    await _pumpCodex(tester);

    await tester.enterText(find.byType(TextField), 'rooibok');
    await tester.pumpAndSettle();

    expect(find.text('Impala'), findsOneWidget);
    expect(find.text('Ground Pangolin'), findsNothing);
  });

  testWidgets('searches by scientific name', (WidgetTester tester) async {
    await _pumpCodex(tester);

    await tester.enterText(find.byType(TextField), 'Panthera');
    await tester.pumpAndSettle();

    expect(find.text('Lion'), findsOneWidget);
    expect(find.text('Leopard'), findsOneWidget);
  });

  testWidgets('search is case-insensitive', (WidgetTester tester) async {
    await _pumpCodex(tester);

    await tester.enterText(find.byType(TextField), 'CHEETAH');
    await tester.pumpAndSettle();

    expect(find.text('Cheetah'), findsOneWidget);
  });

  testWidgets('filters by category', (WidgetTester tester) async {
    await _pumpCodex(tester);

    await tester.tap(find.text('Birds'));
    await tester.pumpAndSettle();

    expect(find.text("Pel's Fishing Owl"), findsOneWidget);
    expect(find.text('Ground Pangolin'), findsNothing);
  });

  testWidgets('shows an empty state when nothing matches', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    await tester.enterText(find.byType(TextField), 'zzzznotananimal');
    await tester.pumpAndSettle();

    expect(find.text('Nothing matches'), findsOneWidget);
    expect(find.byType(SpeciesCard), findsNothing);
  });

  testWidgets('clear filters restores the full list', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    await tester.tap(find.text('Birds'));
    await tester.pumpAndSettle();
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('Clear filters'), findsNothing);
    expect(find.text('Ground Pangolin'), findsOneWidget);
  });

  testWidgets('the filter panel exposes region and rarity', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    expect(find.text('PARK REGION'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('PARK REGION'), findsOneWidget);
    expect(find.text('RARITY'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField), 'rhino');
    await tester.pumpAndSettle();

    // Both rhino concentrate in the south and centre — neither should appear
    // under a northern filter. This is the app's core promise: telling you
    // where to actually drive.
    expect(find.text('White Rhinoceros'), findsNothing);
    expect(find.text('Black Rhinoceros'), findsNothing);
  });

  testWidgets('tapping a species opens its detail screen', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    await tester.tap(find.text('Ground Pangolin'));
    await tester.pumpAndSettle();

    expect(find.byType(SpeciesDetailScreen), findsOneWidget);
    expect(find.text('Smutsia temminckii'), findsOneWidget);
    expect(find.text('Ietermagog'), findsOneWidget);
    expect(find.text('LEGENDARY'), findsOneWidget);
    expect(find.text('WHERE TO FIND IT'), findsOneWidget);
  });

  testWidgets('sensitive species show the protection notice', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    await tester.tap(find.text('Ground Pangolin'));
    await tester.pumpAndSettle();

    // docs/VISION.md non-negotiable.
    expect(find.textContaining('never show a location'), findsOneWidget);
  });

  testWidgets('non-sensitive species show no protection notice', (
    WidgetTester tester,
  ) async {
    await _pumpCodex(tester);

    // Search by the Afrikaans name so the query text does not itself match
    // 'Impala' — otherwise the finder hits both the card and the search field.
    await tester.enterText(find.byType(TextField), 'rooibok');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Impala'));
    await tester.pumpAndSettle();

    expect(find.textContaining('never show a location'), findsNothing);
    expect(find.text('Rooibok'), findsOneWidget);
  });
}
