part of 'art_catalog.dart';

// Catalogue v1: 36 scene compositions, ten geometry editions at three levels.
// Keep IDs, seeds and geometry stable: saved region colours depend on them.
const atelierCount = 1080;
const atelierCategories = [
  'Botanical',
  'Wildlife',
  'Butterflies',
  'Gardens',
  'Landscapes',
  'Travel',
  'Water gardens',
  'Ocean',
  'Still life',
  'Woodland',
  'Mandalas',
  'Succulents',
];
const _atelierTitles = [
  [
    'Peony conservatory',
    'Songbird sanctuary',
    'Butterfly ballet',
    'Rosewood cottage',
    'Alpine reflections',
    'Harbour morning',
    'Lotus & koi',
    'Coral kingdom',
    'Tea in the garden',
    'Toadstool neighbourhood',
    'Celestial rosette',
    'Desert conservatory',
  ],
  [
    'Wildflower terrace',
    'Hummingbird haven',
    'Wings in the wildflowers',
    'The secret greenhouse',
    'Moonrise over the valley',
    'Seaside rooftops',
    'Waterlily reverie',
    'Ocean explorers',
    'Citrus afternoon',
    'Woodland lanterns',
    'Lotus constellation',
    'Agave courtyard',
  ],
  [
    'Blooming wreath',
    'Orchard duet',
    'Meadow garland',
    'Village in bloom',
    'Mountain hideaway',
    'Sails & sunshine',
    'A quiet pond',
    'Turtle lagoon',
    'The potter’s shelf',
    'Mushroom meadow',
    'Starlight medallion',
    'Cactus sunset',
  ],
];
const _atelierEditions = [
  'Spring',
  'Solstice',
  'Daybreak',
  'Serenity',
  'Golden hour',
  'Blue hour',
  'Reverie',
  'Whisper',
  'Harmony',
  'Wonder',
];
final atelierEntries = List<ArtEntry>.unmodifiable(
  List.generate(atelierCount, (i) => ArtEntry(13, i)),
);
List<ArtEntry> atelierForLevel(int level) => [
  for (var edition = 0; edition < 10; edition++)
    for (var layout = 0; layout < 3; layout++)
      for (var topic = 0; topic < 12; topic++)
        atelierEntries[layout * 360 + topic * 30 + level * 10 + edition],
];
final intermediateEntries = List<ArtEntry>.unmodifiable([
  ...adultEntries.where((e) => !e.premium && !e.atelier),
  ...atelierForLevel(0),
  ...atelierForLevel(1),
]);
final advancedEntries = List<ArtEntry>.unmodifiable([
  ...premiumEntries,
  ...atelierForLevel(2),
]);

class _AtelierBuilder {
  final ArtEntry entry;
  late final _ArtRandom rng;
  final regions = <ArtRegion>[];
  final details = <Path>[];
  final detailOwners = <String, List<Path>>{};
  Matrix4 matrix = Matrix4.identity();
  late final int level = entry.atelierLevel;
  late final int topic = entry.variation ~/ 30 % 12;
  late final int layout = entry.variation ~/ 360;
  late final int edition = entry.variation % 10;
  static const rose = 0xFFEAA4B3, wine = 0xFFB96585, gold = 0xFFE8BD70;
  static const sage = 0xFF92B39C, green = 0xFF537F6C, blue = 0xFF92BFD0;
  static const cream = 0xFFF8E8CA, lilac = 0xFFB6A3CF, clay = 0xFFCE9275;
  _AtelierBuilder(this.entry) {
    rng = _ArtRandom(940003 + entry.variation * 15485863);
  }
  double r(double a, double b) => a + rng.nextDouble() * (b - a);
  void add(Path p, int color) => regions.add(
    ArtRegion('r${regions.length}', p.transform(matrix.storage), Color(color)),
  );
  void line(Path p) {
    final path = p.transform(matrix.storage);
    details.add(path);
    (detailOwners[regions.isEmpty ? '' : regions.last.id] ??= []).add(path);
  }

  void at(
    double x,
    double y,
    double scale,
    void Function() draw, [
    double angle = 0,
  ]) {
    final old = matrix;
    matrix = matrix.clone()
      ..translateByDouble(x, y, 0, 1)
      ..rotateZ(angle)
      ..scaleByDouble(scale, scale, 1, 1);
    draw();
    matrix = old;
  }

  void oval(double x, double y, double w, double h, int color) => add(
    Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h)),
    color,
  );
  void rect(
    double x,
    double y,
    double w,
    double h,
    int color, [
    double radius = 8,
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
  void stroke(List<Offset> points) => line(Path()..addPolygon(points, false));
  void leaf(
    double x,
    double y,
    double length,
    double angle, [
    int color = sage,
  ]) {
    at(x, y, 1, () {
      add(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(
            -length * .52,
            -length * .45,
            -length * .35,
            -length * .9,
            0,
            -length,
          )
          ..cubicTo(
            length * .35,
            -length * .9,
            length * .52,
            -length * .45,
            0,
            0,
          )
          ..close(),
        color,
      );
      line(
        Path()
          ..moveTo(0, -4)
          ..quadraticBezierTo(8, -length * .5, 0, -length * .92),
      );
      if (level > 0) {
        for (var i = 1; i <= 3 + level; i++) {
          final y = -length * i / (5 + level);
          stroke([
            Offset(-length * .21, y - 9),
            Offset(2, y + 9),
            Offset(length * .21, y - 9),
          ]);
        }
      }
    }, angle);
  }

  void flower(
    double x,
    double y,
    double size, [
    int color = rose,
    int petals = 7,
  ]) {
    at(x, y, 1, () {
      final phase = r(0, .4);
      for (var ring = level > 0 ? 1 : 0; ring >= 0; ring--) {
        final radius = size * (ring == 1 ? 1 : .62);
        final count = petals + (ring == 1 ? 2 : 0);
        for (var i = 0; i < count; i++) {
          at(0, 0, 1, () {
            add(
              Path()
                ..moveTo(0, 0)
                ..cubicTo(
                  -radius * .5,
                  -radius * .35,
                  -radius * .48,
                  -radius * .9,
                  0,
                  -radius,
                )
                ..cubicTo(
                  radius * .48,
                  -radius * .9,
                  radius * .5,
                  -radius * .35,
                  0,
                  0,
                )
                ..close(),
              ring == 1 ? color : cream,
            );
          }, phase + i * math.pi * 2 / count + (ring == 1 ? .15 : 0));
        }
      }
      oval(0, 0, size * .42, size * .42, gold);
      if (level == 2) {
        for (var i = 0; i < 7; i++) {
          final a = i * math.pi * 2 / 7;
          oval(math.cos(a) * size * .1, math.sin(a) * size * .1, 5, 5, wine);
        }
      }
    });
  }

  void sprig(double x, double y, double height, [double angle = 0]) {
    at(x, y, 1, () {
      line(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(-20, -height * .3, 20, -height * .65, 0, -height),
      );
      final count = 3 + level * 2;
      for (var i = 0; i < count; i++) {
        final y = -height * (i + 1) / (count + 1);
        leaf(
          0,
          y,
          height * .32,
          i.isEven ? -.85 : .85,
          i.isEven ? sage : green,
        );
      }
    }, angle);
  }

  void cloud(double x, double y, double scale) => at(x, y, scale, () {
    add(
      Path()
        ..moveTo(-75, 20)
        ..cubicTo(-120, 15, -110, -30, -65, -25)
        ..cubicTo(-65, -85, 25, -95, 35, -35)
        ..cubicTo(100, -60, 125, 15, 70, 22)
        ..close(),
      cream,
    );
  });
  void star(double x, double y, double size, [int color = gold]) {
    poly(
      List.generate(10, (i) {
        final a = -math.pi / 2 + i * math.pi / 5,
            rad = i.isEven ? size : size * .43;
        return Offset(x + math.cos(a) * rad, y + math.sin(a) * rad);
      }),
      color,
    );
  }

  void bird(double x, double y, double scale, [double angle = 0]) =>
      at(x, y, scale, () {
        poly([
          const Offset(-40, 65),
          const Offset(-215, 150),
          const Offset(-160, 40),
        ], blue);
        add(
          Path()
            ..moveTo(-100, 5)
            ..cubicTo(-140, -100, 75, -145, 105, -10)
            ..cubicTo(140, 110, -65, 160, -100, 5)
            ..close(),
          blue,
        );
        oval(72, -90, 112, 112, rose);
        poly([
          const Offset(119, -104),
          const Offset(172, -83),
          const Offset(120, -65),
        ], gold);
        add(
          Path()
            ..moveTo(-60, -25)
            ..cubicTo(-40, -135, 70, -30, 40, 35)
            ..quadraticBezierTo(0, 100, -60, -25)
            ..close(),
          lilac,
        );
        oval(93, -101, 15, 15, 0xFF30344D);
        for (var i = 0; i < 2 + level * 2; i++) {
          line(
            Path()
              ..moveTo(-50 + i * 14.0, -20)
              ..quadraticBezierTo(-8 + i * 10.0, 55, 25 + i * 5.0, 20),
          );
        }
        stroke([
          const Offset(5, 105),
          const Offset(0, 145),
          const Offset(20, 145),
        ]);
        stroke([
          const Offset(35, 100),
          const Offset(40, 145),
          const Offset(60, 145),
        ]);
      }, angle);
  void butterfly(double x, double y, double scale, [double angle = 0]) => at(
    x,
    y,
    scale,
    () {
      for (final side in [-1.0, 1.0]) {
        at(0, 0, 1, () {
          add(
            Path()
              ..moveTo(0, 0)
              ..cubicTo(50, -90, 230, -230, 210, -60)
              ..cubicTo(195, 40, 85, 70, 0, 0)
              ..close(),
            rose,
          );
          add(
            Path()
              ..moveTo(0, 0)
              ..cubicTo(120, 5, 205, 25, 160, 125)
              ..cubicTo(120, 200, 15, 135, 0, 0)
              ..close(),
            lilac,
          );
          final count = 2 + level * 2;
          for (var i = 0; i < count; i++) {
            final t = i / (count - 1);
            oval(65 + t * 100, -45 - t * 48, 22 + t * 9, 38, cream);
            oval(55 + t * 70, 60 + t * 35, 20, 26, gold);
          }
          line(
            Path()
              ..moveTo(10, 0)
              ..quadraticBezierTo(120, -60, 190, -110),
          );
          line(
            Path()
              ..moveTo(10, 12)
              ..quadraticBezierTo(90, 45, 150, 120),
          );
        });
        // Mirror the second wing set using the canvas-independent path matrix.
        if (side == -1) matrix = matrix.clone()..scaleByDouble(-1, 1, 1, 1);
      }
      matrix = matrix.clone()..scaleByDouble(-1, 1, 1, 1);
      oval(0, 15, 25, 185, wine);
      line(
        Path()
          ..moveTo(-7, -60)
          ..quadraticBezierTo(-45, -140, -62, -105),
      );
      line(
        Path()
          ..moveTo(7, -60)
          ..quadraticBezierTo(45, -140, 62, -105),
      );
    },
    angle,
  );
  void arch() {
    if (layout == 1) {
      line(
        Path()
          ..moveTo(100, 910)
          ..lineTo(100, 420)
          ..cubicTo(100, 0, 900, 0, 900, 420)
          ..lineTo(900, 910),
      );
    } else if (layout == 2) {
      line(Path()..addOval(const Rect.fromLTWH(95, 95, 810, 810)));
    }
  }

  void vase(double x, double y, double size) => at(x, y, size, () {
    add(
      Path()
        ..moveTo(-100, -15)
        ..cubicTo(-80, 65, -165, 210, -100, 255)
        ..quadraticBezierTo(0, 285, 100, 255)
        ..cubicTo(165, 210, 80, 65, 100, -15)
        ..close(),
      clay,
    );
    oval(0, -15, 205, 38, cream);
    for (var i = 0; i < 2 + level; i++) {
      line(
        Path()
          ..moveTo(-90, 65 + i * 36)
          ..quadraticBezierTo(0, 95 + i * 36, 90, 65 + i * 36),
      );
    }
  });
  void tree(double x, double y, double size) => at(x, y, size, () {
    rect(-10, 0, 20, 125, clay, 3);
    for (var i = 0; i < 3; i++) {
      final y = -110 + i * 65.0;
      poly([
        Offset(0, y - 95),
        Offset(-85 - i * 9, y + 65),
        Offset(85 + i * 9, y + 65),
      ], i.isEven ? green : sage);
    }
  });
  void house(
    double x,
    double y,
    double size, {
    bool glass = false,
  }) => at(x, y, size, () {
    rect(-155, -90, 310, 285, glass ? blue : cream, 3);
    rect(82, -235, 40, 90, clay, 2);
    poly([
      const Offset(-185, -90),
      const Offset(0, -255),
      const Offset(185, -90),
    ], clay);
    for (var i = 0; i < level + 1; i++) {
      stroke([
        Offset(-135 + i * 28, -120 - i * 25.0),
        Offset(135 - i * 28, -120 - i * 25.0),
      ]);
    }
    add(
      Path()
        ..moveTo(-38, 195)
        ..lineTo(-38, 63)
        ..cubicTo(-38, 5, 38, 5, 38, 63)
        ..lineTo(38, 195)
        ..close(),
      wine,
    );
    oval(22, 118, 9, 9, gold);
    for (final side in [-1, 1]) {
      rect(side * 100 - 30, -28, 60, 83, blue, 20);
      stroke([Offset(side * 100.0, -28), Offset(side * 100.0, 55)]);
      stroke([Offset(side * 100 - 30.0, 12), Offset(side * 100 + 30.0, 12)]);
      rect(side * 100 - 42, 60, 84, 25, sage, 4);
      if (level > 0) {
        for (var i = 0; i < 3; i++) {
          flower(side * 100 - 25 + i * 25.0, 55, 16, rose, 5);
        }
      }
    }
    oval(0, -140, 54, 54, gold);
    if (glass) {
      for (var i = 0; i < 3; i++) {
        stroke([Offset(-120 + i * 120.0, -80), Offset(-120 + i * 120.0, 190)]);
      }
      stroke([const Offset(-152, 85), const Offset(152, 85)]);
    }
  });
  void fish(
    double x,
    double y,
    double size, {
    bool koi = false,
    double angle = 0,
  }) => at(x, y, size, () {
    poly([
      const Offset(-85, 0),
      const Offset(-175, -70),
      const Offset(-155, 65),
    ], rose);
    add(
      Path()
        ..moveTo(-105, 0)
        ..cubicTo(-30, -115, 120, -105, 150, 0)
        ..cubicTo(90, 105, -40, 100, -105, 0)
        ..close(),
      koi ? cream : gold,
    );
    poly([
      const Offset(-30, -60),
      const Offset(-10, -125),
      const Offset(40, -70),
    ], clay);
    add(
      Path()
        ..moveTo(0, 5)
        ..quadraticBezierTo(55, 18, 20, 90)
        ..close(),
      rose,
    );
    for (var i = 0; i < 2 + level * 2; i++) {
      if (koi) {
        oval(
          -55 + i * 27.0,
          i.isEven ? -22 : 22,
          30,
          32,
          i.isEven ? rose : clay,
        );
      } else {
        line(
          Path()
            ..moveTo(-60 + i * 25.0, -40)
            ..quadraticBezierTo(-35 + i * 25.0, 0, -60 + i * 25.0, 40),
        );
      }
    }
    oval(105, -17, 13, 13, 0xFF30344D);
    line(
      Path()
        ..moveTo(75, -65)
        ..quadraticBezierTo(45, 0, 75, 65),
    );
  }, angle);
  void mushroom(double x, double y, double size) => at(x, y, size, () {
    add(
      Path()
        ..moveTo(-62, -20)
        ..cubicTo(-35, 50, -85, 150, -45, 175)
        ..lineTo(60, 175)
        ..cubicTo(85, 120, 35, 45, 65, -20)
        ..close(),
      cream,
    );
    add(
      Path()
        ..moveTo(-155, -5)
        ..cubicTo(-145, -200, 120, -235, 155, -5)
        ..quadraticBezierTo(0, 55, -155, -5)
        ..close(),
      wine,
    );
    for (var i = 0; i < 3 + level * 2; i++) {
      final a = (i + 1) * math.pi / (4 + level * 2);
      oval(math.cos(a) * 100, -25 - math.sin(a) * 95, 25, 21, cream);
    }
    rect(-12, 100, 35, 75, clay, 16);
    oval(-28, 57, 32, 34, blue);
    stroke([const Offset(-44, 57), const Offset(-12, 57)]);
  });
  void lotus(double x, double y, double size) => at(x, y, size, () {
    for (var i = 0; i < 5 + level * 2; i++) {
      leaf(
        0,
        20,
        100,
        -1.15 + i * 2.3 / (4 + level * 2),
        i.isEven ? rose : lilac,
      );
    }
    oval(0, 27, 160, 34, sage);
  });
  void garden(double y) {
    final count = 4 + level * 3;
    for (var i = 0; i < count; i++) {
      final x = 140 + i * 720 / (count - 1), h = r(90, 170);
      sprig(x, y, h, r(-.3, .3));
      flower(
        x + r(-12, 12),
        y - h,
        r(24, 40),
        i.isEven ? rose : lilac,
        5 + edition % 3,
      );
    }
  }

  void bouquet() {
    if (layout == 2) {
      final count = 6 + level * 3 + edition % 3;
      for (var i = 0; i < count; i++) {
        final a = i * math.pi * 2 / count,
            x = 500 + math.cos(a) * 300,
            y = 500 + math.sin(a) * 300;
        leaf(x, y, 110, a + math.pi / 2, sage);
        flower(x, y, r(55, 80), i.isEven ? rose : lilac, 5 + edition % 4);
      }
      lotus(500, 500, 1.5);
    } else {
      final count = 3 + level * 2 + edition % 3;
      for (var i = 0; i < count; i++) {
        final x = 200 + i * 600 / (count - 1) + r(-20, 20), y = r(220, 400);
        line(
          Path()
            ..moveTo(500, 760)
            ..cubicTo(x - 70, 560, x + 40, 440, x, y),
        );
        sprig(x, 690, r(180, 260), r(-.4, .4));
        flower(x, y, r(60, 90), i.isEven ? rose : lilac, 6 + edition % 4);
      }
      vase(500, 735, .65);
    }
  }

  void birds() {
    line(
      Path()
        ..moveTo(120, 650)
        ..quadraticBezierTo(500, 800, 880, 550),
    );
    for (var i = 0; i < 3 + level * 2; i++) {
      final x = 170 + i * 660 / (2 + level * 2);
      leaf(x, 680, 90, r(-.9, .9), sage);
      flower(x + 15, 620, r(22, 35), rose, 5);
    }
    bird(380 + r(-30, 30), 460, layout == 1 ? 1.15 : 1, r(-.15, .15));
    if (layout != 1) {
      bird(700, 310, .65, r(-.2, .2));
    }
    for (var i = 0; i < 2 + level; i++) {
      flower(220 + i * 175.0, 180 + r(-15, 20), 27, lilac, 5);
    }
  }

  void butterflies() {
    garden(890);
    butterfly(500 + r(-30, 30), 420, layout == 1 ? 1.15 : 1, r(-.25, .25));
    if (layout != 1) {
      butterfly(210, 620, .4, r(-.4, .1));
      butterfly(800, 590, .45, r(.1, .4));
    }
  }

  void cottages() {
    cloud(240, 190, .8);
    oval(780, 160, 100, 100, gold);
    tree(170, 610, .7);
    tree(840, 640, .7);
    house(
      layout == 2 ? 390 : 500,
      540,
      layout == 2 ? .8 : 1,
      glass: layout == 1,
    );
    if (layout == 2) {
      house(740, 660, .45);
    }
    for (var i = 0; i < 4 + level; i++) {
      oval(500 - i * 12.0, 760 + i * 24.0, 125 - i * 10, 18, cream);
    }
    garden(900);
  }

  void mountains() {
    oval(780, 180, 110, 110, gold);
    cloud(240, 180, .75);
    cloud(650, 240, .55);
    for (var i = 0; i < 3; i++) {
      final x = 120 + i * 340.0, y = 270 + r(-50, 50);
      poly([
        Offset(x - 210, 620),
        Offset(x, y),
        Offset(x + 230, 620),
      ], i.isEven ? lilac : blue);
      poly([
        Offset(x - 50, y + 85),
        Offset(x, y),
        Offset(x + 57, y + 85),
        Offset(x + 15, y + 62),
      ], cream);
    }
    add(
      Path()
        ..moveTo(110, 620)
        ..quadraticBezierTo(500, 660, 890, 620)
        ..lineTo(770, 900)
        ..quadraticBezierTo(500, 960, 230, 900)
        ..close(),
      blue,
    );
    for (var i = 0; i < 3 + level * 2; i++) {
      line(
        Path()
          ..moveTo(220 + i * 12.0, 690 + i * 26.0)
          ..quadraticBezierTo(
            490,
            725 + i * 26.0,
            800 - i * 12.0,
            690 + i * 26.0,
          ),
      );
    }
    for (var i = 0; i < 2 + level; i++) {
      tree(170 + i * 45.0, 710 + i * 35.0, .4);
      tree(840 - i * 45.0, 710 + i * 35.0, .4);
    }
    if (layout == 2) {
      house(500, 580, .3);
    }
    flower(390, 900, 25, rose, 6);
    flower(680, 895, 25, gold, 7);
  }

  void boat(double x, double y, double size) => at(x, y, size, () {
    poly([
      const Offset(-110, 0),
      const Offset(120, 0),
      const Offset(70, 50),
      const Offset(-60, 50),
    ], clay);
    stroke([const Offset(0, 0), const Offset(0, -220)]);
    poly([
      const Offset(-5, -210),
      const Offset(-5, -15),
      const Offset(-105, -15),
    ], cream);
    poly([
      const Offset(7, -190),
      const Offset(105, -15),
      const Offset(7, -15),
    ], rose);
  });
  void coast() {
    oval(780, 180, 100, 100, gold);
    cloud(210, 190, .75);
    for (var i = 0; i < 3 + level; i++) {
      final x = 160 + i * 680 / (2 + level), h = r(120, 180);
      rect(x - 55, 490 - h, 110, h, i.isEven ? clay : cream, 2);
      poly([
        Offset(x - 70, 490 - h),
        Offset(x, 440 - h),
        Offset(x + 70, 490 - h),
      ], wine);
      for (var j = 0; j < 2 + level; j++) {
        final windowY = 510 - h + j * (h - 48) / (1 + level);
        rect(x - 30, windowY, 18, 22, blue, 4);
        rect(x + 14, windowY, 18, 22, blue, 4);
      }
    }
    add(
      Path()
        ..moveTo(100, 515)
        ..quadraticBezierTo(500, 550, 900, 515)
        ..lineTo(900, 900)
        ..lineTo(100, 900)
        ..close(),
      blue,
    );
    boat(400 + r(-20, 20), 780, .8);
    if (layout != 1) {
      boat(750, 840, .55);
    }
    for (var i = 0; i < 2 + level; i++) {
      line(
        Path()
          ..moveTo(270, 820 + i * 18.0)
          ..quadraticBezierTo(510, 850 + i * 18.0, 760, 820 + i * 18.0),
      );
    }
    sprig(140, 910, 130);
    flower(175, 845, 35, rose, 6);
  }

  void pond() {
    for (var i = 0; i < 3 + level; i++) {
      final x = i.isEven ? 220.0 : 780.0, y = 220 + i * 130.0;
      oval(x, y, 210, 110, sage);
      lotus(x, y - 25, .7);
    }
    fish(500, 400, .9, koi: true, angle: .6);
    fish(470, 720, .8, koi: true, angle: -.6);
    if (layout == 2) {
      fish(690, 530, .55, koi: true, angle: .5);
    }
    for (var i = 0; i < 4 + level * 2; i++) {
      oval(r(300, 700), r(220, 880), 15, 15, blue);
    }
  }

  void reef() {
    garden(910);
    fish(360, 330, .9, angle: r(-.3, .3));
    fish(750, 530, .6);
    if (layout == 2) {
      for (final side in [-1, 1]) {
        leaf(500 + side * 95, 680, 110, side * 1.1, green);
      }
      oval(500, 560, 65, 80, green);
      oval(500, 690, 150, 200, sage);
      poly([
        const Offset(500, 610),
        const Offset(550, 660),
        const Offset(550, 735),
        const Offset(500, 780),
        const Offset(450, 735),
        const Offset(450, 660),
      ], gold);
    } else {
      fish(600, 690, .75, angle: -.2);
    }
    for (var i = 0; i < 4 + level; i++) {
      oval(820 + r(-15, 15), 160 + i * 65.0, 15, 18, blue);
    }
    star(180, 860, 32, clay);
    star(810, 880, 25, gold);
  }

  void tea() {
    rect(120, 850, 760, 28, clay, 10);
    for (var i = 0; i < 3 + level; i++) {
      final x = 650 + r(-100, 100), y = 400 + r(-120, 80);
      sprig(x, 650, 180, r(-.4, .4));
      flower(x, y, r(40, 60), i.isEven ? rose : lilac, 7);
    }
    vase(650, 630, .65);
    oval(320, 825, 290, 35, lilac);
    oval(458, 710, 95, 110, clay);
    oval(458, 710, 58, 70, cream);
    add(
      Path()
        ..moveTo(190, 650)
        ..quadraticBezierTo(210, 820, 330, 820)
        ..quadraticBezierTo(440, 820, 450, 650)
        ..close(),
      cream,
    );
    oval(320, 650, 260, 65, clay);
    oval(320, 650, 225, 38, 0xFF8E6652);
    for (var i = 0; i < 2 + level; i++) {
      flower(240 + i * 50.0, 735, 22, rose, 5);
    }
    for (var i = 0; i < 3; i++) {
      line(
        Path()
          ..moveTo(240 + i * 70.0, 595)
          ..cubicTo(
            200 + i * 70.0,
            550,
            280 + i * 70.0,
            520,
            240 + i * 70.0,
            480,
          ),
      );
    }
    if (layout == 1) {
      oval(155, 830, 85, 85, gold);
      stroke([const Offset(120, 830), const Offset(190, 830)]);
    }
  }

  void woodland() {
    oval(790, 180, 110, 110, gold);
    for (var i = 0; i < 3 + level; i++) {
      star(170 + i * 120.0, 180 + r(-30, 70), 15, lilac);
    }
    final n = layout == 1 ? 2 : 3 + level;
    for (var i = 0; i < n; i++) {
      mushroom(220 + i * 580 / (n - 1), 600 + r(-50, 70), r(.65, .95));
    }
    garden(910);
  }

  void mandala() {
    final count = 8 + level * 4 + edition % 3;
    for (var i = 0; i < count; i++) {
      final a = i * math.pi * 2 / count;
      at(500, 500, 1, () {
        leaf(0, -170, 140, 0, i.isEven ? rose : lilac);
        oval(0, -150, 28, 32, gold);
        if (level > 0) {
          leaf(0, -320, 85, -.3, sage);
        }
        if (level == 2) {
          star(0, -420, 20, lilac);
        }
      }, a);
    }
    flower(500, 500, 130, gold, 8 + edition % 3);
    for (var i = 0; i < count; i++) {
      final a = (i + .5) * math.pi * 2 / count;
      oval(500 + math.cos(a) * 280, 500 + math.sin(a) * 280, 18, 18, cream);
    }
  }

  void desert() {
    oval(780, 180, 120, 120, gold);
    add(
      Path()
        ..moveTo(100, 740)
        ..quadraticBezierTo(320, 410, 550, 690)
        ..quadraticBezierTo(800, 530, 900, 740)
        ..lineTo(900, 900)
        ..lineTo(100, 900)
        ..close(),
      cream,
    );
    for (var i = 0; i < 3; i++) {
      final x = 230 + i * 270.0, y = 790 + r(-20, 20);
      if (i == 1 || layout == 1) {
        for (var j = 0; j < 5 + level * 2; j++) {
          leaf(
            x,
            y,
            r(130, 190),
            -1.2 + j * 2.4 / (4 + level * 2),
            j.isEven ? sage : green,
          );
        }
      } else {
        rect(x - 28, y - 270, 56, 270, sage, 28);
        rect(x - 92, y - 165, 40, 135, sage, 20);
        rect(x - 60, y - 70, 45, 35, sage, 10);
        for (var j = 0; j < 2 + level; j++) {
          stroke([
            Offset(x - 15 + j * 12.0, y - 230),
            Offset(x - 15 + j * 12.0, y - 15),
          ]);
        }
        flower(x, y - 270, 38, rose, 7);
      }
      if (layout == 1) {
        vase(x, y + 10, .4);
      }
    }
    for (var i = 0; i < 3 + level; i++) {
      oval(250 + i * 120.0, 920 + r(-8, 8), 55, 25, clay);
    }
  }

  ArtDesign build() {
    arch();
    switch (topic) {
      case 0:
        bouquet();
      case 1:
        birds();
      case 2:
        butterflies();
      case 3:
        cottages();
      case 4:
        mountains();
      case 5:
        coast();
      case 6:
        pond();
      case 7:
        reef();
      case 8:
        tea();
      case 9:
        woodland();
      case 10:
        mandala();
      case 11:
        desert();
    }
    // Visibility is precomputed off-device; never run path boolean operations here.
    final hidden = _atelierHiddenRegions.isEmpty
        ? <String>{}
        : _atelierHiddenRegions[entry.variation].split(',').toSet();
    final visibleRegions = regions
        .where((r) => !hidden.contains(r.id.substring(1)))
        .toList();
    var bounds = regions.first.path.getBounds();
    for (final region in regions.skip(1)) {
      bounds = bounds.expandToInclude(region.path.getBounds());
    }
    for (final path in details) {
      bounds = bounds.expandToInclude(path.getBounds());
    }
    final scale = math.min(880 / bounds.width, 880 / bounds.height);
    final fit = Matrix4.identity()
      ..translateByDouble(500, 500, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-bounds.center.dx, -bounds.center.dy, 0, 1);
    return ArtDesign(
      entry,
      List.unmodifiable(
        visibleRegions.map(
          (r) => ArtRegion(r.id, r.path.transform(fit.storage), r.sample),
        ),
      ),
      List.unmodifiable(details.map((p) => p.transform(fit.storage))),
      layeredDetails: {
        for (final item in detailOwners.entries)
          item.key: List.unmodifiable(
            item.value.map((p) => p.transform(fit.storage)),
          ),
      },
    );
  }
}
