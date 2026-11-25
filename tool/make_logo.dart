// Turns assets/branding/logo_original.jpg into the app's branding images.
// Run: dart run tool/make_logo.dart   (then: dart run flutter_launcher_icons)
//
// Output (all 1024x1024 PNG):
//   logo.png             emblem on white, used inside the splash circle
//   icon.png             full icon: gradient + gold-ringed badge (iOS, old Android)
//   icon_background.png  Android adaptive icon background (gradient + blobs)
//   icon_foreground.png  Android adaptive icon foreground (badge, transparent)
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const dir = 'assets/branding';
const size = 1024;

// Same colours as the splash screen (lib/config.dart BrandColors).
const goldDeep = [0xB9, 0x81, 0x00];
const gold = [0xE2, 0xA6, 0x0F];
const goldShine = [0xFF, 0xE0, 0x8A];
const blue = [0x1C, 0x8F, 0xD9];
const navy = [0x16, 0x32, 0x5C];
const bgTop = [0xD6, 0xEB, 0xFB]; // HIS: light blue
const bgMid = [0xFF, 0xFF, 0xFF];
const bgBottom = [0xCF, 0xEF, 0xE9]; // HIS: light teal
const teal = [0x1F, 0xA8, 0x9A];

void main() {
  final emblem = _loadEmblem();

  _write('logo.png', _emblemOnWhite(emblem, 0.94));

  final background = _background();
  _write('icon_background.png', background);

  final full = img.Image.from(background);
  _badge(full, emblem, radius: size * 0.40);
  _write('icon.png', full);

  // Adaptive foreground: flutter_launcher_icons adds a 16% inset, so a
  // 38% radius ends up ~78% of the visible circle, leaving the gradient around it.
  final fg = img.Image(width: size, height: size, numChannels: 4)
    ..clear(img.ColorRgba8(0, 0, 0, 0));
  _badge(fg, emblem, radius: size * 0.38);
  _write('icon_foreground.png', fg);
}

// ---------- emblem ----------

img.Image _loadEmblem() {
  final src =
      img.decodeImage(File('$dir/logo_original.jpg').readAsBytesSync())!;
  // Near-white, low-colour JPEG noise becomes pure white.
  for (final p in src) {
    final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
    final hi = max(r, max(g, b)), lo = min(r, min(g, b));
    if (lo > 228 && hi - lo < 22) {
      p
        ..r = 255
        ..g = 255
        ..b = 255;
    }
  }
  var x0 = src.width, y0 = src.height, x1 = 0, y1 = 0;
  for (final p in src) {
    if (p.r < 245 || p.g < 245 || p.b < 245) {
      x0 = min(x0, p.x);
      y0 = min(y0, p.y);
      x1 = max(x1, p.x);
      y1 = max(y1, p.y);
    }
  }
  stdout.writeln('emblem ${x1 - x0 + 1}x${y1 - y0 + 1}');
  return img.copyCrop(src,
      x: x0, y: y0, width: x1 - x0 + 1, height: y1 - y0 + 1);
}

img.Image _fit(img.Image emblem, double box) {
  final scale = box / max(emblem.width, emblem.height);
  return img.copyResize(emblem,
      width: (emblem.width * scale).round(),
      height: (emblem.height * scale).round(),
      interpolation: img.Interpolation.cubic);
}

img.Image _emblemOnWhite(img.Image emblem, double fill) {
  final canvas = img.Image(width: size, height: size, numChannels: 4)
    ..clear(img.ColorRgba8(255, 255, 255, 255));
  final e = _fit(emblem, size * fill);
  img.compositeImage(canvas, e,
      dstX: (size - e.width) ~/ 2, dstY: (size - e.height) ~/ 2);
  return canvas;
}

// ---------- background ----------

img.Image _background() {
  final bg = img.Image(width: size, height: size, numChannels: 4);
  for (final p in bg) {
    final t = p.y / (size - 1);
    final c = t < 0.5
        ? _mix(bgTop, bgMid, t / 0.5)
        : _mix(bgMid, bgBottom, (t - 0.5) / 0.5);
    p
      ..r = c[0]
      ..g = c[1]
      ..b = c[2]
      ..a = 255;
  }
  // Soft blobs like the splash: gold top-right, blue bottom-left.
  _blob(bg, size * 0.92, size * 0.02, size * 0.46, blue, 0.14);
  _blob(bg, size * 0.06, size * 1.02, size * 0.52, teal, 0.13);
  return bg;
}

void _blob(img.Image im, double cx, double cy, double r, List<int> c,
    double alpha) {
  for (final p in im) {
    final d = sqrt(pow(p.x - cx, 2) + pow(p.y - cy, 2));
    final a = (r - d + 0.5).clamp(0.0, 1.0) * alpha;
    if (a > 0) _blend(p, c, a);
  }
}

// ---------- badge ----------

/// White circle with a gold ring and drop shadow, emblem inside.
void _badge(img.Image im, img.Image emblem, {required double radius}) {
  final cx = size / 2, cy = size / 2;
  final ring = radius * 0.075;
  final inner = radius - ring;

  // Shadow: navy disc, blurred, slightly lower; plus a warm gold glow.
  final shadow = img.Image(width: size, height: size, numChannels: 4)
    ..clear(img.ColorRgba8(0, 0, 0, 0));
  for (final p in shadow) {
    final glow = sqrt(pow(p.x - cx, 2) + pow(p.y - cy, 2));
    final drop = sqrt(pow(p.x - cx, 2) + pow(p.y - (cy + radius * 0.07), 2));
    if (drop < radius) {
      p
        ..r = navy[0]
        ..g = navy[1]
        ..b = navy[2]
        ..a = 70;
    } else if (glow < radius * 1.06) {
      p
        ..r = gold[0]
        ..g = gold[1]
        ..b = gold[2]
        ..a = 90;
    }
  }
  img.gaussianBlur(shadow, radius: (radius * 0.12).round());
  img.compositeImage(im, shadow);

  final e = _fit(emblem, inner * 2 * 0.95);
  final ex = (cx - e.width / 2).round(), ey = (cy - e.height / 2).round();

  for (final p in im) {
    final dx = p.x + 0.5 - cx, dy = p.y + 0.5 - cy;
    final d = sqrt(dx * dx + dy * dy);
    final outerCov = (radius - d + 0.5).clamp(0.0, 1.0);
    if (outerCov <= 0) continue;

    // Gold ring with a metallic sheen that varies around the circle.
    final angle = atan2(dy, dx);
    final sheen = (sin(angle * 2 - 0.6) + 1) / 2; // 0..1
    final ringColor = sheen > 0.5
        ? _mix(gold, goldShine, (sheen - 0.5) * 2)
        : _mix(goldDeep, gold, sheen * 2);
    _blend(p, ringColor, outerCov);

    final innerCov = (inner - d + 0.5).clamp(0.0, 1.0);
    if (innerCov > 0) {
      var c = const [255, 255, 255];
      final x = p.x - ex, y = p.y - ey;
      if (x >= 0 && y >= 0 && x < e.width && y < e.height) {
        final ep = e.getPixel(x, y);
        c = [ep.r.toInt(), ep.g.toInt(), ep.b.toInt()];
      }
      _blend(p, c, innerCov);
    }
  }
}

// ---------- helpers ----------

List<int> _mix(List<int> a, List<int> b, double t) =>
    List.generate(3, (i) => (a[i] + (b[i] - a[i]) * t).round());

void _blend(img.Pixel p, List<int> c, double a) {
  final da = p.a / 255;
  final oa = a + da * (1 - a);
  if (oa == 0) return;
  for (var i = 0; i < 3; i++) {
    final dst = [p.r, p.g, p.b][i].toDouble();
    final v = (c[i] * a + dst * da * (1 - a)) / oa;
    if (i == 0) p.r = v.round();
    if (i == 1) p.g = v.round();
    if (i == 2) p.b = v.round();
  }
  p.a = (oa * 255).round();
}

void _write(String name, img.Image image) {
  File('$dir/$name').writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $dir/$name');
}
