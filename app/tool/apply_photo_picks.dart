// Takes the JSON the photo picker exports and makes it real.
//
// Downloads each chosen photograph, downscales it into assets/species/, and
// rewrites its credit in assets/data/attributions.json. Nothing else in the
// catalogue is touched — a species the owner did not pick keeps exactly the
// photograph it has.
//
// Run from the app/ directory:
//   dart run tool/apply_photo_picks.dart picks.json
//   dart run tool/apply_photo_picks.dart picks.json --dry-run
//
// The input is whatever **Export** put on the clipboard: a map of species id to
// the chosen candidate, each carrying its own licence and photographer. Those
// are the values written to the credits file, so the attribution that ships is
// the attribution attached to the photograph he actually clicked — not one
// re-derived later against a URL that may by then point somewhere else.
//
// **The licence whitelist is checked again here.** The picker only ever shows
// CC0 and CC-BY, but this reads a file off the clipboard and a paid app cannot
// ship a non-commercial image. Cheap to check, expensive to get wrong.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const Set<String> allowedLicences = <String>{'cc0', 'cc-by'};
const String userAgent = 'WildScore/1.0 (Kruger field guide; contact via repo)';

/// Matches tool/prepare_species_photos.dart. A photograph arriving this way
/// must end up the same size and quality as one arriving the other way.
const int maxDimension = 800;
const int jpegQuality = 72;

Future<void> main(List<String> args) async {
  final List<String> files = args
      .where((String a) => !a.startsWith('-'))
      .toList();
  final bool dryRun = args.contains('--dry-run');

  if (files.isEmpty) {
    stderr.writeln('usage: dart run tool/apply_photo_picks.dart <picks.json>');
    exitCode = 64;
    return;
  }

  final File input = File(files.first);
  if (!input.existsSync()) {
    stderr.writeln('not found: ${input.path}');
    exitCode = 66;
    return;
  }

  final Map<String, dynamic> picks =
      json.decode(input.readAsStringSync()) as Map<String, dynamic>;
  if (picks.isEmpty) {
    stdout.writeln('No picks in that file. Nothing changed.');
    return;
  }

  final Map<String, dynamic> catalogue =
      json.decode(File('assets/data/species.json').readAsStringSync())
          as Map<String, dynamic>;
  final Set<String> knownIds = <String>{
    for (final dynamic s in catalogue['species'] as List<dynamic>)
      (s as Map<String, dynamic>)['id'] as String,
  };

  // Everything is validated before anything is written. A half-applied batch
  // leaves the catalogue with photographs whose credits belong to other
  // photographs, which is the one failure here with a legal edge to it.
  final List<String> problems = <String>[];
  for (final MapEntry<String, dynamic> e in picks.entries) {
    final Map<String, dynamic> pick = e.value as Map<String, dynamic>;
    if (!knownIds.contains(e.key)) {
      problems.add('${e.key}: no such species');
    }
    if (!allowedLicences.contains(pick['license'])) {
      problems.add('${e.key}: licence "${pick['license']}" may not ship');
    }
    if ((pick['photo'] as String?)?.isEmpty ?? true) {
      problems.add('${e.key}: no photo url');
    }
    if ((pick['author'] as String?)?.trim().isEmpty ?? true) {
      problems.add('${e.key}: no photographer, and CC-BY requires one');
    }
  }
  if (problems.isNotEmpty) {
    stderr.writeln('Refusing to apply — ${problems.length} problem(s):');
    for (final String p in problems) {
      stderr.writeln('  $p');
    }
    exitCode = 65;
    return;
  }

  stdout.writeln('${picks.length} photograph(s) to replace…\n');

  final HttpClient http = HttpClient()..userAgent = userAgent;
  final Map<String, Map<String, dynamic>> newCredits =
      <String, Map<String, dynamic>>{};
  final List<String> failed = <String>[];

  for (final MapEntry<String, dynamic> e in picks.entries) {
    final String id = e.key;
    final Map<String, dynamic> pick = e.value as Map<String, dynamic>;

    try {
      final Uint8List bytes = await _get(http, pick['photo'] as String);
      // Format-agnostic: iNaturalist serves PNG for some observations
      // regardless of what the URL says.
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        failed.add('$id — could not decode');
        continue;
      }

      final bool landscape = decoded.width >= decoded.height;
      final int longest = landscape ? decoded.width : decoded.height;
      final img.Image resized = longest > maxDimension
          ? img.copyResize(
              decoded,
              width: landscape ? maxDimension : null,
              height: landscape ? null : maxDimension,
              interpolation: img.Interpolation.average,
            )
          : decoded;
      final List<int> encoded = img.encodeJpg(resized, quality: jpegQuality);

      if (!dryRun) {
        File('assets/species/$id.jpg').writeAsBytesSync(encoded);
      }
      newCredits[id] = <String, dynamic>{
        'id': id,
        'author': pick['author'],
        'license': pick['license'],
        'source': pick['obs'],
      };

      stdout.writeln(
        '  ${dryRun ? '·' : '✓'} ${id.padRight(32)} '
        '${(encoded.length / 1024).round()} KB  '
        '${resized.width}x${resized.height}  ${pick['license']}',
      );
    } on Object catch (err) {
      failed.add('$id — $err');
    }
  }
  http.close();

  if (!dryRun && newCredits.isNotEmpty) {
    final File file = File('assets/data/attributions.json');
    final Map<String, dynamic> credits =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final List<dynamic> photos = credits['photos'] as List<dynamic>;

    for (int i = 0; i < photos.length; i++) {
      final Map<String, dynamic> row = photos[i] as Map<String, dynamic>;
      final Map<String, dynamic>? replacement = newCredits[row['id']];
      if (replacement != null) {
        photos[i] = replacement;
      }
    }
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(credits)}\n',
    );
  }

  stdout
    ..writeln('')
    ..writeln(
      '${newCredits.length} applied, ${failed.length} failed'
      '${dryRun ? '  (dry run — nothing written)' : ''}',
    );
  for (final String f in failed) {
    stdout.writeln('  ✗ $f');
  }
}

Future<Uint8List> _get(HttpClient http, String url) async {
  final HttpClientRequest req = await http.getUrl(Uri.parse(url));
  final HttpClientResponse res = await req.close();
  if (res.statusCode != 200) {
    throw HttpException('HTTP ${res.statusCode}');
  }
  final BytesBuilder out = BytesBuilder(copy: false);
  await for (final List<int> chunk in res) {
    out.add(chunk);
  }
  return out.takeBytes();
}
