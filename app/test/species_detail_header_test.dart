import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/codex/species_detail_screen.dart';
import 'package:wildscore/shared/theme.dart';
import 'package:wildscore/shared/widgets/species_image.dart';

/// The card is the screen somebody holds up next to a real animal, so the
/// photograph is the product. It took two rewrites to get there — a corner
/// portrait, then a circular medallion — and neither showed enough animal.
late final List<Species> _catalogue;

Species _byId(String id) => _catalogue.firstWhere((Species s) => s.id == id);

Future<void> _pump(
  WidgetTester tester,
  Species species, {
  Size size = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: SpeciesDetailScreen(species: species),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('the photograph runs the full width of the screen', (
    WidgetTester tester,
  ) async {
    const Size screen = Size(390, 844);
    await _pump(tester, _byId('leopard'), size: screen);

    final Size image = tester.getSize(find.byType(SpeciesImage).first);

    expect(image.width, screen.width, reason: 'edge to edge, not a medallion');
    // Comfortably over half the screen height. The medallion it replaced
    // topped out at 260 points wide with coloured space all around it.
    expect(image.height, greaterThan(screen.height * 0.4));
  });

  testWidgets('the name sits over the photograph, not under it', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _byId('leopard'));

    final Rect image = tester.getRect(find.byType(SpeciesImage).first);
    final Rect name = tester.getRect(find.text('Leopard'));

    expect(name.bottom, lessThanOrEqualTo(image.bottom));
    expect(name.left, lessThan(image.width / 2), reason: 'ranged left');
  });

  testWidgets('a species with no usable photo still fills the header', (
    WidgetTester tester,
  ) async {
    // Caracal and African wildcat fall back to a PhyloPic silhouette. On the
    // dark header that must not become a pale rectangle punched into the
    // colour — see SpeciesImage.onDark.
    final Species caracal = _byId('caracal');
    expect(caracal.photoVerified, isFalse, reason: 'fixture assumption');

    await _pump(tester, caracal);

    expect(tester.getSize(find.byType(SpeciesImage).first).width, 390);
    expect(find.text('Caracal'), findsOneWidget);
  });

  testWidgets('the header holds up on a small screen and at 1.5x text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: SpeciesDetailScreen(
            species: _byId('southern-ground-hornbill'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a protected species says its location is never recorded', (
    WidgetTester tester,
  ) async {
    // docs/VISION.md non-negotiable, and the wording has to stay honest about
    // what the app actually does — it never looks the location up at all.
    await _pump(tester, _byId('white-rhinoceros'));

    expect(find.textContaining('never record a location'), findsOneWidget);
  });
}
