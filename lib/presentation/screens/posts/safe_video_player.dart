import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Renders [VideoPlayer] only while the underlying native player is still alive.
///
/// Prevents the Android fatal:
/// `Bad state: No active player with ID X` from
/// `AndroidVideoPlayer.buildViewWithOptions` after [VideoPlayerController.dispose].
class SafeVideoPlayer extends StatefulWidget {
  const SafeVideoPlayer({
    super.key,
    required this.controller,
    required this.isBuildSafe,
  });

  final VideoPlayerController controller;

  /// Must return false once dispose has started (before native player is removed).
  final bool Function() isBuildSafe;

  @override
  State<SafeVideoPlayer> createState() => _SafeVideoPlayerState();
}

class _SafeVideoPlayerState extends State<SafeVideoPlayer> {
  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(SafeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isBuildSafe()) {
      return const SizedBox.shrink();
    }

    try {
      if (!widget.controller.value.isInitialized) {
        return const SizedBox.shrink();
      }
      // Key by identity so a replacement controller never reuses a dead Element.
      return KeyedSubtree(
        key: ObjectKey(widget.controller),
        child: VideoPlayer(widget.controller),
      );
    } catch (_) {
      // Controller may already be disposed (ChangeNotifier throws when read).
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
  static void scheduleAfterUnmount(
    Object controller,
    Future<void> Function() disposeFn,
  ) {
    final id = identityHashCode(controller);
    final generation = (_generations[id] ?? 0) + 1;
    _generations[id] = generation;

    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      binding.addPostFrameCallback((_) {
        unawaited(() async {
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
