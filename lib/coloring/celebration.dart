import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../drawing/document.dart';
import '../drawing/renderer.dart';
import '../theme.dart';

class CompletionDialog extends StatefulWidget {
  final SketchDocument document;
  final bool enableAudio;
  final Uint8List? previewBytes;
  const CompletionDialog({
    super.key,
    required this.document,
    this.enableAudio = true,
    this.previewBytes,
  });
  @override
  State<CompletionDialog> createState() => _CompletionState();
}

class _CompletionState extends State<CompletionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Future<Uint8List> _preview;
  AudioPlayer? _audio;
  bool _muted = false;
  @override
  void initState() {
    super.initState();
    _preview = widget.previewBytes == null
        ? renderPng(widget.document, maxSide: 640)
        : Future.value(widget.previewBytes!);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _preview.then(
      (_) {
        if (mounted) _animation.forward();
      },
      onError: (Object _) {
        if (mounted) _animation.forward();
      },
    );
    HapticFeedback.mediumImpact();
    _play();
  }

  Future<void> _play() async {
    if (!widget.enableAudio) return;
    try {
      _audio ??= AudioPlayer();
      await _audio!.play(AssetSource('audio/applause.wav'), volume: .5);
    } catch (_) {
      /* Visual celebration remains available without audio. */
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 46,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  size: const Size(260, 46),
                  painter: _Confetti(_animation.value),
                ),
              ),
            ),
            const Text(
              'Artwork complete!',
              style: TextStyle(fontFamily: 'DMSerif', fontSize: 29),
            ),
            const SizedBox(height: 8),
            const Text(
              'Beautifully yours. Your colours are saved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Uint8List>(
              future: _preview,
              builder: (context, snapshot) => snapshot.hasData
                  ? AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        final t = MediaQuery.disableAnimationsOf(context)
                            ? 1.0
                            : _animation.value;
                        final settle = Curves.easeOutCubic.transform(
                          (t * 2).clamp(0, 1),
                        );
                        final flash = t < .14
                            ? (1 - t / .14).clamp(0, 1).toDouble()
                            : 0.0;
                        return Transform.rotate(
                          angle: (1 - settle) * -.06,
                          child: Transform.scale(
                            scale: .78 + .22 * settle,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(9, 9, 9, 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Image.memory(
                                    snapshot.data!,
                                    height: 210,
                                    fit: BoxFit.contain,
                                  ),
                                  if (flash > 0)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: ColoredBox(
                                          color: Colors.white.withValues(
                                            alpha: flash,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox(
                      height: 120,
                      child: Center(
                        child: Icon(
                          Icons.celebration_rounded,
                          color: coral,
                          size: 48,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Saved on this device · find it on Home',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: _muted ? 'Enable applause' : 'Mute applause',
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  ),
                  onPressed: () {
                    setState(() => _muted = !_muted);
                    if (_muted) {
                      _audio?.stop();
                    } else {
                      _play();
                    }
                  },
                ),
                TextButton.icon(
                  onPressed: () {
                    _animation.forward(from: 0);
                    if (!_muted) _play();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Celebrate again'),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Back to Home',
                icon: Icons.home_rounded,
                onTap: () => Navigator.pop(context, true),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep painting'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Confetti extends CustomPainter {
  final double progress;
  _Confetti(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (var i = 0; i < 42; i++) {
      final x = random.nextDouble() * size.width,
          y = (random.nextDouble() * 70 + progress * 100) % 70 - 12;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 5 + random.nextDouble() * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -5, 6, 10),
          const Radius.circular(2),
        ),
        Paint()
          ..color = [
            violet,
            coral,
            const Color(0xFFF2C76D),
            const Color(0xFF79B9AA),
          ][i % 4].withValues(alpha: 1 - progress * .65),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti oldDelegate) => oldDelegate.progress != progress;
}
