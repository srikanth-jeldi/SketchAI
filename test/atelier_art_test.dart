import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/drawing/renderer.dart';

String geometry(ArtDesign art) => [
  for (final r in art.regions)
    for (final m in r.path.computeMetrics())
      '${m.length.toStringAsFixed(3)}:${m.getTangentForOffset(m.length * .37)?.position}',
].join('|');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('1,094 gallery pages include 1,080 stable geometry editions', () {
    final gallery = {
      for (final e in [
        ...kidsEntries,
        ...intermediateEntries,
        ...advancedEntries,
      ])
        e.id: e,
    }.values.toList();
    expect(gallery.length, 1094);
    expect(gallery.map((e) => e.id).toSet().length, 1094);
    expect(
      {
        ...gallery.map((e) => e.id),
        ...ArtCatalog.entries.map((e) => e.id),
      }.length,
      3094,
    );
    expect(kidsEntries.length, 364);
    expect(intermediateEntries.length, 724);
    expect(allVisibleEntries.length, 3094);
    expect(allVisibleEntries.map((e) => e.id).toSet().length, 3094);
    for (final category in [
      'Botanical',
      'Wildlife',
      'Travel',
      'Gardens',
      'Still life',
    ]) {
      for (final level in ['Easy', 'Medium', 'Detailed']) {
        expect(
          atelierEntries.where(
            (e) => e.category == category && e.difficulty == level,
          ),
          isNotEmpty,
          reason: '$category / $level',
        );
      }
    }
    expect(advancedEntries.length, 366);
    final fingerprints = <String>{};
    final counts = [0, 0, 0];
    for (final e in atelierEntries) {
      final art = ArtCatalog.design(e.id);
      expect(ArtCatalog.entry(e.id)?.id, e.id);
      expect(art.regions.length, greaterThan(15), reason: e.id);
      expect(art.regions.map((r) => r.id).toSet().length, art.regions.length);
      for (final r in art.regions) {
        final b = r.path.getBounds();
        expect(b.isEmpty, false, reason: '${e.id}/${r.id}');
        expect(b.left, greaterThanOrEqualTo(59.9));
        expect(b.top, greaterThanOrEqualTo(59.9));
        expect(b.right, lessThanOrEqualTo(940.1));
        expect(b.bottom, lessThanOrEqualTo(940.1));
        expect(r.path.computeMetrics().every((m) => m.isClosed), true);
      }
      expect(fingerprints.add(geometry(art)), true, reason: e.id);
      counts[e.atelierLevel] += art.regions.length;
    }
    expect(counts[1], greaterThan(counts[0]));
    expect(counts[2], greaterThan(counts[1]));
    final before = geometry(ArtCatalog.design('atelier_17'));
    for (var i = 100; i < 150; i++) {
      ArtCatalog.design('atelier_$i');
    }
    expect(geometry(ArtCatalog.design('atelier_17')), before);
    expect(ArtCatalog.entry('atelier_1080'), isNull);
    expect(ArtCatalog.entry('art_9_199')?.id, 'art_9_199');
  });

  testWidgets('every scene topic and level can fill, undo, save and export', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (var topic = 0; topic < 12; topic++) {
        for (var level = 0; level < 3; level++) {
          final id = 'atelier_${topic * 30 + level * 10 + 3}';
          final art = ArtCatalog.design(id);
          final editor = DrawingEditor(
            SketchDocument.create(width: 2048, height: 2048, artworkId: id),
          );
          // Find an actually visible/tappable region rather than a covered seed.
          ArtRegion? selected;
          for (var y = 100.0; y < 900 && selected == null; y += 40) {
            for (var x = 100.0; x < 900 && selected == null; x += 40) {
              selected = art.regionAt(Offset(x, y));
            }
          }
          expect(selected, isNotNull, reason: id);
          editor.fillRegion(selected!.id, 0xFFEAA4B3);
          expect(editor.canUndo, true);
          editor.undo();
          expect(editor.document.regionColors, isEmpty);
          editor.redo();
          final saved = SketchDocument.fromJson(editor.document.toJson());
          expect(saved.regionColors[selected.id], 0xFFEAA4B3);
          final png = await renderPng(
            saved,
            maxSide: topic == 0 && level == 2 ? 2048 : 256,
          );
          final codec = await ui.instantiateImageCodec(png);
          final image = (await codec.getNextFrame()).image;
          expect(image.width, topic == 0 && level == 2 ? 2048 : 256);
          codec.dispose();
          image.dispose();
          editor.dispose();
        }
      }
    });
  });

  testWidgets('render editorial sheets for all compositions and levels', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await Directory('output/atelier-qa').create(recursive: true);
      for (var layout = 0; layout < 3; layout++) {
        for (var level = 0; level < 3; level++) {
          final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
          canvas.drawColor(Colors.white, BlendMode.src);
          for (var topic = 0; topic < 12; topic++) {
            final e =
                atelierEntries[layout * 360 + topic * 30 + level * 10 + 3];
            canvas.save();
            canvas.translate((topic % 4) * 400.0, (topic ~/ 4) * 430.0);
            canvas.save();
            canvas.scale(.4);
            paintArt(canvas, ArtCatalog.design(e.id), sample: true);
            canvas.restore();
            final label = TextPainter(
              textDirection: TextDirection.ltr,
              text: TextSpan(
                text: e.title,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            )..layout(maxWidth: 390);
            label.paint(canvas, const Offset(10, 405));
            label.dispose();
            canvas.restore();
          }
          final picture = recorder.endRecording(),
              image = await picture.toImage(1600, 1290);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('output/atelier-qa/layout-$layout-level-$level.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
        }
      }
    });
  });
}
