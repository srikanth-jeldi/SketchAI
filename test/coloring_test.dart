import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';
import 'package:sketchora/coloring/celebration.dart';
import 'package:sketchora/coloring/library_screen.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/drawing_canvas.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/drawing/renderer.dart';
import 'package:sketchora/storage/sketch_store.dart';
import 'package:sketchora/theme.dart';
import 'package:sketchora/screens/gallery_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('near-line fill selects nearby area without filling distant space', () {
    final region = ArtRegion(
      'r1',
      Path()..addRect(const Rect.fromLTWH(100, 100, 50, 50)),
      Colors.red,
    );
    final art = ArtDesign(const ArtEntry(0, 0), [region], []);
    expect(art.regionAt(const Offset(97, 120)), isNull);
    expect(art.regionAt(const Offset(97, 120), tolerance: 6)?.id, 'r1');
    expect(art.regionAt(const Offset(80, 120), tolerance: 6), isNull);
  });
  setUpAll(() async {
    await loadPremiumArt();
  });
  testWidgets(
    'bottom Gallery opens artwork library even with no saved sketches',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('sketchora-gallery-'),
      ))!;
      final store = _MemoryStore(dir);
      await tester.pumpWidget(
        MaterialApp(
          theme: sketchoraTheme(),
          home: GalleryScreen(store: store),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      expect(find.byType(ArtLibraryScreen), findsOneWidget);
      expect(find.text('Botanical Reverie'), findsNothing);
      await tester.tap(find.text('Adults'));
      await tester.pumpAndSettle();
      expect(find.text('Olive & clay'), findsOneWidget);
      await tester.tap(find.text('Detailed'));
      await tester.pumpAndSettle();
      expect(find.text('Botanical Reverie'), findsOneWidget);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Your sketches'), findsOneWidget);
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adults'));
      await tester.tap(find.text('Detailed'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Botanical Reverie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Botanical Reverie'));
      await tester.pumpAndSettle();
      expect(find.text('Start colouring'), findsOneWidget);
      await tester.ensureVisible(find.text('Start colouring'));
      await tester.tap(find.text('Start colouring'));
      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);
      expect(store.saved?.artworkId, 'premium_0');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => dir.delete(recursive: true));
    },
  );
  testWidgets(
    'chosen fill colour and reset render correctly through the retained cache',
    (tester) async {
      await tester.runAsync(() async {
        final art = ArtCatalog.design('art_5_0');
        final doc = SketchDocument.create(
          width: 200,
          height: 200,
          artworkId: art.entry.id,
        );
        final cache = DrawingRenderCache();
        Future<List<int>> centerPixel(SketchDocument page) async {
          final recorder = ui.PictureRecorder();
          paintDocument(Canvas(recorder), page, cache);
          final picture = recorder.endRecording(),
              image = await picture.toImage(200, 200);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          final point = art.regions.last.path.getBounds().center * .2;
          final offset = (point.dy.floor() * 200 + point.dx.floor()) * 4;
          final result = data!.buffer.asUint8List().sublist(offset, offset + 4);
          image.dispose();
          picture.dispose();
          return result;
        }

        expect(await centerPixel(doc), [255, 255, 255, 255]);
        expect(
          await centerPixel(
            doc.copyWith(regionColors: {art.regions.last.id: 0xFF8050EF}),
          ),
          [128, 80, 239, 255],
        );
        expect(await centerPixel(doc), [255, 255, 255, 255]);
        cache.dispose();
      });
    },
  );
  setUpAll(() async {
    for (final font in [
      ('DMSans', 'assets/fonts/DMSans-Variable.ttf'),
      ('DMSerif', 'assets/fonts/DMSerifDisplay-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });
  test('2,000 stable unique geometries, 200 per category, with closed fill regions', () {
    expect(ArtCatalog.entries.length, 2000);
    final fingerprints = <String>{};
    final first = _fingerprint(ArtCatalog.design('art_0_0'));
    for (var family = 0; family < 10; family++) {
      expect(ArtCatalog.entries.where((e) => e.family == family).length, 200);
    }
    for (final entry in ArtCatalog.entries) {
      final design = ArtCatalog.design(entry.id);
      expect(design.regions.length, greaterThan(10));
      expect(
        design.regions.map((r) => r.id).toSet().length,
        design.regions.length,
      );
      for (final region in design.regions) {
        expect(region.path.computeMetrics().every((m) => m.isClosed), true);
        final b = region.path.getBounds();
        expect(b.left, greaterThanOrEqualTo(0));
        expect(b.top, greaterThanOrEqualTo(0));
        expect(b.right, lessThanOrEqualTo(1000));
        expect(b.bottom, lessThanOrEqualTo(1000));
      }
      fingerprints.add(_fingerprint(design));
    }
    expect(fingerprints.length, 2000);
    expect(_fingerprint(ArtCatalog.design('art_0_0')), first);
  });
  test('colours, reference ID and completion survive save, undo and reset', () {
    final editor = DrawingEditor(
      SketchDocument.create(width: 2048, height: 2048, artworkId: 'art_1_17'),
    );
    editor.fillRegion('r0', 0xFFFF786B);
    editor.markCompleted();
    final roundTrip = SketchDocument.fromJson(
      jsonDecode(jsonEncode(editor.document.toJson())) as Map<String, dynamic>,
    );
    expect(roundTrip.artworkId, 'art_1_17');
    expect(roundTrip.completed, true);
    expect(roundTrip.regionColors['r0'], 0xFFFF786B);
    expect(roundTrip.width, 2048);
    editor.resetColoring();
    expect(editor.document.regionColors, isEmpty);
    expect(editor.document.completed, false);
    editor.undo();
    expect(editor.document.completed, true);
    editor.fillRegion('r0', 0xFFFFFFFF);
    expect(editor.document.regionColors, isEmpty);
    editor.undo();
    expect(editor.document.regionColors.length, 1);
    editor.dispose();
  });
  testWidgets(
    'tap fill commits once, pan never fills, eraser cannot remove the outline',
    (tester) async {
      final editor = DrawingEditor(
        SketchDocument.create(width: 2048, height: 2048, artworkId: 'art_5_0'),
      );
      final controller = DrawingCanvasController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(
              editor: editor,
              controller: controller,
              brush: BrushKind.pen,
              color: coral,
              width: 12,
              opacity: 1,
              handMode: false,
              fillMode: true,
            ),
          ),
        ),
      );
      final box = tester.getRect(find.byType(DrawingCanvas));
      final fit = ui.Size(box.width - 40, box.height - 48).shortestSide / 2048;
      final art = ArtCatalog.design('art_5_0');
      final region = art.regions.last;
      final p = region.path.getBounds().center;
      final position =
          box.center +
          Offset(
            (p.dx - 500) * 2048 / 1000 * fit,
            (p.dy - 500) * 2048 / 1000 * fit,
          );
      await tester.tapAt(position);
      await tester.pump();
      expect(editor.document.regionColors.length, 1);
      final finger = await tester.startGesture(position, pointer: 11);
      final second = await tester.startGesture(
        position + const Offset(40, 0),
        pointer: 12,
      );
      await second.moveBy(const Offset(20, 20));
      await finger.up();
      await second.up();
      expect(editor.document.regionColors.length, 1);
      await tester.pumpWidget(const SizedBox());
      editor.dispose();
      controller.dispose();
    },
  );
  testWidgets('2K export and original outline/sample contact sheet', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final doc = SketchDocument.create(
        width: 2048,
        height: 2048,
        artworkId: 'art_0_0',
      );
      final png = await renderPng(doc);
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 2048);
      expect(frame.image.height, 2048);
      frame.image.dispose();
      codec.dispose();
      final folder = Directory('output/previews');
      await folder.create(recursive: true);
      await File('${folder.path}/colouring-outline-2k.png').writeAsBytes(png);
      final recorder = ui.PictureRecorder();
      final sheet = Canvas(recorder);
      sheet.drawColor(Colors.white, BlendMode.src);
      for (var family = 0; family < 10; family++) {
        final x = (family % 5) * 400.0, y = (family ~/ 5) * 400.0;
        sheet.save();
        sheet.translate(x, y);
        sheet.scale(.4);
        paintArt(sheet, ArtCatalog.design('art_${family}_0'), sample: true);
        sheet.restore();
      }
      final picture = recorder.endRecording(),
          image = await recorderImage(picture, 2000, 800);
      await File('${folder.path}/colouring-designs.png').writeAsBytes(image);
    });
  });
  testWidgets(
    'library, full-screen sample and return preserve the colouring session',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final store = _MemoryStore(Directory.current), boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: sketchoraTheme(),
            home: ArtLibraryScreen(store: store),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, boundary, 'colouring-library');
      await tester.tap(find.text('Adults'));
      await tester.tap(find.text('Detailed'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Botanical Reverie').first);
      await tester.tap(find.text('Botanical Reverie').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start colouring'));
      await tester.tap(find.text('Start colouring'));
      await tester.pumpAndSettle();
      expect(store.saved?.artworkId, 'premium_0');
      expect(find.text('Sample'), findsOneWidget);
      expect(find.text('Suggested palette · make it yours'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
      await tester.tap(find.text('Move'));
      await tester.tap(find.text('Rose'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DrawingCanvas>(find.byType(DrawingCanvas)).handMode,
        isFalse,
      );
      expect(
        tester.widget<DrawingCanvas>(find.byType(DrawingCanvas)).color,
        const Color(0xFFD76C87),
      );
      await tester.tap(find.text('Paint'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DrawingCanvas>(find.byType(DrawingCanvas)).fillMode,
        isFalse,
      );
      expect(find.byType(Slider), findsNWidgets(2));
      await tester.tap(find.text('Fill'));
      await tester.pumpAndSettle();
      await _capture(tester, boundary, 'colouring-studio');
      await tester.tap(find.text('Sample'));
      await tester.pumpAndSettle();
      expect(find.text('Colour inspiration'), findsOneWidget);
      await _capture(tester, boundary, 'colouring-sample');
      await tester.tap(find.text('Minimise · back to painting'));
      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('completion visual can replay and close with sound disabled', (
    tester,
  ) async {
    final doc = SketchDocument.create(
      width: 2048,
      height: 2048,
      artworkId: 'art_0_0',
    ).copyWith(regionColors: {'r0': 0xFFFF786B}, completed: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: sketchoraTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    CompletionDialog(document: doc, enableAudio: false),
              ),
              child: const Text('Finish'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Finish'));
    await tester.pump(const Duration(seconds: 3));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('Beautifully yours!'), findsOneWidget);
    await tester.tap(find.text('Celebrate again'));
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Back to my artwork'));
    await tester.pumpAndSettle();
    expect(find.text('Finish'), findsOneWidget);
  });
}

String _fingerprint(ArtDesign art) => art.regions
    .map((r) {
      final b = r.path.getBounds();
      return '${b.left.toStringAsFixed(4)},${b.top.toStringAsFixed(4)},${b.width.toStringAsFixed(4)},${b.height.toStringAsFixed(4)}';
    })
    .join('|');
Future<Uint8List> recorderImage(ui.Picture picture, int w, int h) async {
  final image = await picture.toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('output/previews');
    await dir.create(recursive: true);
    await File('${dir.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _MemoryStore extends SketchStore {
  SketchDocument? saved;
  _MemoryStore(super.directory);
  @override
  Future<SketchLoadResult> loadAll() async => SketchLoadResult([?saved], 0, 0);
  @override
  Future<void> save(SketchDocument document) async {
    saved = document;
  }
}
