// Downscales and re-encodes sourced species photographs into assets/species/.
//
// Source images from iNaturalist arrive at 100KB–1MB each. Seventy-one of those
// would add ~25MB to a 16MB app, which is a real cost in installs — plenty of
// people install over mobile data.
//
// Run from the app/ directory:
//   dart run tool/prepare_species_photos.dart <source-dir>
//   dart run tool/prepare_species_photos.dart <source-dir> --overwrite
//
// **By default an existing asset is never replaced**, and that default was
// bought the hard way. `build/sourced-photos/` accumulates — a run that sources
// thirty birds leaves those thirty files sitting there — so the next run over
// the same directory silently reprocesses all of them. Doing exactly that
// reverted seven photographs that had been re-picked by hand the session
// before, putting back a dead hornbill, a hadada reduced to a skeleton and a
// lapwing chick. Nothing failed; the tool reported success and the app shipped
// a bird's bones in a field guide.
//
// So replacing something already in assets/ has to be asked for. `--overwrite`
// is the intentional path, and the skipped list is printed either way.
//
// Not part of the app build. This is a one-off content pipeline that lives in
// the repo so it can be re-run when artwork changes.

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Cap on the **longest** side, not the width. Capping width alone leaves
/// portrait photographs untouched, which is how a 768x1024 image sailed through
/// at 309KB on the first run.
const int maxDimension = 800;

/// 72 is the point where JPEG artefacts stop being visible on photographs of
/// animals in bush, which is forgiving subject matter.
const int jpegQuality = 72;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/prepare_species_photos.dart <dir>');
    exitCode = 64;
    return;
  }

  final bool overwrite = args.contains('--overwrite');
  final Directory source = Directory(args.first);
  if (!source.existsSync()) {
    stderr.writeln('source directory not found: ${source.path}');
    exitCode = 66;
    return;
  }

  final Directory target = Directory('assets/species');
  target.createSync(recursive: true);

  final List<File> files =
      source
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.toLowerCase().endsWith('.jpg'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));

  int totalBefore = 0;
  int totalAfter = 0;
  int converted = 0;
  final List<String> kept = <String>[];

  for (final File file in files) {
    final String name = file.uri.pathSegments.last;

    if (!overwrite && File('${target.path}/$name').existsSync()) {
      kept.add(name);
      continue;
    }

    final Uint8List bytes = file.readAsBytesSync();
    // Format-agnostic: iNaturalist serves PNG for some observations, and a
    // `.jpg` filename says nothing about the actual encoding. decodeJpg throws
    // on those; decodeImage sniffs the header.
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      stdout.writeln('  SKIP (undecodable)  $name');
      continue;
    }

    final bool isLandscape = decoded.width >= decoded.height;
    final int longest = isLandscape ? decoded.width : decoded.height;

    final img.Image resized = longest > maxDimension
        ? img.copyResize(
            decoded,
            width: isLandscape ? maxDimension : null,
            height: isLandscape ? null : maxDimension,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    final List<int> encoded = img.encodeJpg(resized, quality: jpegQuality);
    File('${target.path}/$name').writeAsBytesSync(encoded);

    totalBefore += bytes.length;
    totalAfter += encoded.length;
    converted++;

    stdout.writeln(
      '  ${name.padRight(34)} '
      '${_kb(bytes.length).padLeft(7)} -> ${_kb(encoded.length).padLeft(7)}'
      '   ${resized.width}x${resized.height}',
    );
  }

  stdout
    ..writeln('')
    ..writeln('$converted images')
    ..writeln('before: ${_mb(totalBefore)}')
    ..writeln('after:  ${_mb(totalAfter)}');

  if (kept.isNotEmpty) {
    stdout
      ..writeln('')
      ..writeln('${kept.length} left alone — already in assets/species:')
      ..writeln('  ${kept.join(', ')}')
      ..writeln('')
      ..writeln('Pass --overwrite if you mean to replace them.');
  }
}

String _kb(int bytes) => '${(bytes / 1024).round()} KB';

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
