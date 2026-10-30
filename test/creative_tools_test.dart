import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/drawing/decoration.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/drawing_canvas.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/drawing/renderer.dart';
import 'package:sketchora/storage/sketch_store.dart';
import 'package:sketchora/storage/sticker_shelf.dart';
import 'package:sketchora/screens/studio_screen.dart';
import 'package:sketchora/coloring/library_screen.dart';
import 'package:sketchora/theme.dart';

CanvasDecoration object(String id, {int sticker = 0}) => CanvasDecoration(
  id: id,
  sticker: sticker,
  center: const Offset(200, 200),
  size: 200,
);
Future<String> photoFixture() async {
  final recorder = ui.PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 80, 40), Paint()..color = Colors.blue);
  final picture = recorder.endRecording(),
      image = await picture.toImage(80, 40);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final data = base64Encode(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('multiline text exports as three separated lines', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final doc = SketchDocument.create(width: 600, height: 600).copyWith(
        decorations: [
          CanvasDecoration(
            id: 'words',
            center: const Offset(300, 300),
            size: 500,
            text: 'one\ntwo\nthree',
          ),
        ],
      );
      final codec = await ui.instantiateImageCodec(
        await renderPng(doc, transparent: true),
      );
      final image = (await codec.getNextFrame()).image;
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      var bands = 0, previous = false;
      for (var y = 0; y < 600; y++) {
        var ink = false;
        for (var x = 0; x < 600; x++) {
          if (bytes[(y * 600 + x) * 4 + 3] > 128) {
            ink = true;
            break;
          }
        }
        if (ink && !previous) bands++;
        previous = ink;
      }
      expect(bands, 3);
      image.dispose();
      codec.dispose();
    });
  });
  test(
    'objects preserve undo, ordering, photo settings and old document versions',
    () {
      final old = SketchDocument.create(width: 400, height: 400);
      expect(SketchDocument.fromJson(old.toJson()).decorations, isEmpty);
      final editor = DrawingEditor(old);
      editor.putDecoration(object('a'));
      editor.putDecoration(object('b', sticker: 1));
      editor.putDecoration(
        editor.document.decorations.first.copyWith(
          size: 180,
          rotation: .6,
          opacity: .7,
          flipped: true,
          text: 'Hello',
          textStyle: 1,
        ),
      );
      editor.orderDecoration('a', front: true);
      expect(editor.document.decorations.last.id, 'a');
      editor.undo();
      expect(editor.document.decorations.first.id, 'a');
      editor.redo();
      expect(editor.document.decorations.last.id, 'a');
      final reopened = SketchDocument.fromJson(
        jsonDecode(jsonEncode(editor.document.toJson()))
            as Map<String, dynamic>,
      );
      expect(reopened.toJson()['version'], 3);
      expect(reopened.decorations.last.text, 'Hello');
      expect(reopened.decorations.last.flipped, true);
      editor.removeDecoration('a');
      editor.undo();
      expect(editor.document.decorations.length, 2);
      expect(
        () => object('x').copyWith(size: double.nan),
        throwsFormatException,
      );
      expect(
        () => old.copyWith(decorations: [object('same'), object('same')]),
        throwsFormatException,
      );
      editor.dispose();
    },
  );

  testWidgets(
    'photo cut-outs stay transparent and brush strokes paint above background photos',
    (tester) async {
      await tester.runAsync(() async {
        final data = await photoFixture();
        final photo = CanvasDecoration(
          id: 'photo',
          center: const Offset(200, 200),
          size: 300,
          imageData: data,
          crop: 1,
          behindInk: true,
        );
        final doc = SketchDocument.create(
          width: 400,
          height: 400,
        ).copyWith(decorations: [photo]);
        final editor = DrawingEditor(doc);
        editor.addStroke(
          InkStroke(
            points: [
              const InkPoint(Offset(130, 200)),
              const InkPoint(Offset(270, 200)),
            ],
            color: 0xFFFF0000,
            width: 30,
            opacity: 1,
            brush: BrushKind.pen,
          ),
        );
        final png = await renderPng(editor.document, transparent: true);
        final codec = await ui.instantiateImageCodec(png),
            image = (await codec.getNextFrame()).image;
        final pixels = (await image.toByteData())!.buffer.asUint8List();
        int offset(int x, int y) => (y * 400 + x) * 4;
        expect(pixels[offset(200, 200)], greaterThan(240));
        expect(pixels[offset(200, 200) + 2], lessThan(15));
        expect(pixels[offset(70, 70) + 3], 0);
        expect(pixels[offset(200, 120) + 2], greaterThan(200));
        image.dispose();
        codec.dispose();
        editor.dispose();
        final decoded = SketchDocument.fromJson(doc.toJson());
        expect(decoded.decorations.single.imageData, data);
        expect(decoded.decorations.single.behindInk, true);
      });
    },
  );
  testWidgets(
    'large PNG imports resize automatically instead of being rejected',
    (tester) async {
      await tester.runAsync(() async {
        final original = await File(
          'assets/artwork/coastal-cafe-reference-v1.png',
        ).readAsBytes();
        expect(original.length, greaterThan(1600000));
        final resized = await DecorationPhotos.normalize(original);
        expect(resized.length, lessThanOrEqualTo(1600000));
        final codec = await ui.instantiateImageCodec(resized),
            image = (await codec.getNextFrame()).image;
        expect(image.width, lessThanOrEqualTo(768));
        expect(image.height, lessThanOrEqualTo(768));
        image.dispose();
        codec.dispose();
      });
    },
  );

  testWidgets(
    'saved custom stickers and decorated sketches survive disk reopen',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp(
          'sketluma-sticker-shelf-',
        );
        final shelf = StickerShelf(dir), store = SketchStore(dir);
        final photo = CanvasDecoration(
          id: 'photo',
          center: const Offset(200, 200),
          imageData: await photoFixture(),
          crop: 2,
          cropZoom: 1.4,
          cropX: .5,
          frame: true,
          behindInk: true,
        );
        await shelf.save(photo);
        final saved = (await shelf.load()).single;
        expect(saved.crop, 2);
        expect(saved.cropZoom, 1.4);
        expect(saved.behindInk, false);
        final doc = SketchDocument.create(width: 400, height: 400).copyWith(
          decorations: [
            photo,
            object('text').copyWith(text: 'Made by me'),
          ],
        );
        await store.save(doc);
        expect((await store.loadAll()).documents.single.decorations.length, 2);
        await shelf.delete(saved.id);
        expect(await shelf.load(), isEmpty);
        expect(
          (await store.loadAll()).documents.single.decorations.first.imageData,
          photo.imageData,
        );
        await dir.delete(recursive: true);
      });
    },
  );

  testWidgets(
    'dragging a selected sticker commits one undo and no ink stroke',
    (tester) async {
      final editor = DrawingEditor(
        SketchDocument.create(width: 400, height: 400).copyWith(
          decorations: [
            object('drag'),
            object('back').copyWith(behindInk: true, size: 300),
          ],
        ),
      );
      final controller = DrawingCanvasController();
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: DrawingCanvas(
                editor: editor,
                controller: controller,
                brush: BrushKind.pen,
                color: Colors.black,
                width: 8,
                opacity: 1,
                handMode: false,
                objectMode: true,
                selectedDecorationId: 'drag',
                onSelectDecoration: (id) => selected = id,
              ),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(DrawingCanvas), const Offset(50, 20));
      await tester.pump();
      expect(selected, 'drag');
      expect(editor.document.decorations.first.center.dx, greaterThan(240));
      expect(editor.document.strokeCount, 0);
      editor.undo();
      expect(editor.document.decorations.first.center, const Offset(200, 200));
      expect(editor.canUndo, false);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      editor.dispose();
    },
  );

  testWidgets(
    'sticker picker, transformation sheet, duplication and save are accessible',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('sketluma-creative-ui-'),
      ))!;
      final doc = SketchDocument.create(width: 400, height: 400);
      final store = _CreativeMemoryStore(dir);
      await tester.pumpWidget(
        MaterialApp(
          theme: sketchoraTheme(),
          home: StudioScreen(
            document: doc,
            store: store,
            completionAudio: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add something creative'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add stickers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Heart'));
      await tester.pumpAndSettle();
      expect(find.text('Drag to move'), findsOneWidget);
      await tester.tap(find.text('Edit object'));
      await tester.pumpAndSettle();
      expect(find.text('Rotation'), findsOneWidget);
      await tester.ensureVisible(find.text('Apply changes'));
      await tester.tap(find.text('Apply changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      final current = tester
          .widget<DrawingCanvas>(find.byType(DrawingCanvas))
          .editor
          .document;
      expect(current.decorations.length, 2);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      expect(store.saved?.decorations.length, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => dir.delete(recursive: true));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all designs starts unfiltered and scrolling loads beyond the first thirty',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('sketluma-all-pages-'),
      ))!;
      await tester.pumpWidget(
        MaterialApp(
          theme: sketchoraTheme(),
          home: ArtLibraryScreen(store: SketchStore(dir)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3094 designs · choose your favourite'), findsOneWidget);
      final scroll = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      final initialExtent = scroll.controller!.position.maxScrollExtent;
      scroll.controller!.jumpTo(initialExtent);
      await tester.pumpAndSettle();
      expect(
        scroll.controller!.position.maxScrollExtent,
        greaterThan(initialExtent),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => dir.delete(recursive: true));
    },
  );
  testWidgets(
    'render original sticker kit and photo/text composition for visual QA',
    (tester) async {
      await tester.runAsync(() async {
        final fonts = FontLoader('DMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'));
        await fonts.load();
        final serif = FontLoader('DMSerif')
          ..addFont(rootBundle.load('assets/fonts/DMSerifDisplay-Regular.ttf'));
        await serif.load();
        await Directory('output/creative-qa').create(recursive: true);
        final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xFFF9F6F0), BlendMode.src);
        for (var i = 0; i < stickerNames.length; i++) {
          final x = (i % 6) * 200.0, y = (i ~/ 6) * 220.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 8, y + 8, 184, 204),
              const Radius.circular(24),
            ),
            Paint()..color = Colors.white,
          );
          paintDecoration(
            canvas,
            CanvasDecoration(
              id: 'preview',
              sticker: i,
              center: Offset(x + 100, y + 91),
              size: 140,
              color: [0xFF8050EF, 0xFFFF786B, 0xFFE4A950, 0xFF559D88][i % 4],
            ),
          );
          final text = TextPainter(
            text: TextSpan(
              text: stickerNames[i],
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 18,
                color: Color(0xFF292034),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 180);
          text.paint(canvas, Offset(x + 100 - text.width / 2, y + 175));
          text.dispose();
        }
        final picture = recorder.endRecording(),
            image = await picture.toImage(1200, 880);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('output/creative-qa/sticker-kit.png')
            .writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        final reference = await rootBundle.load(
          'assets/artwork/coastal-cafe-reference-v1.webp',
        );
        final doc = SketchDocument.create(width: 800, height: 1000).copyWith(
          decorations: [
            CanvasDecoration(
              id: 'photo',
              imageData: base64Encode(reference.buffer.asUint8List()),
              center: const Offset(400, 560),
              size: 630,
              crop: 2,
              frame: true,
              color: 0xFFB6A3CF,
              behindInk: true,
            ),
            CanvasDecoration(
              id: 'text',
              text: 'Create something yours',
              textStyle: 1,
              center: const Offset(400, 140),
              size: 300,
              color: 0xFF292034,
            ),
            CanvasDecoration(
              id: 'bloom',
              sticker: 0,
              center: const Offset(120, 300),
              size: 150,
              color: 0xFFFF786B,
              rotation: -.2,
            ),
            CanvasDecoration(
              id: 'butterfly',
              sticker: 4,
              center: const Offset(680, 830),
              size: 180,
              color: 0xFF8050EF,
              rotation: .25,
            ),
          ],
        );
        await File('output/creative-qa/composition.png')
            .writeAsBytes(await renderPng(doc));
      });
    },
  );
}

class _CreativeMemoryStore extends SketchStore {
  SketchDocument? saved;
  _CreativeMemoryStore(super.directory);
  @override
  Future<void> save(SketchDocument document) async {
    saved = document;
  }
}
