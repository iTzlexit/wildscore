import 'package:flutter/material.dart';

/// Renders `**bold**` inside otherwise plain copy.
///
/// The rules screen is skimmed, not read, at a park gate with the engine
/// running. A wall of even-weight text gives a skimmer nothing to catch on;
/// four bold words per screen give them the rule without the sentence.
///
/// A deliberately tiny subset of Markdown — bold and nothing else. A full
/// Markdown package is a dependency, a parser and a licence for a feature that
/// is one regular expression, and every extra syntax it supports is another way
/// for copy to render wrong.
Text emphasised(String source, {required TextStyle style, int? maxLines}) {
  return Text.rich(
    TextSpan(children: emphasisSpans(source, style)),
    style: style,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
  );
}

/// The spans behind [emphasised], exposed for callers that build their own
/// [Text.rich] — and for tests, which is the only way to prove the markers
/// were consumed rather than printed.
List<InlineSpan> emphasisSpans(String source, TextStyle style) {
  final TextStyle bold = style.copyWith(
    fontWeight: FontWeight.w800,
    // A variable font ignores fontWeight unless the axis is set too, and this
    // app ships one. Without this the "bold" text is identical to the rest,
    // which is a bug that looks like a design decision.
    fontVariations: const <FontVariation>[FontVariation('wght', 800)],
    color: style.color,
  );

  final List<InlineSpan> spans = <InlineSpan>[];
  int at = 0;
  while (true) {
    final int open = source.indexOf('**', at);
    if (open == -1) {
      break;
    }
    final int close = source.indexOf('**', open + 2);
    if (close == -1) {
      break;
    }
    if (open > at) {
      spans.add(TextSpan(text: source.substring(at, open)));
    }
    spans.add(TextSpan(text: source.substring(open + 2, close), style: bold));
    at = close + 2;
  }
  // Everything after the last pair, and the whole string when there was none.
  if (at < source.length) {
    spans.add(TextSpan(text: source.substring(at)));
  }
  return spans;
}
