// Original synthesized handclap crowd: no downloaded or licensed audio samples.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const rate = 22050, seconds = 3;
  final samples = Float64List(rate * seconds), random = Random(94);
  for (var clap = 0; clap < 55; clap++) {
    final start = (random.nextDouble() * 2.55 * rate).round(),
        strength = .18 + random.nextDouble() * .32;
    var previous = 0.0;
    for (var j = 0; j < rate * .16 && start + j < samples.length; j++) {
      final noise = random.nextDouble() * 2 - 1,
          filtered = noise * .7 + previous * .3;
      previous = filtered;
      samples[start + j] += filtered * exp(-j / (rate * .024)) * strength;
    }
  }
  final bytes = ByteData(44 + samples.length * 2);
  void word(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  word(0, 'RIFF');
  bytes.setUint32(4, bytes.lengthInBytes - 8, Endian.little);
  word(8, 'WAVE');
  word(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  word(36, 'data');
  bytes.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(
      44 + i * 2,
      (samples[i].clamp(-1, 1) * 23000).round(),
      Endian.little,
    );
  }
  final file = File('assets/audio/applause.wav');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes.buffer.asUint8List());
}
