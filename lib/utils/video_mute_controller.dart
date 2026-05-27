import 'package:flutter/foundation.dart';

/// App-wide mute state for video playback in feeds and reels.
class VideoMuteController {
  VideoMuteController._();

  static bool _isMuted = true;
  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(true);

  static bool get isMuted => _isMuted;

  /// Applies the default mute flag from post feed UI config at startup.
  static void applyDefaultMuted(bool defaultMuted) {
    setMuted(defaultMuted);
  }

  static void setMuted(bool muted) {
    if (_isMuted == muted) return;
    _isMuted = muted;
    notifier.value = muted;
  }

  static void toggle() => setMuted(!_isMuted);
}
