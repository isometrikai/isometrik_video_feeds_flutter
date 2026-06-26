import 'package:flutter/foundation.dart';

/// App-wide mute state for video playback in feeds and reels.
class VideoMuteController {
  VideoMuteController._();

  static bool _isMuted = false;
  static bool _userHasOverridden = false;
  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(false);

  static bool get isMuted => _isMuted;

  /// Applies the default mute flag from post feed UI config at startup.
  /// Skipped after the user toggles mute so config re-applies (theme, login
  /// sheet, session clear) do not reset their choice.
  static void applyDefaultMuted(bool defaultMuted) {
    if (_userHasOverridden) return;
    setMuted(defaultMuted);
  }

  static void setMuted(bool muted) {
    if (_isMuted == muted) return;
    _isMuted = muted;
    notifier.value = muted;
  }

  static void toggle() {
    _userHasOverridden = true;
    setMuted(!_isMuted);
  }
}
