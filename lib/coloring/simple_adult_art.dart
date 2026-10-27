part of 'art_catalog.dart';

const simpleAdultTitles = [
  'Olive & clay',
  'Stillwater sunset',
  'Lotus calm',
  'Garden rhythm',
  'Mountain morning',
  'Petal harmony',
];
const simpleAdultEntries = [
  ArtEntry(11, 0),
  ArtEntry(11, 1),
  ArtEntry(11, 2),
  ArtEntry(11, 3),
  ArtEntry(11, 4),
  ArtEntry(11, 5),
];
final kidsEntries = List<ArtEntry>.unmodifiable([
  illustratedEntries[0],
  illustratedEntries[1],
  illustratedEntries[4],
  illustratedEntries[5],
  ...atelierForLevel(0),
]);
final adultEntries = List<ArtEntry>.unmodifiable([
  illustratedEntries[2],
  illustratedEntries[3],
  illustratedEntries[6],
  illustratedEntries[7],
  ...premiumEntries,
]);

/// Composed, broad closed shapes designed for relaxed finger colouring.
/// These masters have permanent IDs independent of the older procedural set.
ArtDesign buildSimpleAdult(ArtEntry entry) {
  final regions = <ArtRegion>[], details = <Path>[];
  void add(Path p, int color) =>
      regions.add(ArtRegion('r${regions.length}', p, Color(color)));
  void oval(Rect r, int color) => add(Path()..addOval(r), color);
  final more = entry.variation >= 3;
  switch (entry.variation % 3) {
    case 0:
      oval(const Rect.fromLTWH(150, 150, 700, 700), 0xFFF5E9D5);
      add(
        Path()
          ..moveTo(370, 640)
          ..lineTo(630, 640)
          ..cubicTo(605, 730, 665, 820, 570, 840)
          ..lineTo(430, 840)
          ..cubicTo(335, 820, 395, 730, 370, 640)
          ..close(),
        0xFFC47F68,
      );
      details.add(
        Path()
          ..moveTo(500, 650)
          ..cubicTo(460, 480, 565, 330, 515, 215),
      );
      for (var i = 0; i < (more ? 8 : 5); i++) {
        final y = 300 + i * (more ? 41 : 64),
            x = 510 + (i.isEven ? 0.0 : -15.0),
            side = i.isEven ? 1.0 : -1.0;
        add(
          Path()
            ..moveTo(x, y + 35)
            ..cubicTo(
              x + side * 35,
              y - 35,
              x + side * 130,
              y - 60,
              x + side * 150,
              y - 45,
            )
            ..cubicTo(x + side * 115, y + 35, x + side * 55, y + 60, x, y + 35)
            ..close(),
          i.isEven ? 0xFF69866A : 0xFFA6B18A,
        );
      }
      oval(const Rect.fromLTWH(355, 625, 290, 45), 0xFFE1B294);
    case 1:
      add(
        Path()..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(140, 160, 720, 680),
            const Radius.circular(100),
          ),
        ),
        0xFFF4CBA8,
      );
      oval(const Rect.fromLTWH(530, 230, 160, 160), 0xFFE5A65F);
      add(
        Path()
          ..moveTo(140, 560)
          ..lineTo(340, 300)
          ..lineTo(560, 560)
          ..close(),
        0xFF9EA9A9,
      );
      add(
        Path()
          ..moveTo(390, 560)
          ..lineTo(650, 360)
          ..lineTo(860, 560)
          ..close(),
        0xFF728B89,
      );
      add(
        Path()
          ..moveTo(140, 560)
          ..lineTo(860, 560)
          ..lineTo(860, 700)
          ..lineTo(140, 700)
          ..close(),
        0xFF89B9BE,
      );
      add(
        Path()
          ..moveTo(140, 700)
          ..quadraticBezierTo(500, 640, 860, 700)
          ..lineTo(860, 740)
          ..quadraticBezierTo(850, 840, 760, 840)
          ..lineTo(240, 840)
          ..quadraticBezierTo(140, 840, 140, 740)
          ..close(),
        0xFFC8AD87,
      );
      for (var i = 0; i < (more ? 5 : 2); i++) {
        final y = 590.0 + i * 20;
        details.add(
          Path()
            ..moveTo(300 + i * 30, y)
            ..quadraticBezierTo(470, y - 12, 650 - i * 18, y),
        );
      }
      if (more) {
        for (var i = 0; i < 5; i++) {
          final x = 230.0 + i * 125;
          add(
            Path()
              ..moveTo(x, 770)
              ..lineTo(x + 25, 680)
              ..lineTo(x + 50, 770)
              ..close(),
            0xFF4C7564,
          );
        }
      }
    case 2:
      oval(const Rect.fromLTWH(145, 145, 710, 710), 0xFFF1E8DC);
      final count = more ? 12 : 8;
      for (var i = 0; i < count; i++) {
        final angle = i * 2 * math.pi / count;
        final p = Path()
          ..moveTo(500, 500)
          ..cubicTo(380, 400, 410, 240, 500, 210)
          ..cubicTo(590, 240, 620, 400, 500, 500)
          ..close();
        final m = Matrix4.identity()
          ..translateByDouble(500, 500, 0, 1)
          ..rotateZ(angle)
          ..translateByDouble(-500, -500, 0, 1);
        add(p.transform(m.storage), i.isEven ? 0xFFC7909A : 0xFF9E91BC);
      }
      if (more) {
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          oval(
            Rect.fromCircle(
              center: Offset(500 + math.cos(a) * 150, 500 + math.sin(a) * 150),
              radius: 45,
            ),
            0xFFEAC98B,
          );
        }
      }
      oval(const Rect.fromLTWH(420, 420, 160, 160), 0xFFD8B56D);
  }
  return ArtDesign(entry, regions, details);
}
