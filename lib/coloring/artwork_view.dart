import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'art_catalog.dart';

/// Gallery tiles decode a small preview, never a full colouring mask.
class ArtworkView extends StatefulWidget {
  final String id;
  const ArtworkView(this.id, {super.key});
  @override
  State<ArtworkView> createState() => _ArtworkViewState();
}

class _ArtworkViewState extends State<ArtworkView> {
  ui.Image? _image;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ArtworkView old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _image?.dispose();
      _image = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.id, entry = ArtCatalog.entry(widget.id);
    if (entry?.raster != true) return;
    try {
      final bytes = await rootBundle.load(referenceAsset(entry!));
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: entry.illustrated ? 384 : 576,
      );
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      if (!mounted || widget.id != id) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted && widget.id == id) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = ArtCatalog.entry(widget.id);
    if (entry?.raster != true) {
      return CustomPaint(painter: ArtworkPainter(widget.id));
    }
    if (_failed) return const Center(child: Icon(Icons.broken_image_outlined));
    if (_image == null) {
      return const Center(
        child: Icon(Icons.palette_outlined, color: Color(0xFFB5A4C6)),
      );
    }
    return CustomPaint(painter: _PreviewPainter(_image!, entry!.illustrated));
  }
}

class _PreviewPainter extends CustomPainter {
  final ui.Image image;
  final bool square;
  _PreviewPainter(this.image, this.square);
  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      square ? 0 : image.width / 2,
      0,
      square ? image.width.toDouble() : image.width / 2,
      image.height.toDouble(),
    );
    final dest = applyBoxFit(BoxFit.contain, source.size, size).destination;
    canvas.drawImageRect(
      image,
      source,
      Alignment.center.inscribe(dest, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.image != image || old.square != square;
}
