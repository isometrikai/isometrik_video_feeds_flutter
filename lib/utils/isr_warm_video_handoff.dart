import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';

/// Lets a feed video lend its already-playing controller to an overlay reels page.
///
/// The default player does not keep controllers in a URL cache, so the reels
/// page has to receive the live instance. While [yieldedUrl] is set, the feed
/// player must not paint a second platform view or pause that controller.
class IsrWarmVideoHandoff {
  IsrWarmVideoHandoff._();

  static final ValueNotifier<String?> yieldedUrl = ValueNotifier<String?>(null);
  static IVideoPlayerController? _controller;

  static void yieldToOverlay(
    String url, {
    IVideoPlayerController? controller,
  }) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    _controller = (controller != null &&
            !controller.isDisposed &&
            controller.isInitialized)
        ? controller
        : null;
    yieldedUrl.value = trimmed;
  }

  static void release() {
    _controller = null;
    if (yieldedUrl.value == null) return;
    yieldedUrl.value = null;
  }

  static bool releasesSurface(String url) {
    final yielded = yieldedUrl.value;
    if (yielded == null || yielded.isEmpty) return false;
    return yielded == url.trim();
  }

  /// Live feed controller for the clip being opened.
  ///
  /// [acceptHeld] is for the reels page of that clip when the URL string is not
  /// identical to the feed URL.
  static IVideoPlayerController? controllerFor(
    String url, {
    bool acceptHeld = false,
  }) {
    final controller = _controller;
    if (controller == null ||
        controller.isDisposed ||
        !controller.isInitialized) {
      return null;
    }
    if (acceptHeld || releasesSurface(url)) return controller;
    return null;
  }
}
