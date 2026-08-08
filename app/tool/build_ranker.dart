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
//   dart run tool/build_ranker.dart --whatsapp 27821234567 --email me@example.com
//
// Both are optional and both only affect how a finished set of answers gets
// back to you. The WhatsApp number pre-fills the share sheet; without it the
// button still works, it just asks the sender to pick a contact. The email
// address is not defaulted, because this file gets posted in public Facebook
// groups and an address sitting in the source is an address that gets scraped —
// so leaving it out hides the button entirely.
//
// Hosted on Netlify the page also posts the answers by itself, via a Netlify
// Form that needs no configuration beyond deploying the file. That is the route
// that actually collects most of the responses; the buttons are the fallback.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final int wa = args.indexOf('--whatsapp');
  final String whatsapp = wa == -1 ? '' : args[wa + 1].replaceAll('+', '');
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

  // Only what the ranker needs to ask a fair question. No points and no tier:
  // showing somebody the answer we already guessed would anchor them to it, and
  // the whole reason this exists is that our guess is not trustworthy.
  final List<Map<String, String>> lean = <Map<String, String>>[
    for (final dynamic s in data['species'] as List<dynamic>)
      <String, String>{
        'id': (s as Map<String, dynamic>)['id'] as String,
        'name': s['commonName'] as String,
        'afr': s['afrikaansName'] as String,
        'cat': s['category'] as String,
        'desc': _firstSentence(s['description'] as String),
      },
  ];

  final String out = template
      .readAsStringSync()
      .replaceFirst('/*__CATALOGUE__*/[]', json.encode(lean))
      .replaceFirst('/*__WHATSAPP__*/', whatsapp)
      .replaceFirst('/*__EMAIL__*/', email);

  File('../tools/ranker.html').writeAsStringSync(out);

  final int kb = (out.length / 1024).round();
  stdout
    ..writeln('tools/ranker.html — ${lean.length} species, $kb KB')
    ..writeln('')
    ..writeln('How answers come back:')
    ..writeln('  1. Automatically, if you host it on Netlify — no setup needed')
    ..writeln(
      whatsapp.isEmpty
          ? '  2. WhatsApp button — asks the sender to pick a contact '
                '(pass --whatsapp 27… to aim it at you)'
          : '  2. WhatsApp button — goes straight to $whatsapp',
    )
    ..writeln(
      email.isEmpty
          ? '  3. Email button — hidden (pass --email you@example.com to show it)'
          : '  3. Email button — goes to $email',
    )
    ..writeln('  4. The code on screen, copied and pasted anywhere');
}

/// The first sentence of the description, so a card stays a card.
///
/// Somebody being asked to rank a suni needs to know what a suni is, and the
/// full description is three sentences of field notes that nobody reads at the
/// pace this thing is answered.
String _firstSentence(String description) {
  final int stop = description.indexOf('. ');
  return stop == -1 ? description : description.substring(0, stop + 1);
}
