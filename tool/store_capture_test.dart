import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/renderer.dart';
import 'package:sketchora/screens/gallery_screen.dart';
import 'package:sketchora/screens/studio_screen.dart';
import 'package:sketchora/storage/sketch_store.dart';
import 'package:sketchora/theme.dart';

// Real Flutter UI captures with locally seeded, editable demonstration artwork.
// Run explicitly: flutter test tool/store_capture_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in [
      ('DMSans', 'assets/fonts/DMSans-Variable.ttf'),
      ('DMSerif', 'assets/fonts/DMSerifDisplay-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });
  testWidgets('capture Sketluma store screens', (tester) async {
    const size = Size(432, 768);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.binding.setSurfaceSize(size);
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('sketluma-store-'),
    ))!;
    late _CaptureStore store;
    final boundary = GlobalKey();
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/play-store/sketluma-v1/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    late SketchDocument painting;
    await tester.runAsync(() async {
      store = _CaptureStore(directory);
      for (final id in ['illustrated_0', 'illustrated_2']) {
        retainArtwork(id);
        await ensureArtworkLoaded(id);
        final regions = ArtCatalog.design(id).regions;
        final reference = await rootBundle.load(
          referenceAsset(ArtCatalog.entry(id)!),
        );
        final codec = await ui.instantiateImageCodec(
          reference.buffer.asUint8List(),
        );
        final referenceImage = (await codec.getNextFrame()).image;
        final rgba = (await referenceImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final colours = <String, int>{};
        for (final r in regions) {
          final bounds = r.path.getBounds();
          var point = bounds.center;
          if (!r.path.contains(point)) {
            search:
            for (var y = 1; y < 10; y++) {
              for (var x = 1; x < 10; x++) {
                final candidate = Offset(
                  bounds.left + bounds.width * x / 10,
                  bounds.top + bounds.height * y / 10,
                );
                if (r.path.contains(candidate)) {
                  point = candidate;
                  break search;
                }
              }
            }
          }
          final x = (point.dx / 1000 * referenceImage.width).floor().clamp(
            0,
            referenceImage.width - 1,
          );
          final y = (point.dy / 1000 * referenceImage.height).floor().clamp(
            0,
            referenceImage.height - 1,
          );
          final p = (y * referenceImage.width + x) * 4;
          colours[r.id] = rgba[p] + rgba[p + 1] + rgba[p + 2] < 150
              ? 0xFFEAC69D
              : Color.fromARGB(
                  255,
                  rgba[p],
                  rgba[p + 1],
                  rgba[p + 2],
                ).toARGB32();
        }
        referenceImage.dispose();
        codec.dispose();
        final doc = SketchDocument.create(
          title: ArtCatalog.entry(id)!.title,
          width: 2048,
          height: 2048,
          artworkId: id,
        ).copyWith(regionColors: {...colours});
        await store.save(doc);
        await store.saveThumbnail(doc.id, await renderPng(doc, maxSide: 640));
        if (id == 'illustrated_2') {
          painting = doc.copyWith(
            regionColors: {
              for (final r in regions.take(regions.length ~/ 2))
                r.id: colours[r.id]!,
            },
          );
        }
        releaseArtwork(id);
      }
    });
    Future<void> show(Widget child) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: sketchoraTheme(),
            home: child,
          ),
        ),
      );
      await settle();
    }

    await show(GalleryScreen(store: store));
    await tester.runAsync(() async {
      for (final doc in store.documents) {
        await precacheImage(
          FileImage(store.thumbnail(doc.id)),
          tester.element(find.byType(GalleryScreen)),
        );
      }
    });
    await settle();
    expect(find.text('Sketluma'), findsOneWidget);
    expect(find.text('Powered by EpitomeHub®'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await capture('screen-01-home');
    await tester.tap(find.text('Gallery'));
    await settle();
    await capture('screen-02-kids');
    await tester.tap(find.text('Advanced'));
    await tester.tap(find.text('Detailed'));
    await settle();
    await capture('screen-03-adults');
    retainArtwork(painting.artworkId);
    await tester.runAsync(() => ensureArtworkLoaded(painting.artworkId));
    await show(StudioScreen(document: painting, store: store));
    await capture('screen-04-colouring');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    releaseArtwork(painting.artworkId);
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}

class _CaptureStore extends SketchStore {
  _CaptureStore(super.directory);
  final documents = <SketchDocument>[];
  @override
  Future<void> save(SketchDocument document) async {
    documents.removeWhere((doc) => doc.id == document.id);
    documents.add(document);
    await super.save(document);
  }

  @override
  Future<SketchLoadResult> loadAll() async =>
      SketchLoadResult(documents.reversed.toList(), 0, 0);
}
