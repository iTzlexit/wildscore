import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/codex/collection_screen.dart';
import 'package:wildscore/features/codex/species_detail_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// Adding something to a collection and then changing your mind. It was
/// impossible from a collection screen and awkward everywhere else, which is
/// the sort of bug that makes people distrust the whole record.
late final List<Species> _catalogue;

Species _byId(String id) => _catalogue.firstWhere((Species s) => s.id == id);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('the detail screen toggles in place rather than closing', (
    WidgetTester tester,
  ) async {
    // It used to pop itself after every toggle, because it had no state of its
    // own and no way to show the new value. Adding an animal made the card
    // vanish, which reads as an error, and changing your mind meant finding the
    // animal again.
    int calls = 0;
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SpeciesDetailScreen(
          species: _byId('leopard'),
          onToggleSpotted: () => calls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('I have seen this one'), findsOneWidget);

    await tester.tap(find.text('I have seen this one'));
    await tester.pumpAndSettle();
    expect(find.text('In your collection'), findsOneWidget);
    expect(calls, 1);

    // And straight back again, without leaving the screen.
    await tester.tap(find.text('In your collection'));
    await tester.pumpAndSettle();
    expect(find.text('I have seen this one'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('a collection knows what is already in it', (
    WidgetTester tester,
  ) async {
    // The collection screen passed no spotted flag at all, so opening an animal
    // from your own collection offered to add it — to the collection it was
    // already in.
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: CollectionScreen(
          species: _catalogue,
          caughtIds: const <String>{'leopard'},
          group: null,
          mode: CollectionMode.spotted,
          onToggleSpotted: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leopard').first);
    await tester.pumpAndSettle();

    expect(find.text('In your collection'), findsOneWidget);
    expect(find.text('I have seen this one'), findsNothing);
  });

  testWidgets('taking one out of a collection is possible and is reported', (
    WidgetTester tester,
  ) async {
    final List<String> removed = <String>[];
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: CollectionScreen(
          species: _catalogue,
          caughtIds: const <String>{'leopard'},
          mode: CollectionMode.spotted,
          onToggleSpotted: removed.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leopard').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('In your collection'));
    await tester.pumpAndSettle();

    expect(removed, <String>['leopard']);
  });

  testWidgets('a read-only collection offers no button at all', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: CollectionScreen(
          species: _catalogue,
          caughtIds: const <String>{'leopard'},
          mode: CollectionMode.spotted,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leopard').first);
    await tester.pumpAndSettle();

    expect(find.text('In your collection'), findsNothing);
    expect(find.text('I have seen this one'), findsNothing);
  });
}
