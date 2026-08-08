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
//   dart run tool/build_ranker.dart --whatsapp 27821234567
//
// The WhatsApp number is optional and is only used to pre-fill the share
// button. Without it the button still works, it just asks the sender to pick
// a contact.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final int flag = args.indexOf('--whatsapp');
  final String whatsapp = flag == -1 ? '' : args[flag + 1].replaceAll('+', '');

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
      .replaceFirst('/*__WHATSAPP__*/', whatsapp);

  File('../tools/ranker.html').writeAsStringSync(out);

  final int kb = (out.length / 1024).round();
  stdout
    ..writeln('tools/ranker.html — ${lean.length} species, $kb KB')
    ..writeln(
      whatsapp.isEmpty
          ? 'No WhatsApp number baked in; the share button will ask for a contact.'
          : 'WhatsApp share goes to $whatsapp.',
    );
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
