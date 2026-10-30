import 'dart:ui';

import 'decoration.dart';

import '../coloring/art_catalog.dart' show ArtCatalog;

enum BrushKind { pen, pencil, marker, eraser }

int _lastGeneratedId = 0;
String newSketchId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _lastGeneratedId = now > _lastGeneratedId ? now : _lastGeneratedId + 1;
  return _lastGeneratedId.toString();
}

class InkPoint {
  final Offset position;
  final double pressure;
  const InkPoint(this.position, [this.pressure = 1]);
  List<double> toJson() => [position.dx, position.dy, pressure];
  factory InkPoint.fromJson(List<dynamic> json) => InkPoint(
    Offset((json[0] as num).toDouble(), (json[1] as num).toDouble()),
    (json[2] as num).toDouble().clamp(0.1, 1),
  );
}

class InkStroke {
  final List<InkPoint> points;
  final int color;
  final double width;
  final double opacity;
  final BrushKind brush;
  InkStroke({
    required List<InkPoint> points,
    required this.color,
    required this.width,
    required this.opacity,
    required this.brush,
  }) : points = List.unmodifiable(points);
  // Only the in-progress painter uses this; committed strokes always copy input.
  InkStroke.live({
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
    required this.brush,
  });
  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'width': width,
    'opacity': opacity,
    'brush': brush.name,
  };
  factory InkStroke.fromJson(Map<String, dynamic> json) => InkStroke(
    points: (json['points'] as List)
        .map((p) => InkPoint.fromJson(p as List))
        .toList(),
    color: json['color'] as int,
    width: (json['width'] as num).toDouble().clamp(1, 100),
    opacity: (json['opacity'] as num).toDouble().clamp(0.05, 1),
    brush: BrushKind.values.byName(json['brush'] as String),
  );
}

class InkLayer {
  final String id;
  final String name;
  final bool visible;
  final double opacity;
  final List<InkStroke> strokes;
  InkLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.opacity = 1,
    List<InkStroke> strokes = const [],
  }) : strokes = List.unmodifiable(strokes);
  InkLayer copyWith({
    String? name,
    bool? visible,
    double? opacity,
    List<InkStroke>? strokes,
  }) => InkLayer(
    id: id,
    name: name ?? this.name,
    visible: visible ?? this.visible,
    opacity: opacity ?? this.opacity,
    strokes: strokes ?? this.strokes,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'visible': visible,
    'opacity': opacity,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };
  factory InkLayer.fromJson(Map<String, dynamic> json) => InkLayer(
    id: json['id'] as String,
    name: json['name'] as String,
    visible: json['visible'] as bool,
    opacity: (json['opacity'] as num).toDouble().clamp(0, 1),
    strokes: (json['strokes'] as List)
        .map((s) => InkStroke.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

class SketchDocument {
  final String id;
  final String title;
  final int width;
  final int height;
  final String activeLayerId;
  final DateTime modified;
  final List<InkLayer> layers;
  final String? artworkId;
  final Map<String, int> regionColors;
  final bool completed;
  final List<CanvasDecoration> decorations;
  SketchDocument({
    required this.id,
    required this.title,
    this.width = 1200,
    this.height = 1600,
    required this.activeLayerId,
    required this.modified,
    required List<InkLayer> layers,
    this.artworkId,
    Map<String, int> regionColors = const {},
    this.completed = false,
    List<CanvasDecoration> decorations = const [],
  }) : layers = List.unmodifiable(layers),
       decorations = List.unmodifiable(decorations),
       regionColors = Map.unmodifiable(regionColors) {
    if (decorations.where((d) => d.imageData.isNotEmpty).length > 6 ||
        decorations.fold<int>(0, (n, d) => n + d.imageData.length) > 8000000 ||
        decorations.length > 100 ||
        decorations.map((d) => d.id).toSet().length != decorations.length ||
        width < 1 ||
        height < 1 ||
        width > 4096 ||
        height > 4096 ||
        layers.isEmpty ||
        layers.length > 12 ||
        layers.map((l) => l.id).toSet().length != layers.length ||
        !layers.any((l) => l.id == activeLayerId)) {
      throw const FormatException('Invalid sketch document');
    }
    if (artworkId != null && ArtCatalog.entry(artworkId) == null) {
      throw const FormatException('Unknown artwork ID');
    }
    if (regionColors.keys.any((key) => !RegExp(r'^r\d+$').hasMatch(key))) {
      throw const FormatException('Invalid colour region');
    }
  }
  factory SketchDocument.create({
    String title = 'Untitled sketch',
    int width = 1200,
    int height = 1600,
    String? artworkId,
  }) {
    final id = newSketchId();
    return SketchDocument(
      id: id,
      title: title,
      width: width,
      height: height,
      activeLayerId: '${id}_1',
      modified: DateTime.now(),
      layers: [InkLayer(id: '${id}_1', name: 'Layer 1')],
      artworkId: artworkId,
    );
  }
  InkLayer get activeLayer => layers.firstWhere((l) => l.id == activeLayerId);
  int get strokeCount => layers.fold(0, (sum, l) => sum + l.strokes.length);
  SketchDocument copyWith({
    String? title,
    List<InkLayer>? layers,
    String? activeLayerId,
    DateTime? modified,
    Map<String, int>? regionColors,
    bool? completed,
    List<CanvasDecoration>? decorations,
  }) => SketchDocument(
    id: id,
    title: title ?? this.title,
    width: width,
    height: height,
    activeLayerId: activeLayerId ?? this.activeLayerId,
    modified: modified ?? DateTime.now(),
    layers: layers ?? this.layers,
    artworkId: artworkId,
    regionColors: regionColors ?? this.regionColors,
    completed: completed ?? this.completed,
    decorations: decorations ?? this.decorations,
  );
  Map<String, dynamic> toJson() => {
    'version': decorations.isNotEmpty
        ? 3
        : artworkId == null
        ? 1
        : 2,
    if (decorations.isNotEmpty)
      'decorations': decorations.map((d) => d.toJson()).toList(),
    if (artworkId != null) 'artworkId': artworkId,
    if (artworkId != null) 'regionColors': regionColors,
    if (artworkId != null || completed) 'completed': completed,
    'id': id,
    'title': title,
    'width': width,
    'height': height,
    'activeLayerId': activeLayerId,
    'modified': modified.toIso8601String(),
    'layers': layers.map((l) => l.toJson()).toList(),
  };
  factory SketchDocument.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 && json['version'] != 2 && json['version'] != 3) {
      throw const FormatException('Unsupported sketch version');
    }
    final id = json['id'] as String;
    if (!RegExp(r'^\d+$').hasMatch(id)) {
      throw const FormatException('Invalid sketch ID');
    }
    return SketchDocument(
      id: id,
      title: json['title'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      activeLayerId: json['activeLayerId'] as String,
      modified: DateTime.parse(json['modified'] as String),
      layers: (json['layers'] as List)
          .map((l) => InkLayer.fromJson(l as Map<String, dynamic>))
          .toList(),
      artworkId: json['artworkId'] as String?,
      regionColors: (json['regionColors'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value as int),
      ),
      completed: json['completed'] as bool? ?? false,
      decorations: (json['decorations'] as List? ?? [])
          .map((d) => CanvasDecoration.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
