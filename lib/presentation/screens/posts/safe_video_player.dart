import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Renders the platform video surface only while the native player is alive.
///
/// Prevents the Android fatal:
/// `Bad state: No active player with ID X` from
/// `AndroidVideoPlayer.buildViewWithOptions` after [VideoPlayerController.dispose].
///
/// Unlike embedding [VideoPlayer] (whose [State.build] throws outside this
/// widget's try/catch), the platform view is built **here** so dispose races
/// return [SizedBox.shrink] instead of crashing.
class SafeVideoPlayer extends StatefulWidget {
  const SafeVideoPlayer({
    super.key,
    required this.controller,
    required this.isBuildSafe,
    this.onSurfaceMounted,
    this.onSurfaceUnmounted,
  });

  final VideoPlayerController controller;

  /// Must return false once dispose has started (before native player is removed).
  final bool Function() isBuildSafe;

  /// Called when this surface mounts so dispose can wait for unmount.
  final VoidCallback? onSurfaceMounted;

  /// Called when this surface leaves the tree.
  final VoidCallback? onSurfaceUnmounted;

  @override
  State<SafeVideoPlayer> createState() => _SafeVideoPlayerState();
}

class _SafeVideoPlayerState extends State<SafeVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.onSurfaceMounted?.call();
  }

  @override
  void didUpdateWidget(SafeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.onSurfaceUnmounted?.call();
      widget.onSurfaceMounted?.call();
    }
  }

  @override
  void dispose() {
    widget.onSurfaceUnmounted?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isBuildSafe()) {
      return const SizedBox.shrink();
    }

    try {
      final controller = widget.controller;
      if (!controller.value.isInitialized) {
        return const SizedBox.shrink();
      }

      // playerId is @visibleForTesting but is the only public handle for the
      // platform surface; reading it here lets us catch dispose races.
      // ignore: invalid_use_of_visible_for_testing_member
      final playerId = controller.playerId;
      // ignore: invalid_use_of_visible_for_testing_member
      if (playerId == VideoPlayerController.kUninitializedPlayerId) {
        return const SizedBox.shrink();
      }

      // Build the platform view in *this* build so StateError is catchable.
      final view = VideoPlayerPlatform.instance.buildViewWithOptions(
        VideoViewOptions(playerId: playerId),
      );

      final rotation = controller.value.rotationCorrection;
      final child = rotation == 0
          ? view
          : RotatedBox(quarterTurns: rotation ~/ 90, child: view);

      return KeyedSubtree(
        key: ObjectKey(controller),
        child: child,
      );
    } catch (_) {
      // Controller disposed, native player gone, or ChangeNotifier already dead.
      return const SizedBox.shrink();
    }
  }
}

/// Schedules native controller disposal only after the current UI frame(s) so
/// any platform video view Element has a chance to unmount first.
abstract final class VideoControllerDisposeScheduler {
  static final Map<int, int> _generations = <int, int>{};

  /// Invalidates any pending dispose for [controller].
  static void cancel(Object controller) {
    final id = identityHashCode(controller);
    _generations[id] = (_generations[id] ?? 0) + 1;
  }

  /// Runs [disposeFn] after two frame ends unless [cancel] was called.
  ///
  /// When [waitBeforeDispose] is provided, it is awaited (with a short timeout)
  /// after the frames so callers can wait for [SafeVideoPlayer] unmount.
  static void scheduleAfterUnmount(
    Object controller,
    Future<void> Function() disposeFn, {
    Future<void> Function()? waitBeforeDispose,
  }) {
    final id = identityHashCode(controller);
    final generation = (_generations[id] ?? 0) + 1;
    _generations[id] = generation;

    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      binding.addPostFrameCallback((_) {
        unawaited(() async {
          if (_generations[id] != generation) return;

          if (waitBeforeDispose != null) {
            try {
              await waitBeforeDispose().timeout(
                const Duration(milliseconds: 500),
              );
            } on TimeoutException {
              // Fall through — do not block native dispose forever.
            } catch (_) {}
          }

          if (_generations[id] != generation) return;
          _generations.remove(id);
          try {
            await disposeFn();
          } catch (e) {
            debugPrint('⚠️ VideoControllerDisposeScheduler dispose error: $e');
          }
        }());
      });
      // Ensure the second callback has a frame to run on.
      binding.scheduleFrame();
    });
    // Ensure the first callback has a frame to run on (idle tests / no UI).
    binding.scheduleFrame();
  }
}
