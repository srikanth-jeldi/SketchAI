import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const stickerNames = [
  'Bloom',
  'Heart',
  'Star',
  'Sunshine',
  'Butterfly',
  'Leaf',
  'Sparkle',
  'Cloud',
  'Moon',
  'Rainbow',
  'Smile',
  'Crown',
  'Cat',
  'Fish',
  'Balloon',
  'Lightning',
  'Music',
  'Speech bubble',
  'Gift',
  'Diamond',
  'Tulip',
  'Rocket',
  'Coffee',
  'Bow',
];

/// Original, resolution-independent stickers and editable text. Coordinates are
/// document pixels; objects stay editable after saving and are exported without handles.
class CanvasDecoration {
  final String id;
  final int sticker;
  final String text;
  final Offset center;
  final double size, rotation, opacity;
  final int color;
  final bool flipped;
  final String imageData;
  final int crop, textStyle;
  final double cropZoom, cropX, cropY;
  final bool frame;
  final bool behindInk;
  CanvasDecoration({
    required this.id,
    this.sticker = 0,
    this.text = '',
    required this.center,
    this.size = 240,
    this.rotation = 0,
    this.opacity = 1,
    this.color = 0xFF8050EF,
    this.flipped = false,
    this.imageData = '',
    this.crop = 0,
    this.textStyle = 0,
    this.cropZoom = 1,
    this.cropX = 0,
    this.cropY = 0,
    this.frame = false,
    this.behindInk = false,
  }) {
    if (imageData.length > 2200000 ||
        crop < 0 ||
        crop > 2 ||
        textStyle < 0 ||
        textStyle > 2 ||
        !cropZoom.isFinite ||
        cropZoom < 1 ||
        cropZoom > 4 ||
        !cropX.isFinite ||
        cropX.abs() > 1 ||
        !cropY.isFinite ||
        cropY.abs() > 1 ||
        id.isEmpty ||
        sticker < 0 ||
        sticker >= stickerNames.length ||
        text.length > 200 ||
        !center.dx.isFinite ||
        !center.dy.isFinite ||
        !size.isFinite ||
        size < 20 ||
        size > 4096 ||
        !rotation.isFinite ||
        !opacity.isFinite ||
        opacity < 0 ||
        opacity > 1) {
      throw const FormatException('Invalid decoration');
    }
  }
  CanvasDecoration copyWith({
    Offset? center,
    double? size,
    double? rotation,
    double? opacity,
    int? color,
    bool? flipped,
    String? text,
    String? id,
    String? imageData,
    int? crop,
    int? textStyle,
    double? cropZoom,
    double? cropX,
    double? cropY,
    bool? frame,
    bool? behindInk,
  }) => CanvasDecoration(
    id: id ?? this.id,
    sticker: sticker,
    text: text ?? this.text,
    center: center ?? this.center,
    size: size ?? this.size,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    color: color ?? this.color,
    flipped: flipped ?? this.flipped,
    imageData: imageData ?? this.imageData,
    crop: crop ?? this.crop,
    textStyle: textStyle ?? this.textStyle,
    cropZoom: cropZoom ?? this.cropZoom,
    cropX: cropX ?? this.cropX,
    cropY: cropY ?? this.cropY,
    frame: frame ?? this.frame,
    behindInk: behindInk ?? this.behindInk,
  );
  Offset local(Offset p) {
    final v = p - center, c = math.cos(rotation), s = math.sin(rotation);
    return Offset((v.dx * c + v.dy * s) / size, (-v.dx * s + v.dy * c) / size);
  }

  bool contains(Offset p) {
    final q = local(p);
    return q.dx.abs() <= .55 && q.dy.abs() <= .55;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sticker': sticker,
    'text': text,
    'x': center.dx,
    'y': center.dy,
    'size': size,
    'rotation': rotation,
    'opacity': opacity,
    'color': color,
    'flipped': flipped,
    if (imageData.isNotEmpty) 'imageData': imageData,
    'crop': crop,
    'textStyle': textStyle,
    'cropZoom': cropZoom,
    'cropX': cropX,
    'cropY': cropY,
    'frame': frame,
    'behindInk': behindInk,
  };
  factory CanvasDecoration.fromJson(Map<String, dynamic> j) => CanvasDecoration(
    id: j['id'] as String,
    sticker: j['sticker'] as int,
    text: j['text'] as String,
    center: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
    size: (j['size'] as num).toDouble(),
    rotation: (j['rotation'] as num).toDouble(),
    opacity: (j['opacity'] as num).toDouble(),
    color: j['color'] as int,
    flipped: j['flipped'] as bool,
    imageData: j['imageData'] as String? ?? '',
    crop: j['crop'] as int? ?? 0,
    textStyle: j['textStyle'] as int? ?? 0,
    cropZoom: (j['cropZoom'] as num? ?? 1).toDouble(),
    cropX: (j['cropX'] as num? ?? 0).toDouble(),
    cropY: (j['cropY'] as num? ?? 0).toDouble(),
    frame: j['frame'] as bool? ?? false,
    behindInk: j['behindInk'] as bool? ?? false,
  );
}

void paintDecoration(Canvas canvas, CanvasDecoration item) {
  canvas.save();
  canvas.translate(item.center.dx, item.center.dy);
  canvas.rotate(item.rotation);
  canvas.scale(item.flipped ? -item.size : item.size, item.size);
  final fill = Paint()
    ..color = Color(item.color).withValues(alpha: item.opacity);
  final ink = Paint()
    ..color = const Color(0xFF292034).withValues(alpha: item.opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .025
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  void shape(Path p) {
    canvas.drawPath(p, fill);
    canvas.drawPath(p, ink);
  }

  void oval(double x, double y, double w, double h) => shape(
    Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h)),
  );
  void star(int points, double outer, double inner) => shape(
    Path()..addPolygon(
      List.generate(points * 2, (i) {
        final a = -math.pi / 2 + i * math.pi / points,
            r = i.isEven ? outer : inner;
        return Offset(math.cos(a) * r, math.sin(a) * r);
      }),
      true,
    ),
  );
  if (item.imageData.isNotEmpty) {
    final image = DecorationPhotos.images[item.imageData];
    final box = const Rect.fromLTWH(-.48, -.48, .96, .96);
    final clip = Path();
    if (item.crop == 1) {
      clip.addOval(box);
    } else {
      clip.addRRect(
        RRect.fromRectAndRadius(box, Radius.circular(item.crop == 2 ? .12 : 0)),
      );
    }
    canvas.save();
    canvas.clipPath(clip);
    if (image != null) {
      final fitting = applyBoxFit(
        item.crop == 0 ? BoxFit.contain : BoxFit.cover,
        Size(image.width.toDouble(), image.height.toDouble()),
        box.size,
      );
      final source = Alignment(item.cropX, item.cropY).inscribe(
        fitting.source / item.cropZoom,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      );
      final target = Alignment.center.inscribe(fitting.destination, box);
      canvas.drawImageRect(
        image,
        source,
        target,
        Paint()
          ..color = Colors.white.withValues(alpha: item.opacity)
          ..filterQuality = FilterQuality.medium,
      );
    } else {
      canvas.drawRect(box, Paint()..color = Colors.grey.shade200);
    }
    canvas.restore();
    if (item.frame) {
      canvas.drawPath(
        clip,
        Paint()
          ..color = fill.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = .045,
      );
    }
  } else if (item.text.isNotEmpty) {
    final painter = TextPainter(
      text: TextSpan(
        text: item.text,
        style: TextStyle(
          fontFamily: item.textStyle == 1 ? 'DMSerif' : 'DMSans',
          fontStyle: item.textStyle == 2 ? FontStyle.italic : FontStyle.normal,
          fontWeight: FontWeight.w700,
          // Shape at normal pixel sizes so multiline font metrics cannot round
          // to zero before the sticker's canvas transform is applied.
          fontSize: 180,
          height: 1.2,
          color: fill.color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 940);
    canvas.save();
    final textScale =
        math.min(1.0, 940 / math.max(painter.height, painter.width)) / 1000;
    canvas.clipRect(const Rect.fromLTWH(-.5, -.5, 1, 1));
    canvas.scale(textScale);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    painter.dispose();
    canvas.restore();
  } else {
    switch (item.sticker) {
      case 0:
        for (var i = 0; i < 8; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 4);
          oval(0, -.25, .3, .42);
          canvas.restore();
        }
        final old = fill.color;
        fill.color = const Color(0xFFFFCB67).withValues(alpha: item.opacity);
        oval(0, 0, .3, .3);
        fill.color = old;
      case 1:
        shape(
          Path()
            ..moveTo(0, .43)
            ..cubicTo(-.8, -.05, -.35, -.72, 0, -.25)
            ..cubicTo(.35, -.72, .8, -.05, 0, .43)
            ..close(),
        );
      case 2:
        star(5, .47, .22);
      case 3:
        star(12, .48, .34);
        oval(0, 0, .58, .58);
      case 4:
        for (final side in [-1, 1]) {
          oval(side * .23, -.15, .42, .5);
          oval(side * .2, .22, .35, .32);
        }
        canvas.drawLine(
          const Offset(0, -.3),
          const Offset(0, .4),
          ink..strokeWidth = .065,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0, -.25)
            ..quadraticBezierTo(-.2, -.6, -.22, -.38)
            ..moveTo(0, -.25)
            ..quadraticBezierTo(.2, -.6, .22, -.38),
          ink..strokeWidth = .025,
        );
      case 5:
        shape(
          Path()
            ..moveTo(-.4, .4)
            ..cubicTo(-.5, -.2, -.1, -.5, .43, -.43)
            ..cubicTo(.5, .1, .15, .5, -.4, .4)
            ..close(),
        );
        canvas.drawLine(const Offset(-.4, .4), const Offset(.28, -.28), ink);
      case 6:
        star(4, .48, .11);
      case 7:
        shape(
          Path()
            ..moveTo(-.38, .24)
            ..cubicTo(-.7, .12, -.42, -.3, -.2, -.2)
            ..cubicTo(-.12, -.62, .42, -.45, .38, -.14)
            ..cubicTo(.7, -.08, .55, .3, .35, .27)
            ..lineTo(-.38, .24)
            ..close(),
        );
      case 8:
        shape(
          Path()
            ..moveTo(.25, -.43)
            ..cubicTo(-.55, -.48, -.6, .48, .18, .45)
            ..cubicTo(-.16, .22, -.22, -.12, .25, -.43)
            ..close(),
        );
      case 9:
        final colours = [
          Color(item.color),
          const Color(0xFFFF786B),
          const Color(0xFFFFCB67),
          const Color(0xFF559D88),
        ];
        for (var i = 0; i < 4; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(0, .3), radius: .43 - i * .09),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = colours[i].withValues(alpha: item.opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .075
              ..strokeCap = StrokeCap.round,
          );
        }
      case 10:
        oval(0, 0, .9, .9);
        canvas.drawCircle(
          const Offset(-.16, -.12),
          .035,
          Paint()..color = ink.color,
        );
        canvas.drawCircle(
          const Offset(.16, -.12),
          .035,
          Paint()..color = ink.color,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-.22, -.02, .44, .35),
          0,
          math.pi,
          false,
          ink,
        );
      case 11:
        shape(
          Path()
            ..moveTo(-.4, .3)
            ..lineTo(-.47, -.25)
            ..lineTo(-.18, -.05)
            ..lineTo(0, -.45)
            ..lineTo(.18, -.05)
            ..lineTo(.47, -.25)
            ..lineTo(.4, .3)
            ..close(),
        );
        canvas.drawLine(const Offset(-.38, .18), const Offset(.38, .18), ink);
      case 12:
        shape(
          Path()
            ..moveTo(-.4, .3)
            ..lineTo(-.4, -.42)
            ..lineTo(-.12, -.2)
            ..quadraticBezierTo(0, -.25, .12, -.2)
            ..lineTo(.4, -.42)
            ..lineTo(.4, .3)
            ..quadraticBezierTo(0, .55, -.4, .3)
            ..close(),
        );
        for (final side in [-1, 1]) {
          canvas.drawCircle(
            Offset(side * .18, 0),
            .03,
            Paint()..color = ink.color,
          );
          canvas.drawLine(Offset(side * .12, .2), Offset(side * .47, .14), ink);
        }
        canvas.drawPath(
          Path()
            ..moveTo(-.06, .12)
            ..lineTo(0, .19)
            ..lineTo(.06, .12),
          ink,
        );
      case 13:
        shape(
          Path()..addPolygon([
            const Offset(-.2, 0),
            const Offset(-.47, -.28),
            const Offset(-.47, .28),
          ], true),
        );
        oval(.08, 0, .7, .58);
        canvas.drawCircle(
          const Offset(.3, -.08),
          .035,
          Paint()..color = ink.color,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-.1, -.24, .25, .48),
          -math.pi / 2,
          math.pi,
          false,
          ink,
        );
      case 14:
        canvas.drawPath(
          Path()
            ..moveTo(0, .2)
            ..cubicTo(-.2, .3, .2, .4, 0, .5),
          ink,
        );
        oval(0, -.12, .63, .72);
        shape(
          Path()..addPolygon([
            const Offset(0, .2),
            const Offset(-.06, .3),
            const Offset(.06, .3),
          ], true),
        );
      case 15:
        shape(
          Path()..addPolygon([
            const Offset(.08, -.48),
            const Offset(-.33, .08),
            const Offset(-.02, .08),
            const Offset(-.12, .48),
            const Offset(.36, -.13),
            const Offset(.08, -.13),
          ], true),
        );
      case 16:
        canvas.drawPath(
          Path()
            ..moveTo(-.12, .28)
            ..lineTo(-.12, -.3)
            ..lineTo(.33, -.43)
            ..lineTo(.33, .18),
          ink..strokeWidth = .05,
        );
        oval(-.22, .28, .25, .18);
        oval(.23, .18, .25, .18);
      case 17:
        shape(
          Path()
            ..moveTo(-.45, -.3)
            ..lineTo(.45, -.3)
            ..lineTo(.45, .2)
            ..lineTo(0, .2)
            ..lineTo(-.26, .45)
            ..lineTo(-.22, .2)
            ..lineTo(-.45, .2)
            ..close(),
        );
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(-.2 + i * .2, -.05),
            .025,
            Paint()..color = ink.color,
          );
        }
      case 18:
        shape(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-.38, -.1, .76, .54),
              const Radius.circular(.03),
            ),
          ),
        );
        shape(Path()..addRect(const Rect.fromLTWH(-.44, -.23, .88, .2)));
        canvas.drawLine(const Offset(0, -.23), const Offset(0, .43), ink);
        oval(-.15, -.35, .29, .18);
        oval(.15, -.35, .29, .18);
      case 19:
        shape(
          Path()..addPolygon([
            const Offset(-.46, -.12),
            const Offset(-.25, -.4),
            const Offset(.25, -.4),
            const Offset(.46, -.12),
            const Offset(0, .46),
          ], true),
        );
        canvas.drawPath(
          Path()
            ..moveTo(-.46, -.12)
            ..lineTo(.46, -.12)
            ..moveTo(-.25, -.4)
            ..lineTo(-.12, -.12)
            ..lineTo(0, .46)
            ..lineTo(.12, -.12)
            ..lineTo(.25, -.4),
          ink,
        );
      case 20:
        canvas.drawLine(
          const Offset(0, 0),
          const Offset(0, .48),
          ink..strokeWidth = .04,
        );
        shape(
          Path()
            ..moveTo(-.3, -.4)
            ..lineTo(0, -.18)
            ..lineTo(.3, -.4)
            ..cubicTo(.45, .28, -.45, .28, -.3, -.4)
            ..close(),
        );
        canvas.drawPath(
          Path()
            ..moveTo(0, .42)
            ..quadraticBezierTo(-.4, .15, -.35, .05)
            ..quadraticBezierTo(-.05, .1, 0, .42),
          ink..strokeWidth = .025,
        );
      case 21:
        shape(
          Path()..addPolygon([
            const Offset(-.19, .15),
            const Offset(-.38, .4),
            const Offset(-.38, -.05),
            const Offset(-.13, -.2),
          ], true),
        );
        shape(
          Path()..addPolygon([
            const Offset(.19, .15),
            const Offset(.38, .4),
            const Offset(.38, -.05),
            const Offset(.13, -.2),
          ], true),
        );
        shape(
          Path()
            ..moveTo(0, -.49)
            ..cubicTo(-.3, -.3, -.24, .25, -.13, .3)
            ..lineTo(.13, .3)
            ..cubicTo(.24, .25, .3, -.3, 0, -.49)
            ..close(),
        );
        oval(0, -.1, .22, .22);
        canvas.drawPath(
          Path()
            ..moveTo(-.08, .34)
            ..lineTo(0, .5)
            ..lineTo(.08, .34),
          ink,
        );
      case 22:
        oval(.34, .05, .27, .34);
        shape(
          Path()
            ..moveTo(-.35, -.18)
            ..lineTo(.25, -.18)
            ..quadraticBezierTo(.25, .4, -.05, .4)
            ..quadraticBezierTo(-.35, .4, -.35, -.18)
            ..close(),
        );
        oval(-.05, -.18, .6, .15);
        canvas.drawLine(
          const Offset(-.12, -.32),
          const Offset(-.05, -.46),
          ink,
        );
      case 23:
        shape(
          Path()
            ..moveTo(0, 0)
            ..cubicTo(-.65, -.7, -.65, .7, 0, 0)
            ..cubicTo(.65, -.7, .65, .7, 0, 0)
            ..close(),
        );
        oval(0, 0, .17, .2);
        canvas.drawPath(
          Path()
            ..moveTo(-.07, .1)
            ..lineTo(-.18, .45)
            ..lineTo(0, .35)
            ..lineTo(.18, .45)
            ..lineTo(.07, .1),
          ink,
        );
    }
  }
  canvas.restore();
}

class DecorationPhotos {
  static Future<Uint8List> normalize(Uint8List bytes) async {
    if (bytes.length <= 1600000) return bytes;
    if (bytes.length > 20000000) {
      throw const FormatException('Photo is too large');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      for (final edge in [768, 600]) {
        final scale = math.min(
          1.0,
          edge / math.max(descriptor.width, descriptor.height),
        );
        final codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (descriptor.width * scale).round()),
          targetHeight: math.max(1, (descriptor.height * scale).round()),
        );
        ui.Image? image;
        try {
          image = (await codec.getNextFrame()).image;
          final encoded = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          if (encoded.length <= 1600000) return encoded;
        } finally {
          image?.dispose();
          codec.dispose();
        }
      }
      throw const FormatException('Could not resize photo');
    } finally {
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static final images = <String, ui.Image>{};
  static final _owners = <Object, Set<String>>{};
  static void retain(Object owner, Iterable<CanvasDecoration> items) {
    _owners[owner] = items
        .where((d) => d.imageData.isNotEmpty)
        .map((d) => d.imageData)
        .toSet();
  }

  static void release(Object owner) {
    _owners.remove(owner);
    trim();
  }

  static void trim() {
    final active = _owners.values.expand((v) => v).toSet();
    for (final key
        in images.keys.where((key) => !active.contains(key)).toList()) {
      images.remove(key)?.dispose();
    }
  }

  static final _loading = <String, Future<void>>{};
  static Future<void> prepare(Iterable<CanvasDecoration> items) async {
    final wanted = items
        .where((d) => d.imageData.isNotEmpty)
        .map((d) => d.imageData)
        .toSet();
    for (final data in wanted) {
      if (images.containsKey(data)) continue;
      await (_loading[data] ??= _decode(data));
    }
    while (images.length > 12) {
      final protected = {...wanted, ..._owners.values.expand((v) => v)};
      final unused = images.keys.where((key) => !protected.contains(key));
      if (unused.isEmpty) break;
      images.remove(unused.first)?.dispose();
    }
  }

  static Future<void> _decode(String data) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(base64Decode(data));
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final scale = math.min(
        1.0,
        1024 / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      images[data] = (await codec.getNextFrame()).image;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
      _loading.remove(data);
    }
  }
}

class StickerPreview extends CustomPainter {
  final CanvasDecoration item;
  StickerPreview(this.item);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintDecoration(
      canvas,
      item.copyWith(
        center: Offset(size.width / 2, size.height / 2),
        size: math.min(size.width, size.height) * .85,
        rotation: item.rotation,
      ),
    );
  }

  @override
  bool shouldRepaint(StickerPreview old) => old.item != item;
}
