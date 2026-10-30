import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'document.dart';
import 'decoration.dart';
import 'editor.dart';
import 'renderer.dart';
import '../coloring/art_catalog.dart';

class DrawingCanvasController extends ChangeNotifier {
  VoidCallback? _reset;
  void resetView() => _reset?.call();
}

class DrawingCanvas extends StatefulWidget {
  final DrawingEditor editor;
  final DrawingCanvasController controller;
  final BrushKind brush;
  final Color color;
  final double width, opacity;
  final bool handMode;
  final bool fillMode;
  final bool objectMode;
  final String? selectedDecorationId;
  final ValueChanged<String?>? onSelectDecoration;
  const DrawingCanvas({
    super.key,
    required this.editor,
    required this.controller,
    required this.brush,
    required this.color,
    required this.width,
    required this.opacity,
    required this.handMode,
    this.fillMode = false,
    this.objectMode = false,
    this.selectedDecorationId,
    this.onSelectDecoration,
  });
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final _scene = _CanvasScene();
  final Map<int, Offset> _pointers = {};
  final _cache = DrawingRenderCache();
  Size _viewport = Size.zero;
  double _fit = 1, _gestureScale = 1, _gestureDistance = 1;
  Offset _gestureAnchor = Offset.zero;
  bool _gesture = false;
  int? _drawingPointer;
  String? _strokeLayer;
  Offset? _fillStart;
  int? _movingPointer;
  Offset? _objectAnchor;
  CanvasDecoration? _objectStart;
  @override
  void initState() {
    super.initState();
    widget.controller._reset = _reset;
    widget.editor.addListener(_documentChanged);
  }

  void _documentChanged() {
    _movingPointer = null;
    _objectStart = null;
    _objectAnchor = null;
    _scene.decorationPreview = null;
    // Layer/history changes cancel uncommitted input.
    _scene.live = null;
    _fillStart = null;
    _drawingPointer = null;
    _cache.prune(widget.editor.document);
    _scene.changed();
  }

  void _reset() {
    _scene.scale = _fit;
    final doc = widget.editor.document;
    _scene.offset = Offset(
      (_viewport.width - doc.width * _fit) / 2,
      (_viewport.height - doc.height * _fit) / 2,
    );
    _scene.changed();
  }

  Offset _toDocument(Offset point) => (point - _scene.offset) / _scene.scale;
  double _pressure(PointerEvent event) {
    if (event.kind != PointerDeviceKind.stylus &&
        event.kind != PointerDeviceKind.invertedStylus) {
      return 1;
    }
    final range = event.pressureMax - event.pressureMin;
    return range <= 0
        ? 1
        : ((event.pressure - event.pressureMin) / range).clamp(.15, 1);
  }

  Offset get _centroid =>
      _pointers.values.reduce((a, b) => a + b) / _pointers.length.toDouble();
  double get _distance => _pointers.length < 2
      ? 1
      : (_pointers.values.elementAt(0) - _pointers.values.elementAt(1))
            .distance;
  void _startGesture() {
    _movingPointer = null;
    _scene.decorationPreview = null;
    _scene.live = null;
    _drawingPointer = null;
    _gesture = true;
    _gestureScale = _scene.scale;
    _gestureDistance = math.max(1, _distance);
    _gestureAnchor = _toDocument(_centroid);
  }

  void _down(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2 || widget.handMode) {
      _startGesture();
      _scene.changed();
      return;
    }
    if (_gesture ||
        (!widget.objectMode && !widget.editor.document.activeLayer.visible)) {
      return;
    }
    final point = _toDocument(event.localPosition);
    final doc = widget.editor.document;
    if (widget.objectMode) {
      CanvasDecoration? hit;
      for (final item in [
        ...doc.decorations.where((d) => d.behindInk),
        ...doc.decorations.where((d) => !d.behindInk),
      ].reversed) {
        if (item.contains(point)) {
          hit = item;
          break;
        }
      }
      widget.onSelectDecoration?.call(hit?.id);
      _movingPointer = hit == null ? null : event.pointer;
      _objectAnchor = point;
      _objectStart = hit;
      _scene.decorationPreview = hit;
      _scene.changed();
      return;
    }
    if (!(Offset.zero & Size(doc.width.toDouble(), doc.height.toDouble()))
        .contains(point)) {
      return;
    }
    _drawingPointer = event.pointer;
    _strokeLayer = doc.activeLayerId;
    if (widget.fillMode && doc.artworkId != null) {
      _fillStart = event.localPosition;
      return;
    }
    _scene.live = InkStroke.live(
      points: [InkPoint(point, _pressure(event))],
      color: widget.color.toARGB32(),
      width: widget.width,
      opacity: widget.opacity,
      brush: event.kind == PointerDeviceKind.invertedStylus
          ? BrushKind.eraser
          : widget.brush,
    );
    _scene.changed();
  }

  void _move(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (_gesture) {
      if (_pointers.length >= 2 || widget.handMode) {
        final factor = _pointers.length >= 2
            ? _distance / _gestureDistance
            : 1.0;
        _scene.scale = (_gestureScale * factor).clamp(_fit * .5, _fit * 8);
        _scene.offset = _centroid - _gestureAnchor * _scene.scale;
        _scene.changed();
      }
      return;
    }
    if (_movingPointer == event.pointer && _objectStart != null) {
      final doc = widget.editor.document;
      final p =
          _objectStart!.center +
          _toDocument(event.localPosition) -
          _objectAnchor!;
      _scene.decorationPreview = _objectStart!.copyWith(
        center: Offset(
          p.dx.clamp(0, doc.width.toDouble()),
          p.dy.clamp(0, doc.height.toDouble()),
        ),
      );
      _scene.changed();
      return;
    }
    if (_drawingPointer != event.pointer || _scene.live == null) return;
    _append(event);
    _scene.changed();
  }

  void _append(PointerEvent event) {
    final live = _scene.live;
    if (live == null) return;
    final point = _toDocument(event.localPosition);
    if ((point - live.points.last.position).distance < .35) return;
    live.points.add(InkPoint(point, _pressure(event)));
  }

  void _up(PointerEvent event, {bool cancel = false}) {
    if (_movingPointer == event.pointer) {
      final next = _scene.decorationPreview;
      _movingPointer = null;
      _scene.decorationPreview = null;
      if (!cancel && next != null && next.center != _objectStart?.center) {
        widget.editor.putDecoration(next);
      }
    }
    if (_drawingPointer == event.pointer &&
        _fillStart != null &&
        !cancel &&
        !_gesture &&
        (event.localPosition - _fillStart!).distance < 12) {
      final doc = widget.editor.document;
      final p = _toDocument(event.localPosition);
      final region = ArtCatalog.design(doc.artworkId!).regionAt(
        Offset(p.dx * 1000 / doc.width, p.dy * 1000 / doc.height),
        tolerance: (8 / _scene.scale * 1000 / doc.width).clamp(0, 12),
      );
      _fillStart = null;
      if (region != null) {
        widget.editor.fillRegion(region.id, widget.color.toARGB32());
      }
    }
    if (_drawingPointer == event.pointer) {
      if (!cancel) _append(event);
      final live = _scene.live;
      _scene.live = null;
      _drawingPointer = null;
      if (!cancel &&
          live != null &&
          _strokeLayer == widget.editor.document.activeLayerId) {
        widget.editor.addStroke(
          InkStroke(
            points: live.points,
            color: live.color,
            width: live.width,
            opacity: live.opacity,
            brush: live.brush,
          ),
        );
      }
    }
    _pointers.remove(event.pointer);
    _fillStart = null;
    if (_pointers.isEmpty) {
      _gesture = false;
    } else if (_gesture && (_pointers.length >= 2 || widget.handMode)) {
      _startGesture();
    }
    _scene.changed();
  }

  @override
  void dispose() {
    widget.controller._reset = null;
    widget.editor.removeListener(_documentChanged);
    _scene.dispose();
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      if (size != _viewport) {
        _viewport = size;
        final doc = widget.editor.document;
        _fit = math.min(
          (size.width - 40) / doc.width,
          (size.height - 48) / doc.height,
        );
        _fit = math.max(.01, _fit);
        _scene.scale = _fit;
        _scene.offset = Offset(
          (size.width - doc.width * _fit) / 2,
          (size.height - doc.height * _fit) / 2,
        );
        _scene.live = null;
        _pointers.clear();
        _drawingPointer = null;
        _gesture = false;
      }
      return Semantics(
        label: 'Drawing canvas. Draw with one finger or stylus. Pan and zoom with two fingers.',
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: (event) => _up(event, cancel: true),
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _ViewportPainter(
                scene: _scene,
                editor: widget.editor,
                cache: _cache,
                selected: widget.objectMode
                    ? widget.selectedDecorationId
                    : null,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _CanvasScene extends ChangeNotifier {
  CanvasDecoration? decorationPreview;
  InkStroke? live;
  double scale = 1;
  Offset offset = Offset.zero;
  void changed() => notifyListeners();
}

class _ViewportPainter extends CustomPainter {
  final _CanvasScene scene;
  final DrawingEditor editor;
  final DrawingRenderCache cache;
  final String? selected;
  _ViewportPainter({
    required this.scene,
    required this.editor,
    required this.cache,
    this.selected,
  }) : super(repaint: scene);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2EEE8),
    );
    final dots = Paint()..color = const Color(0xFFE0D8CC);
    for (double x = 12; x < size.width; x += 22) {
      for (double y = 12; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), .7, dots);
      }
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(scene.offset.dx, scene.offset.dy);
    canvas.scale(scene.scale);
    final doc = editor.document;
    final bounds = Rect.fromLTWH(
      0,
      0,
      doc.width.toDouble(),
      doc.height.toDouble(),
    );
    canvas.drawShadow(
      Path()..addRect(bounds),
      plum.withValues(alpha: .16),
      12 / scene.scale,
      true,
    );
    paintDocument(
      canvas,
      doc,
      cache,
      live: scene.live,
      decorationPreview: scene.decorationPreview,
    );
    for (final original in doc.decorations.where((d) => d.id == selected)) {
      final item = scene.decorationPreview ?? original;
      canvas.save();
      canvas.translate(item.center.dx, item.center.dy);
      canvas.rotate(item.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: item.size * 1.1,
          height: item.size * 1.1,
        ),
        Paint()
          ..color = const Color(0xFF8050EF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scene.scale,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ViewportPainter oldDelegate) => true;
}
