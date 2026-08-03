// Draws the launcher icon at every density Android needs, plus the 512px
// version the Play Console asks for.
//
//   dart run tool/generate_icon.dart
//
// Generated rather than drawn in an editor so the mark can be adjusted by
// changing a number here, and so it never drifts from the paw in AppHeader.
// Not part of the app build.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// The accent green from shared/theme.dart. If that changes, change this.
const int _bgR = 0x1B;
const int _bgG = 0x7A;
const int _bgB = 0x54;

/// Legacy square-ish launcher icons, and the store listing.
const Map<String, int> _legacy = <String, int>{
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
};

/// Adaptive icon foregrounds. Android crops these to a shape, and only the
/// middle 66/108 is guaranteed visible — hence the small paw inside a large
/// transparent canvas.
const Map<String, int> _foreground = <String, int>{
  'android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png': 108,
  'android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png': 162,
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png': 216,
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png': 324,
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
};

void main() {
  _legacy.forEach((String path, int size) {
    _write(path, _icon(size, withBackground: true));
  });
  _foreground.forEach((String path, int size) {
    // 0.42 keeps the paw inside the 61% safe zone with room to spare, so no
    // launcher shape can clip a toe off.
    _write(path, _icon(size, withBackground: false, pawScale: 0.42));
  });

  // Google Play requires exactly 512x512, 32-bit PNG, no transparency.
  _write('../store/icon-512.png', _icon(512, withBackground: true));

  stdout.writeln('done');
}

img.Image _icon(
  int size, {
  required bool withBackground,
  double pawScale = 0.56,
}) {
  final img.Image canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  if (withBackground) {
    _roundedSquare(canvas, size);
  }
  _paw(canvas, size, pawScale);
  return canvas;
}

/// A squircle-ish rounded square. Android masks adaptive icons itself, but the
/// legacy ones and the store listing need their own shape.
void _roundedSquare(img.Image canvas, int size) {
  final double radius = size * 0.22;
  final img.ColorRgba8 green = img.ColorRgba8(_bgR, _bgG, _bgB, 255);

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if (_insideRounded(x.toDouble(), y.toDouble(), size.toDouble(), radius)) {
        canvas.setPixel(x, y, green);
      }
    }
  }
}

bool _insideRounded(double x, double y, double size, double r) {
  final double cx = x < r ? r : (x > size - r ? size - r : x);
  final double cy = y < r ? r : (y > size - r ? size - r : y);
  final double dx = x - cx;
  final double dy = y - cy;
  return dx * dx + dy * dy <= r * r;
}

/// Four toes and a pad. The same shape as the header mark, drawn by hand
/// because a paw is five ellipses and not worth a dependency.
void _paw(img.Image canvas, int size, double scale) {
  final img.ColorRgba8 white = img.ColorRgba8(255, 255, 255, 255);
  final double s = size * scale;
  final double cx = size / 2;
  // Sits slightly low: the toes read as "above" the pad, and centring on the
  // bounding box makes it look high.
  final double cy = size / 2 + s * 0.06;

  // Pad — a wide ellipse, sitting low.
  _ellipse(canvas, cx, cy + s * 0.24, s * 0.29, s * 0.235, white);

  // Toes, arced over the pad. Outer two sit lower and are slightly smaller,
  // which is what makes it read as a paw rather than as four dots.
  //
  // Gaps matter more than sizes here: at 48px a paw whose toes touch each
  // other reads as one blob, so these are spaced wider than looks right at
  // 512px.
  const List<List<double>> toes = <List<double>>[
    <double>[-0.40, -0.20, 0.115],
    <double>[-0.14, -0.36, 0.125],
    <double>[0.14, -0.36, 0.125],
    <double>[0.40, -0.20, 0.115],
  ];
  for (final List<double> toe in toes) {
    _ellipse(
      canvas,
      cx + s * toe[0],
      cy + s * toe[1],
      s * toe[2],
      s * toe[2] * 1.22,
      white,
    );
  }
}

/// Anti-aliased filled ellipse. `image` has fillCircle but no ellipse, and an
/// aliased icon looks cheap at 48px.
void _ellipse(
  img.Image canvas,
  double cx,
  double cy,
  double rx,
  double ry,
  img.ColorRgba8 colour,
) {
  final int minX = math.max(0, (cx - rx - 2).floor());
  final int maxX = math.min(canvas.width - 1, (cx + rx + 2).ceil());
  final int minY = math.max(0, (cy - ry - 2).floor());
  final int maxY = math.min(canvas.height - 1, (cy + ry + 2).ceil());

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      // Supersample 3x3 for a smooth edge.
      int hits = 0;
      for (int sy = 0; sy < 3; sy++) {
        for (int sx = 0; sx < 3; sx++) {
          final double px = x + (sx + 0.5) / 3;
          final double py = y + (sy + 0.5) / 3;
          final double dx = (px - cx) / rx;
          final double dy = (py - cy) / ry;
          if (dx * dx + dy * dy <= 1) {
            hits++;
          }
        }
      }
      if (hits == 0) {
        continue;
      }
      final double alpha = hits / 9;
      final img.Pixel under = canvas.getPixel(x, y);
      canvas.setPixel(
        x,
        y,
        img.ColorRgba8(
          _mix(under.r.toInt(), colour.r, alpha),
          _mix(under.g.toInt(), colour.g, alpha),
          _mix(under.b.toInt(), colour.b, alpha),
          math.max(under.a.toInt(), (alpha * 255).round()),
        ),
      );
    }
  }
}

int _mix(int under, num over, double alpha) =>
    (under * (1 - alpha) + over * alpha).round().clamp(0, 255);

void _write(String path, img.Image image) {
  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('  ${file.path}  ${image.width}px');
}
