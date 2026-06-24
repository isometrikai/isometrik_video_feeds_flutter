import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';

/// Playback state transferred between feed [VideoPlayerWidget] and
/// fullscreen preview so a single controller keeps position in sync.
class FeedVideoPlayerHandoffSnapshot {
  const FeedVideoPlayerHandoffSnapshot({
    required this.mediaUrl,
    required this.position,
    required this.shouldResumePlayback,
    required this.wasManuallyPaused,
    required this.controller,
    required this.hadPlayed,
  });

  final String mediaUrl;
  final Duration position;

  /// Whether the destination surface should start playback after handoff.
  /// Captured before the source pauses for transfer.
  final bool shouldResumePlayback;
  final bool wasManuallyPaused;
  final IVideoPlayerController controller;
  final bool hadPlayed;
}

/// In-memory bridge for feed ↔ fullscreen video controller handoff.
class FeedVideoPlayerHandoff {
  FeedVideoPlayerHandoff._();

  static final Map<String, FeedVideoPlayerHandoffSnapshot> _openSessions = {};
  static final Set<IVideoPlayerController> _protectedControllers = {};
  static FeedVideoPlayerHandoffSnapshot? _pendingForFeed;

  static bool isControllerProtected(IVideoPlayerController? controller) =>
      controller != null && _protectedControllers.contains(controller);

  static void _protect(IVideoPlayerController controller) {
    _protectedControllers.add(controller);
  }

  static void _unprotect(IVideoPlayerController controller) {
    _protectedControllers.remove(controller);
  }

  /// Feed opened preview — keep controller alive while fullscreen owns it.
  static void openSession(FeedVideoPlayerHandoffSnapshot snapshot) {
    final previous = _openSessions.remove(snapshot.mediaUrl);
    if (previous != null && previous.controller != snapshot.controller) {
      _unprotect(previous.controller);
    }
    _openSessions[snapshot.mediaUrl] = snapshot;
    _protect(snapshot.controller);
  }

  static FeedVideoPlayerHandoffSnapshot? sessionFor(String mediaUrl) =>
      _openSessions[mediaUrl];

  static void closeSession(String mediaUrl) {
    final session = _openSessions.remove(mediaUrl);
    if (session != null) {
      _unprotect(session.controller);
    }
  }

  static void publishReturnToFeed(FeedVideoPlayerHandoffSnapshot snapshot) {
    _pendingForFeed = snapshot;
    _openSessions[snapshot.mediaUrl] = snapshot;
    _protect(snapshot.controller);
  }

  static FeedVideoPlayerHandoffSnapshot? peekForFeed(String mediaUrl) {
    final pending = _pendingForFeed;
    if (pending == null || pending.mediaUrl != mediaUrl) return null;
    return pending;
  }

  static FeedVideoPlayerHandoffSnapshot? takeForFeed(String mediaUrl) {
    final pending = _pendingForFeed;
    if (pending == null || pending.mediaUrl != mediaUrl) return null;
    _pendingForFeed = null;
    closeSession(mediaUrl);
    return pending;
  }

  /// Disposes a pending controller when the feed card is gone before restore.
  static Future<void> disposePendingForUrl(String? mediaUrl) async {
    if (mediaUrl == null) return;
    final pending = _pendingForFeed;
    if (pending != null && pending.mediaUrl == mediaUrl) {
      _pendingForFeed = null;
      try {
        if (!pending.controller.isDisposed) {
          await pending.controller.pause();
          await pending.controller.dispose();
        }
      } catch (_) {}
    }
    final session = _openSessions.remove(mediaUrl);
    if (session != null) {
      _unprotect(session.controller);
      try {
        if (!session.controller.isDisposed) {
          await session.controller.pause();
          await session.controller.dispose();
        }
      } catch (_) {}
    }
  }
}
