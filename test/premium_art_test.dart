import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/drawing/renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'six approved pages have selectable regions, persistence and 2K rendering',
    (tester) async {
      await tester.runAsync(() async {
        await loadPremiumArt();
        for (final entry in premiumEntries) {
          final art = ArtCatalog.design(entry.id);
          expect(art.regions.length, greaterThan(25));
          final region = art.regions.reduce(
            (a, b) =>
                a.path.getBounds().size.longestSide >
                    b.path.getBounds().size.longestSide
                ? a
                : b,
          );
          Offset? point;
          for (var y = 1.0; y < 1000 && point == null; y += 1) {
            for (var x = 126.0; x < 875; x += 1) {
              if (region.path.contains(Offset(x, y))) {
                point = Offset(x, y);
                break;
              }
            }
          }
          expect(point, isNotNull);
          expect(art.regionAt(point!)?.id, region.id);
          final editor = DrawingEditor(
            SketchDocument.create(
              width: 2048,
              height: 2048,
              artworkId: entry.id,
            ),
          );
          editor.fillRegion(region.id, 0xFFFF786B);
          expect(editor.document.regionColors[region.id], 0xFFFF786B);
          final reopened = SketchDocument.fromJson(editor.document.toJson());
          expect(reopened.artworkId, entry.id);
          expect(reopened.regionColors[region.id], 0xFFFF786B);
          editor.undo();
          expect(editor.document.regionColors, isEmpty);
          editor.redo();
          final png = await renderPng(editor.document);
          final codec = await ui.instantiateImageCodec(png);
          final image = (await codec.getNextFrame()).image;
          expect(image.width, 2048);
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          final offset =
              ((point.dy * 2.048).floor() * 2048 + (point.dx * 2.048).floor()) *
              4;
          expect(pixels[offset], greaterThan(pixels[offset + 1]));
          await Directory('output/previews').create(recursive: true);
          await File('output/previews/${entry.id}-filled.png')
              .writeAsBytes(png);
          image.dispose();
          codec.dispose();
          editor.dispose();
          // ignore: avoid_print
          print('${entry.title}: ${art.regions.length} fill areas');
        }
      });
    },
  );
}
