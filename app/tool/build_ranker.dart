// Builds tools/ranker.html from the template and the live species catalogue.
//
// The ranker gets handed to strangers — Facebook groups, field guides, a couple
// with a YouTube channel — so it has to be one self-contained file with no
// server, no build step on their side and no sign-up. That means the catalogue
// is baked in, and that means it goes stale the moment a species is added.
// Hence a generator rather than a hand-edited file.
//
// Run from the app/ directory:
//   dart run tool/build_ranker.dart
//   dart run tool/build_ranker.dart --email me@example.com
//
// Hosted on Netlify the page posts the answers by itself, through a Netlify
// Form that needs no configuration beyond deploying the file. That is how
// results are meant to arrive — the person answering does nothing at all.
//
// --email is only the fallback, shown when that automatic send fails. It is
// not defaulted, because this file gets posted in public Facebook groups and
// an address sitting in the source is an address that gets scraped.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final int em = args.indexOf('--email');
  final String email = em == -1 ? '' : args[em + 1];

  final File template = File('../tools/ranker.template.html');
  final File catalogue = File('assets/data/species.json');
  if (!template.existsSync() || !catalogue.existsSync()) {
    stderr.writeln('run this from the app/ directory');
    exitCode = 66;
    return;
  }

  final Map<String, dynamic> data =
      json.decode(catalogue.readAsStringSync()) as Map<String, dynamic>;

  // Only what the ranker needs to ask a fair question.
  //
  // No points and no tier: showing somebody the answer we already guessed would
  // anchor them to it, and the whole reason this exists is that our guess is
  // not trustworthy. No description either — the audience is people who know
  // Kruger, who read "Serval" and are already deciding, and sixty descriptions
  // is sixty things to skip.
  // Common and Frequent are left out of the survey entirely.
  //
  // Not to save the respondent time — to spend their time where it is worth
  // something. Every question a person answers is one comparison, and a
  // comparison between a laughing dove and an impala tells us nothing we did
  // not already know. The tiers that are genuinely uncertain are Notable and
  // up, which is where a caracal, a serval and a cheetah all sit together
  // without anybody being sure of the order.
  //
  // The arithmetic matters as much as the principle. Each respondent ranks a
  // random subset, so the chance a given species appears is subset ÷ pool. At
  // 191 species that is 13%, and the number of respondents needed to fit a
  // decent model roughly doubles. Cutting the pool to the 80 that need it puts
  // it back to 30% — better than the 96-species pool this was tuned against.
  final List<Map<String, String>> lean = <Map<String, String>>[
    for (final dynamic s in data['species'] as List<dynamic>)
      if (!<String>{
        'common',
        'frequent',
      }.contains((s as Map<String, dynamic>)['rarityTier'] as String))
        <String, String>{
          'id': s['id'] as String,
          'name': s['commonName'] as String,
          'afr': s['afrikaansName'] as String,
        },
  ];

  final String out = template
      .readAsStringSync()
      .replaceFirst('/*__CATALOGUE__*/[]', json.encode(lean))
      .replaceFirst('/*__EMAIL__*/', email);

  File('../tools/ranker.html').writeAsStringSync(out);

  final int kb = (out.length / 1024).round();
  stdout
    ..writeln('tools/ranker.html — ${lean.length} species, $kb KB')
    ..writeln('')
    ..writeln('How answers come back:')
    ..writeln(
      '  1. By themselves, if you host this on Netlify. The person '
      'answering does nothing.',
    )
    ..writeln(
      email.isEmpty
          ? '  2. Fallback only, if that fails: no email button '
                '(pass --email you@example.com to add one)'
          : '  2. Fallback only, if that fails: email button to $email',
    );
}
