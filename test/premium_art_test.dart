import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sketchora/coloring/art_catalog.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/drawing/renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'simple adult masters offer broad areas, stable saves and a preview',
    (tester) async {
      await tester.runAsync(() async {
        expect(kidsEntries.length, 34);
        expect(kidsEntries.where((e) => e.difficulty == 'Easy'), isNotEmpty);
        expect(adultEntries.where((e) => e.difficulty == 'Easy').length, 2);
        expect(adultEntries.where((e) => e.difficulty == 'Medium').length, 2);
        expect(adultEntries.where((e) => e.difficulty == 'Detailed').length, 6);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)
          ..drawColor(const Color(0xFFFFFFFF), ui.BlendMode.src);
        for (final e in simpleAdultEntries) {
          final art = ArtCatalog.design(e.id);
          expect(ArtCatalog.entry(e.id)?.id, e.id);
          expect(art.regions.length, lessThan(25));
          final editor = DrawingEditor(SketchDocument.create(artworkId: e.id));
          editor.fillRegion(art.regions.last.id, 0xFF8050EF);
          expect(
            SketchDocument.fromJson(editor.document.toJson()).regionColors,
            editor.document.regionColors,
          );
          editor.dispose();
          canvas.save();
          canvas.translate(
            (e.variation % 3) * 500.0,
            (e.variation ~/ 3) * 500.0,
          );
          canvas.scale(.5);
          paintArt(canvas, art, sample: true);
          canvas.restore();
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(1500, 1000);
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
        await Directory('output/previews').create(recursive: true);
        await File('output/previews/simple-adult-designs.png')
            .writeAsBytes(png);
        image.dispose();
        picture.dispose();
      });
    },
  );
  testWidgets(
    'botanical fills cover bright artwork pixels without white stripe gaps',
    (tester) async {
      await tester.runAsync(() async {
        await loadPremiumArt();
        final art = ArtCatalog.design('premium_0');
        final doc =
            SketchDocument.create(
              width: 2048,
              height: 2048,
              artworkId: art.entry.id,
            ).copyWith(
              regionColors: {for (final r in art.regions) r.id: 0xFFFF786B},
            );
        final codec = await ui.instantiateImageCodec(await renderPng(doc));
        final image = (await codec.getNextFrame()).image;
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final bytes = await rootBundle.load(
          'assets/artwork/01-botanical-v1.webp',
        );
        final sourceCodec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final source = (await sourceCodec.getNextFrame()).image;
        final raw = (await source.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        var bright = 0, filled = 0;
        for (var y = 20; y < source.height - 20; y += 4) {
          for (var x = 20; x < source.width ~/ 2 - 20; x += 4) {
            final p = (y * source.width + x) * 4;
            if (raw[p] + raw[p + 1] + raw[p + 2] < 720) continue;
            bright++;
            final dx = ((125 + x / (source.width / 2) * 750) * 2.048).floor();
            final dy = (y / source.height * 2048).floor();
            final q = (dy * 2048 + dx) * 4;
            if (pixels[q] > pixels[q + 1] + 25) filled++;
          }
        }
        expect(filled / bright, greaterThan(.95));
        image.dispose();
        codec.dispose();
        source.dispose();
        sourceCodec.dispose();
      });
    },
  );
  testWidgets(
    'six approved pages have selectable regions, persistence and 2K rendering',
    (tester) async {
      await tester.runAsync(() async {
        await loadPremiumArt();
        for (final entry in premiumEntries) {
          final art = ArtCatalog.design(entry.id);
          final blankCodec = await ui.instantiateImageCodec(
            await renderPng(
              SketchDocument.create(
                width: 1000,
                height: 1000,
                artworkId: entry.id,
              ),
            ),
          );
          final blankImage = (await blankCodec.getNextFrame()).image;
          final blankPixels = (await blankImage.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
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
              if (region.path.contains(Offset(x, y)) &&
                  blankPixels[(y.toInt() * 1000 + x.toInt()) * 4] > 240) {
                point = Offset(x, y);
                break;
              }
            }
          }
          expect(point, isNotNull);
          blankImage.dispose();
          blankCodec.dispose();
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
          var visibleFill = false;
          for (var i = 0; i < pixels.length; i += 4) {
            if (pixels[i] > pixels[i + 1] + 25) {
              visibleFill = true;
              break;
            }
          }
          expect(visibleFill, isTrue);
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
