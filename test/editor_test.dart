import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/editor.dart';

InkStroke stroke([BrushKind brush = BrushKind.pen]) => InkStroke(
  points: const [InkPoint(Offset(20, 20)), InkPoint(Offset(60, 60), .5)],
  color: 0xFF8050EF,
  width: 8,
  opacity: .7,
  brush: brush,
);

void main() {
  test('strokes are immutable and undo/redo branches discard stale redo', () {
    final editor = DrawingEditor(SketchDocument.create());
    editor.addStroke(stroke());
    editor.addStroke(stroke(BrushKind.eraser));
    expect(editor.document.strokeCount, 2);
    editor.undo();
    expect(editor.document.strokeCount, 1);
    editor.redo();
    expect(editor.document.strokeCount, 2);
    editor.undo();
    editor.addStroke(stroke(BrushKind.marker));
    expect(editor.canRedo, false);
    expect(
      () => editor.document.activeLayer.strokes.clear(),
      throwsUnsupportedError,
    );
    editor.dispose();
  });
  test(
    'hidden layers reject input; delete and undo restore content and selection',
    () {
      final editor = DrawingEditor(SketchDocument.create());
      final bottom = editor.document.activeLayerId;
      editor.addStroke(stroke());
      editor.addLayer();
      final top = editor.document.activeLayerId;
      editor.addStroke(stroke());
      editor.toggleLayer(top);
      editor.addStroke(stroke());
      expect(editor.document.activeLayer.strokes.length, 1);
      editor.deleteLayer(top);
      expect(editor.document.activeLayerId, bottom);
      editor.undo();
      expect(editor.document.activeLayerId, top);
      expect(editor.document.strokeCount, 2);
      editor.dispose();
    },
  );
  test('last layer survives deletion and layer ordering is undoable', () {
    final editor = DrawingEditor(SketchDocument.create());
    final original = editor.document.activeLayerId;
    editor.deleteLayer(original);
    expect(editor.document.layers.length, 1);
    editor.addLayer();
    final top = editor.document.activeLayerId;
    editor.moveLayer(top, -1);
    expect(editor.document.layers.first.id, top);
    editor.undo();
    expect(editor.document.layers.last.id, top);
    editor.setLayerOpacity(top, 2);
    expect(editor.document.activeLayer.opacity, 1);
    editor.dispose();
  });
  test('JSON round trip preserves dimensions, layer visibility, eraser and pressure', () {
    final editor = DrawingEditor(
      SketchDocument.create(width: 1600, height: 1200),
    );
    editor.addStroke(stroke(BrushKind.eraser));
    editor.addLayer();
    editor.toggleLayer(editor.document.activeLayerId);
    final json = jsonEncode(editor.document.toJson());
    final restored = SketchDocument.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
    expect(jsonEncode(restored.toJson()), json);
    expect(restored.width, 1600);
    expect(restored.activeLayer.visible, false);
    expect(restored.layers.first.strokes.first.points.last.pressure, .5);
    editor.dispose();
  });
  test('malformed documents and unsupported schema are rejected', () {
    final json = SketchDocument.create().toJson();
    expect(
      () => SketchDocument.fromJson({...json, 'version': 2}),
      throwsFormatException,
    );
    expect(
      () => SketchDocument.fromJson({...json, 'id': '../escape'}),
      throwsFormatException,
    );
    expect(
      () => SketchDocument.fromJson({...json, 'layers': []}),
      throwsFormatException,
    );
    expect(
      () => SketchDocument.fromJson({...json, 'activeLayerId': 'missing'}),
      throwsFormatException,
    );
  });
  test(
    'clear is undoable and 12-layer cap prevents unbounded GPU surfaces',
    () {
      final editor = DrawingEditor(SketchDocument.create());
      editor.addStroke(stroke());
      editor.clearLayer();
      expect(editor.document.strokeCount, 0);
      editor.undo();
      expect(editor.document.strokeCount, 1);
      for (var i = 0; i < 20; i++) {
        editor.addLayer();
      }
      expect(editor.document.layers.length, 12);
      editor.dispose();
    },
  );
}
