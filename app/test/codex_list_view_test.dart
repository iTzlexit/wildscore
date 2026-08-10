import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/house_rules.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/codex/codex_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The ranked list, which is the Dex's other half.
///
/// Alex: *"the filter doesn't work for the list view. They should work for both
/// the list view and the tile view."*
class _InMemoryRepository implements SpeciesRepository {
  const _InMemoryRepository(this.species);

  final List<Species> species;

  @override
  Future<List<Species>> loadAll({HouseRules rules = HouseRules.none}) async =>
      species;
}

late final List<Species> _catalogue;

Future<void> _pump(WidgetTester tester, {double width = 2000}) async {
  await tester.binding.setSurfaceSize(Size(width, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: CodexScreen(repository: _InMemoryRepository(_catalogue)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _showList(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.format_list_numbered));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('search narrows the ranked list', (WidgetTester tester) async {
    await _pump(tester);
    await _showList(tester);
    await _search(tester, 'pangolin');

    expect(find.text('Ground Pangolin'), findsOneWidget);
    expect(find.text('Impala'), findsNothing);
  });

  testWidgets('a category filter narrows the ranked list', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await _showList(tester);

    await tester.tap(find.text('Birds').first);
    await tester.pumpAndSettle();

    expect(find.text('Leopard'), findsNothing);
    expect(find.text('Impala'), findsNothing);
  });

  testWidgets('a rarity filter narrows the ranked list', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await _showList(tester);

    await tester.tap(find.text('Ghost').first);
    await tester.pumpAndSettle();

    expect(find.text('Ground Pangolin'), findsOneWidget);
    expect(find.text('Impala'), findsNothing);
  });

  testWidgets('the sort applies here too, rather than being ignored', (
    WidgetTester tester,
  ) async {
    // It was pinned to rarest-first on the grounds that a ranking has one
    // number one. True, and it still meant tapping Dex order did nothing at
    // all — a control that visibly does nothing reads as a broken filter.
    await _pump(tester);
    await _showList(tester);

    // Rarest first: a Ghost is at number one.
    expect(find.text('1'), findsWidgets);
    expect(find.text('Ground Pangolin'), findsOneWidget);

    await tester.tap(find.text('Rarest first'));
    await tester.pumpAndSettle();

    // Dex order: aardvark is 001 and always will be.
    expect(find.text('Dex order'), findsOneWidget);
    expect(find.text('Aardvark'), findsOneWidget);
    expect(find.text('Impala'), findsNothing, reason: 'dex order, not rarity');
  });

  testWidgets('clearing the filters brings everything back', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await _showList(tester);
    await tester.tap(find.text('Birds').first);
    await tester.pumpAndSettle();
    await _search(tester, 'roller');

    expect(find.text('Lilac-breasted Roller'), findsOneWidget);

    await _search(tester, '');
    await tester.tap(find.text('Birds').first);
    await tester.pumpAndSettle();

    expect(find.text('Ground Pangolin'), findsOneWidget);
  });
}
