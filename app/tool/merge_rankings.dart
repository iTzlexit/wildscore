// Merges the codes people send back from the ranker into one ranking.
//
//   dart run tool/merge_rankings.dart submissions.txt
//
// One `WSRANK1:...` code per line; anything else on the line is ignored, so a
// WhatsApp export or a folder of emails can be pasted straight in. Writes a
// report to stdout and build/rankings.json.
//
// ---------------------------------------------------------------------------
// Why this is not Elo
// ---------------------------------------------------------------------------
// The first version pooled everybody's comparisons and re-ran Elo over them.
// Elo is an *online* estimator built for players whose real strength drifts
// over time, and it has two properties that are wrong here:
//
//   * It is order-dependent. Whoever answered first sets the anchors, and the
//     same set of judgements produces different numbers depending on the order
//     they are fed in.
//   * It uses transitivity only weakly. If everybody agrees a caracal beats a
//     serval and a serval beats a cheetah, the caracal should end up above the
//     cheetah *even if nobody ever compared them directly*. Elo gets there
//     eventually and only with lots of data.
//
// An animal's rarity does not drift, so this is a static-ranking problem, and
// the right tool is the **Bradley-Terry model** fitted by maximum likelihood.
// It asks: what set of strengths makes the observed answers most probable? That
// is order-independent, uses every indirect path through the comparison graph,
// and is the reason a species can be placed confidently against one it never
// met.
//
// Fitted with the MM (minorise-maximise) algorithm, which is a handful of lines
// and converges monotonically.
//
// **Confidence is reported, not assumed.** Bootstrapping the comparisons gives
// each species a range of plausible ranks, which is what tells you whether
// second place is real or a coin toss.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// MM iterations. Convergence is monotonic and fast; this is well past enough.
const int fitIterations = 300;

/// Bootstrap resamples used to work out how firm each position is.
const int bootstraps = 300;

/// Every species is given this many virtual half-wins and half-losses against
/// the field.
///
/// Without it, a species that won every one of its comparisons has infinite
/// likelihood strength and the fit runs away; with it, an animal seen three
/// times is pulled gently towards the middle, which is exactly the humility a
/// species with three data points deserves.
const double prior = 1.0;

/// A guide's answers count for more than a stranger's. Matched case-insensitively
/// against whatever they typed as their name.
const List<String> trustedMarkers = <String>[
  'guide',
  'ranger',
  'sanparks',
  'field guide',
  'ecologist',
];
const double trustedWeight = 3;

/// Below this many comparisons a species' position is not worth reading.
const int thinEvidence = 8;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/merge_rankings.dart <file-of-codes>');
    exitCode = 64;
    return;
  }

  final Map<String, dynamic> catalogue =
      json.decode(File('assets/data/species.json').readAsStringSync())
          as Map<String, dynamic>;
  final List<dynamic> raw = catalogue['species'] as List<dynamic>;
  final List<String> ids = <String>[
    for (final dynamic s in raw) (s as Map<String, dynamic>)['id'] as String,
  ];
  final Map<String, String> names = <String, String>{
    for (final dynamic s in raw)
      (s as Map<String, dynamic>)['id'] as String: s['commonName'] as String,
  };
  final Map<String, String> tiers = <String, String>{
    for (final dynamic s in raw)
      (s as Map<String, dynamic>)['id'] as String: s['rarityTier'] as String,
  };
  final List<_Comparison> pool = <_Comparison>[];
  final List<String> contributors = <String>[];
  int rejected = 0;

  for (final String line in File(args.first).readAsLinesSync()) {
    final int start = line.indexOf('WSRANK1:');
    if (start == -1) {
      continue;
    }
    try {
      final Map<String, dynamic> body =
          json.decode(
                utf8.decode(base64.decode(line.substring(start + 8).trim())),
              )
              as Map<String, dynamic>;

      final String who = body['who'] as String? ?? 'anonymous';
      final bool trusted = trustedMarkers.any(
        (String m) => who.toLowerCase().contains(m),
      );
      int kept = 0;

      for (final dynamic v in body['votes'] as List<dynamic>) {
        final List<dynamic> t = v as List<dynamic>;
        final int a = (t[0] as num).toInt();
        final int b = (t[1] as num).toInt();
        // An index from a submission made before a species was added points at
        // the wrong animal now. Dropping it is the only safe answer.
        if (a < 0 || b < 0 || a >= ids.length || b >= ids.length || a == b) {
          rejected++;
          continue;
        }
        pool.add(
          _Comparison(
            a,
            b,
            (t[2] as num).toDouble(),
            trusted ? trustedWeight : 1,
          ),
        );
        kept++;
      }
      contributors.add('$who${trusted ? ' ★' : ''} ($kept)');
    } on Object {
      rejected++;
    }
  }

  if (pool.isEmpty) {
    stderr.writeln('no usable codes found in ${args.first}');
    exitCode = 65;
    return;
  }

  final List<int> seen = List<int>.filled(ids.length, 0);
  for (final _Comparison c in pool) {
    seen[c.a]++;
    seen[c.b]++;
  }

  final List<double> strength = _fit(pool, ids.length);
  final List<int> order = List<int>.generate(ids.length, (int i) => i)
    ..sort((int a, int b) => strength[b].compareTo(strength[a]));

  // ------------------------------------------------------------- confidence
  final math.Random random = math.Random(11);
  final List<List<int>> ranksSeen = List<List<int>>.generate(
    ids.length,
    (_) => <int>[],
  );
  for (int b = 0; b < bootstraps; b++) {
    final List<_Comparison> resample = <_Comparison>[
      for (int i = 0; i < pool.length; i++) pool[random.nextInt(pool.length)],
    ];
    final List<double> s = _fit(resample, ids.length, iterations: 60);
    final List<int> o = List<int>.generate(ids.length, (int i) => i)
      ..sort((int x, int y) => s[y].compareTo(s[x]));
    for (int rank = 0; rank < o.length; rank++) {
      ranksSeen[o[rank]].add(rank + 1);
    }
  }

  final Map<int, List<int>> band = <int, List<int>>{};
  for (int i = 0; i < ids.length; i++) {
    final List<int> r = ranksSeen[i]..sort();
    band[i] = <int>[r[(r.length * 0.05).floor()], r[(r.length * 0.95).floor()]];
  }

  // ----------------------------------------------------------------- report
  final int comparisons = pool.length;
  final double perSpecies = 2 * comparisons / ids.length;
  stdout
    ..writeln(
      '${contributors.length} submissions, $comparisons comparisons'
      '${rejected == 0 ? '' : ', $rejected rejected'}',
    )
    ..writeln(
      '${perSpecies.toStringAsFixed(1)} comparisons per species '
      'on average',
    )
    ..writeln(contributors.join(', '))
    ..writeln('');

  final List<String> thin = <String>[
    for (int i = 0; i < ids.length; i++)
      if (seen[i] < thinEvidence) '${names[ids[i]]} (${seen[i]})',
  ];
  if (thin.isNotEmpty) {
    stdout.writeln(
      '⚠ ${thin.length} species still have fewer than $thinEvidence '
      'comparisons. Their positions are guesses:\n  ${thin.join(', ')}\n',
    );
  }

  stdout
    ..writeln('RANKED, RAREST FIRST')
    ..writeln(
      'rank  score   species                          '
      'likely range   duels  current tier',
    );
  for (int rank = 0; rank < order.length; rank++) {
    final int i = order[rank];
    final List<int> r = band[i]!;
    stdout.writeln(
      '${(rank + 1).toString().padLeft(4)}  '
      '${strength[i].toStringAsFixed(2).padLeft(6)}  '
      '${names[ids[i]]!.padRight(32)} '
      '${'${r[0]}–${r[1]}'.padLeft(9)}      '
      '${seen[i].toString().padLeft(4)}   ${tiers[ids[i]]}',
    );
  }

  File('build/rankings.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'submissions': contributors,
        'comparisons': comparisons,
        'method': 'Bradley-Terry MM, $bootstraps bootstraps',
        'ranked': <Map<String, dynamic>>[
          for (int rank = 0; rank < order.length; rank++)
            <String, dynamic>{
              'rank': rank + 1,
              'id': ids[order[rank]],
              'name': names[ids[order[rank]]],
              'score': double.parse(strength[order[rank]].toStringAsFixed(4)),
              'rankLow': band[order[rank]]![0],
              'rankHigh': band[order[rank]]![1],
              'comparisons': seen[order[rank]],
              'currentTier': tiers[ids[order[rank]]],
              'confident': seen[order[rank]] >= thinEvidence,
            },
        ],
      }),
    );

  stdout
    ..writeln('\nbuild/rankings.json written')
    ..writeln(
      perSpecies < 10
          ? '\nNOT ENOUGH DATA YET. Aim for at least 10 comparisons per species '
                '— roughly ${(10 * ids.length / 2 / 60).ceil()} more sittings.'
          : '\nCoverage looks healthy. Read the likely range before moving '
                'anything: an overlapping range means the order between those two '
                'is not settled.',
    );
}

/// Bradley-Terry strengths, fitted by MM.
///
/// Each iteration replaces every strength with wins divided by the sum, over
/// its opponents, of games weighted by the current pair strength. That step is
/// guaranteed not to decrease the likelihood, so this walks uphill to the
/// maximum-likelihood answer regardless of what order the data arrives in —
/// which is the whole reason for preferring it to Elo.
List<double> _fit(
  List<_Comparison> pool,
  int n, {
  int iterations = fitIterations,
}) {
  final List<double> wins = List<double>.filled(n, prior);
  final List<Map<int, double>> against = List<Map<int, double>>.generate(
    n,
    (_) => <int, double>{},
  );

  for (final _Comparison c in pool) {
    // A draw is half a win each way, which is what "about the same" means and
    // keeps the model in one piece rather than needing a separate tie term.
    wins[c.a] += c.score * c.weight;
    wins[c.b] += (1 - c.score) * c.weight;
    against[c.a][c.b] = (against[c.a][c.b] ?? 0) + c.weight;
    against[c.b][c.a] = (against[c.b][c.a] ?? 0) + c.weight;
  }
  // The prior's own games, against a notional average opponent, so a species
  // that won everything cannot run away to infinity.
  final List<double> priorGames = List<double>.filled(n, 2 * prior);

  List<double> p = List<double>.filled(n, 1);
  for (int it = 0; it < iterations; it++) {
    final List<double> next = List<double>.filled(n, 0);
    double mean = 0;
    for (int i = 0; i < n; i++) {
      mean += p[i];
    }
    mean /= n;

    for (int i = 0; i < n; i++) {
      double denom = priorGames[i] / (p[i] + mean);
      against[i].forEach((int j, double games) {
        denom += games / (p[i] + p[j]);
      });
      next[i] = denom == 0 ? p[i] : wins[i] / denom;
    }

    // Normalised to a geometric mean of 1, which keeps the numbers readable and
    // stops the whole vector drifting up or down between iterations.
    double logSum = 0;
    for (final double v in next) {
      logSum += math.log(v <= 0 ? 1e-12 : v);
    }
    final double scale = math.exp(logSum / n);
    for (int i = 0; i < n; i++) {
      next[i] /= scale;
    }
    p = next;
  }
  return p;
}

class _Comparison {
  const _Comparison(this.a, this.b, this.score, this.weight);

  final int a;
  final int b;

  /// 1 when [a] is rarer, 0 when [b] is, 0.5 for "about the same".
  final double score;

  final double weight;
}
