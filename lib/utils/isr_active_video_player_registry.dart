import 'dart:ui';

/// Lets [IsrVideoReelConfig] pause every mounted feed/reel [VideoPlayerWidget]
/// without importing presentation widgets (avoids circular imports).
abstract final class IsrActiveVideoPlayerRegistry {
  static final Set<VoidCallback> _pauseHandlers = <VoidCallback>{};

  static void registerPauseHandler(VoidCallback handler) =>
      _pauseHandlers.add(handler);

  static void unregisterPauseHandler(VoidCallback handler) =>
      _pauseHandlers.remove(handler);

  static void pauseAll() {
    for (final handler in _pauseHandlers.toList()) {
      try {
        handler();
      } catch (_) {}
    }
  }
}
