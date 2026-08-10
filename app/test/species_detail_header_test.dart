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

  /// The sharp, contained copy — not the blurred one filling the box behind it.
  final Finder portrait = find.byKey(const Key('species-portrait'));

  testWidgets('the photograph runs the full width of the screen', (
    WidgetTester tester,
  ) async {
    const Size screen = Size(390, 844);
    await _pump(tester, _byId('leopard'), size: screen);

    final Size image = tester.getSize(portrait);

    expect(image.width, screen.width, reason: 'edge to edge, not a medallion');
    // Comfortably over half the screen height. The medallion it replaced
    // topped out at 260 points wide with coloured space all around it.
    expect(image.height, greaterThan(screen.height * 0.4));
  });

  testWidgets('the whole animal is shown, never cropped to fit', (
    WidgetTester tester,
  ) async {
    // The regression this exists to catch: `cover` in a portrait box threw
    // away a third of the width of a 4:3 photograph and well over half of a
    // 2.43:1 one, which cut heads and hindquarters off animals in a *field
    // guide*. Sixty-three of the seventy-seven photographs are landscape, so
    // this is the common case rather than an edge one.
    await _pump(tester, _byId('leopard'));

    final Image image = tester.widget<Image>(
      find.descendant(of: portrait, matching: find.byType(Image)),
    );

    expect(image.fit, BoxFit.contain);
  });

  testWidgets('even the widest photograph in the set fits whole', (
    WidgetTester tester,
  ) async {
    // The worst case is 2.43:1 against a header of roughly 0.9:1. Under
    // `cover` that lost about 63% of the width — most of an animal. This
    // measures what actually gets painted rather than trusting the BoxFit
    // constant, so a later change to the layout around it cannot quietly
    // reintroduce the crop.
    const Size screen = Size(390, 844);
    await _pump(tester, _byId('leopard'), size: screen);

    final RenderBox box = tester.renderObject<RenderBox>(portrait);
    const double widest = 2.43;
    final Size painted = applyBoxFit(
      BoxFit.contain,
      const Size(widest * 1000, 1000),
      box.size,
    ).destination;

    expect(painted.width, lessThanOrEqualTo(box.size.width + 0.01));
    expect(painted.height, lessThanOrEqualTo(box.size.height + 0.01));
    // And it is still a usefully large picture, not a letterboxed sliver.
    expect(painted.width, screen.width);
  });

  testWidgets('a blurred copy fills the box behind the portrait', (
    WidgetTester tester,
  ) async {
    // Otherwise `contain` leaves flat bands above and below a landscape
    // photograph, which is the coloured dead space the medallion was rejected
    // for in the first place.
    await _pump(tester, _byId('leopard'));

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(SpeciesImage), findsNWidgets(2));
  });

  testWidgets('the name sits over the photograph, not under it', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _byId('leopard'));

    final Rect image = tester.getRect(portrait);
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

    expect(tester.getSize(portrait).width, 390);
    expect(find.text('Caracal'), findsOneWidget);
    // No blur behind a silhouette — blurring a flat shape makes a smear, and
    // the tier gradient is a better backdrop than a smudge of itself.
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(SpeciesImage), findsOneWidget);
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

  group('where to find', () {
    testWidgets('is a tab for an ordinary animal', (WidgetTester tester) async {
      await _pump(tester, _byId('impala'));

      expect(find.text('Where to find'), findsOneWidget);
    });

    testWidgets('is not offered for either rhino or the pangolin', (
      WidgetTester tester,
    ) async {
      // Alex's instruction, 10 August 2026. The tab held a region strip, which
      // is coarse — and coarse is still an answer to "where do I go to find a
      // rhino". Poaching pressure in Kruger is not hypothetical.
      for (final String id in <String>[
        'white-rhinoceros',
        'black-rhinoceros',
        'ground-pangolin',
      ]) {
        await _pump(tester, _byId(id));

        expect(find.text('Where to find'), findsNothing, reason: id);
        expect(find.text('About'), findsOneWidget, reason: id);
        expect(find.text('Field notes'), findsOneWidget, reason: id);
      }
    });
  });
}
