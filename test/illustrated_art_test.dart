import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/drawing/renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'all eight bundled illustrations load, fill, persist, export and release',
    (tester) async {
      await tester.runAsync(() async {
        expect(illustratedEntries.length, 8);
        for (final e in illustratedEntries) {
          retainArtwork(e.id);
          await ensureArtworkLoaded(e.id);
          final art = ArtCatalog.design(e.id);
          expect(art.regions.length, greaterThan(20));
          final editor = DrawingEditor(
            SketchDocument.create(width: 2048, height: 2048, artworkId: e.id),
          );
          editor.fillRegion(art.regions.first.id, 0xFFF3A455);
          final reopened = SketchDocument.fromJson(editor.document.toJson());
          expect(reopened.regionColors, editor.document.regionColors);
          final png = await renderPng(reopened);
          final codec = await ui.instantiateImageCodec(png);
          final image = (await codec.getNextFrame()).image;
          expect(image.width, 2048);
          expect(image.height, 2048);
          image.dispose();
          codec.dispose();
          editor.dispose();
          releaseArtwork(e.id);
          expect(premiumDesigns.containsKey(e.id), isFalse);
        }
      });
    },
  );
}
