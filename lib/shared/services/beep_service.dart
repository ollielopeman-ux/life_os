import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class BeepService {
  BeepService._();

  // Two players so work + rest beeps can overlap cleanly
  static final _playerA = AudioPlayer();
  static final _playerB = AudioPlayer();
  static bool _useA = true;

  static Uint8List _wav(int freqHz, int durationMs) {
    const rate = 22050;
    final n = (rate * durationMs / 1000).round();
    final buf = ByteData(44 + n * 2);

    void bytes(int o, List<int> c) {
      for (var i = 0; i < c.length; i++) {
        buf.setUint8(o + i, c[i]);
      }
    }

    bytes(0, [0x52, 0x49, 0x46, 0x46]); // RIFF
    buf.setUint32(4, 36 + n * 2, Endian.little);
    bytes(8, [0x57, 0x41, 0x56, 0x45]); // WAVE
    bytes(12, [0x66, 0x6D, 0x74, 0x20]); // fmt
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little); // PCM
    buf.setUint16(22, 1, Endian.little); // mono
    buf.setUint32(24, rate, Endian.little);
    buf.setUint32(28, rate * 2, Endian.little);
    buf.setUint16(32, 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    bytes(36, [0x64, 0x61, 0x74, 0x61]); // data
    buf.setUint32(40, n * 2, Endian.little);

    final fade = (rate * 0.015).round();
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      var a = sin(2 * pi * freqHz * t);
      if (i < fade) a *= i / fade;
      if (i > n - fade) a *= (n - i) / fade;
      buf.setInt16(44 + i * 2, (a * 28000).round().clamp(-32768, 32767), Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  // High short beep — work phase starting
  static Future<void> workBeep() => _play(880, 150);

  // Lower longer beep — rest phase starting / done
  static Future<void> restBeep() => _play(440, 300);

  static Future<void> _play(int freq, int ms) async {
    try {
      final player = _useA ? _playerA : _playerB;
      _useA = !_useA;
      await player.play(BytesSource(_wav(freq, ms)));
    } catch (_) {
      // Platform may not support audio (e.g. Windows dev builds)
    }
  }
}
