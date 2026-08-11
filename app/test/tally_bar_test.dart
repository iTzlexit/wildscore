import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/features/scorecard/standings_board.dart';
import 'package:wildscore/shared/theme.dart';

/// The bar under each name.
///
/// Alex, after one drive: *"not sure why it shows full progression when one
/// animal is spotted."* It was drawn as a fraction of the leader's score, so
/// whoever was ahead — by any margin, including one impala to nothing — had a
/// bar that was completely full. The game looked finished before it started.
late final List<Species> _catalogue;

Scorecard _card({List<String> players = const <String>['Alex', 'Sam']}) =>
    Scorecard.start(players, owner: 'Alex', now: DateTime(2026, 8, 11, 6));

Claim _claim(String playerId, String speciesId, int points, {int hour = 7}) =>
    Claim(
      speciesId: speciesId,
      playerId: playerId,
      at: DateTime(2026, 8, 11, hour),
      points: points,
    );

Future<void> _pump(WidgetTester tester, Scorecard card) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StandingsBoard(card: card, species: _catalogue),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// How much of the track the leader's bar covers, 0 to 1.
double _fill(WidgetTester tester) {
  final FractionallySizedBox box = tester
      .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .first;
  return box.widthFactor ?? 0;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = await const SpeciesRepository().loadAll();
  });

  testWidgets('one impala does not fill anybody\'s bar', (
    WidgetTester tester,
  ) async {
    final Scorecard card = _card();
    final String alex = card.players.first.id;
    await _pump(tester, card.withClaim(_claim(alex, 'impala', 10)));

    expect(_fill(tester), lessThan(0.05));
  });

  testWidgets('a very good day is still not a finished one', (
    WidgetTester tester,
  ) async {
    // The leader is held at about 87% of the track, so the bar always reads as
    // still climbing. A full bar on a drive that has not ended is a lie.
    final Scorecard card = _card();
    final String alex = card.players.first.id;
    await _pump(
      tester,
      card
          .withClaim(_claim(alex, 'leopard', 300))
          .withClaim(_claim(alex, 'lion', 300, hour: 8))
          .withClaim(_claim(alex, 'ground-pangolin', 1000, hour: 9)),
    );

    expect(_fill(tester), lessThan(0.9));
    expect(_fill(tester), greaterThan(0.8));
  });

  testWidgets('the bar grows as the day does', (WidgetTester tester) async {
    final Scorecard card = _card();
    final String alex = card.players.first.id;

    await _pump(tester, card.withClaim(_claim(alex, 'impala', 10)));
    final double early = _fill(tester);

    await _pump(
      tester,
      card
          .withClaim(_claim(alex, 'impala', 10))
          .withClaim(_claim(alex, 'leopard', 250, hour: 8)),
    );

    expect(_fill(tester), greaterThan(early));
  });

  testWidgets('second place is drawn against the same road, not the leader', (
    WidgetTester tester,
  ) async {
    // Relative-to-the-leader made the gap unreadable: 10 against 20 looked
    // like a thrashing, and 900 against 1000 looked like one too.
    final Scorecard card = _card();
    final String alex = card.players.first.id;
    final String sam = card.players[1].id;
    await _pump(
      tester,
      card
          .withClaim(_claim(alex, 'lion', 120))
          .withClaim(_claim(sam, 'impala', 10, hour: 8)),
    );

    final List<FractionallySizedBox> bars = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .toList();

    expect(bars, hasLength(2));
    expect(bars.first.widthFactor, greaterThan(bars.last.widthFactor!));
    expect(bars.first.widthFactor, lessThan(0.5), reason: '120 is not a day');
  });

  testWidgets('each sighting is its own block on the bar', (
    WidgetTester tester,
  ) async {
    // The tally Alex asked for: three spots, three blocks, sized by what each
    // one scored. A morning of impala looks like a morning of impala.
    final Scorecard card = _card(players: <String>['Alex']);
    final String alex = card.players.first.id;
    await _pump(
      tester,
      card
          .withClaim(_claim(alex, 'impala', 10))
          .withClaim(_claim(alex, 'leopard', 250, hour: 8))
          .withClaim(_claim(alex, 'burchells-zebra', 20, hour: 9)),
    );

    final List<Expanded> blocks = tester
        .widgetList<Expanded>(find.byType(Expanded))
        .where((Expanded e) => e.child is ColoredBox)
        .toList();

    expect(blocks, hasLength(3));
    expect(blocks[0].flex, 10);
    expect(blocks[1].flex, 250, reason: 'the leopard is the wide one');
    expect(blocks[2].flex, 20);
  });

  testWidgets('nobody has scored yet: empty bars, no crash', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _card());

    expect(tester.takeException(), isNull);
    expect(_fill(tester), lessThan(0.01));
  });
}
