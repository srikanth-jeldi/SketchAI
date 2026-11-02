import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/drawing/decoration.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/sticker_library.dart';
import 'package:sketchora/screens/sticker_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('append-only IDs round trip and each category has 90 editions', () {
    expect(stickerNames.length, 1104);
    expect(stickerBrowseOrder.toSet().length, 1104);
    expect(stickerBrowseOrder.sublist(24, 84), [
      for (var motif = 0; motif < 60; motif++) 24 + motif * 18,
    ]);
    expect(stickerNames.toSet().length, 1104);
    expect(stickerNames[0], 'Bloom');
    expect(stickerNames[23], 'Bow');
    for (final topic in stickerTopics) {
      expect(
        List.generate(
          1104,
          (i) => i,
        ).where((i) => stickerTopic(i) == topic).length,
        90,
      );
    }
    final items = [
      for (var i = 0; i < 1104; i++)
        CanvasDecoration(
          id: 'sticker-$i',
          sticker: i,
          center: const Offset(150, 150),
        ),
    ];
    // Documents intentionally cap canvas object count at 100; check every ID
    // individually so the catalogue test does not bypass that safety limit.
    for (final item in items) {
      final doc = SketchDocument.create(
        width: 300,
        height: 300,
      ).copyWith(decorations: [item]);
      expect(
        SketchDocument.fromJson(doc.toJson()).decorations.single.sticker,
        item.sticker,
      );
    }
  });
  testWidgets(
    'every sticker renders nonempty, distinct and within object bounds',
    (tester) async {
      await tester.runAsync(() async {
        final hashes = <int>{};
        for (var id = 24; id < 1104; id++) {
          final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
          paintDecoration(
            canvas,
            CanvasDecoration(
              id: 'render',
              sticker: id,
              center: const Offset(40, 40),
              size: 64,
            ),
          );
          final picture = recorder.endRecording(),
              image = await picture.toImage(80, 80);
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          var filled = 0, hash = 2166136261;
          for (var p = 0; p < data.length; p += 4) {
            if (data[p + 3] > 0) {
              filled++;
              final x = (p ~/ 4) % 80, y = (p ~/ 4) ~/ 80;
              expect(
                x,
                inInclusiveRange(7, 72),
                reason: 'Sticker $id overflows horizontally',
              );
              expect(
                y,
                inInclusiveRange(7, 72),
                reason: 'Sticker $id overflows vertically',
              );
            }
            for (var c = 0; c < 4; c++) {
              hash = ((hash ^ data[p + c]) * 16777619) & 0xFFFFFFFF;
            }
          }
          expect(filled, greaterThan(60), reason: stickerNames[id]);
          expect(
            hashes.add(hash),
            isTrue,
            reason: 'Duplicate raster: ${stickerNames[id]}',
          );
          image.dispose();
          picture.dispose();
        }
        // A zero-opacity object must leave no coloured frame/background pixels.
        final recorder = ui.PictureRecorder();
        paintDecoration(
          Canvas(recorder),
          CanvasDecoration(
            id: 'hidden',
            sticker: 24 + 17,
            center: const Offset(40, 40),
            size: 64,
            opacity: 0,
          ),
        );
        final picture = recorder.endRecording(),
            image = await picture.toImage(80, 80);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        expect(
          [for (var p = 3; p < bytes.length; p += 4) bytes[p]]
              .every((a) => a == 0),
          isTrue,
        );
        image.dispose();
        picture.dispose();
      });
    },
  );
  testWidgets(
    'search finds last item, recolours selection and clears no-results',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      int? selected;
      Color? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickerPicker(
              initialColor: Colors.purple,
              onSelect: (id, color) {
                selected = id;
                chosen = color;
              },
              onMyStickers: () {},
            ),
          ),
        ),
      );
      expect(find.text('1104 results'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Pinwheel Night sky');
      await tester.pump();
      expect(find.text('1 results'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no-such-sticker');
      await tester.pump();
      expect(find.text('No matching stickers'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Pinwheel');
      await tester.pump();
      expect(find.text('18 results'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Sticker colour 2'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Pinwheel · Night sky'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Pinwheel · Night sky'));
      await tester.pump();
      expect(selected, 1103);
      expect(chosen, const Color(0xFFFF786B));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 10,
              height: 10,
              child: CustomPaint(
                painter: StickerPreview(
                  CanvasDecoration(
                    id: 'tiny',
                    sticker: 1103,
                    center: Offset.zero,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'render all 60 motifs and representative compositions for visual QA',
    (tester) async {
      await tester.runAsync(() async {
        final fonts = FontLoader('DMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'));
        await fonts.load();
        final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xFFF9F6F0), BlendMode.src);
        final ids = [
          for (var motif = 0; motif < 60; motif++) 24 + motif * 18,
          for (var edition = 0; edition < 18; edition++) 24 + edition,
        ];
        for (var tile = 0; tile < ids.length; tile++) {
          final x = (tile % 10) * 120.0, y = (tile ~/ 10) * 130.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 4, y + 4, 112, 122),
              const Radius.circular(12),
            ),
            Paint()..color = Colors.white,
          );
          paintDecoration(
            canvas,
            CanvasDecoration(
              id: 'atlas',
              sticker: ids[tile],
              center: Offset(x + 60, y + 56),
              size: 85,
              color: [0xFF8050EF, 0xFFFF786B, 0xFF279C84, 0xFF4F8BC9][tile % 4],
            ),
          );
          final text = TextPainter(
            text: TextSpan(
              text: stickerNames[ids[tile]],
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10,
                color: Colors.black,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 106);
          text.paint(canvas, Offset(x + 7, y + 104));
          text.dispose();
        }
        final picture = recorder.endRecording(),
            image = await picture.toImage(1200, 1040);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('output/creative-qa').create(recursive: true);
        await File('output/creative-qa/sticker-library-090.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      });
    },
  );
}
