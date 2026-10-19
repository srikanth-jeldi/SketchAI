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
final _referenceImages = <String, ui.Image>{};
final _rasterLoads = <String, Future<void>>{};
final _rasterPins = <String, int>{};
Future<void> _rasterQueue = Future.value();

/// Decode approved sheets once. Regions come from the actual outline pixels,
/// never the independently painted colour reference.
Future<void> loadPremiumArt() =>
    Future.wait(premiumEntries.map((e) => ensureArtworkLoaded(e.id)))
        .then((_) {});

void retainArtwork(String? id) {
  if (id != null && ArtCatalog.entry(id)?.raster == true) {
    _rasterPins[id] = (_rasterPins[id] ?? 0) + 1;
  }
}

void releaseArtwork(String? id) {
  if (id == null) return;
  final pins = (_rasterPins[id] ?? 0) - 1;
  if (pins <= 0) {
    _rasterPins.remove(id);
  } else {
    _rasterPins[id] = pins;
  }
  clearUnusedArtwork();
}

void clearUnusedArtwork() {
  for (final id in _premiumImages.keys.toList()) {
    if ((_rasterPins[id] ?? 0) > 0) continue;
    _premiumImages.remove(id)?.dispose();
    _referenceImages.remove(id)?.dispose();
    premiumDesigns.remove(id);
  }
}

Future<void> ensureArtworkLoaded(String? id) {
  if (id == null ||
      ArtCatalog.entry(id)?.raster != true ||
      premiumDesigns.containsKey(id)) {
    return Future.value();
  }
  return _rasterLoads.putIfAbsent(id, () {
    final next = _rasterQueue.then((_) => _loadRaster(id));
    _rasterQueue = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next.whenComplete(() {
      _rasterLoads.remove(id);
    });
  });
}

String outlineAsset(ArtEntry entry) => entry.illustrated
    ? 'assets/artwork/${illustratedFiles[entry.variation]}-outline-v1.png'
    : 'assets/artwork/${_premiumFiles[entry.variation]}-v1.png';
String referenceAsset(ArtEntry entry) => entry.illustrated
    ? 'assets/artwork/${illustratedFiles[entry.variation]}-reference-v1.png'
    : outlineAsset(entry);

Future<void> _loadRaster(String id) async {
  final entry = ArtCatalog.entry(id)!;
  final bytes = await rootBundle.load(outlineAsset(entry));
  final codec = await ui.instantiateImageCodec(
    bytes.buffer.asUint8List(),
    targetWidth: entry.illustrated ? 1024 : null,
  );
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final mask = await compute(_outlineRuns, (
      data,
      image.width,
      image.height,
      entry.illustrated,
    ));
    final regions = _regionsFromRuns(mask, square: entry.illustrated);
    if (entry.illustrated) {
      final reference = await rootBundle.load(referenceAsset(entry));
      final referenceCodec = await ui.instantiateImageCodec(
        reference.buffer.asUint8List(),
        targetWidth: 512,
      );
      _referenceImages[id] = (await referenceCodec.getNextFrame()).image;
      referenceCodec.dispose();
    }
    _premiumImages[entry.id] = image;
    premiumDesigns[entry.id] = ArtDesign(entry, regions, const []);
  } catch (_) {
    image.dispose();
    _referenceImages.remove(id)?.dispose();
    rethrow;
  }
}

Map<String, Object> _outlineRuns((Uint8List, int, int, bool) input) {
  final (rgba, width, height, square) = input;
  // Half-resolution hit masks keep touch detection and retained paths bounded.
  // A dark source pixel blocks its cell, preserving fine walls conservatively.
  final w = width ~/ (square ? 2 : 4), h = height ~/ 2;
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
  final runs = <int>[];
  for (var y = 0; y < h; y++) {
    var x = 0;
    while (x < w) {
      final id = labels[y * w + x], start = x++;
      while (x < w && labels[y * w + x] == id) {
        x++;
      }
      if (id > 0) {
        runs.addAll([id, start, y, x - start]);
      }
    }
  }
  return {'w': w, 'h': h, 'runs': Int32List.fromList(runs)};
}

List<ArtRegion> _regionsFromRuns(
  Map<String, Object> mask, {
  required bool square,
}) {
  final w = mask['w']! as int,
      h = mask['h']! as int,
      runs = mask['runs']! as Int32List;
  final paths = <int, Path>{};
  final sx = (square ? 1000 : 750) / w,
      sy = 1000 / h,
      left = square ? 0.0 : 125.0;
  for (var i = 0; i < runs.length; i += 4) {
    (paths[runs[i]] ??= Path()).addRect(
      Rect.fromLTWH(
        left + runs[i + 1] * sx,
        runs[i + 2] * sy,
        runs[i + 3] * sx,
        sy,
      ),
    );
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
  final square = art.entry.illustrated;
  final destination = Rect.fromLTWH(
    square ? 0 : 125,
    0,
    square ? 1000 : 750,
    1000,
  );
  if (sample) {
    canvas.drawImageRect(
      square ? _referenceImages[art.entry.id]! : image,
      Rect.fromLTWH(
        square ? 0 : image.width / 2,
        0,
        square
            ? _referenceImages[art.entry.id]!.width.toDouble()
            : image.width / 2,
        square
            ? _referenceImages[art.entry.id]!.height.toDouble()
            : image.height.toDouble(),
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
      Rect.fromLTWH(
        0,
        0,
        square ? image.width.toDouble() : image.width / 2,
        image.height.toDouble(),
      ),
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
