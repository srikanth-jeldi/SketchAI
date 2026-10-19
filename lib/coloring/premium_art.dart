part of 'art_catalog.dart';

const premiumTitles = [
  'Botanical Reverie',
  'Forest Guardian',
  'Celestial Lotus',
  'Moonlit Conservatory',
  'Alpine Stillness',
  'Amalfi Afternoon',
];
const premiumCategories = [
  'Botanical',
  'Wildlife',
  'Mandalas',
  'Fantasy',
  'Landscapes',
  'Architecture',
];
const _premiumFiles = [
  '01-botanical',
  '02-wildlife',
  '03-mandala',
  '04-fantasy',
  '05-landscape',
  '06-architecture',
];
const premiumEntries = [
  ArtEntry(10, 0),
  ArtEntry(10, 1),
  ArtEntry(10, 2),
  ArtEntry(10, 3),
  ArtEntry(10, 4),
  ArtEntry(10, 5),
];
final premiumDesigns = <String, ArtDesign>{};
final _premiumImages = <String, ui.Image>{};
Future<void>? _premiumLoading;

/// Decode approved sheets once. Regions come from the actual outline pixels,
/// never the independently painted colour reference.
Future<void> loadPremiumArt() => _premiumLoading ??= _loadPremiumArt();

Future<void> _loadPremiumArt() async {
  for (var n = 0; n < premiumEntries.length; n++) {
    final bytes = await rootBundle.load(
      'assets/artwork/${_premiumFiles[n]}-v1.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final regions = _outlineRegions(data, image.width, image.height);
    final entry = premiumEntries[n];
    _premiumImages[entry.id] = image;
    premiumDesigns[entry.id] = ArtDesign(entry, regions, const []);
    await Future<void>.delayed(Duration.zero);
  }
}

List<ArtRegion> _outlineRegions(Uint8List rgba, int width, int height) {
  // Half-resolution hit masks keep touch detection and retained paths bounded.
  // A dark source pixel blocks its cell, preserving fine walls conservatively.
  final w = width ~/ 4, h = height ~/ 2;
  final labels = Int32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      for (var dy = 0; dy < 2; dy++) {
        for (var dx = 0; dx < 2; dx++) {
          final p = ((y * 2 + dy) * width + x * 2 + dx) * 4;
          if (rgba[p] + rgba[p + 1] + rgba[p + 2] < 570) labels[y * w + x] = -1;
        }
      }
    }
  }
  var label = 0;
  final queue = Int32List(w * h);
  final counts = <int>[0];
  for (var seed = 0; seed < labels.length; seed++) {
    if (labels[seed] != 0) continue;
    label++;
    var head = 0, tail = 1;
    queue[0] = seed;
    labels[seed] = label;
    while (head < tail) {
      final p = queue[head++], x = p % w;
      for (final q in [
        if (x > 0) p - 1,
        if (x < w - 1) p + 1,
        if (p >= w) p - w,
        if (p < labels.length - w) p + w,
      ]) {
        if (labels[q] == 0) {
          labels[q] = label;
          queue[tail++] = q;
        }
      }
    }
    counts.add(tail);
  }
  final paths = <int, Path>{};
  // Preserve component IDs from v0.3 saves, but extend colour beneath ink.
  // Conservative source barriers otherwise leave white stripes where the
  // monochrome display suppresses pale source texture.
  var head = 0, tail = 0;
  for (var p = 0; p < labels.length; p++) {
    if (labels[p] > 0 && counts[labels[p]] >= 18) {
      queue[tail++] = p;
    } else {
      labels[p] = 0;
    }
  }
  while (head < tail) {
    final p = queue[head++], x = p % w;
    // Absorb discarded texture specks into the nearest original area. Existing
    // area seeds never change ownership; ink is drawn above this colour map.
    for (final q in [
      if (x > 0) p - 1,
      if (x < w - 1) p + 1,
      if (p >= w) p - w,
      if (p < labels.length - w) p + w,
    ]) {
      if (labels[q] == 0) {
        labels[q] = labels[p];
        queue[tail++] = q;
      }
    }
  }
  final sx = 750 / w, sy = 1000 / h;
  for (var y = 0; y < h; y++) {
    var x = 0;
    while (x < w) {
      final id = labels[y * w + x], start = x++;
      while (x < w && labels[y * w + x] == id) {
        x++;
      }
      if (id > 0) {
        (paths[id] ??= Path()).addRect(
          Rect.fromLTWH(125 + start * sx, y * sy, (x - start) * sx, sy),
        );
      }
    }
  }
  return [
    for (final e in paths.entries)
      ArtRegion('r${e.key}', e.value, Colors.white),
  ];
}

void paintPremium(
  Canvas canvas,
  ArtDesign art, {
  required Map<String, int> colors,
  required bool sample,
  required bool fills,
  required bool outlines,
}) {
  final image = _premiumImages[art.entry.id]!;
  const destination = Rect.fromLTWH(125, 0, 750, 1000);
  if (sample) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        image.width / 2,
        0,
        image.width / 2,
        image.height.toDouble(),
      ),
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
    return;
  }
  if (fills) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1000, 1000),
      Paint()..color = Colors.white,
    );
    for (final region in art.regions) {
      if (colors.containsKey(region.id)) {
        canvas.drawPath(
          region.path,
          Paint()
            ..isAntiAlias = false
            ..color = Color(colors[region.id]!),
        );
      }
    }
  }
  if (outlines) {
    canvas.saveLayer(destination, Paint()..blendMode = BlendMode.multiply);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width / 2, image.height.toDouble()),
      destination,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = const ColorFilter.matrix([
          .6378,
          2.1456,
          .2166,
          0,
          -255,
          .6378,
          2.1456,
          .2166,
          0,
          -255,
          .6378,
          2.1456,
          .2166,
          0,
          -255,
          0,
          0,
          0,
          1,
          0,
        ]),
    );
    canvas.restore();
  }
}
