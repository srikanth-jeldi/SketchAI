import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/renderer.dart';

InkStroke dot(
  int color, {
  BrushKind brush = BrushKind.pen,
  double width = 30,
}) => InkStroke(
  points: const [InkPoint(ui.Offset(50, 50))],
  color: color,
  width: width,
  opacity: 1,
  brush: brush,
);
Future<Uint8List> pixels(SketchDocument doc, {bool transparent = true}) async {
  final png = await renderPng(doc, transparent: transparent);
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  frame.image.dispose();
  codec.dispose();
  return data!.buffer.asUint8List();
}

SketchDocument document(List<InkLayer> layers) => SketchDocument(
  id: '123',
  title: 'Test',
  width: 100,
  height: 100,
  activeLayerId: layers.last.id,
  modified: DateTime.now(),
  layers: layers,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'transparent PNG leaves untouched pixels clear; white export includes paper',
    (tester) async {
      await tester.runAsync(() async {
        final doc = document([
          InkLayer(id: 'a', name: 'A', strokes: [dot(0xFFFF0000)]),
        ]);
        final clear = await pixels(doc);
        final white = await pixels(doc, transparent: false);
        expect(clear[3], 0);
        expect(white.sublist(0, 4), [255, 255, 255, 255]);
        final center = (50 * 100 + 50) * 4;
        expect(clear.sublist(center, center + 4), [255, 0, 0, 255]);
      });
    },
  );
  testWidgets(
    'eraser clears only its own layer and reveals the lower drawing',
    (tester) async {
      await tester.runAsync(() async {
        final doc = document([
          InkLayer(id: 'bottom', name: 'Bottom', strokes: [dot(0xFFFF0000)]),
          InkLayer(
            id: 'top',
            name: 'Top',
            strokes: [
              dot(0xFF0000FF),
              dot(0, brush: BrushKind.eraser),
            ],
          ),
        ]);
        final data = await pixels(doc);
        final center = (50 * 100 + 50) * 4;
        expect(data.sublist(center, center + 4), [255, 0, 0, 255]);
      });
    },
  );
  testWidgets('hidden layers are excluded and opacity composites correctly', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final doc = document([
        InkLayer(
          id: 'bottom',
          name: 'Bottom',
          opacity: .5,
          strokes: [dot(0xFFFF0000)],
        ),
        InkLayer(
          id: 'top',
          name: 'Top',
          visible: false,
          strokes: [dot(0xFF0000FF)],
        ),
      ]);
      final data = await pixels(doc);
      final center = (50 * 100 + 50) * 4;
      expect(data[center], 255);
      expect(data[center + 2], 0);
      expect(data[center + 3], closeTo(128, 1));
    });
  });
}
