import 'dart:math' as math;

import 'package:flutter/material.dart';

// Append-only catalogue: persisted sketches store these indices. Never reorder
// the original 24 or the motif/edition rows after shipping.
const stickerTopics = [
  'Flowers',
  'Botanical',
  'Animals',
  'Ocean',
  'Space',
  'Food',
  'Travel',
  'Celebrations',
  'Weather',
  'Creative',
  'Love',
  'Geometric',
];
const stickerMotifs = [
  'Daisy',
  'Rose',
  'Lotus',
  'Poppy',
  'Sunflower',
  'Monstera',
  'Fern',
  'Cactus',
  'Mushrooms',
  'Sprig',
  'Fox',
  'Bunny',
  'Bear',
  'Owl',
  'Panda',
  'Whale',
  'Jellyfish',
  'Seahorse',
  'Shell',
  'Starfish',
  'Planet',
  'Astronaut',
  'Comet',
  'UFO',
  'Telescope',
  'Strawberry',
  'Cupcake',
  'Avocado',
  'Ice cream',
  'Cherries',
  'Mountains',
  'Camper',
  'Sailboat',
  'Camera',
  'Lighthouse',
  'Cake',
  'Party hat',
  'Confetti',
  'Present',
  'Fireworks',
  'Sunrise',
  'Rain cloud',
  'Snowflake',
  'Rainbow sky',
  'Moonrise',
  'Paint palette',
  'Brush jar',
  'Pencil',
  'Headphones',
  'Open book',
  'Heart wings',
  'Love letter',
  'Linked hearts',
  'Heart lock',
  'Heart balloon',
  'Rosette',
  'Kaleidoscope',
  'Crystal',
  'Orbit',
  'Pinwheel',
];
const stickerEditions = [
  'Classic',
  'Sparkling',
  'Botanical wreath',
  'Sunburst',
  'Scallop seal',
  'Polaroid',
  'Postage stamp',
  'Ribbon badge',
  'Heart frame',
  'Orbit frame',
  'Arch',
  'Diamond frame',
  'Confetti party',
  'Twin charms',
  'Trio',
  'Bouquet',
  'Pendant',
  'Night sky',
];
const expandedStickerCount = 60 * 18;
// Present a variety of subjects before their editions, without changing IDs.
final stickerBrowseOrder = List<int>.unmodifiable([
  for (var id = 0; id < 24; id++) id,
  for (var edition = 0; edition < 18; edition++)
    for (var motif = 0; motif < 60; motif++) 24 + motif * 18 + edition,
]);
String stickerTopic(int id) =>
    id < 24 ? 'Essentials' : stickerTopics[((id - 24) ~/ 18) ~/ 5];
String expandedStickerName(int index) =>
    '${stickerMotifs[index ~/ 18]} · ${stickerEditions[index % 18]}';

/// Code-native, multicolour artwork; editions change composition and geometry,
/// not merely a palette swap. No bitmap downloads or third-party art required.
void paintLibrarySticker(Canvas canvas, int index, Color primary) {
  final motif = index ~/ 18, edition = index % 18;
  final hsl = HSLColor.fromColor(primary);
  final accent = hsl.withHue((hsl.hue + 65) % 360).withLightness(.7).toColor();
  final pale = Color.lerp(
    primary,
    Colors.white.withValues(alpha: primary.a),
    .86,
  )!;
  final gold = const Color(0xFFFFC65C).withValues(alpha: primary.a);
  final dark = const Color(0xFF30233F).withValues(alpha: primary.a);
  final paper = Colors.white.withValues(alpha: primary.a);
  final fill = Paint()..color = primary;
  final pen = Paint()
    ..color = dark
    ..style = PaintingStyle.stroke
    ..strokeWidth = .018
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  void path(Path p, Color color, {bool outline = true}) {
    canvas.drawPath(p, fill..color = color);
    if (outline) canvas.drawPath(p, pen);
  }

  void ellipse(
    double x,
    double y,
    double w,
    double h,
    Color color, {
    bool outline = true,
  }) => path(
    Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h)),
    color,
    outline: outline,
  );
  void box(
    double x,
    double y,
    double w,
    double h,
    Color color, {
    double radius = .04,
  }) => path(
    Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        Radius.circular(radius),
      ),
    ),
    color,
  );
  void line(double x, double y, double x2, double y2) =>
      canvas.drawLine(Offset(x, y), Offset(x2, y2), pen);
  Path polygon(
    int n,
    double outer,
    double inner, {
    double angle = -math.pi / 2,
  }) => Path()
    ..addPolygon(
      List.generate(n * 2, (i) {
        final a = angle + i * math.pi / n, r = i.isEven ? outer : inner;
        return Offset(math.cos(a) * r, math.sin(a) * r);
      }),
      true,
    );
  void sparkle(double x, double y, double r) {
    canvas.save();
    canvas.translate(x, y);
    path(polygon(4, r, r * .25), gold, outline: false);
    canvas.restore();
  }

  void leaf(double x, double y, double size, double angle) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.scale(size);
    path(
      Path()
        ..moveTo(0, .5)
        ..quadraticBezierTo(-.7, 0, 0, -.5)
        ..quadraticBezierTo(.7, 0, 0, .5)
        ..close(),
      accent,
    );
    line(0, -.32, 0, .35);
    canvas.restore();
  }

  void heart(double x, double y, double r, Color color) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(r);
    path(
      Path()
        ..moveTo(0, .46)
        ..cubicTo(-.95, -.05, -.38, -.85, 0, -.24)
        ..cubicTo(.38, -.85, .95, -.05, 0, .46)
        ..close(),
      color,
    );
    canvas.restore();
  }

  void petals(int n, double radius, Color color) {
    for (var i = 0; i < n; i++) {
      canvas.save();
      canvas.rotate(i * 2 * math.pi / n);
      ellipse(0, -radius, .23, radius * 1.4, color);
      canvas.restore();
    }
  }

  void face({bool nose = true}) {
    ellipse(-.11, -.02, .035, .05, dark, outline: false);
    ellipse(.11, -.02, .035, .05, dark, outline: false);
    if (nose) {
      ellipse(0, .08, .07, .05, dark, outline: false);
      line(0, .09, 0, .14);
    }
    canvas.drawArc(
      const Rect.fromLTWH(-.08, .06, .16, .14),
      .15,
      math.pi - .3,
      false,
      pen,
    );
  }

  void wave(double y) => canvas.drawPath(
    Path()
      ..moveTo(-.35, y)
      ..quadraticBezierTo(-.18, y - .1, 0, y)
      ..quadraticBezierTo(.18, y + .1, .35, y),
    pen,
  );

  canvas.save();
  // All frames fit inside the same edit/hit-test boundary.
  switch (edition) {
    case 2:
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        leaf(math.cos(a) * .38, math.sin(a) * .38, .17, a + math.pi / 2);
      }
    case 3:
      path(polygon(18, .46, .37), gold);
      ellipse(0, 0, .73, .73, pale);
    case 4:
      path(polygon(16, .46, .42), pale);
      canvas.drawCircle(Offset.zero, .35, pen);
    case 5:
      box(0, .015, .85, .94, paper, radius: .015);
      box(0, -.05, .71, .66, pale, radius: .008);
      line(-.18, .37, .18, .37);
    case 6:
      box(0, 0, .82, .9, pale, radius: .01);
      for (var i = 0; i < 7; i++) {
        final t = -.36 + i * .12;
        ellipse(t, -.45, .055, .055, paper);
        ellipse(t, .45, .055, .055, paper);
      }
      for (var i = 0; i < 6; i++) {
        final t = -.3 + i * .12;
        ellipse(-.41, t, .055, .055, paper);
        ellipse(.41, t, .055, .055, paper);
      }
    case 7:
      path(
        Path()..addPolygon([
          const Offset(-.3, .18),
          const Offset(-.38, .48),
          const Offset(-.17, .4),
          const Offset(-.05, .48),
          const Offset(.04, .18),
        ], true),
        accent,
      );
      path(
        Path()..addPolygon([
          const Offset(.3, .18),
          const Offset(.38, .48),
          const Offset(.17, .4),
          const Offset(.05, .48),
          const Offset(-.04, .18),
        ], true),
        accent,
      );
      ellipse(0, -.06, .81, .81, pale);
    case 8:
      heart(0, -.01, .94, pale);
    case 9:
      canvas.save();
      canvas.rotate(-.4);
      canvas.drawOval(const Rect.fromLTWH(-.46, -.34, .92, .68), pen);
      canvas.restore();
      ellipse(-.39, .16, .11, .11, gold);
      ellipse(.37, -.2, .09, .09, accent);
    case 10:
      path(
        Path()
          ..moveTo(-.39, .43)
          ..lineTo(-.39, -.05)
          ..cubicTo(-.39, -.57, .39, -.57, .39, -.05)
          ..lineTo(.39, .43)
          ..close(),
        pale,
      );
    case 11:
      path(polygon(4, .47, .34), pale);
    case 12:
      for (var i = 0; i < 13; i++) {
        final a = i * 2.4;
        final x = math.cos(a) * .41, y = math.sin(a) * .41;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(a);
        box(0, 0, .045, .08, i.isEven ? gold : accent, radius: .008);
        canvas.restore();
      }
    case 16:
      ellipse(0, -.4, .13, .13, gold);
      ellipse(0, .03, .8, .8, pale);
    case 17:
      ellipse(0, 0, .87, .87, dark);
      for (var i = 0; i < 7; i++) {
        final a = i * 2.4;
        sparkle(math.cos(a) * .36, math.sin(a) * .36, .035);
      }
  }
  if (edition == 1) {
    sparkle(-.36, -.28, .09);
    sparkle(.37, -.16, .07);
    sparkle(.3, .33, .085);
  }
  final scale = switch (edition) {
    0 => .96,
    1 => .8,
    13 => .54,
    14 => .46,
    15 => .48,
    _ => .65,
  };
  void drawMotif(double x, double y, double rotation) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    canvas.scale(scale);
    if (motif == 46) canvas.scale(.8);
    switch (motif) {
      case 0:
        petals(10, .25, paper);
        ellipse(0, 0, .25, .25, gold);
      case 1:
        petals(6, .2, primary);
        petals(5, .12, accent);
        canvas.drawArc(
          const Rect.fromLTWH(-.13, -.13, .26, .26),
          0,
          math.pi * 1.7,
          false,
          pen,
        );
        leaf(-.24, .3, .25, -.9);
        leaf(.24, .3, .25, .9);
      case 2:
        for (var i = -2; i <= 2; i++) {
          canvas.save();
          canvas.rotate(i * .35);
          ellipse(0, -.12, .2, .56, i.isEven ? primary : accent);
          canvas.restore();
        }
        path(
          Path()
            ..moveTo(-.43, .2)
            ..quadraticBezierTo(0, .55, .43, .2)
            ..quadraticBezierTo(0, .12, -.43, .2)
            ..close(),
          gold,
        );
      case 3:
        petals(5, .21, primary);
        ellipse(0, 0, .21, .21, dark);
        ellipse(-.04, -.04, .05, .05, gold);
      case 4:
        petals(14, .28, gold);
        ellipse(0, 0, .43, .43, primary);
        for (var i = 0; i < 12; i++) {
          final a = i * 2.4, r = .04 + i * .009;
          ellipse(
            math.cos(a) * r,
            math.sin(a) * r,
            .035,
            .035,
            gold,
            outline: false,
          );
        }
      case 5:
        path(
          Path()
            ..moveTo(0, .43)
            ..cubicTo(-.7, .18, -.46, -.58, 0, -.28)
            ..cubicTo(.46, -.58, .7, .18, 0, .43)
            ..close(),
          primary,
        );
        line(0, -.2, 0, .4);
        for (var i = 0; i < 3; i++) {
          final y = -.1 + i * .15;
          line(-.28, y - .1, -.1, y);
          line(.28, y - .1, .1, y);
        }
      case 6:
        line(0, -.43, 0, .44);
        for (var i = 0; i < 5; i++) {
          final y = -.3 + i * .14;
          leaf(-.13, y, .27, -1);
          leaf(.13, y, .27, 1);
        }
      case 7:
        box(0, -.05, .25, .65, primary, radius: .12);
        box(-.25, -.12, .15, .32, primary, radius: .08);
        box(.25, -.24, .15, .32, primary, radius: .08);
        box(-.17, -.02, .22, .13, primary);
        box(.17, -.14, .22, .13, primary);
        box(0, .32, .45, .24, accent);
        for (var i = -1; i <= 1; i++) {
          line(i * .06, -.27, i * .06, .16);
        }
        petals(5, .055, gold);
      case 8:
        box(-.14, .22, .14, .38, pale);
        box(.21, .28, .12, .25, pale);
        path(
          Path()
            ..moveTo(-.47, .08)
            ..cubicTo(-.5, -.6, .22, -.6, .21, .08)
            ..close(),
          primary,
        );
        path(
          Path()
            ..moveTo(.02, .2)
            ..cubicTo(.02, -.24, .46, -.24, .45, .2)
            ..close(),
          accent,
        );
        for (final p in [
          const Offset(-.29, -.08),
          const Offset(-.11, -.26),
          const Offset(.04, -.09),
        ]) {
          ellipse(p.dx, p.dy, .08, .08, paper);
        }
      case 9:
        canvas.drawPath(
          Path()
            ..moveTo(-.24, .43)
            ..quadraticBezierTo(.14, 0, .18, -.4),
          pen,
        );
        for (var i = 0; i < 5; i++) {
          final y = -.28 + i * .14;
          leaf(-.04, y, .3, -.8);
          leaf(.2, y - .06, .26, .9);
        }
      case 10:
        path(
          Path()..addPolygon([
            const Offset(-.4, -.42),
            const Offset(-.3, .16),
            const Offset(0, .39),
            const Offset(.3, .16),
            const Offset(.4, -.42),
            const Offset(.12, -.22),
            const Offset(-.12, -.22),
          ], true),
          primary,
        );
        path(
          Path()
            ..moveTo(-.3, .06)
            ..quadraticBezierTo(-.13, -.02, 0, .3)
            ..quadraticBezierTo(.13, -.02, .3, .06)
            ..lineTo(0, .39)
            ..close(),
          paper,
        );
        face();
      case 11:
        ellipse(-.19, -.31, .2, .44, primary);
        ellipse(.19, -.31, .2, .44, primary);
        ellipse(-.19, -.34, .08, .27, accent);
        ellipse(.19, -.34, .08, .27, accent);
        ellipse(0, .12, .65, .58, pale);
        face();
      case 12:
        ellipse(-.29, -.25, .27, .27, primary);
        ellipse(.29, -.25, .27, .27, primary);
        ellipse(0, .04, .73, .7, primary);
        ellipse(0, .17, .35, .26, pale);
        face();
      case 13:
        ellipse(0, .02, .65, .77, primary);
        path(
          Path()..addPolygon([
            const Offset(-.32, -.15),
            const Offset(-.33, -.45),
            const Offset(-.1, -.25),
          ], true),
          primary,
        );
        path(
          Path()..addPolygon([
            const Offset(.32, -.15),
            const Offset(.33, -.45),
            const Offset(.1, -.25),
          ], true),
          primary,
        );
        ellipse(-.15, -.09, .29, .32, paper);
        ellipse(.15, -.09, .29, .32, paper);
        face(nose: false);
        path(
          Path()..addPolygon([
            const Offset(-.07, .05),
            const Offset(.07, .05),
            const Offset(0, .16),
          ], true),
          gold,
        );
        for (var i = -1; i <= 1; i++) {
          ellipse(i * .13, .28, .06, .08, accent);
        }
      case 14:
        ellipse(-.28, -.27, .25, .26, dark);
        ellipse(.28, -.27, .25, .26, dark);
        ellipse(0, .03, .74, .69, paper);
        ellipse(-.15, -.05, .18, .23, dark);
        ellipse(.15, -.05, .18, .23, dark);
        ellipse(-.15, -.08, .04, .05, paper);
        ellipse(.15, -.08, .04, .05, paper);
        ellipse(0, .11, .07, .05, dark);
        ellipse(-.24, .14, .1, .055, accent);
        ellipse(.24, .14, .1, .055, accent);
      case 15:
        path(
          Path()
            ..moveTo(-.4, .05)
            ..cubicTo(-.45, -.38, .22, -.4, .27, 0)
            ..lineTo(.46, -.16)
            ..lineTo(.45, .14)
            ..quadraticBezierTo(.17, .55, -.4, .05)
            ..close(),
          primary,
        );
        ellipse(-.2, -.02, .04, .05, dark);
        canvas.drawArc(
          const Rect.fromLTWH(-.3, -.06, .2, .2),
          0,
          math.pi,
          false,
          pen,
        );
        line(-.08, -.3, -.08, -.44);
        ellipse(-.16, -.43, .15, .07, accent);
        ellipse(.02, -.43, .15, .07, accent);
      case 16:
        for (var i = 0; i < 5; i++) {
          canvas.drawPath(
            Path()
              ..moveTo(-.28 + i * .14, .12)
              ..cubicTo(
                -.4 + i * .14,
                .31,
                -.1 + i * .14,
                .35,
                -.26 + i * .14,
                .46,
              ),
            pen,
          );
        }
        path(
          Path()
            ..moveTo(-.39, .13)
            ..cubicTo(-.4, -.58, .4, -.58, .39, .13)
            ..quadraticBezierTo(.28, .24, .2, .13)
            ..quadraticBezierTo(.1, .25, 0, .13)
            ..quadraticBezierTo(-.1, .25, -.2, .13)
            ..quadraticBezierTo(-.3, .24, -.39, .13)
            ..close(),
          primary,
        );
        face(nose: false);
      case 17:
        path(
          Path()
            ..moveTo(.15, -.4)
            ..cubicTo(-.25, -.58, -.35, -.12, -.05, .02)
            ..cubicTo(.38, .14, -.4, .26, -.1, .42)
            ..cubicTo(.12, .5, .25, .33, .1, .28)
            ..cubicTo(-.05, .25, .1, .18, .22, .14)
            ..cubicTo(.5, -.01, .1, -.12, .12, -.16)
            ..lineTo(.37, -.18)
            ..lineTo(.37, -.28)
            ..lineTo(.16, -.27)
            ..close(),
          primary,
        );
        ellipse(-.04, -.31, .045, .045, dark);
        leaf(-.18, .03, .24, -.5);
      case 18:
        path(
          Path()
            ..moveTo(-.1, .4)
            ..lineTo(-.43, -.01)
            ..cubicTo(-.58, -.58, .58, -.58, .43, -.01)
            ..lineTo(.1, .4)
            ..close(),
          accent,
        );
        for (var i = -2; i <= 2; i++) {
          canvas.drawPath(
            Path()
              ..moveTo(i * .19, -.19)
              ..quadraticBezierTo(i * .13, .03, 0, .33),
            pen,
          );
        }
        box(0, .37, .23, .1, gold);
      case 19:
        path(polygon(5, .46, .21), gold);
        for (var i = 0; i < 5; i++) {
          canvas.save();
          canvas.rotate(i * math.pi * 2 / 5);
          ellipse(0, -.22, .04, .04, primary);
          canvas.restore();
        }
      case 20:
        canvas.save();
        canvas.rotate(-.35);
        ellipse(0, 0, .7, .7, primary);
        canvas.drawOval(const Rect.fromLTWH(-.48, -.15, .96, .3), pen);
        canvas.restore();
        ellipse(-.1, -.13, .12, .12, accent);
        ellipse(.13, .08, .09, .09, gold);
      case 21:
        box(0, .2, .49, .43, paper);
        ellipse(0, -.18, .69, .63, paper);
        ellipse(0, -.18, .51, .4, primary);
        sparkle(.14, -.23, .07);
        box(-.3, .16, .13, .29, accent);
        box(.3, .16, .13, .29, accent);
        line(-.11, .17, .11, .17);
        line(-.1, .43, -.1, .48);
        line(.1, .43, .1, .48);
      case 22:
        path(
          Path()..addPolygon([
            const Offset(-.3, .32),
            const Offset(.41, -.43),
            const Offset(.26, .14),
            const Offset(.02, .02),
          ], true),
          gold,
        );
        ellipse(-.19, .22, .36, .36, primary);
        sparkle(.1, -.3, .06);
      case 23:
        ellipse(0, -.11, .43, .4, pale);
        ellipse(0, .12, .87, .27, primary);
        for (var i = -1; i <= 1; i++) {
          ellipse(i * .22, .13, .07, .07, gold);
        }
        line(-.25, .21, -.33, .35);
        line(.25, .21, .33, .35);
      case 24:
        canvas.save();
        canvas.rotate(-.55);
        box(0, -.13, .59, .25, primary);
        box(.3, -.13, .14, .32, accent);
        canvas.restore();
        line(0, .03, 0, .42);
        line(0, .12, -.29, .45);
        line(0, .12, .29, .45);
      case 25:
        path(
          Path()
            ..moveTo(-.33, -.2)
            ..cubicTo(-.63, .03, -.1, .63, 0, .39)
            ..cubicTo(.1, .63, .63, .03, .33, -.2)
            ..quadraticBezierTo(0, -.42, -.33, -.2)
            ..close(),
          primary,
        );
        for (var i = 0; i < 7; i++) {
          final a = i * 2.4;
          ellipse(
            math.cos(a) * .2,
            math.sin(a) * .17,
            .025,
            .055,
            gold,
            outline: false,
          );
        }
        leaf(-.1, -.3, .22, -1);
        leaf(.1, -.3, .22, 1);
      case 26:
        path(
          Path()..addPolygon([
            const Offset(-.3, .02),
            const Offset(.3, .02),
            const Offset(.22, .42),
            const Offset(-.22, .42),
          ], true),
          primary,
        );
        ellipse(0, -.03, .67, .29, pale);
        ellipse(0, -.19, .47, .3, accent);
        ellipse(0, -.32, .24, .25, pale);
        ellipse(0, -.43, .11, .11, primary);
        for (var i = -1; i <= 1; i++) {
          line(i * .12, .1, i * .09, .33);
        }
      case 27:
        path(
          Path()
            ..moveTo(0, -.46)
            ..cubicTo(-.22, -.46, -.58, .17, -.25, .39)
            ..cubicTo(.12, .67, .62, .16, .18, -.36)
            ..quadraticBezierTo(.1, -.46, 0, -.46)
            ..close(),
          primary,
        );
        ellipse(0, .15, .43, .49, gold);
        ellipse(0, .2, .27, .31, dark);
      case 28:
        path(
          Path()..addPolygon([
            const Offset(-.25, .02),
            const Offset(.25, .02),
            const Offset(0, .46),
          ], true),
          gold,
        );
        line(-.15, .14, .08, .33);
        line(.15, .14, -.08, .33);
        ellipse(0, -.16, .6, .45, pale);
        ellipse(-.19, -.02, .24, .22, accent);
        ellipse(.2, -.02, .24, .22, accent);
        ellipse(0, -.43, .12, .12, primary);
      case 29:
        canvas.drawPath(
          Path()
            ..moveTo(-.23, .14)
            ..quadraticBezierTo(-.2, -.36, .22, -.4)
            ..quadraticBezierTo(.1, -.2, .24, .16),
          pen,
        );
        ellipse(-.24, .23, .36, .36, primary);
        ellipse(.24, .23, .36, .36, primary);
        leaf(.1, -.38, .26, 1.1);
      case 30:
        path(
          Path()..addPolygon([
            const Offset(-.47, .35),
            const Offset(-.1, -.4),
            const Offset(.35, .35),
          ], true),
          primary,
        );
        path(
          Path()..addPolygon([
            const Offset(-.05, .35),
            const Offset(.24, -.2),
            const Offset(.47, .35),
          ], true),
          accent,
        );
        path(
          Path()..addPolygon([
            const Offset(-.23, -.12),
            const Offset(-.1, -.4),
            const Offset(.06, -.13),
            const Offset(-.04, -.17),
            const Offset(-.11, -.08),
          ], true),
          paper,
        );
        line(-.42, .42, .42, .42);
      case 31:
        box(0, .02, .86, .52, primary);
        box(0, -.08, .69, .25, pale);
        line(-.04, -.2, -.04, .28);
        ellipse(-.25, .3, .19, .19, dark);
        ellipse(.25, .3, .19, .19, dark);
        ellipse(-.25, .3, .08, .08, paper);
        ellipse(.25, .3, .08, .08, paper);
        box(.2, .13, .09, .03, gold);
      case 32:
        path(
          Path()..addPolygon([
            const Offset(-.43, .2),
            const Offset(.43, .2),
            const Offset(.24, .4),
            const Offset(-.2, .4),
          ], true),
          primary,
        );
        line(0, -.45, 0, .2);
        path(
          Path()..addPolygon([
            const Offset(-.04, -.42),
            const Offset(-.04, .12),
            const Offset(-.39, .12),
          ], true),
          pale,
        );
        path(
          Path()..addPolygon([
            const Offset(.04, -.32),
            const Offset(.04, .12),
            const Offset(.34, .12),
          ], true),
          accent,
        );
        wave(.46);
      case 33:
        box(0, .05, .86, .54, primary);
        box(-.2, -.28, .25, .12, accent);
        ellipse(.06, .05, .39, .39, pale);
        ellipse(.06, .05, .23, .23, dark);
        box(.28, -.12, .13, .07, gold);
      case 34:
        path(
          Path()..addPolygon([
            const Offset(-.26, .43),
            const Offset(-.15, -.16),
            const Offset(.15, -.16),
            const Offset(.26, .43),
          ], true),
          pale,
        );
        box(0, -.23, .4, .2, gold);
        path(
          Path()..addPolygon([
            const Offset(-.26, -.33),
            const Offset(0, -.49),
            const Offset(.26, -.33),
          ], true),
          primary,
        );
        box(0, .36, .13, .16, primary);
        line(-.2, .16, .2, .16);
        line(-.17, -.01, .17, -.01);
      case 35:
        box(0, .19, .74, .39, primary);
        box(0, -.05, .57, .24, pale);
        for (var i = -1; i <= 1; i++) {
          line(i * .17, -.16, i * .17, -.34);
          ellipse(i * .17, -.39, .055, .09, gold);
        }
        line(-.3, .25, .3, .25);
        ellipse(0, .06, .06, .06, accent);
      case 36:
        path(
          Path()..addPolygon([
            const Offset(0, -.45),
            const Offset(-.34, .36),
            const Offset(.34, .36),
          ], true),
          primary,
        );
        ellipse(0, -.43, .14, .14, gold);
        ellipse(-.1, .02, .1, .1, accent);
        ellipse(.12, .17, .1, .1, gold);
        box(0, .37, .79, .12, pale);
      case 37:
        path(
          Path()..addPolygon([
            const Offset(-.4, .43),
            const Offset(-.25, -.04),
            const Offset(.06, .27),
          ], true),
          primary,
        );
        for (var i = 0; i < 14; i++) {
          final a = i * 2.4, r = .12 + (i % 4) * .08;
          canvas.save();
          canvas.translate(math.cos(a) * r + .08, math.sin(a) * r - .08);
          canvas.rotate(a);
          box(0, 0, .045, .085, i.isEven ? accent : gold, radius: .01);
          canvas.restore();
        }
      case 38:
        box(0, .14, .7, .5, primary);
        box(0, -.14, .83, .16, accent);
        box(0, .12, .13, .55, gold);
        ellipse(-.13, -.3, .3, .17, pale);
        ellipse(.13, -.3, .3, .17, pale);
        ellipse(0, -.27, .1, .13, gold);
      case 39:
        for (var i = 0; i < 12; i++) {
          final a = i * math.pi / 6;
          canvas.save();
          canvas.rotate(a);
          line(0, -.12, 0, -.37);
          ellipse(0, -.43, .045, .045, i.isEven ? gold : primary);
          canvas.restore();
        }
        sparkle(0, 0, .12);
      case 40:
        ellipse(0, .01, .59, .59, gold);
        box(0, .25, .88, .25, pale);
        wave(.3);
        wave(.41);
        for (var i = 0; i < 5; i++) {
          final a = math.pi + i * math.pi / 4;
          line(
            math.cos(a) * .36,
            math.sin(a) * .36,
            math.cos(a) * .46,
            math.sin(a) * .46,
          );
        }
      case 41:
        for (var i = -1; i <= 1; i++) {
          line(i * .22, .21, i * .22 - .06, .38);
        }
        ellipse(0, 0, .76, .35, pale);
        ellipse(-.16, -.16, .35, .37, pale);
        ellipse(.12, -.2, .42, .43, pale);
      case 42:
        for (var i = 0; i < 6; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 3);
          line(0, 0, 0, -.44);
          line(0, -.23, -.12, -.34);
          line(0, -.23, .12, -.34);
          line(0, -.37, -.06, -.42);
          line(0, -.37, .06, -.42);
          canvas.restore();
        }
        ellipse(0, 0, .13, .13, accent);
      case 43:
        for (var i = 0; i < 4; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: const Offset(0, .19),
              radius: .4 - i * .075,
            ),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = [primary, accent, gold, pale][i]
              ..style = PaintingStyle.stroke
              ..strokeWidth = .07,
          );
        }
        ellipse(-.32, .21, .3, .22, paper);
        ellipse(.32, .21, .3, .22, paper);
      case 44:
        ellipse(0, -.04, .69, .69, gold);
        ellipse(.15, -.17, .57, .57, paper, outline: false);
        sparkle(-.32, -.32, .07);
        sparkle(.3, .19, .07);
        wave(.35);
        wave(.45);
      case 45:
        path(
          Path()
            ..moveTo(-.42, .1)
            ..cubicTo(-.67, -.51, .52, -.58, .4, -.04)
            ..cubicTo(.32, .28, .03, .01, -.04, .29)
            ..cubicTo(-.15, .59, -.38, .36, -.42, .1)
            ..close(),
          pale,
        );
        for (var i = 0; i < 5; i++) {
          final a = 2.4 + i * .68;
          ellipse(
            math.cos(a) * .29,
            math.sin(a) * .27,
            .12,
            .12,
            [primary, gold, accent, primary, accent][i],
          );
        }
        ellipse(.18, .1, .13, .16, paper);
      case 46:
        for (var i = -1; i <= 1; i++) {
          canvas.save();
          canvas.translate(i * .16, -.2);
          canvas.rotate(i * .25);
          box(0, 0, .08, .47, i.isEven ? primary : accent);
          ellipse(0, -.29, .13, .2, gold);
          canvas.restore();
        }
        box(0, .25, .57, .42, pale);
        heart(0, .24, .22, primary);
      case 47:
        canvas.save();
        canvas.rotate(.55);
        box(0, -.03, .24, .62, gold);
        path(
          Path()..addPolygon([
            const Offset(-.12, .28),
            const Offset(.12, .28),
            const Offset(0, .49),
          ], true),
          pale,
        );
        path(
          Path()..addPolygon([
            const Offset(-.04, .41),
            const Offset(.04, .41),
            const Offset(0, .49),
          ], true),
          dark,
        );
        box(0, -.4, .24, .16, primary);
        line(-.03, -.25, -.03, .22);
        canvas.restore();
      case 48:
        canvas.drawArc(
          const Rect.fromLTWH(-.35, -.43, .7, .8),
          math.pi,
          math.pi,
          false,
          pen..strokeWidth = .07,
        );
        pen.strokeWidth = .018;
        box(-.33, .09, .19, .4, primary);
        box(.33, .09, .19, .4, primary);
        line(-.23, -.08, -.23, .27);
        line(.23, -.08, .23, .27);
      case 49:
        path(
          Path()
            ..moveTo(0, -.25)
            ..quadraticBezierTo(-.2, -.48, -.43, -.25)
            ..lineTo(-.43, .36)
            ..quadraticBezierTo(-.16, .21, 0, .4)
            ..quadraticBezierTo(.16, .21, .43, .36)
            ..lineTo(.43, -.25)
            ..quadraticBezierTo(.2, -.48, 0, -.25)
            ..close(),
          pale,
        );
        line(0, -.25, 0, .4);
        for (var i = 0; i < 4; i++) {
          line(-.34, -.1 + i * .1, -.1, -.05 + i * .1);
          line(.1, -.05 + i * .1, .34, -.1 + i * .1);
        }
      case 50:
        for (final side in [-1, 1]) {
          canvas.save();
          canvas.scale(side.toDouble(), 1);
          path(
            Path()
              ..moveTo(.08, .04)
              ..quadraticBezierTo(.22, -.4, .48, -.28)
              ..lineTo(.39, -.03)
              ..lineTo(.46, -.02)
              ..quadraticBezierTo(.32, .25, .12, .18)
              ..close(),
            pale,
          );
          canvas.restore();
        }
        heart(0, .05, .58, primary);
      case 51:
        box(0, .05, .83, .55, pale);
        path(
          Path()
            ..moveTo(-.4, -.21)
            ..lineTo(0, .1)
            ..lineTo(.4, -.21),
          paper,
          outline: true,
        );
        line(-.4, .32, -.12, .08);
        line(.4, .32, .12, .08);
        heart(0, .02, .27, primary);
      case 52:
        heart(-.16, -.08, .61, primary);
        heart(.16, .1, .61, accent);
      case 53:
        canvas.drawArc(
          const Rect.fromLTWH(-.22, -.44, .44, .57),
          math.pi,
          math.pi,
          false,
          pen..strokeWidth = .065,
        );
        pen.strokeWidth = .018;
        box(0, .12, .62, .52, primary);
        heart(0, .08, .3, pale);
        line(0, .14, 0, .26);
      case 54:
        canvas.drawPath(
          Path()
            ..moveTo(0, .02)
            ..cubicTo(-.17, .19, .2, .26, -.04, .47),
          pen,
        );
        heart(0, -.15, .68, primary);
        path(
          Path()..addPolygon([
            const Offset(0, .08),
            const Offset(-.06, .17),
            const Offset(.06, .17),
          ], true),
          accent,
        );
      case 55:
        petals(12, .27, primary);
        petals(8, .16, accent);
        ellipse(0, 0, .21, .21, gold);
      case 56:
        for (var i = 0; i < 8; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 4);
          path(
            Path()..addPolygon([
              Offset.zero,
              const Offset(-.1, -.25),
              const Offset(0, -.45),
              const Offset(.1, -.25),
            ], true),
            i.isEven ? primary : accent,
          );
          canvas.restore();
        }
        ellipse(0, 0, .17, .17, gold);
      case 57:
        path(
          Path()..addPolygon([
            const Offset(0, -.48),
            const Offset(-.3, -.15),
            const Offset(-.25, .33),
            const Offset(0, .47),
            const Offset(.25, .33),
            const Offset(.3, -.15),
          ], true),
          pale,
        );
        line(0, -.48, -.1, -.05);
        line(0, -.48, .1, -.05);
        line(-.3, -.15, -.1, -.05);
        line(.3, -.15, .1, -.05);
        line(-.1, -.05, 0, .47);
        line(.1, -.05, 0, .47);
        line(-.25, .33, -.1, -.05);
        line(.25, .33, .1, -.05);
      case 58:
        for (var i = 0; i < 3; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 3);
          canvas.drawOval(const Rect.fromLTWH(-.43, -.18, .86, .36), pen);
          canvas.restore();
        }
        ellipse(0, 0, .18, .18, primary);
        ellipse(.33, .16, .12, .12, gold);
        ellipse(-.2, -.28, .11, .11, accent);
      case 59:
        for (var i = 0; i < 6; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 3);
          path(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(-.18, -.2, 0, -.45)
              ..quadraticBezierTo(.35, -.3, 0, 0)
              ..close(),
            i.isEven ? primary : accent,
          );
          canvas.restore();
        }
        ellipse(0, 0, .14, .14, gold);
    }
    canvas.restore();
  }

  switch (edition) {
    case 13:
      drawMotif(-.18, -.05, -.25);
      drawMotif(.2, .13, .25);
    case 14:
      drawMotif(0, -.23, 0);
      drawMotif(-.23, .21, -.2);
      drawMotif(.23, .21, .2);
    case 15:
      line(-.2, -.12, 0, .43);
      line(.2, -.12, 0, .43);
      drawMotif(-.2, -.16, -.3);
      drawMotif(.2, -.16, .3);
      drawMotif(0, .05, 0);
      box(0, .35, .18, .12, gold);
    default:
      drawMotif(0, edition == 7 ? -.06 : 0, 0);
  }
  canvas.restore();
}
