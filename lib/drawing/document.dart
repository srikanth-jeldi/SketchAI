import 'dart:ui';

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
  SketchDocument({
    required this.id,
    required this.title,
    this.width = 1200,
    this.height = 1600,
    required this.activeLayerId,
    required this.modified,
    required List<InkLayer> layers,
  }) : layers = List.unmodifiable(layers) {
    if (width < 1 ||
        height < 1 ||
        width > 4096 ||
        height > 4096 ||
        layers.isEmpty ||
        layers.length > 12 ||
        layers.map((l) => l.id).toSet().length != layers.length ||
        !layers.any((l) => l.id == activeLayerId)) {
      throw const FormatException('Invalid sketch document');
    }
  }
  factory SketchDocument.create({
    String title = 'Untitled sketch',
    int width = 1200,
    int height = 1600,
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
    );
  }
  InkLayer get activeLayer => layers.firstWhere((l) => l.id == activeLayerId);
  int get strokeCount => layers.fold(0, (sum, l) => sum + l.strokes.length);
  SketchDocument copyWith({
    String? title,
    List<InkLayer>? layers,
    String? activeLayerId,
    DateTime? modified,
  }) => SketchDocument(
    id: id,
    title: title ?? this.title,
    width: width,
    height: height,
    activeLayerId: activeLayerId ?? this.activeLayerId,
    modified: modified ?? DateTime.now(),
    layers: layers ?? this.layers,
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'title': title,
    'width': width,
    'height': height,
    'activeLayerId': activeLayerId,
    'modified': modified.toIso8601String(),
    'layers': layers.map((l) => l.toJson()).toList(),
  };
  factory SketchDocument.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
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
    );
  }
}
