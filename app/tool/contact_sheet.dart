// Lays the species photographs out in a grid so they can be checked in one
// look — is that actually a Puff Adder, is the animal big enough in frame, is
// the light usable.
//
// A misidentified photograph in a field guide is worse than no photograph:
// somebody learns the wrong animal from it and then claims the wrong points.
// Automated sourcing makes that failure cheap to introduce and invisible, so
// the grid is how it stays checked.
//
//   dart run tool/contact_sheet.dart                    # everything in assets
//   dart run tool/contact_sheet.dart puff-adder ...     # named ids
//   dart run tool/contact_sheet.dart --dir build/x      # any folder of jpgs
//
// Writes build/contact-sheet.jpg.

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

const int cell = 260;
const int columns = 5;
const int labelHeight = 22;

void main(List<String> args) {
  final int dirFlag = args.indexOf('--dir');
  final String folder = dirFlag == -1 ? 'assets/species' : args[dirFlag + 1];
  final List<String> names = <String>[
    for (int i = 0; i < args.length; i++)
      if (args[i] != '--dir' && (i == 0 || args[i - 1] != '--dir')) args[i],
  ];

  final List<String> ids;
  if (dirFlag != -1) {
    ids =
        Directory(folder)
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.jpg'))
            .map((File f) => f.uri.pathSegments.last.replaceAll('.jpg', ''))
            .toList()
          ..sort();
  } else {
    final Map<String, dynamic> catalogue =
        json.decode(File('assets/data/species.json').readAsStringSync())
            as Map<String, dynamic>;
    ids = <String>[
      for (final dynamic s in catalogue['species'] as List<dynamic>)
        if (names.isEmpty || names.contains((s as Map<String, dynamic>)['id']))
          (s as Map<String, dynamic>)['id'] as String,
    ]..removeWhere((String id) => !File('$folder/$id.jpg').existsSync());
  }

  if (ids.isEmpty) {
    stderr.writeln('no matching images in $folder');
    exitCode = 66;
    return;
  }

  final int rows = (ids.length / columns).ceil();
  final img.Image sheet = img.Image(
    width: columns * cell,
    height: rows * (cell + labelHeight),
  );
  img.fill(sheet, color: img.ColorRgb8(16, 16, 16));

  for (int i = 0; i < ids.length; i++) {
    // Format-agnostic. iNaturalist serves PNG for some observations regardless
    // of what the filename says, and `decodeJpg` throws on the first one —
    // taking the whole sheet down rather than the one picture.
    final img.Image? photo = img.decodeImage(
      File('$folder/${ids[i]}.jpg').readAsBytesSync(),
    );
    if (photo == null) {
      continue;
    }
    final int x = (i % columns) * cell;
    final int y = (i ~/ columns) * (cell + labelHeight);

    // Contained, not cropped — the same rule the detail screen follows, and for
    // the same reason: a crop can hide exactly the part of the animal that
    // would show the identification is wrong.
    final double scale = photo.width / photo.height > 1
        ? (cell - 8) / photo.width
        : (cell - 8) / photo.height;
    final img.Image fitted = img.copyResize(
      photo,
      width: (photo.width * scale).round(),
      height: (photo.height * scale).round(),
      interpolation: img.Interpolation.average,
    );

    img.compositeImage(
      sheet,
      fitted,
      dstX: x + (cell - fitted.width) ~/ 2,
      dstY: y + (cell - fitted.height) ~/ 2,
    );
    img.drawString(
      sheet,
      ids[i],
      font: img.arial14,
      x: x + 4,
      y: y + cell + 3,
      color: img.ColorRgb8(210, 210, 210),
    );
  }

  File('build/contact-sheet.jpg')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodeJpg(sheet, quality: 88));
  stdout.writeln('build/contact-sheet.jpg — ${ids.length} images');
}
