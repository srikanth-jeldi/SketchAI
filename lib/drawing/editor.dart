import 'package:flutter/foundation.dart';

import 'document.dart';

class DrawingEditor extends ChangeNotifier {
  SketchDocument _document;
  final List<SketchDocument> _past = [];
  final List<SketchDocument> _future = [];
  DrawingEditor(this._document);
  SketchDocument get document => _document;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  void fillRegion(String id, int color) {
    if (document.artworkId == null) return;
    final colors = Map<String, int>.of(document.regionColors);
    if (color == 0xFFFFFFFF) {
      if (!colors.containsKey(id)) return;
      colors.remove(id);
    } else {
      if (colors[id] == color) return;
      colors[id] = color;
    }
    _edit(document.copyWith(regionColors: colors, completed: false));
  }

  void markCompleted() {
    if (document.artworkId != null && !document.completed) {
      _edit(document.copyWith(completed: true));
    }
  }

  void resetColoring() {
    _edit(
      document.copyWith(
        regionColors: {},
        completed: false,
        layers: document.layers.map((l) => l.copyWith(strokes: [])).toList(),
      ),
    );
  }

  void _edit(SketchDocument next) {
    _past.add(_document);
    if (_past.length > 60) _past.removeAt(0);
    _future.clear();
    _document = next;
    notifyListeners();
  }

  void addStroke(InkStroke stroke) {
    if (stroke.points.isEmpty || !document.activeLayer.visible) return;
    _edit(
      document.copyWith(
        layers: document.layers
            .map(
              (l) => l.id == document.activeLayerId
                  ? l.copyWith(strokes: [...l.strokes, stroke])
                  : l,
            )
            .toList(),
      ),
    );
  }

  void rename(String title) {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty && trimmed != document.title) {
      _edit(document.copyWith(title: trimmed));
    }
  }

  void undo() {
    if (!canUndo) return;
    _future.add(_document);
    _document = _past.removeLast().copyWith();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _past.add(_document);
    _document = _future.removeLast().copyWith();
    notifyListeners();
  }

  void addLayer() {
    if (document.layers.length >= 12) return;
    final layer = InkLayer(
      id: newSketchId(),
      name: 'Layer ${document.layers.length + 1}',
    );
    _edit(
      document.copyWith(
        layers: [...document.layers, layer],
        activeLayerId: layer.id,
      ),
    );
  }

  void selectLayer(String id) {
    if (document.layers.any((l) => l.id == id)) {
      _document = document.copyWith(activeLayerId: id);
      notifyListeners();
    }
  }

  void toggleLayer(String id) => _edit(
    document.copyWith(
      layers: document.layers
          .map((l) => l.id == id ? l.copyWith(visible: !l.visible) : l)
          .toList(),
    ),
  );
  void setLayerOpacity(String id, double value) => _edit(
    document.copyWith(
      layers: document.layers
          .map((l) => l.id == id ? l.copyWith(opacity: value.clamp(0, 1)) : l)
          .toList(),
    ),
  );
  void deleteLayer(String id) {
    if (document.layers.length == 1 ||
        !document.layers.any((l) => l.id == id)) {
      return;
    }
    final remaining = document.layers.where((l) => l.id != id).toList();
    _edit(
      document.copyWith(
        layers: remaining,
        activeLayerId: document.activeLayerId == id
            ? remaining.last.id
            : document.activeLayerId,
      ),
    );
  }

  void moveLayer(String id, int delta) {
    final layers = document.layers.toList();
    final from = layers.indexWhere((l) => l.id == id);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= layers.length) return;
    layers.insert(to, layers.removeAt(from));
    _edit(document.copyWith(layers: layers));
  }

  void clearLayer() {
    if (document.activeLayer.strokes.isEmpty) return;
    _edit(
      document.copyWith(
        layers: document.layers
            .map(
              (l) =>
                  l.id == document.activeLayerId ? l.copyWith(strokes: []) : l,
            )
            .toList(),
      ),
    );
  }
}
