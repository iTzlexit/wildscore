import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/species.dart';
import 'package:wildscore/domain/visit.dart';
import 'package:wildscore/features/profile/visit_history_screen.dart';
import 'package:wildscore/shared/theme.dart';

/// The drive history is where a season ends up, so the things that could hide a
/// day from its owner — a filter, a page boundary — are worth testing.
late final List<Species> _catalogue;

Visit _visit(DateTime ended, {int points = 100, String species = 'leopard'}) {
  final Scorecard card = Scorecard.start(
    <String>['Alex'],
    owner: 'Alex',
    now: ended,
  );
  return Visit(
    startedAt: ended,
    endedAt: ended,
    players: card.players,
    claims: <Claim>[
      Claim(
        speciesId: species,
        playerId: card.players.first.id,
        at: ended,
        points: points,
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, List<Visit> visits) async {
  await tester.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: VisitHistoryScreen(visits: visits, species: _catalogue),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _catalogue = <Species>[];
  });

  testWidgets('lists every drive with the owner points', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <Visit>[
      _visit(DateTime(2026, 8, 1)),
      _visit(DateTime(2025, 6, 4), points: 250),
    ]);

    expect(find.text('2 drives · 350 points'), findsOneWidget);
    expect(find.text('1 August 2026'), findsOneWidget);
    expect(find.text('4 June 2025'), findsOneWidget);
  });

  testWidgets('filtering by year hides the other years', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <Visit>[
      _visit(DateTime(2026, 8, 1)),
      _visit(DateTime(2025, 6, 4), points: 250),
    ]);

    await tester.tap(find.text('2025'));
    await tester.pumpAndSettle();

    expect(find.text('1 drive · 250 points'), findsOneWidget);
    expect(find.text('4 June 2025'), findsOneWidget);
    expect(find.text('1 August 2026'), findsNothing);
  });

  testWidgets('only offers years that contain a drive', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <Visit>[
      _visit(DateTime(2026, 8, 1)),
      _visit(DateTime(2024, 6, 4)),
    ]);

    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.text('2025'), findsNothing);
  });

  testWidgets('the month list follows the chosen year', (
    WidgetTester tester,
  ) async {
    // The combination that would return nothing — June, but in 2026 — is not
    // offered, so it cannot be selected. That is why there is no empty state.
    await _pump(tester, <Visit>[
      _visit(DateTime(2026, 8, 1)),
      _visit(DateTime(2025, 6, 4)),
    ]);

    expect(find.text('June'), findsOneWidget);

    await tester.tap(find.text('2026'));
    await tester.pumpAndSettle();

    expect(find.text('June'), findsNothing);
    expect(find.text('1 drive · 100 points'), findsOneWidget);
  });

  testWidgets('shows a page at a time, and the rest on request', (
    WidgetTester tester,
  ) async {
    // Nothing is ever aged out — a two-year-old drive is the reason someone
    // renews — so a long history has to stay reachable.
    await _pump(tester, <Visit>[
      for (int i = 1; i <= 20; i++) _visit(DateTime(2026, 1, i)),
    ]);

    expect(find.text('20 drives · 2000 points'), findsOneWidget);
    expect(find.textContaining('Show 8 older drives'), findsOneWidget);

    await tester.tap(find.textContaining('Show 8 older drives'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Show'), findsNothing);
  });

  testWidgets('a running drive sits on top, marked unbanked', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: VisitHistoryScreen(
          visits: <Visit>[_visit(DateTime(2026, 8, 1))],
          species: _catalogue,
          live: Scorecard.start(
            <String>['Alex'],
            owner: 'Alex',
            now: DateTime(2026, 8, 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('IN PLAY'), findsOneWidget);
    expect(find.text('2 August 2026'), findsOneWidget);
    expect(
      find.textContaining('Not banked yet'),
      findsOneWidget,
      reason: 'the day only counts once it is ended',
    );
  });
}
