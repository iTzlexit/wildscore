import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/house_rules.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/tracker_profile.dart';
import 'package:wildscore/features/codex/widgets/species_grid_card.dart';
import 'package:wildscore/features/home_shell.dart';
import 'package:wildscore/shared/theme.dart';

/// **The bug this file exists for.**
///
/// A player set their own price, started a game, and the game scored the
/// catalogue's number. The save was fine and the domain was fine: the shell
/// held its catalogue in a `late final` field and reassigned it whenever a
/// rule changed, which throws `LateInitializationError` from inside
/// `setState`. The rule reached disk and never reached the screen.
///
/// Everything below drives the real shell rather than the pieces, because
/// every piece was already correct on its own.
class _MemoryRepository implements SpeciesRepository {
  const _MemoryRepository(this.all);

  final List<Species> all;

  /// The real folding logic, minus the asset read — that is what is under test.
  @override
  Future<List<Species>> loadAll({HouseRules rules = HouseRules.none}) async =>
      <Species>[
        for (final Species s in all)
          s.underHouseRules(
            points: rules.points[s.id],
            cap: rules.caps[s.id],
            capChanged: rules.caps.containsKey(s.id),
          ),
      ];
}

late final List<Species> _catalogue;

/// Built from the catalogue read in `setUpAll`. Reading the asset inside
/// `testWidgets` is real I/O in a fake-async zone: it never completes, and the
/// test dies ten minutes later on a guard it did not break.
_MemoryRepository _repo() => _MemoryRepository(_catalogue);

Future<void> _pumpShell(WidgetTester tester, _MemoryRepository repo) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: HomeShell(
        profile: TrackerProfile.create('Alex', now: DateTime(2026, 8, 10)),
        repository: repo,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the Animals tab, then one species' card.
Future<void> _openAnimal(WidgetTester tester, String name) async {
  await tester.tap(find.text('Animals').last);
  await tester.pumpAndSettle();
  await _find(tester, name);
}

/// Filters the grid to one animal and opens it.
///
/// By tile rather than by name: the name is on the card and in the field it
/// was just typed into, and `tap` refuses an ambiguous target.
Future<void> _find(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField).first, name);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SpeciesGridCard).first);
  await tester.pumpAndSettle();
}

/// Closes the species card.
///
/// Not `pageBack`: the card draws its own back arrow over the photograph
/// rather than wearing an AppBar, so there is no Cupertino back button to find.
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back_rounded));
  await tester.pumpAndSettle();
}

/// Drives the price editor on an open species card to the top rung.
Future<void> _setToTopRung(WidgetTester tester) async {
  await tester.tap(find.textContaining('Worth something else to you?'));
  await tester.pumpAndSettle();

  // Tapped at the right-hand end rather than dragged. A drag has to begin on
  // the thumb, which for an impala sits at the far left of the track.
  final Rect slider = tester.getRect(find.byType(Slider));
  await tester.tapAt(Offset(slider.right - 2, slider.center.dy));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Use this'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('a price set by the player reaches the screen, not just disk', (
    WidgetTester tester,
  ) async {
    final _MemoryRepository repo = _repo();
    await _pumpShell(tester, repo);
    await _openAnimal(tester, 'Impala');

    await _setToTopRung(tester);

    // The card says so without being reopened.
    expect(find.text('1000'), findsWidgets);
    expect(find.textContaining('You changed this from'), findsOneWidget);

    // And so does the Dex tile behind it, which is the half that was broken:
    // it is rebuilt from the catalogue the shell holds.
    await _back(tester);
    expect(find.text('1000'), findsWidgets);
  });

  testWidgets('the shell survives more than one edit', (
    WidgetTester tester,
  ) async {
    // The `late final` threw on the *second* assignment, so a single edit in a
    // fresh install looked fine and the next one broke everything.
    final _MemoryRepository repo = _repo();
    await _pumpShell(tester, repo);

    await _openAnimal(tester, 'Impala');
    await _setToTopRung(tester);
    await _back(tester);

    await _find(tester, 'Warthog');
    await _setToTopRung(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('You changed this from'), findsOneWidget);
  });

  testWidgets('every edit is kept, including one made a moment after another', (
    WidgetTester tester,
  ) async {
    // The second half of the same bug. Each edit derives the next rule set
    // from the one held in state, and that used to be updated *after* the
    // write to disk — so a car going down the list changing three animals in
    // ten seconds lost the earlier two.
    final _MemoryRepository repo = _repo();
    await _pumpShell(tester, repo);

    await _openAnimal(tester, 'Impala');
    await _setToTopRung(tester);
    await _back(tester);

    await _find(tester, 'Warthog');
    await _setToTopRung(tester);
    await _back(tester);

    // Both, not just the last one.
    await tester.enterText(find.byType(TextField).first, 'Impala');
    await tester.pumpAndSettle();
    expect(find.text('1000'), findsWidgets);
    expect(
      find.text(
        '${_catalogue.firstWhere((Species s) => s.id == 'impala').points}',
      ),
      findsNothing,
    );
  });
}
