import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Builds [VideoPlayer] only when [controller] is safe to use.
///
/// Catches native dispose races ("No active player with ID") during build.
class SafeVideoPlayer extends StatelessWidget {
  const SafeVideoPlayer({
    super.key,
    required this.controller,
    this.placeholderColor = Colors.black,
    this.fit = BoxFit.contain,
  });

  final VideoPlayerController? controller;
  final Color placeholderColor;
  final BoxFit fit;

  static bool canBuild(VideoPlayerController? controller) {
    if (controller == null) return false;
    try {
      return controller.value.isInitialized && !controller.value.hasError;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = controller;
    if (!canBuild(active)) {
      return ColoredBox(color: placeholderColor);
    }

    try {
      return FittedBox(
        fit: fit,
        child: SizedBox(
          width: active!.value.size.width,
          height: active.value.size.height,
          child: VideoPlayer(
            active,
            key: ValueKey<Object>(identityHashCode(active)),
          ),
        ),
      );
    } catch (_) {
      return ColoredBox(color: placeholderColor);
    }
  }
}
