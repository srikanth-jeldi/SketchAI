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
    ? 'assets/artwork/${illustratedFiles[entry.variation]}-outline-v1.webp'
    : 'assets/artwork/${_premiumFiles[entry.variation]}-v1.webp';
String referenceAsset(ArtEntry entry) => entry.illustrated
    ? 'assets/artwork/${illustratedFiles[entry.variation]}-reference-v1.webp'
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
    // Original component IDs remain stable across display-image compression.
    final packed = await rootBundle.load(
      outlineAsset(entry).replaceAll('.webp', '.mask'),
    );
    final raw = Uint8List.fromList(zlib.decode(packed.buffer.asUint8List()));
    final data = ByteData.sublistView(raw);
    final runs = Int32List((raw.length - 8) ~/ 4);
    for (var i = 0; i < runs.length; i++) {
      runs[i] = data.getInt32(8 + i * 4, Endian.little);
    }
    final mask = <String, Object>{
      'w': data.getUint32(0, Endian.little),
      'h': data.getUint32(4, Endian.little),
      'runs': runs,
    };
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
