import 'dart:ui';

/// Lets [IsrVideoReelConfig] pause every mounted feed/reel [VideoPlayerWidget]
/// without importing presentation widgets (avoids circular imports).
abstract final class IsrActiveVideoPlayerRegistry {
  static final Set<VoidCallback> _pauseHandlers = <VoidCallback>{};
  static final Set<VoidCallback> _hostFeedReleaseHandlers = <VoidCallback>{};
  static final Set<VoidCallback> _preloadedReleaseHandlers = <VoidCallback>{};

  static void registerPauseHandler(VoidCallback handler) =>
      _pauseHandlers.add(handler);

  static void unregisterPauseHandler(VoidCallback handler) =>
      _pauseHandlers.remove(handler);

  /// [handler] must guard with live [VideoPlayerWidget.isHostFeedPlayer].
  static void registerHostFeedReleaseHandler(VoidCallback handler) =>
      _hostFeedReleaseHandlers.add(handler);

  static void unregisterHostFeedReleaseHandler(VoidCallback handler) =>
      _hostFeedReleaseHandlers.remove(handler);

  /// [handler] must guard with live [VideoPlayerWidget.isPreloaded].
  static void registerPreloadedReleaseHandler(VoidCallback handler) =>
      _preloadedReleaseHandlers.add(handler);

  static void unregisterPreloadedReleaseHandler(VoidCallback handler) =>
      _preloadedReleaseHandlers.remove(handler);

  static void pauseAll() {
    for (final handler in _pauseHandlers.toList()) {
      try {
        handler();
      } catch (_) {}
    }
  }

  /// Disposes native decoders on the kept-alive home [IsmPostView] only.
  static void releaseHostFeedMemory() {
    for (final handler in _hostFeedReleaseHandlers.toList()) {
      try {
        handler();
      } catch (_) {}
    }
  }

  /// Drops adjacent preloaded reel decoders before a seek to limit spikes.
  static void releasePreloadedMemory() {
    for (final handler in _preloadedReleaseHandlers.toList()) {
      try {
        handler();
      } catch (_) {}
    }
  }
}
