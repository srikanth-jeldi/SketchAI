import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'premium_art.dart';

const artCategories = [
  'Flowers',
  'Butterflies',
  'Mandalas',
  'Ocean',
  'Birds',
  'Little homes',
  'Balloons',
  'Turtles',
  'Sweet treats',
  'Cats',
];
const artNames = [
  'Petal poetry',
  'Wings of wonder',
  'Quiet circles',
  'Ocean daydream',
  'Garden song',
  'A place to dream',
  'Up & away',
  'Slow and lovely',
  'Sweet little joys',
  'Whisker wishes',
];
const _pinks = [0xFFF48DA6, 0xFFB895E7, 0xFFFFAD80, 0xFFF7C564, 0xFF89C7C4];
const _greens = [0xFF7BB89B, 0xFFA8CA83, 0xFF62A995, 0xFFBDCF91];
const _blues = [0xFF78BBD7, 0xFF8D9DDB, 0xFF8ED1CB, 0xFFAECEEB];

class ArtEntry {
  final int family, variation;
  const ArtEntry(this.family, this.variation);
  bool get premium => family == 10;
  String get id => premium ? 'premium_$variation' : 'art_${family}_$variation';
  String get category =>
      premium ? premiumCategories[variation] : artCategories[family];
  String get title => premium
      ? premiumTitles[variation]
      : '${artNames[family]} ${variation + 1}';
  String get difficulty => premium
      ? 'Detailed'
      : variation % 3 == 0
      ? 'Relaxed'
      : variation % 3 == 1
      ? 'Playful'
      : 'Detailed';
}

class ArtRegion {
  final String id;
  final Path path;
  final Color sample;
  const ArtRegion(this.id, this.path, this.sample);
}

class ArtDesign {
  final ArtEntry entry;
  final List<ArtRegion> regions;
  final List<Path> details;
  const ArtDesign(this.entry, this.regions, this.details);
  ArtRegion? regionAt(Offset position) {
    for (final region in regions.reversed) {
      if (region.path.contains(position)) return region;
    }
    return null;
  }
}

class ArtCatalog {
  static final entries = List<ArtEntry>.unmodifiable(
    List.generate(2000, (index) => ArtEntry(index ~/ 200, index % 200)),
  );
  static final _cache = <String, ArtDesign>{};
  static ArtEntry? entry(String? id) {
    for (final art in premiumEntries) {
      if (art.id == id) return art;
    }
    final match = RegExp(r'^art_(\d+)_(\d+)$').firstMatch(id ?? '');
    if (match == null) return null;
    final family = int.parse(match[1]!), variant = int.parse(match[2]!);
    return family < 10 && variant < 200
        ? entries[family * 200 + variant]
        : null;
  }

  static ArtDesign design(String id) {
    if (premiumDesigns.containsKey(id)) return premiumDesigns[id]!;
    final cached = _cache.remove(id);
    if (cached != null) {
      _cache[id] = cached;
      return cached;
    }
    final metadata = entry(id);
    if (metadata == null) throw const FormatException('Unknown artwork');
    final result = _ArtBuilder(metadata).build();
    _cache[id] = result;
    if (_cache.length > 24) _cache.remove(_cache.keys.first);
    return result;
  }
}

/// Original closed-path artwork. Each category has 200 deterministic geometry
/// variations, not 200 colour swaps. No downloaded stock art or raster masks.
class _ArtBuilder {
  final ArtEntry entry;
  late final _ArtRandom random;
  final regions = <ArtRegion>[];
  final details = <Path>[];
  _ArtBuilder(this.entry) {
    random = _ArtRandom(71023 + entry.family * 1009 + entry.variation * 7919);
  }
  double between(double a, double b) => a + random.nextDouble() * (b - a);
  int pick(List<int> values) =>
      values[(entry.variation + random.nextInt(values.length)) % values.length];
  void add(Path path, int color) =>
      regions.add(ArtRegion('r${regions.length}', path, Color(color)));
  void oval(double x, double y, double w, double h, int color) => add(
    Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h)),
    color,
  );
  void box(
    double x,
    double y,
    double w,
    double h,
    int color, [
    double radius = 12,
  ]) => add(
    Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      ),
    ),
    color,
  );
  void poly(List<Offset> points, int color) =>
      add(Path()..addPolygon(points, true), color);
  void leaf(Offset a, Offset b, double width, int color) {
    final d = b - a, normal = Offset(-d.dy, d.dx) / d.distance;
    final mid = (a + b) / 2;
    add(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(
          mid.dx + normal.dx * width,
          mid.dy + normal.dy * width,
          b.dx,
          b.dy,
        )
        ..quadraticBezierTo(
          mid.dx - normal.dx * width,
          mid.dy - normal.dy * width,
          a.dx,
          a.dy,
        )
        ..close(),
      color,
    );
    details.add(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy),
    );
  }

  void flower(double x, double y, double radius, int petals) {
    final phase = between(0, .5);
    final color = pick(_pinks);
    for (var i = 0; i < petals; i++) {
      final angle = phase + i * math.pi * 2 / petals;
      final center = Offset(
        x + math.cos(angle) * radius * .62,
        y + math.sin(angle) * radius * .62,
      );
      final path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * .7,
            height: radius * 1.05,
          ),
        );
      final matrix = Matrix4.identity()
        ..translateByDouble(center.dx, center.dy, 0, 1)
        ..rotateZ(angle + math.pi / 2);
      add(path.transform(matrix.storage), color);
    }
    oval(x, y, radius * .55, radius * .55, 0xFFF5C65F);
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      details.add(
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(
              x + math.cos(a) * radius * .13,
              y + math.sin(a) * radius * .13,
            ),
            radius: 2.5,
          ),
        ),
      );
    }
  }

  void star(double x, double y, double radius, int color, {int points = 5}) {
    poly(
      List.generate(points * 2, (i) {
        final a = -math.pi / 2 + i * math.pi / points,
            r = i.isEven ? radius : radius * .45;
        return Offset(x + math.cos(a) * r, y + math.sin(a) * r);
      }),
      color,
    );
  }

  void cloud(double x, double y, double scale) {
    add(
      Path()
        ..moveTo(x - 70 * scale, y + 20 * scale)
        ..cubicTo(
          x - 115 * scale,
          y,
          x - 75 * scale,
          y - 55 * scale,
          x - 40 * scale,
          y - 35 * scale,
        )
        ..cubicTo(
          x - 20 * scale,
          y - 95 * scale,
          x + 55 * scale,
          y - 80 * scale,
          x + 58 * scale,
          y - 30 * scale,
        )
        ..cubicTo(
          x + 110 * scale,
          y - 35 * scale,
          x + 120 * scale,
          y + 30 * scale,
          x + 65 * scale,
          y + 30 * scale,
        )
        ..lineTo(x - 70 * scale, y + 30 * scale)
        ..close(),
      pick(_blues),
    );
  }

  void eye(double x, double y, double size) {
    oval(x, y, size, size, 0xFFFFF0CC);
    details.add(
      Path()..addOval(
        Rect.fromCircle(center: Offset(x + size * .08, y), radius: size * .16),
      ),
    );
  }

  ArtDesign build() {
    switch (entry.family) {
      case 0:
        _flowers();
      case 1:
        _butterfly();
      case 2:
        _mandala();
      case 3:
        _ocean();
      case 4:
        _bird();
      case 5:
        _home();
      case 6:
        _balloons();
      case 7:
        _turtle();
      case 8:
        _treats();
      case 9:
        _cat();
    }
    return ArtDesign(
      entry,
      List.unmodifiable(regions),
      List.unmodifiable(details),
    );
  }

  void _flowers() {
    final count = 3 + entry.variation % 3;
    for (var i = 0; i < count; i++) {
      final x = 170 + i * 650 / (count - 1) + between(-22, 22),
          y = between(270, 500),
          r = between(78, 115);
      box(x - 6, y + 35, 12, 830 - y, pick(_greens), 5);
      leaf(
        Offset(x, 690),
        Offset(x + (i.isEven ? 135 : -135), 550 + between(-40, 40)),
        45,
        pick(_greens),
      );
      flower(x, y, r, 5 + entry.variation % 5);
    }
    box(210, 840, 580, 35, 0xFFCEB4E9, 16);
    for (var i = 0; i < 3; i++) {
      star(170 + i * 320, 140, between(14, 24), 0xFFF7C564);
    }
  }

  void _butterfly() {
    final spread = between(285, 340), upper = between(210, 280);
    for (final s in [-1.0, 1.0]) {
      add(
        Path()
          ..moveTo(500, 480)
          ..cubicTo(
            500 + s * 150,
            120,
            500 + s * (spread + 80),
            140,
            500 + s * spread,
            420,
          )
          ..quadraticBezierTo(500 + s * 260, 565, 500, 530)
          ..close(),
        pick(_pinks),
      );
      add(
        Path()
          ..moveTo(500, 515)
          ..cubicTo(500 + s * 370, 440, 500 + s * 320, 850, 500 + s * 140, 760)
          ..quadraticBezierTo(500 + s * 40, 690, 500, 550)
          ..close(),
        pick(_blues),
      );
      for (var i = 0; i < 3 + entry.variation % 3; i++) {
        final a = i * .42;
        oval(
          500 + s * (150 + math.sin(a) * 75),
          upper + 70 + i * 48,
          between(30, 48),
          between(38, 60),
          pick(_pinks),
        );
      }
      oval(500 + s * 175, 640, 65, 95, 0xFFF7CB74);
      details.add(
        Path()
          ..moveTo(500 + s * 12, 330)
          ..quadraticBezierTo(500 + s * 65, 190, 500 + s * 100, 235),
      );
    }
    oval(500, 500, 50, 350, 0xFFBDB0DB);
    oval(500, 320, 66, 66, 0xFFF4BC80);
    for (var i = 0; i < 5; i++) {
      details.add(
        Path()
          ..moveTo(480, 405 + i * 40)
          ..lineTo(520, 405 + i * 40),
      );
    }
    flower(190, 855, 45, 5);
    flower(810, 855, 45, 6);
  }

  void _mandala() {
    final symmetry = 6 + entry.variation % 7;
    for (var ring = 3; ring >= 1; ring--) {
      final r = ring * 100.0 + between(-10, 10),
          phase = (ring.isEven ? .5 : 0) * math.pi * 2 / symmetry;
      for (var i = 0; i < symmetry; i++) {
        final a = phase + i * math.pi * 2 / symmetry;
        leaf(
          Offset(500 + math.cos(a) * r * .7, 500 + math.sin(a) * r * .7),
          Offset(500 + math.cos(a) * (r + 120), 500 + math.sin(a) * (r + 120)),
          between(32, 55),
          ring.isEven ? pick(_blues) : pick(_pinks),
        );
      }
    }
    oval(500, 500, 105, 105, 0xFFF5CB72);
    for (var i = 0; i < symmetry; i++) {
      final a = i * math.pi * 2 / symmetry;
      oval(
        500 + math.cos(a) * 365,
        500 + math.sin(a) * 365,
        24,
        24,
        pick(_pinks),
      );
    }
  }

  void _ocean() {
    final fishes = 3 + entry.variation % 3;
    for (var i = 0; i < fishes; i++) {
      final x = between(280, 720),
          y = 210 + i * 125.0,
          w = between(170, 245),
          s = i.isEven ? 1.0 : -1.0;
      poly([
        Offset(x - s * w * .4, y),
        Offset(x - s * w * .8, y - 65),
        Offset(x - s * w * .8, y + 65),
      ], pick(_pinks));
      oval(x, y, w, w * .55, pick(_blues));
      eye(x + s * w * .29, y - 8, 25);
      leaf(Offset(x, y + 10), Offset(x - s * 38, y + 75), 25, pick(_pinks));
      for (var j = 0; j < 2 + entry.variation % 3; j++) {
        details.add(
          Path()
            ..moveTo(x - 35 + j * 24, y - 45)
            ..quadraticBezierTo(x - 15 + j * 24, y, x - 35 + j * 24, y + 45),
        );
      }
    }
    for (var i = 0; i < 5; i++) {
      leaf(
        Offset(130 + i * 180, 890),
        Offset(110 + i * 180 + between(-50, 50), between(720, 810)),
        30,
        pick(_greens),
      );
    }
    for (var i = 0; i < 6; i++) {
      oval(
        between(120, 880),
        between(90, 800),
        between(15, 28),
        between(20, 32),
        0xFFB8DFE8,
      );
    }
    star(510, 865, 55, 0xFFF4B69B);
  }

  void _bird() {
    box(140, 765, 720, 18, 0xFFCFAD86, 8);
    final x = between(420, 540), y = between(480, 540), w = between(270, 340);
    poly([
      Offset(x - w * .3, y + 10),
      Offset(x - 280, y + 100),
      Offset(x - 140, y + 145),
    ], pick(_pinks));
    oval(x, y, w, 260, pick(_blues));
    leaf(Offset(x - 65, y + 65), Offset(x + 85, y - 60), 80, pick(_pinks));
    oval(x + 105, y - 145, 160, 160, pick(_blues));
    eye(x + 130, y - 160, 36);
    poly([
      Offset(x + 180, y - 150),
      Offset(x + 245, y - 120),
      Offset(x + 174, y - 107),
    ], 0xFFF1B963);
    for (final dx in [-35.0, 45.0]) {
      details.add(
        Path()
          ..moveTo(x + dx, y + 125)
          ..lineTo(x + dx, 765)
          ..lineTo(x + dx - 22, 765),
      );
    }
    for (var i = 0; i < 4; i++) {
      leaf(
        Offset(185 + i * 190, 770),
        Offset(150 + i * 190, 675),
        32,
        pick(_greens),
      );
    }
    cloud(260, 195, .7);
    star(770, 200, 55, 0xFFF5C564);
  }

  void _home() {
    final x = between(260, 320), w = between(360, 440), top = between(390, 450);
    box(x, top, w, 365, pick(_pinks));
    poly([
      Offset(x - 45, top),
      Offset(x + w / 2, top - between(160, 220)),
      Offset(x + w + 45, top),
    ], pick(_blues));
    box(x + w * .4, top + 170, w * .22, 195, 0xFFCCA174, 30);
    for (final dx in [.12, .68]) {
      box(x + w * dx, top + 75, 75, 95, 0xFFFFDC89, 8);
      details.add(
        Path()
          ..moveTo(x + w * dx + 37, top + 75)
          ..lineTo(x + w * dx + 37, top + 170)
          ..moveTo(x + w * dx, top + 122)
          ..lineTo(x + w * dx + 75, top + 122),
      );
    }
    oval(x + w * .57, top + 270, 10, 10, 0xFFF2CA7C);
    for (var i = 0; i < 5; i++) {
      box(110 + i * 180, 825, 32, 75, pick(_greens), 8);
      flower(126 + i * 180, 815, 35, 5 + entry.variation % 3);
    }
    cloud(230, 170, .75);
    oval(800, 180, 100, 100, 0xFFF7C461);
    details.add(
      Path()
        ..moveTo(100, 900)
        ..lineTo(900, 900),
    );
  }

  void _balloons() {
    final count = 3 + entry.variation % 3;
    for (var i = 0; i < count; i++) {
      final x = 170 + i * 650 / (count - 1),
          y = between(250, 430),
          w = between(125, 170),
          h = between(170, 240);
      details.add(
        Path()
          ..moveTo(x, y + h / 2)
          ..cubicTo(x - 80, 690, x + 80, 760, 500, 900),
      );
      oval(x, y, w, h, pick(_pinks));
      poly([
        Offset(x, y + h / 2 - 3),
        Offset(x - 12, y + h / 2 + 20),
        Offset(x + 12, y + h / 2 + 20),
      ], pick(_pinks));
      if (i.isEven) {
        star(x, y, 35, pick(_blues));
      } else {
        oval(x, y, 50, 75, 0xFFF9DCA4);
      }
    }
    cloud(230, 700, .7);
    cloud(790, 680, .6);
    for (var i = 0; i < 4; i++) {
      star(170 + i * 220, 130 + between(-20, 40), between(15, 25), 0xFFF5CD76);
    }
  }

  void _turtle() {
    final cx = 480.0, cy = 500.0, r = between(210, 245);
    for (final x in [290.0, 650.0]) {
      for (final y in [300.0, 700.0]) {
        oval(x, y, 110, 155, pick(_greens));
      }
    }
    poly([
      const Offset(245, 470),
      const Offset(145, 500),
      const Offset(245, 530),
    ], 0xFF9BC69A);
    oval(800, 500, 155, 125, 0xFFACD99F);
    eye(825, 485, 25);
    oval(cx, cy, r * 2, r * 1.65, pick(_greens));
    final count = 5 + entry.variation % 4;
    for (var i = 0; i < count; i++) {
      final a = i * math.pi * 2 / count;
      leaf(
        Offset(cx + math.cos(a) * 45, cy + math.sin(a) * 45),
        Offset(cx + math.cos(a) * r * .88, cy + math.sin(a) * r * .7),
        between(40, 60),
        pick(_blues),
      );
    }
    oval(cx, cy, 100, 90, 0xFFF5D587);
    for (var i = 0; i < 5; i++) {
      oval(170 + i * 170, 820 + between(-25, 25), 30, 20, 0xFFEBD6B2);
    }
    cloud(240, 150, .5);
  }

  void _treats() {
    final count = 3 + entry.variation % 2;
    for (var i = 0; i < count; i++) {
      final x = 220 + i * (560 / (count - 1)),
          y = i.isEven ? 450.0 : 600.0,
          w = between(120, 160);
      poly([
        Offset(x - w * .7, y + 20),
        Offset(x + w * .7, y + 20),
        Offset(x + w * .48, y + 190),
        Offset(x - w * .48, y + 190),
      ], pick(_blues));
      add(
        Path()
          ..moveTo(x - w * .8, y + 20)
          ..cubicTo(
            x - w * 1.2,
            y - 55,
            x - w * .4,
            y - 80,
            x - w * .25,
            y - 120,
          )
          ..cubicTo(
            x - w * .2,
            y - 185,
            x + w * .75,
            y - 170,
            x + w * .5,
            y - 80,
          )
          ..cubicTo(x + w * 1.1, y - 55, x + w * .9, y + 20, x + w * .8, y + 20)
          ..close(),
        pick(_pinks),
      );
      oval(x, y - 140, 30, 30, 0xFFF1818C);
      for (var j = 0; j < 3; j++) {
        details.add(
          Path()
            ..moveTo(x - w * .4 + j * w * .4, y + 45)
            ..lineTo(x - w * .25 + j * w * .25, y + 165),
        );
      }
      for (var j = 0; j < 3; j++) {
        oval(x - w * .45 + j * w * .45, y - 30, 12, 10, 0xFFF4D18A);
      }
    }
    for (var i = 0; i < 5; i++) {
      star(120 + i * 180, 170 + between(-40, 40), between(18, 28), 0xFFF5CB7B);
    }
    box(120, 845, 760, 25, 0xFFCEB4E9);
  }

  void _cat() {
    final x = 500.0,
        w = between(270, 340),
        head = between(390, 440),
        coat = pick(_pinks);
    add(
      Path()
        ..moveTo(650, 750)
        ..cubicTo(880, 850, 910, 550, 800, 600)
        ..cubicTo(750, 620, 840, 740, 650, 690)
        ..close(),
      coat,
    );
    oval(x, 660, w, 330, coat);
    poly([
      Offset(x - 170, head - 60),
      Offset(x - 145, head - 235),
      Offset(x - 45, head - 135),
    ], coat);
    poly([
      Offset(x + 170, head - 60),
      Offset(x + 145, head - 235),
      Offset(x + 45, head - 135),
    ], coat);
    oval(x, head, 350, 290, coat);
    poly([
      Offset(x - 133, head - 100),
      Offset(x - 125, head - 185),
      Offset(x - 75, head - 125),
    ], 0xFFF9C5C8);
    poly([
      Offset(x + 133, head - 100),
      Offset(x + 125, head - 185),
      Offset(x + 75, head - 125),
    ], 0xFFF9C5C8);
    eye(435, head - 5, 60);
    eye(565, head - 5, 60);
    poly([
      Offset(x - 16, head + 38),
      Offset(x + 16, head + 38),
      Offset(x, head + 55),
    ], 0xFFF18E9A);
    details.add(
      Path()
        ..moveTo(500, head + 55)
        ..quadraticBezierTo(478, head + 85, 455, head + 65)
        ..moveTo(500, head + 55)
        ..quadraticBezierTo(522, head + 85, 545, head + 65),
    );
    for (final s in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        details.add(
          Path()
            ..moveTo(x + s * 90, head + 45 + i * 14)
            ..lineTo(x + s * (210 + between(-8, 8)), head + 20 + i * 38),
        );
      }
    }
    oval(500, 675, 145, 200, 0xFFFCE0BD);
    oval(410, 810, 115, 70, coat);
    oval(590, 810, 115, 70, coat);
    box(395, head + 125, 210, 25, pick(_blues));
    oval(500, head + 163, 38, 38, 0xFFF3C769);
    for (var i = 0; i < 3; i++) {
      flower(190 + i * 310, 905, 30, 5);
    }
  }
}

void paintArt(
  Canvas canvas,
  ArtDesign art, {
  Map<String, int> colors = const {},
  bool sample = false,
  bool fills = true,
  bool outlines = true,
}) {
  if (art.entry.premium) {
    paintPremium(
      canvas,
      art,
      colors: colors,
      sample: sample,
      fills: fills,
      outlines: outlines,
    );
    return;
  }
  final ink = Paint()
    ..color = const Color(0xFF292233)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final region in art.regions) {
    canvas.drawPath(
      region.path,
      Paint()
        ..color = fills
            ? (sample ? region.sample : Color(colors[region.id] ?? 0xFFFFFFFF))
            : Colors.white,
    );
    if (outlines) canvas.drawPath(region.path, ink);
  }
  if (outlines) {
    for (final path in art.details) {
      canvas.drawPath(path, ink..strokeWidth = 2);
    }
  }
}

class ArtworkPainter extends CustomPainter {
  final String artId;
  final bool sample;
  const ArtworkPainter(this.artId, {this.sample = true});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final scale = math.min(size.width, size.height) / 1000;
    canvas.translate(
      (size.width - 1000 * scale) / 2,
      (size.height - 1000 * scale) / 2,
    );
    canvas.scale(scale);
    paintArt(canvas, ArtCatalog.design(artId), sample: sample);
  }

  @override
  bool shouldRepaint(ArtworkPainter oldDelegate) =>
      oldDelegate.artId != artId || oldDelegate.sample != sample;
}

// Catalogue v1 owns its PRNG so saved pages never depend on SDK Random changes.
class _ArtRandom {
  int _state;
  _ArtRandom(this._state);
  int _next() {
    var x = _state;
    x = (x ^ (x << 13)) & 0xffffffff;
    x = (x ^ (x >> 17)) & 0xffffffff;
    x = (x ^ (x << 5)) & 0xffffffff;
    return _state = x;
  }

  double nextDouble() => _next() / 4294967296;
  int nextInt(int max) => _next() % max;
}
