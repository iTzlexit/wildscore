// Merges the codes people send back from the ranker into one ranking.
//
//   dart run tool/merge_rankings.dart submissions.txt
//
// One `WSRANK1:...` code per line; blank lines and anything else are ignored,
// so you can paste a WhatsApp export straight in. Writes a report to stdout and
// build/rankings.json with the merged order.
//
// **Individual sessions are not averaged.** A sixty-duel session produces very
// noisy ratings on its own and pooling those ratings would carry the noise
// through. The codes carry the raw judgements instead, so this re-runs Elo over
// everybody's comparisons together, in shuffled order, several times — which is
// the thing that actually converges.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Passes over the pooled comparisons. Elo is order-dependent, so one pass in
/// submission order would let whoever answered first set the anchors.
const int passes = 40;
const double k = 16;

/// A guide's answers count for more than a stranger's on Facebook. Matched
/// case-insensitively against the name they typed.
const List<String> trustedMarkers = <String>['guide', 'ranger', 'sanparks'];

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/merge_rankings.dart <file-of-codes>');
    exitCode = 64;
    return;
  }

  final Map<String, dynamic> catalogue =
      json.decode(File('assets/data/species.json').readAsStringSync())
          as Map<String, dynamic>;
  final List<String> ids = <String>[
    for (final dynamic s in catalogue['species'] as List<dynamic>)
      (s as Map<String, dynamic>)['id'] as String,
  ];
  final Map<String, String> names = <String, String>{
    for (final dynamic s in catalogue['species'] as List<dynamic>)
      (s as Map<String, dynamic>)['id'] as String: s['commonName'] as String,
  };
  final Map<String, String> tiers = <String, String>{
    for (final dynamic s in catalogue['species'] as List<dynamic>)
      (s as Map<String, dynamic>)['id'] as String: s['rarityTier'] as String,
  };

  final List<_Vote> pool = <_Vote>[];
  final List<String> contributors = <String>[];
  int rejected = 0;

  for (final String raw in File(args.first).readAsLinesSync()) {
    final int start = raw.indexOf('WSRANK1:');
    if (start == -1) {
      continue;
    }
    try {
      final String code = raw.substring(start + 8).trim();
      final Map<String, dynamic> body =
          json.decode(utf8.decode(base64.decode(code))) as Map<String, dynamic>;
      final String who = body['who'] as String? ?? 'anonymous';
      final double weight =
          trustedMarkers.any((String m) => who.toLowerCase().contains(m))
          ? 3
          : 1;

      for (final dynamic v in body['votes'] as List<dynamic>) {
        final List<dynamic> t = v as List<dynamic>;
        final int a = (t[0] as num).toInt();
        final int b = (t[1] as num).toInt();
        // An index from a submission made before a species was added would
        // point at the wrong animal. Dropping it is the only safe answer.
        if (a < 0 || b < 0 || a >= ids.length || b >= ids.length) {
          rejected++;
          continue;
        }
        pool.add(_Vote(ids[a], ids[b], (t[2] as num).toDouble(), weight));
      }
      contributors.add('$who (${(body['votes'] as List<dynamic>).length})');
    } on Object {
      rejected++;
    }
  }

  if (pool.isEmpty) {
    stderr.writeln('no usable codes found in ${args.first}');
    exitCode = 65;
    return;
  }

  final Map<String, double> rating = <String, double>{
    for (final String id in ids) id: 1500,
  };
  final Map<String, int> seen = <String, int>{
    for (final String id in ids) id: 0,
  };
  for (final _Vote v in pool) {
    seen[v.a] = seen[v.a]! + 1;
    seen[v.b] = seen[v.b]! + 1;
  }

  final math.Random random = math.Random(7);
  for (int pass = 0; pass < passes; pass++) {
    final List<_Vote> shuffled = <_Vote>[...pool]..shuffle(random);
    for (final _Vote v in shuffled) {
      final double expected =
          1 / (1 + math.pow(10, (rating[v.b]! - rating[v.a]!) / 400));
      final double move = k * v.weight * (v.score - expected);
      rating[v.a] = rating[v.a]! + move;
      rating[v.b] = rating[v.b]! - move;
    }
  }

  final List<String> ranked = <String>[...ids]
    ..sort((String a, String b) => rating[b]!.compareTo(rating[a]!));

  stdout
    ..writeln(
      '${contributors.length} submissions, ${pool.length} comparisons'
      '${rejected == 0 ? '' : ', $rejected rejected'}',
    )
    ..writeln(contributors.join(', '))
    ..writeln('');

  final Iterable<String> thin = ids
      .where((String id) => seen[id]! < 5)
      .map((String id) => names[id]!);
  if (thin.isNotEmpty) {
    stdout.writeln(
      'Too few comparisons to trust yet (${thin.length}): ${thin.join(', ')}\n',
    );
  }

  stdout.writeln('RANKED, RAREST FIRST — current tier in brackets');
  for (int i = 0; i < ranked.length; i++) {
    final String id = ranked[i];
    stdout.writeln(
      '${(i + 1).toString().padLeft(3)}  '
      '${rating[id]!.round().toString().padLeft(5)}  '
      '${names[id]!.padRight(32)} [${tiers[id]}]  ${seen[id]} duels',
    );
  }

  File('build/rankings.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'submissions': contributors,
        'comparisons': pool.length,
        'ranked': <Map<String, dynamic>>[
          for (final String id in ranked)
            <String, dynamic>{
              'id': id,
              'name': names[id],
              'elo': rating[id]!.round(),
              'duels': seen[id],
              'currentTier': tiers[id],
            },
        ],
      }),
    );
  stdout.writeln('\nbuild/rankings.json written');
}

class _Vote {
  const _Vote(this.a, this.b, this.score, this.weight);

  final String a;
  final String b;

  /// 1 when [a] is rarer, 0 when [b] is, 0.5 for a draw.
  final double score;

  final double weight;
}
