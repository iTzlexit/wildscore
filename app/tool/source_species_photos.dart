// Finds a legally usable photograph for every species that has not got one.
//
// This is the missing half of the picture pipeline. `prepare_species_photos`
// downscales what you already have; this is what *gets* it, and without it
// adding forty birds means forty manual searches and forty chances to paste in
// a licence nobody checked.
//
// Run from the app/ directory:
//   dart run tool/source_species_photos.dart              # everything missing
//   dart run tool/source_species_photos.dart puff-adder   # named ids only
//   dart run tool/source_species_photos.dart --all        # re-source everything
//
// Writes full-size images to build/sourced-photos/ and a candidate report to
// build/sourced-photos/report.json. Nothing lands in assets/ from here — run
// `prepare_species_photos build/sourced-photos` after checking the report, and
// merge the credits it prints into assets/data/attributions.json.
//
// **The licence filter is the point of this file.** This project walked into
// the non-commercial trap twice (docs/IMAGE-ASSETS.md). CC-BY-NC images look
// identical to CC-BY ones in a browser and are illegal in a paid app, so the
// allowed set is a hard-coded whitelist here and the API is asked to filter on
// it as well. Two locks on the same door, deliberately.

import 'dart:convert';
import 'dart:io';

/// The only licences that may ever ship.
///
/// CC0 is public domain. CC-BY requires attribution, which the app carries on
/// the photograph and in the credits screen. **Everything else is excluded**,
/// including every -NC and -ND variant: this app is sold, so "non-commercial"
/// is not a licence it can use, and "no derivatives" is broken by downscaling.
const Set<String> allowedLicences = <String>{'cc0', 'cc-by'};

/// iNaturalist asks for a real User-Agent and rate-limits hard without one.
const String userAgent = 'WildScore/1.0 (Kruger field guide; contact via repo)';

/// One request a second. Their published guidance is 60/minute and they are
/// giving this away for nothing.
const Duration politeDelay = Duration(seconds: 1);

/// Kruger sits inside South Africa; observations from here are of the same
/// subspecies in the same light, which matters for a guide people identify
/// animals from.
const int southAfricaPlaceId = 6986;

/// How many candidates `--candidates` fetches per species.
const int candidateCount = 8;

/// How many `--wide` offers instead.
///
/// For the species where every local option is poor, more of the same eight is
/// no help — the sheet has to get both bigger and less parochial.
const int wideCandidateCount = 20;

Future<void> main(List<String> args) async {
  final bool all = args.contains('--all');
  // Downloads several options per species instead of picking one, for the
  // cases where picking one went wrong. It goes wrong often enough to matter:
  // the first automated run produced two photographs of *roadkill* — a dead
  // barn owl on tar and a flattened boomslang on gravel — and three vultures
  // too distant to identify. iNaturalist is a biodiversity record, not a photo
  // library, and a dead animal by the road is a perfectly good record.
  final bool candidates = args.contains('--candidates');

  // Builds the page the owner picks from, rather than picking for him.
  //
  // Same search, same licence whitelist, no downloads: the picker loads the
  // photographs straight off iNaturalist by URL, so this writes metadata only
  // and finishes in minutes for the whole catalogue. Nothing is fetched until
  // he has chosen — see tool/apply_photo_picks.dart.
  final bool picker = args.contains('--picker');

  // A bigger, less parochial sheet for the species where every local option
  // was poor. Named ids only — see _ranked.
  final bool wide = args.contains('--wide');
  final Set<String> only = args.where((String a) => !a.startsWith('-')).toSet();

  if (picker) {
    await _buildPicker(only, all, wide);
    return;
  }

  final Map<String, dynamic> catalogue =
      json.decode(File('assets/data/species.json').readAsStringSync())
          as Map<String, dynamic>;
  final Map<String, dynamic> credits =
      json.decode(File('assets/data/attributions.json').readAsStringSync())
          as Map<String, dynamic>;
  final Set<String> haveCredit = <String>{
    for (final dynamic e in credits['photos'] as List<dynamic>)
      (e as Map<String, dynamic>)['id'] as String,
  };

  final List<Map<String, dynamic>> wanted = <Map<String, dynamic>>[
    for (final dynamic s in catalogue['species'] as List<dynamic>)
      if (only.isNotEmpty
          ? only.contains((s as Map<String, dynamic>)['id'])
          : all || !haveCredit.contains((s as Map<String, dynamic>)['id']))
        s as Map<String, dynamic>,
  ];

  if (wanted.isEmpty) {
    stdout.writeln('Nothing to source. Every species already has a credit.');
    return;
  }

  final Directory out = Directory('build/sourced-photos')
    ..createSync(recursive: true);
  final HttpClient http = HttpClient()..userAgent = userAgent;
  final List<Map<String, dynamic>> report = <Map<String, dynamic>>[];
  final List<String> failed = <String>[];

  stdout.writeln('Sourcing ${wanted.length} species…\n');

  for (final Map<String, dynamic> species in wanted) {
    final String id = species['id'] as String;
    final String latin = species['scientificName'] as String;

    if (candidates) {
      final List<_Candidate> options = await _ranked(http, latin);
      for (int i = 0; i < options.length && i < candidateCount; i++) {
        await _download(
          http,
          options[i].photoUrl,
          File('${out.path}/$id~$i.jpg'),
        );
        report.add(<String, dynamic>{
          'id': '$id~$i',
          'author': options[i].author,
          'license': options[i].licence,
          'source': options[i].observationUrl,
          'place': options[i].place,
        });
      }
      stdout.writeln(
        '  · $id — ${options.length.clamp(0, candidateCount)} candidates',
      );
      if (options.isEmpty) {
        failed.add(id);
      }
      await Future<void>.delayed(politeDelay);
      continue;
    }

    final _Candidate? best = await _best(http, latin);
    if (best == null) {
      stdout.writeln('  ✗ $id — no CC0/CC-BY photo found for $latin');
      failed.add(id);
      await Future<void>.delayed(politeDelay);
      continue;
    }

    final File file = File('${out.path}/$id.jpg');
    await _download(http, best.photoUrl, file);
    stdout.writeln(
      '  ✓ $id — ${best.licence.toUpperCase()}, ${best.author}'
      '${best.inSouthAfrica ? ' (ZA)' : ''}',
    );

    report.add(<String, dynamic>{
      'id': id,
      'author': best.author,
      'license': best.licence,
      'source': best.observationUrl,
      'place': best.place,
    });
    await Future<void>.delayed(politeDelay);
  }

  http.close();

  // Merged with whatever is already there, keyed on id. Each run used to
  // overwrite the file wholesale, which quietly destroyed the credits for
  // everything sourced on the previous run — and a photograph whose licence
  // and author have been lost is a photograph that cannot ship.
  final File reportFile = File('${out.path}/report.json');
  final Map<String, Map<String, dynamic>> merged =
      <String, Map<String, dynamic>>{};
  if (reportFile.existsSync()) {
    final Map<String, dynamic> old =
        json.decode(reportFile.readAsStringSync()) as Map<String, dynamic>;
    for (final dynamic e in old['photos'] as List<dynamic>) {
      merged[(e as Map<String, dynamic>)['id'] as String] = e;
    }
  }
  for (final Map<String, dynamic> e in report) {
    merged[e['id'] as String] = e;
  }
  final List<String> keys = merged.keys.toList()..sort();
  reportFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'photos': <Map<String, dynamic>>[for (final String k in keys) merged[k]!],
    }),
  );

  stdout
    ..writeln('\n${report.length} sourced, ${failed.length} failed.')
    ..writeln('Images:  ${out.path}')
    ..writeln(
      'Credits: ${out.path}/report.json — merge into '
      'assets/data/attributions.json',
    )
    ..writeln('\nThen: dart run tool/prepare_species_photos.dart ${out.path}');

  if (failed.isNotEmpty) {
    stdout.writeln(
      '\nNo usable photo for: ${failed.join(', ')}\n'
      'These need either a silhouette (photoVerified: false) or a hand-picked '
      'image. Do not lower the licence bar for them.',
    );
    exitCode = 1;
  }
}

/// The best usable photograph of this species, or null.
///
/// Asks twice: South Africa first, then anywhere. A Kruger photograph is worth
/// more than a better-lit one from a zoo in Europe, because the whole job of
/// the picture is to match what is standing in the road.
/// Writes `tools/photo-candidates.json` and regenerates `tools/photo-picker.html`.
///
/// The picker existed once, for four species, as a hand-written page with the
/// candidates pasted into it. That is why it went away: it was a one-off, so
/// the next hundred species were chosen by a machine instead, and the machine
/// picked a dead hornbill. This makes the page reproducible for any set of
/// species, which is the only version of it worth having.
Future<void> _buildPicker(Set<String> only, bool all, bool wide) async {
  final Map<String, dynamic> catalogue =
      json.decode(File('assets/data/species.json').readAsStringSync())
          as Map<String, dynamic>;

  final List<Map<String, dynamic>> wanted = <Map<String, dynamic>>[
    for (final dynamic s in catalogue['species'] as List<dynamic>)
      if (only.isEmpty || only.contains((s as Map<String, dynamic>)['id']))
        s as Map<String, dynamic>,
  ];

  final File template = File('../tools/photo-picker.template.html');
  if (!template.existsSync()) {
    stderr.writeln('missing ${template.path} — run this from app/');
    exitCode = 66;
    return;
  }

  final HttpClient http = HttpClient()..userAgent = userAgent;
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  int done = 0;

  stdout.writeln('Fetching options for ${wanted.length} species…\n');

  for (final Map<String, dynamic> species in wanted) {
    final String id = species['id'] as String;
    final List<_Candidate> options = await _ranked(
      http,
      species['scientificName'] as String,
      wide: wide,
    );

    final int cap = wide ? wideCandidateCount : candidateCount;
    for (int i = 0; i < options.length && i < cap; i++) {
      rows.add(<String, dynamic>{
        'id': id,
        'name': species['commonName'],
        'sci': species['scientificName'],
        'photo': options[i].photoUrl,
        'license': options[i].licence,
        'author': options[i].author,
        'obs': options[i].observationUrl,
        'place': options[i].place,
      });
    }

    done++;
    if (done % 10 == 0 || done == wanted.length) {
      stdout.writeln('  $done / ${wanted.length}');
    }
    await Future<void>.delayed(politeDelay);
  }
  http.close();

  // Belt and braces. The API is asked to filter and _Candidate filters again;
  // this is the third check, on the exact bytes about to be published in a page
  // somebody will pick from.
  final Iterable<Map<String, dynamic>> illegal = rows.where(
    (Map<String, dynamic> r) => !allowedLicences.contains(r['license']),
  );
  if (illegal.isNotEmpty) {
    stderr.writeln(
      'refusing to write: ${illegal.length} rows are not CC0/CC-BY',
    );
    exitCode = 65;
    return;
  }

  // A run for named species writes its own page rather than replacing the full
  // one. Redoing nine birds should not throw away the sheet for the other
  // hundred and eighty.
  final String suffix = only.isEmpty ? '' : '-redo';
  File(
    '../tools/photo-candidates$suffix.json',
  ).writeAsStringSync(json.encode(rows));
  File('../tools/photo-picker$suffix.html').writeAsStringSync(
    template
        .readAsStringSync()
        .replaceFirst('/*__CANDIDATES__*/[]', json.encode(rows))
        .replaceFirst(
          'Search 191 species…',
          'Search ${wanted.length} species…',
        ),
  );

  final int kb = (json.encode(rows).length / 1024).round();
  stdout
    ..writeln('')
    ..writeln(
      'tools/photo-picker$suffix.html — ${wanted.length} species, '
      '${rows.length} options, $kb KB',
    )
    ..writeln('')
    ..writeln('Open it, pick, press Export, and paste the JSON back. Then:')
    ..writeln('  dart run tool/apply_photo_picks.dart <picks.json>');
}

Future<_Candidate?> _best(HttpClient http, String latin) async {
  final List<_Candidate> found = await _ranked(http, latin);
  return found.isEmpty ? null : found.first;
}

/// Every usable candidate, best guess first.
///
/// **Ranked by how good the photograph is, not by licence.** The first version
/// sorted CC0 ahead of CC-BY, which sounds prudent and produced a dead owl on
/// tarmac: both licences are equally fine to ship, so preferring one of them
/// buys nothing and throws away the better picture. Licence is a filter, and
/// filters do not belong in sort orders.
///
/// Votes are the only quality signal the API gives, and a photograph other
/// naturalists have faved is one where the animal is visible and correctly
/// named. It is a weak signal, which is why `--candidates` exists.
Future<List<_Candidate>> _ranked(
  HttpClient http,
  String latin, {
  bool wide = false,
}) async {
  final List<_Candidate> found = <_Candidate>[
    ...await _search(http, latin, place: southAfricaPlaceId),
  ];

  // Normally the rest of the world is only consulted when South Africa cannot
  // fill the sheet. `--wide` always consults it, which is the whole point: for
  // a species where all eight local options are poor, "eight local options" is
  // the problem and not the answer. A white-headed vulture in Botswana is the
  // same bird.
  if (wide || found.length < candidateCount) {
    final Set<String> have = found.map((_Candidate c) => c.photoUrl).toSet();
    for (final _Candidate c in await _search(http, latin)) {
      if (have.add(c.photoUrl)) {
        found.add(c);
      }
    }
  }
  // Local first — a Kruger animal photographed in Kruger is the one that
  // matches what is standing in the road — then by votes.
  found.sort((_Candidate a, _Candidate b) {
    if (a.inSouthAfrica != b.inSouthAfrica) {
      return a.inSouthAfrica ? -1 : 1;
    }
    return b.votes.compareTo(a.votes);
  });
  return found;
}

Future<List<_Candidate>> _search(
  HttpClient http,
  String latin, {
  int? place,
}) async {
  final Uri uri = Uri.https(
    'api.inaturalist.org',
    '/v1/observations',
    <String, String>{
      'taxon_name': latin,
      // Belt: the API filters, and _Candidate refuses anything that slips past.
      'photo_license': allowedLicences.join(','),
      'quality_grade': 'research',
      'photos': 'true',
      'order_by': 'votes',
      'per_page': '30',
      if (place != null) 'place_id': '$place',
    },
  );

  final Map<String, dynamic>? body = await _getJson(http, uri);
  if (body == null) {
    return const <_Candidate>[];
  }

  return <_Candidate>[
    for (final dynamic r in body['results'] as List<dynamic>)
      if (_Candidate.from(r as Map<String, dynamic>, place != null)
          case final _Candidate c)
        c,
  ];
}

Future<Map<String, dynamic>?> _getJson(HttpClient http, Uri uri) async {
  try {
    final HttpClientRequest request = await http.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final HttpClientResponse response = await request.close();
    if (response.statusCode != 200) {
      stderr.writeln('  ! ${response.statusCode} from $uri');
      return null;
    }
    return json.decode(await response.transform(utf8.decoder).join())
        as Map<String, dynamic>;
  } on Object catch (e) {
    stderr.writeln('  ! $e');
    return null;
  }
}

Future<void> _download(HttpClient http, String url, File to) async {
  final HttpClientRequest request = await http.getUrl(Uri.parse(url));
  final HttpClientResponse response = await request.close();
  await to.openWrite().addStream(response);
}

class _Candidate {
  const _Candidate({
    required this.photoUrl,
    required this.licence,
    required this.author,
    required this.observationUrl,
    required this.place,
    required this.votes,
    required this.inSouthAfrica,
  });

  /// Null unless the observation has a photograph under a licence this app is
  /// actually allowed to ship. The API is asked to filter on the same set;
  /// this is the second lock, because a filter that silently stops working
  /// would put a non-commercial image into a paid app.
  static _Candidate? from(Map<String, dynamic> obs, bool inSouthAfrica) {
    final List<dynamic> photos = (obs['photos'] as List<dynamic>?) ?? const [];
    for (final dynamic p in photos) {
      final Map<String, dynamic> photo = p as Map<String, dynamic>;
      final String? licence = photo['license_code'] as String?;
      if (licence == null || !allowedLicences.contains(licence)) {
        continue;
      }
      final String? url = photo['url'] as String?;
      if (url == null) {
        continue;
      }
      final Map<String, dynamic>? user = obs['user'] as Map<String, dynamic>?;
      final String author = licence == 'cc0'
          ? 'Public domain (CC0)'
          : (user?['name'] as String?)?.trim().isNotEmpty ?? false
          ? user!['name'] as String
          : (user?['login'] as String?) ?? 'Unknown';

      return _Candidate(
        // The API returns a square thumbnail; `large` is the same photo at
        // roughly 1024px, which is what prepare_species_photos expects.
        photoUrl: url.replaceFirst('/square.', '/large.'),
        licence: licence,
        author: author,
        observationUrl: 'https://www.inaturalist.org/observations/${obs['id']}',
        place: (obs['place_guess'] as String?) ?? '',
        votes: (obs['cached_votes_total'] as num?)?.toInt() ?? 0,
        inSouthAfrica: inSouthAfrica,
      );
    }
    return null;
  }

  final String photoUrl;
  final String licence;
  final String author;
  final String observationUrl;
  final String place;
  final int votes;
  final bool inSouthAfrica;
}
