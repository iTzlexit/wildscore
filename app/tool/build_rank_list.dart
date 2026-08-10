// Builds tools/rank-list.html from the template and the live species catalogue.
//
//   cd app && dart run tool/build_rank_list.dart
//
// **The second ranking tool, not a replacement for the first.** ranker.html
// asks "which of these two is harder to find" over and over and fits a
// Bradley-Terry model to the answers — good for a crowd, because it needs no
// expertise and no patience, and it survives people disagreeing.
//
// This one asks one person who knows Kruger to just put them in order. It is
// worthless as a survey and much better as a way for the owner to say what he
// thinks, which is what he actually wanted: not a tier where every animal
// scores the same, but a rank inside each tier with the points spread across a
// band. A leopard and a lion are both Big Five and nobody believes they are
// equally hard to find.
//
// Both files stay. The pairwise one goes to the public; this one settles what
// the app ships in the meantime.

import 'dart:convert';
import 'dart:io';

/// Point bands per tier, low to high, taken from the scheme the owner brought.
///
/// His had lettered groups — near-impossible, exceptional, lucky, achievable —
/// which are our tiers under different names, so the numbers transfer directly.
/// They are only defaults: the page has two editable boxes per category, and
/// whatever comes back in the export is what he settled on.
///
/// The bands do not touch: the bottom of one sits above the top of the next, so
/// **the worst Legendary always beats the best Very rare.** A tier that can be
/// out-scored by the tier below it is not a tier.
const Map<String, (int, int)> bands = <String, (int, int)>{
  'legendary': (1500, 3500),
  'rare': (800, 1400),
  'scarce': (300, 700),
  'uncommon': (100, 280),
  'frequent': (25, 90),
  'common': (5, 20),
};

/// Tier order, rarest first, and which ones are worth opening on arrival.
const List<(String, String, bool)> tiers = <(String, String, bool)>[
  ('legendary', 'Legendary', true),
  ('rare', 'Very rare', true),
  ('scarce', 'Rare', true),
  ('uncommon', 'Notable', true),
  ('frequent', 'Frequent', false),
  ('common', 'Common', false),
];

Future<void> main(List<String> args) async {
  final File template = File('../tools/rank-list.template.html');
  final File catalogue = File('assets/data/species.json');
  if (!template.existsSync() || !catalogue.existsSync()) {
    stderr.writeln('run this from the app/ directory');
    exitCode = 66;
    return;
  }

  final List<dynamic> species =
      (json.decode(catalogue.readAsStringSync())
              as Map<String, dynamic>)['species']
          as List<dynamic>;

  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final (String tier, String label, bool important) in tiers) {
    final List<Map<String, String>> members =
        <Map<String, String>>[
          for (final dynamic s in species)
            if ((s as Map<String, dynamic>)['rarityTier'] == tier)
              <String, String>{
                'id': s['id'] as String,
                'name': s['commonName'] as String,
                'afr': s['afrikaansName'] as String,
                // Where it started, so the page can say what moved and the
                // export can be applied without diffing it against the
                // catalogue by hand.
                'from': tier,
              },
        ]..sort(
          (Map<String, String> a, Map<String, String> b) =>
              a['name']!.compareTo(b['name']!),
        );

    if (members.isEmpty) {
      continue;
    }
    final (int low, int high) = bands[tier]!;
    out.add(<String, dynamic>{
      'tier': tier,
      'label': label,
      'important': important,
      'low': low,
      'high': high,
      // Alphabetical to start with, deliberately. Seeding it with the current
      // order would read as a suggestion, and the whole point is to find out
      // whether the current order is wrong.
      'species': members,
    });
  }

  final String json_ = json.encode(out);
  // Stamped so a "this does not work" can be answered with "which copy have
  // you got". Downloading the same filename twice leaves the browser holding
  // rank-list.html and rank-list (1).html, and the older one opens first.
  final DateTime now = DateTime.now();
  final String stamp =
      '${now.year}-${_two(now.month)}-${_two(now.day)} '
      '${_two(now.hour)}:${_two(now.minute)}';

  File('../tools/rank-list.html').writeAsStringSync(
    template
        .readAsStringSync()
        .replaceFirst('/*__TIERS__*/[]', json_)
        .replaceFirst('/*__BUILT__*/', 'built $stamp'),
  );

  final int total = out.fold(
    0,
    (int a, Map<String, dynamic> t) =>
        a + (t['species'] as List<dynamic>).length,
  );
  stdout
    ..writeln(
      'tools/rank-list.html — $total animals in ${out.length} categories',
    )
    ..writeln('');
  for (final Map<String, dynamic> t in out) {
    final (int, int) b = (t['low'] as int, t['high'] as int);
    stdout.writeln(
      '  ${(t['label'] as String).padRight(10)} '
      '${(t['species'] as List<dynamic>).length.toString().padLeft(3)} animals   '
      '${b.$1}–${b.$2} points',
    );
  }
  stdout
    ..writeln('')
    ..writeln('Open it, order them, press Export, and paste the JSON back.');
}

String _two(int n) => n.toString().padLeft(2, '0');
