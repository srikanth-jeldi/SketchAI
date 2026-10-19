import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/drawing_canvas.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/drawing/renderer.dart';
import 'package:sketchora/screens/gallery_screen.dart';
import 'package:sketchora/screens/studio_screen.dart';
import 'package:sketchora/storage/sketch_store.dart';
import 'package:sketchora/theme.dart';
import 'package:sketchora/coloring/art_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadPremiumArt();
    for (final font in [
      ('DMSans', 'assets/fonts/DMSans-Variable.ttf'),
      ('DMSerif', 'assets/fonts/DMSerifDisplay-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });
  testWidgets(
    'drawing commits one stroke; pinch and cancellation never leave marks',
    (tester) async {
      final editor = DrawingEditor(SketchDocument.create());
      final controller = DrawingCanvasController();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: DrawingCanvas(
              editor: editor,
              controller: controller,
              brush: BrushKind.pen,
              color: violet,
              width: 8,
              opacity: 1,
              handMode: false,
            ),
          ),
        ),
      );
      final canvas = find.byType(DrawingCanvas);
      final center = tester.getCenter(canvas);
      final draw = await tester.startGesture(center);
      await draw.moveBy(const Offset(30, 30));
      await draw.up();
      await tester.pump();
      expect(editor.document.strokeCount, 1);
      final first = await tester.startGesture(center, pointer: 11);
      final second = await tester.startGesture(
        center + const Offset(60, 0),
        pointer: 12,
      );
      await second.moveBy(const Offset(30, 30));
      await first.up();
      await second.up();
      await tester.pump();
      expect(editor.document.strokeCount, 1);
      final cancelled = await tester.startGesture(center, pointer: 13);
      await cancelled.cancel();
      expect(editor.document.strokeCount, 1);
      editor.toggleLayer(editor.document.activeLayerId);
      await tester.drag(canvas, const Offset(40, 10));
      expect(editor.document.strokeCount, 1);
      await tester.pumpWidget(const SizedBox());
      editor.dispose();
      controller.dispose();
    },
  );

  testWidgets(
    'phone and tablet studio controls render and undo/redo change document',
    (tester) async {
      final store = _MemoryStore(Directory.current);
      for (final size in [
        const Size(390, 844),
        const Size(320, 640),
        const Size(1024, 768),
      ]) {
        await tester.binding.setSurfaceSize(size);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        final doc = SketchDocument.create();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: sketchoraTheme(),
            home: StudioScreen(key: UniqueKey(), document: doc, store: store),
          ),
        );
        await tester.pump();
        final canvas = find.byType(DrawingCanvas);
        await tester.dragFrom(tester.getCenter(canvas), const Offset(35, 20));
        await tester.pump();
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.undo_rounded),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.redo_rounded),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byTooltip('Redo'));
        await tester.pump();
        await tester.tap(find.text('Layers'));
        await tester.pumpAndSettle();
        expect(find.text('Layer 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('capture reference-inspired home, gallery and studio previews', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('sketchora_preview_'),
    ))!;
    final doc = _demoSketch();
    final store = _PreviewStore(directory, doc);
    await tester.runAsync(() async {
      await store.save(doc);
      await store.saveThumbnail(doc.id, await renderPng(doc, maxSide: 420));
    });
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: sketchoraTheme(),
          home: GalleryScreen(store: store),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/sketluma-icon-v1.png'),
        tester.element(find.byType(GalleryScreen)),
      );
      await precacheImage(
        FileImage(store.thumbnail(doc.id)),
        tester.element(find.byType(GalleryScreen)),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('Make something\nbeautiful.'), findsOneWidget);
    await _capture(tester, boundary, 'home');
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    await _capture(tester, boundary, 'gallery');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: sketchoraTheme(),
          home: StudioScreen(document: doc, store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, boundary, 'studio');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('output/previews');
    await folder.create(recursive: true);
    await File('${folder.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

SketchDocument _demoSketch() {
  // Editable vector test fixture, not an imported illustration or user artwork.
  final strokes = <InkStroke>[];
  void line(
    List<Offset> points,
    int color,
    double width, {
    double opacity = 1,
  }) {
    strokes.add(
      InkStroke(
        points: points.map((p) => InkPoint(p)).toList(),
        color: color,
        width: width,
        opacity: opacity,
        brush: BrushKind.pen,
      ),
    );
  }

  line(
    [
      const Offset(540, 1360),
      const Offset(550, 1100),
      const Offset(620, 850),
      const Offset(560, 550),
      const Offset(670, 240),
    ],
    0xFF66866B,
    10,
  );
  for (final leaf in [
    (const Offset(590, 940), const Offset(300, 600)),
    (const Offset(575, 680), const Offset(860, 380)),
    (const Offset(555, 1130), const Offset(850, 850)),
    (const Offset(605, 450), const Offset(420, 210)),
  ]) {
    final mid = (leaf.$1 + leaf.$2) / 2;
    line(
      [leaf.$1, mid + const Offset(-25, -25), leaf.$2],
      0xFF98AB85,
      64,
      opacity: .8,
    );
    line([leaf.$1, mid, leaf.$2], 0xFF526E54, 5);
  }
  // Bold violet/coral botanical study to exercise layered strokes in screenshots.
  for (final petal in [
    const Offset(370, 800),
    const Offset(300, 950),
    const Offset(450, 1080),
    const Offset(570, 950),
    const Offset(470, 790),
  ]) {
    line([const Offset(450, 940), petal], 0xFFB692DB, 104, opacity: .9);
    line(
      [const Offset(450, 940), petal + const Offset(8, 5)],
      0xFF8050EF,
      15,
      opacity: .65,
    );
  }
  line([const Offset(450, 940)], 0xFFFFB462, 100);
  line([const Offset(450, 940)], 0xFFFF786B, 45);
  return SketchDocument(
    id: '123456789',
    title: 'Botanical study',
    width: 1200,
    height: 1600,
    activeLayerId: 'demo',
    modified: DateTime.now(),
    layers: [InkLayer(id: 'demo', name: 'Botanical study', strokes: strokes)],
  );
}

class _PreviewStore extends SketchStore {
  final SketchDocument preview;
  _PreviewStore(super.directory, this.preview);
  @override
  Future<SketchLoadResult> loadAll() async => SketchLoadResult([preview], 0, 0);
}

class _MemoryStore extends SketchStore {
  _MemoryStore(super.directory);
  @override
  Future<void> save(SketchDocument document) async {}
}
