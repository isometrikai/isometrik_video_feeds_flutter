import 'package:flutter/foundation.dart';

/// App-wide playback speed for feed and reel videos (YouTube-style).
class VideoPlaybackSpeedController {
  VideoPlaybackSpeedController._();

  static const List<double> defaultSpeeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
  ];

  static double _speed = 1.0;
  static final ValueNotifier<double> notifier = ValueNotifier<double>(1.0);

  static double get speed => _speed;

  static void setSpeed(double speed) {
    final normalized = speed <= 0 ? 1.0 : speed;
    if (_speed == normalized) return;
    _speed = normalized;
    notifier.value = normalized;
  }

  static void reset() => setSpeed(1.0);

  /// Formats a rate for UI chips (e.g. `1x`, `1.5x`, `0.75x`).
  static String labelFor(double speed) {
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()}x';
    }
    final trimmed = speed.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    final cleaned = trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return '${cleaned}x';
  }
}
