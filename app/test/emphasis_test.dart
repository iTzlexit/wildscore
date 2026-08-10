import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/features/scorecard/rules_screen.dart';
import 'package:wildscore/shared/emphasis.dart';
import 'package:wildscore/shared/theme.dart';

/// The failure mode of a hand-rolled markup parser is that it prints its own
/// syntax at the reader — "**first player to say it out loud**" on the screen,
/// asterisks and all. Cheap to prevent, embarrassing to ship.
void main() {
  const TextStyle plain = TextStyle(fontSize: 14);

  String rendered(List<InlineSpan> spans) =>
      spans.map((InlineSpan s) => (s as TextSpan).text ?? '').join();

  group('parsing', () {
    test('plain text comes through untouched', () {
      final List<InlineSpan> spans = emphasisSpans('nothing special', plain);

      expect(spans, hasLength(1));
      expect(rendered(spans), 'nothing special');
    });

    test('a bold run loses its markers and gains weight', () {
      final List<InlineSpan> spans = emphasisSpans(
        'the **first** voice',
        plain,
      );

      expect(rendered(spans), 'the first voice');
      expect(rendered(spans), isNot(contains('*')));
      final TextSpan bold = spans[1] as TextSpan;
      expect(bold.text, 'first');
      expect(bold.style?.fontWeight, FontWeight.w800);
    });

    test('the weight axis is set, not just fontWeight', () {
      // The app ships a variable font, which ignores fontWeight unless the
      // axis moves too — so "bold" text would render identically to the rest.
      // A bug that looks exactly like a design decision.
      final List<InlineSpan> spans = emphasisSpans('**heavy**', plain);
      final TextSpan bold = spans.first as TextSpan;

      expect(
        bold.style?.fontVariations,
        contains(const FontVariation('wght', 800)),
      );
    });

    test('several runs in one string', () {
      final List<InlineSpan> spans = emphasisSpans(
        '**one** then **two** then done',
        plain,
      );

      expect(rendered(spans), 'one then two then done');
      expect(rendered(spans), isNot(contains('*')));
    });

    test('an unclosed marker is left alone rather than eating the rest', () {
      // Copy is edited by hand. A stray marker should cost one visible pair of
      // asterisks, not the remainder of the paragraph.
      final List<InlineSpan> spans = emphasisSpans('an **unclosed run', plain);

      expect(rendered(spans), 'an **unclosed run');
    });
  });

  testWidgets('the rules screen shows no asterisks anywhere', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 5200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const RulesScreen()),
    );
    await tester.pumpAndSettle();

    final Iterable<String> withMarkers = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .where((String s) => s.contains('**'));

    expect(withMarkers, isEmpty, reason: 'markers leaked to the screen');
  });

  testWidgets('the jam penalty is actually emphasised', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 5200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const RulesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('20% fewer points'), findsOneWidget);
  });
}
