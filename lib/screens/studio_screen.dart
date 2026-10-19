import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../drawing/document.dart';
import '../drawing/drawing_canvas.dart';
import '../drawing/editor.dart';
import '../drawing/renderer.dart';
import '../storage/sketch_store.dart';
import '../theme.dart';
import '../coloring/art_catalog.dart';
import '../coloring/celebration.dart';

const palette = [
  Color(0xFF292034),
  Color(0xFF8050EF),
  Color(0xFFB45CE0),
  Color(0xFFFF786B),
  Color(0xFFE4A950),
  Color(0xFF559D88),
  Color(0xFF548AC6),
  Colors.white,
];

class StudioScreen extends StatefulWidget {
  final SketchDocument document;
  final SketchStore store;
  const StudioScreen({super.key, required this.document, required this.store});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen>
    with WidgetsBindingObserver {
  late final DrawingEditor _editor;
  final _canvas = DrawingCanvasController();
  Timer? _saveTimer;
  BrushKind _brush = BrushKind.pen;
  Color _color = palette.first;
  double _width = 8, _opacity = 1;
  bool _hand = false, _leaving = false, _exporting = false;
  String _saveStatus = 'Saved on device';
  int _revision = 0;
  bool _fillMode = false, _celebrating = false;
  int _lastFilledCount = 0;
  @override
  void initState() {
    super.initState();
    _editor = DrawingEditor(widget.document);
    _fillMode = widget.document.artworkId != null;
    _lastFilledCount = widget.document.regionColors.length;
    _editor.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    _revision++;
    setState(() => _saveStatus = 'Saving…');
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 650), _save);
    final doc = _editor.document;
    if (doc.artworkId != null) {
      final total = ArtCatalog.design(doc.artworkId!).regions.length;
      final justFinished =
          _lastFilledCount < total &&
          doc.regionColors.length >= total &&
          !doc.completed;
      _lastFilledCount = doc.regionColors.length;
      if (justFinished && !_celebrating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _finish();
        });
      }
    }
  }

  Future<void> _finish() async {
    if (_celebrating || _leaving) return;
    if (_editor.document.regionColors.isEmpty &&
        _editor.document.strokeCount == 0) {
      _snack('Add a little colour first, then celebrate your artwork.');
      return;
    }
    setState(() => _celebrating = true);
    _editor.markCompleted();
    final saved = await _save();
    if (saved && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => CompletionDialog(document: _editor.document),
      );
    }
    if (mounted) setState(() => _celebrating = false);
  }

  void _showReference() {
    final artId = _editor.document.artworkId!;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back to painting',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Colour inspiration'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    minScale: .7,
                    maxScale: 5,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(painter: ArtworkPainter(artId)),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Follow this palette, or make it completely yours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_fullscreen_rounded),
                      label: const Text('Minimise · back to painting'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _save() async {
    final revision = _revision;
    final document = _editor.document;
    try {
      await widget.store.save(document);
      if (mounted && revision == _revision) {
        setState(() => _saveStatus = 'Saved on device');
      }
      return true;
    } catch (_) {
      if (mounted) setState(() => _saveStatus = 'Save failed · tap to retry');
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _saveTimer?.cancel();
      unawaited(_save());
    }
  }

  Future<void> _leave() async {
    if (_leaving || _exporting || _celebrating) return;
    setState(() => _leaving = true);
    _saveTimer?.cancel();
    final saved = await _save();
    if (!saved) {
      if (mounted) {
        setState(() => _leaving = false);
        _snack(
          'Your latest changes are not saved. Free up storage, then tap the save status to retry.',
        );
      }
      return;
    }
    try {
      final doc = _editor.document;
      await widget.store.saveThumbnail(
        doc.id,
        await renderPng(doc, maxSide: 420),
      );
      await FileImage(widget.store.thumbnail(doc.id)).evict();
    } catch (_) {
      /* The editable project is saved even if the preview fails. */
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  Future<void> _rename() async {
    if (_leaving || _celebrating) return;
    final title = await requestName(context, _editor.document.title);
    if (title != null && mounted) _editor.rename(title);
  }

  Future<void> _export() async {
    if (_exporting || _leaving || _celebrating) return;
    final transparent = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let your work travel',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Export full-resolution PNG. Save or share from the next screen.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: violet),
                title: const Text('White background'),
                subtitle: const Text('Ready to post or print'),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_rounded, color: violet),
                title: const Text('Transparent background'),
                subtitle: const Text('Just your strokes, no paper'),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (transparent == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      final doc = _editor.document;
      final bytes = await renderPng(doc, transparent: transparent);
      final directory = Directory(
        '${(await getTemporaryDirectory()).path}/sketchora_exports',
      );
      await directory.create(recursive: true);
      // Keep recent exports available for receiving apps; prune older sessions.
      await for (final entry in directory.list()) {
        if (entry is File &&
            DateTime.now().difference((await entry.stat()).modified).inDays >
                2) {
          await entry.delete();
        }
      }
      final safeName = doc.title
          .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
          .trim();
      final file = File(
        '${directory.path}/${safeName.isEmpty ? 'Sketchora' : safeName}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          title: doc.title,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        _snack(
          'Export did not finish. Your sketch is still here. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showColors() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _ColorSheet(
      initial: _color,
      onSelect: (color) => setState(() => _color = color),
    ),
  );
  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _editor.document.artworkId == null
              ? 'Clear this layer?'
              : 'Reset this colouring?',
        ),
        content: Text(
          _editor.document.artworkId == null
              ? 'Other layers stay as they are. You can undo this change.'
              : 'Colours and brush marks will be cleared. The outline stays. You can undo this change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      if (_editor.document.artworkId == null) {
        _editor.clearLayer();
      } else {
        _editor.resetColoring();
      }
    }
  }

  void _showLayers() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _LayerSheet(editor: _editor),
  );
  @override
  void dispose() {
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _editor.removeListener(_changed);
    _editor.dispose();
    _canvas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Save and return to studio',
            onPressed: _leaving ? null : _leave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          title: InkWell(
            onTap: _rename,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editor.document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_editor.document.width} × ${_editor.document.height} · ${_editor.document.layers.length} layers',
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
          actions: [
            if (_editor.document.artworkId != null)
              IconButton(
                tooltip: 'Finish artwork',
                onPressed: _leaving ? null : _finish,
                icon: const Icon(Icons.celebration_outlined, color: coral),
              ),
            IconButton(
              tooltip: 'Undo',
              onPressed: !_leaving && !_celebrating && _editor.canUndo
                  ? _editor.undo
                  : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: !_leaving && !_celebrating && _editor.canRedo
                  ? _editor.redo
                  : null,
              icon: const Icon(Icons.redo_rounded),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton.filled(
                tooltip: 'Export PNG',
                onPressed: _exporting || _leaving ? null : _export,
                icon: _exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 20),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: _leaving || _celebrating,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _save,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _saveStatus.startsWith('Save failed')
                                      ? Icons.error_outline_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 13,
                                  color: _saveStatus.startsWith('Save failed')
                                      ? coral
                                      : muted,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    _leaving
                                        ? 'Finishing up…'
                                        : _editor.document.artworkId == null
                                        ? _saveStatus
                                        : '${_editor.document.completed ? 'Completed · ' : ''}${_editor.document.regionColors.length}/${ArtCatalog.design(_editor.document.artworkId!).regions.length} areas · $_saveStatus',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _canvas.resetView,
                        icon: const Icon(Icons.fit_screen_rounded, size: 16),
                        label: const Text(
                          'Fit',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showLayers,
                        icon: const Icon(Icons.layers_outlined, size: 16),
                        label: const Text(
                          'Layers',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (wide)
                        Container(
                          width: 82,
                          color: Colors.white,
                          child: _tools(vertical: true),
                        ),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DrawingCanvas(
                              editor: _editor,
                              controller: _canvas,
                              brush: _brush,
                              color: _color,
                              width: _width,
                              opacity: _opacity,
                              handMode: _hand,
                              fillMode: _fillMode,
                            ),
                            if (_editor.document.artworkId != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Semantics(
                                  button: true,
                                  label: 'Open full colour sample',
                                  child: Material(
                                    color: Colors.white,
                                    elevation: 0,
                                    borderRadius: BorderRadius.circular(14),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: _showReference,
                                      child: Padding(
                                        padding: const EdgeInsets.all(7),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: 74,
                                              height: 74,
                                              child: CustomPaint(
                                                painter: ArtworkPainter(
                                                  _editor.document.artworkId!,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Sample',
                                                  style: TextStyle(
                                                    color: violet,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.open_in_full_rounded,
                                                  size: 11,
                                                  color: violet,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: paper,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Column(
                    children: [
                      if (!wide) _tools(vertical: false),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: palette
                              .map(
                                (color) => Semantics(
                                  button: true,
                                  label:
                                      'Choose colour ${color.toARGB32().toRadixString(16)}',
                                  selected: color == _color,
                                  child: InkWell(
                                    onTap: () => setState(() => _color = color),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color == _color
                                              ? violet
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFE4DDDF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.line_weight_rounded,
                            size: 16,
                            color: muted,
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${_width.round()}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              semanticFormatterCallback: (value) =>
                                  'Brush size ${value.round()}',
                              min: 1,
                              max: 64,
                              value: _width,
                              onChanged: (value) =>
                                  setState(() => _width = value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.opacity_rounded,
                            size: 16,
                            color: muted,
                          ),
                          Expanded(
                            child: Slider(
                              semanticFormatterCallback: (value) =>
                                  'Opacity ${(value * 100).round()} percent',
                              min: .05,
                              max: 1,
                              value: _opacity,
                              onChanged: (value) =>
                                  setState(() => _opacity = value),
                            ),
                          ),
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${(_opacity * 100).round()}%',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(
                          !_editor.document.activeLayer.visible
                              ? 'This layer is hidden. Show it in Layers to draw.'
                              : _fillMode && !_hand
                              ? 'Tap a closed area to fill · sample is only a guide'
                              : _hand
                              ? 'Drag to move your canvas · pinch to zoom'
                              : 'One finger to draw · two fingers to move & zoom',
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tools({required bool vertical}) {
    final children = <Widget>[
      if (_editor.document.artworkId != null)
        _Tool(
          icon: Icons.format_color_fill_rounded,
          label: 'Fill',
          selected: _fillMode && !_hand,
          onTap: () => setState(() {
            _fillMode = true;
            _hand = false;
          }),
        ),
      for (final item in [
        (BrushKind.pen, Icons.edit_rounded, 'Pen'),
        (BrushKind.pencil, Icons.draw_outlined, 'Pencil'),
        (BrushKind.marker, Icons.brush_rounded, 'Marker'),
        (BrushKind.eraser, Icons.backspace_outlined, 'Eraser'),
      ])
        _Tool(
          icon: item.$2,
          label: item.$3,
          selected: !_hand && !_fillMode && _brush == item.$1,
          onTap: () => setState(() {
            _brush = item.$1;
            _hand = false;
            _fillMode = false;
          }),
        ),
      _Tool(
        icon: Icons.pan_tool_outlined,
        label: 'Move',
        selected: _hand,
        onTap: () => setState(() => _hand = !_hand),
      ),
      _Tool(
        icon: Icons.circle,
        label: 'Colour',
        color: _color,
        onTap: _showColors,
      ),
      _Tool(icon: Icons.delete_sweep_outlined, label: 'Clear', onTap: _clear),
    ];
    return vertical
        ? SingleChildScrollView(child: Column(children: children))
        : _editor.document.artworkId == null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children.map((child) => Expanded(child: child)).toList(),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: children
                  .map((child) => SizedBox(width: 52, child: child))
                  .toList(),
            ),
          );
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 58),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? violet.withValues(alpha: .1) : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color ?? (selected ? violet : muted),
                size: 22,
                shadows: color == Colors.white
                    ? const [Shadow(color: muted, blurRadius: 3)]
                    : null,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? violet : muted,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ColorSheet extends StatefulWidget {
  final Color initial;
  final ValueChanged<Color> onSelect;
  const _ColorSheet({required this.initial, required this.onSelect});
  @override
  State<_ColorSheet> createState() => _ColorSheetState();
}

class _ColorSheetState extends State<_ColorSheet> {
  late HSVColor _hsv;
  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  void _update(HSVColor value) {
    setState(() => _hsv = value);
    widget.onSelect(value.toColor());
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Find your colour',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hsv.toColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: muted.withValues(alpha: .3)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: palette
                  .map(
                    (color) => Semantics(
                      label: 'Colour ${color.toARGB32().toRadixString(16)}',
                      button: true,
                      child: InkWell(
                        onTap: () => _update(HSVColor.fromColor(color)),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  color.toARGB32() == _hsv.toColor().toARGB32()
                                  ? violet
                                  : const Color(0xFFE5DFEB),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            for (final control in [
              ('Hue', _hsv.hue, 360.0, (double v) => _hsv.withHue(v)),
              (
                'Saturation',
                _hsv.saturation,
                1.0,
                (double v) => _hsv.withSaturation(v),
              ),
              ('Brightness', _hsv.value, 1.0, (double v) => _hsv.withValue(v)),
            ])
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      control.$1,
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      label: control.$1,
                      max: control.$3,
                      value: control.$2,
                      semanticFormatterCallback: (value) =>
                          '${control.$1} ${value.round()}',
                      onChanged: (v) => _update(control.$4(v)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LayerSheet extends StatelessWidget {
  final DrawingEditor editor;
  const _LayerSheet({required this.editor});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .65,
      child: AnimatedBuilder(
        animation: editor,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Layers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: editor.document.layers.length < 12
                        ? editor.addLayer
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    label: Text('${editor.document.layers.length}/12'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top layer appears above the others.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: editor.document.layers.reversed.map((layer) {
                  final active = layer.id == editor.document.activeLayerId;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Material(
                      color: active ? const Color(0xFFEEE6FD) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () => editor.selectLayer(layer.id),
                            leading: IconButton(
                              tooltip: layer.visible
                                  ? 'Hide ${layer.name}'
                                  : 'Show ${layer.name}',
                              onPressed: () => editor.toggleLayer(layer.id),
                              icon: Icon(
                                layer.visible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: violet,
                              ),
                            ),
                            title: Text(
                              layer.name,
                              style: TextStyle(
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            subtitle: Text(
                              '${layer.strokes.length} strokes',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Layer options',
                              onSelected: (value) {
                                if (value == 'up') {
                                  editor.moveLayer(layer.id, 1);
                                }
                                if (value == 'down') {
                                  editor.moveLayer(layer.id, -1);
                                }
                                if (value == 'delete') {
                                  editor.deleteLayer(layer.id);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'up',
                                  enabled:
                                      layer.id !=
                                      editor.document.layers.last.id,
                                  child: const Text('Move up'),
                                ),
                                PopupMenuItem(
                                  value: 'down',
                                  enabled:
                                      layer.id !=
                                      editor.document.layers.first.id,
                                  child: const Text('Move down'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  enabled: editor.document.layers.length > 1,
                                  child: const Text(
                                    'Delete layer (undo available)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: _LayerOpacity(
                                layer: layer,
                                onEnd: (value) =>
                                    editor.setLayerOpacity(layer.id, value),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LayerOpacity extends StatefulWidget {
  final InkLayer layer;
  final ValueChanged<double> onEnd;
  const _LayerOpacity({required this.layer, required this.onEnd});
  @override
  State<_LayerOpacity> createState() => _LayerOpacityState();
}

class _LayerOpacityState extends State<_LayerOpacity> {
  double? _value;
  @override
  void didUpdateWidget(_LayerOpacity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layer != widget.layer) _value = null;
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text('Opacity', style: TextStyle(fontSize: 11, color: muted)),
      Expanded(
        child: Slider(
          value: _value ?? widget.layer.opacity,
          onChanged: (value) => setState(() => _value = value),
          onChangeEnd: widget.onEnd,
        ),
      ),
      Text(
        '${((_value ?? widget.layer.opacity) * 100).round()}%',
        style: const TextStyle(fontSize: 11, color: muted),
      ),
    ],
  );
}
