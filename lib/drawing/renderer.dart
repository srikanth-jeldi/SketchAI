import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'document.dart';
import 'decoration.dart';
import '../coloring/art_catalog.dart';

void paintStroke(Canvas canvas, InkStroke stroke) {
  if (stroke.points.isEmpty) return;
  final marker = stroke.brush == BrushKind.marker;
  final pencil = stroke.brush == BrushKind.pencil;
  final erase = stroke.brush == BrushKind.eraser;
  final paint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..blendMode = erase ? BlendMode.clear : BlendMode.srcOver
    ..color = Color(stroke.color).withValues(
      alpha: erase
          ? 1
          : stroke.opacity *
                (marker
                    ? .3
                    : pencil
                    ? .65
                    : 1),
    );
  final width =
      stroke.width *
      (marker
          ? 2.5
          : pencil
          ? .65
          : 1);
  if (stroke.points.length == 1) {
    canvas.drawCircle(
      stroke.points.first.position,
      math.max(.3, width * stroke.points.first.pressure / 2),
      paint..style = PaintingStyle.fill,
    );
    return;
  }
  final uniformPressure = stroke.points.every(
    (p) => (p.pressure - stroke.points.first.pressure).abs() < .01,
  );
  if (uniformPressure || marker) {
    // One path avoids dark overlap seams in translucent finger/marker strokes.
    final path = Path()
      ..moveTo(
        stroke.points.first.position.dx,
        stroke.points.first.position.dy,
      );
    for (var i = 1; i < stroke.points.length; i++) {
      final previous = stroke.points[i - 1].position;
      final point = stroke.points[i].position;
      final end = i == stroke.points.length - 1
          ? point
          : (previous + point) / 2;
      path.quadraticBezierTo(previous.dx, previous.dy, end.dx, end.dy);
    }
    paint.strokeWidth = width * (.35 + .65 * stroke.points.first.pressure);
    canvas.drawPath(path, paint);
    return;
  }
  // Quadratic midpoint interpolation removes angular joins while retaining input.
  var start = stroke.points.first.position;
  for (var i = 1; i < stroke.points.length; i++) {
    final previous = stroke.points[i - 1];
    final point = stroke.points[i];
    final end = i == stroke.points.length - 1
        ? point.position
        : (previous.position + point.position) / 2;
    paint.strokeWidth = math.max(
      .5,
      width * (.35 + .65 * (previous.pressure + point.pressure) / 2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          previous.position.dx,
          previous.position.dy,
          end.dx,
          end.dy,
        ),
      paint,
    );
    start = end;
  }
}

/// A retained picture per layer avoids reconstructing old paths on pointer moves.
class DrawingRenderCache {
  final Map<String, ({InkLayer layer, ui.Picture picture})> _entries = {};
  String? _artId;
  ui.Picture? _artBase, _artLines;
  Map<String, int>? _artColors;
  ui.Picture artPicture(SketchDocument doc, {bool outlines = false}) {
    if (_artId != doc.artworkId) {
      _artBase?.dispose();
      _artLines?.dispose();
      _artBase = null;
      _artLines = null;
      _artColors = null;
      _artId = doc.artworkId;
    }
    if (outlines && _artLines != null) return _artLines!;
    if (!outlines &&
        _artBase != null &&
        identical(_artColors, doc.regionColors)) {
      return _artBase!;
    }
    final recorder = ui.PictureRecorder();
    paintArt(
      Canvas(recorder),
      ArtCatalog.design(doc.artworkId!),
      colors: doc.regionColors,
      fills: !outlines,
      outlines: outlines,
    );
    final picture = recorder.endRecording();
    if (outlines) {
      _artLines = picture;
    } else {
      _artBase?.dispose();
      _artBase = picture;
      _artColors = doc.regionColors;
    }
    return picture;
  }

  ui.Picture picture(InkLayer layer) {
    final entry = _entries[layer.id];
    if (entry != null && identical(entry.layer.strokes, layer.strokes)) {
      return entry.picture;
    }
    entry?.picture.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final stroke in layer.strokes) {
      paintStroke(canvas, stroke);
    }
    final picture = recorder.endRecording();
    _entries[layer.id] = (layer: layer, picture: picture);
    return picture;
  }

  void prune(SketchDocument document) {
    final ids = document.layers.map((l) => l.id).toSet();
    for (final id in _entries.keys.where((id) => !ids.contains(id)).toList()) {
      _entries.remove(id)?.picture.dispose();
    }
  }

  void dispose() {
    _artBase?.dispose();
    _artLines?.dispose();
    for (final entry in _entries.values) {
      entry.picture.dispose();
    }
    _entries.clear();
  }
}

void paintDocument(
  Canvas canvas,
  SketchDocument doc,
  DrawingRenderCache cache, {
  InkStroke? live,
  bool paper = true,
  CanvasDecoration? decorationPreview,
}) {
  final bounds = Rect.fromLTWH(
    0,
    0,
    doc.width.toDouble(),
    doc.height.toDouble(),
  );
  canvas.save();
  canvas.clipRect(bounds);
  if (paper) canvas.drawRect(bounds, Paint()..color = Colors.white);
  final artwork = ArtCatalog.entry(doc.artworkId);
  if (artwork != null) {
    canvas.save();
    canvas.scale(doc.width / 1000, doc.height / 1000);
    canvas.drawPicture(cache.artPicture(doc));
    canvas.restore();
  }
  for (final item in doc.decorations.where((d) => d.behindInk)) {
    paintDecoration(
      canvas,
      decorationPreview?.id == item.id ? decorationPreview! : item,
    );
  }
  for (final layer in doc.layers) {
    if (!layer.visible || layer.opacity <= 0) continue;
    if (layer.strokes.isEmpty &&
        !(layer.id == doc.activeLayerId && live != null)) {
      continue;
    }
    // Each layer is isolated: an eraser never punches through lower layers.
    canvas.saveLayer(
      bounds,
      Paint()..color = Colors.white.withValues(alpha: layer.opacity),
    );
    canvas.drawPicture(cache.picture(layer));
    if (layer.id == doc.activeLayerId && live != null) {
      paintStroke(canvas, live);
    }
    canvas.restore();
  }
  if (artwork != null) {
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.multiply);
    canvas.scale(doc.width / 1000, doc.height / 1000);
    canvas.drawPicture(cache.artPicture(doc, outlines: true));
    canvas.restore();
  }
  for (final item in doc.decorations.where((d) => !d.behindInk)) {
    paintDecoration(
      canvas,
      decorationPreview?.id == item.id ? decorationPreview! : item,
    );
  }
  canvas.restore();
}

Future<Uint8List> renderPng(
  SketchDocument doc, {
  bool transparent = false,
  int? maxSide,
}) async {
  await ensureArtworkLoaded(doc.artworkId);
  await DecorationPhotos.prepare(doc.decorations);
  final scale = maxSide == null
      ? 1.0
      : math.min(1.0, maxSide / math.max(doc.width, doc.height));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  final cache = DrawingRenderCache();
  ui.Picture? picture;
  ui.Image? image;
  try {
    paintDocument(canvas, doc, cache, paper: !transparent);
    picture = recorder.endRecording();
    image = await picture.toImage(
      (doc.width * scale).round(),
      (doc.height * scale).round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Could not encode PNG');
    return bytes.buffer.asUint8List();
  } finally {
    image?.dispose();
    picture?.dispose();
    if (recorder.isRecording) recorder.endRecording().dispose();
    cache.dispose();
  }
}
