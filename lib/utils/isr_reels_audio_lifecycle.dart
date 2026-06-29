import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/media_kit_video_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_cache_manager.dart';

/// Native audio/video teardown for hot restart, app updates, and tab handoff.
///
/// After a Flutter hot restart the Dart isolate resets but iOS/Android native
/// [VideoPlayerController] / MediaKit players can keep emitting audio. Dart-side
/// pause registries only cover the new isolate, so we deactivate the platform
/// audio session and dispose cached native players at isolate start and on hard stop.
abstract final class IsrReelsAudioLifecycle {
  /// Call at the very beginning of [main] (and before reels SDK init).
  static Future<void> silenceOrphanedMediaOnIsolateStart() async {
    await deactivateAudioSessionBestEffort();
    MediaKitCacheManager.resetAudioSession();
    try {
      await VideoCacheManager.disposeAll();
    } catch (e) {
      debugPrint('IsrReelsAudioLifecycle: disposeAll on start: $e');
    }
  }

  /// Best-effort cut of all app audio output (orphaned native players included).
  static Future<void> deactivateAudioSessionBestEffort() async {
    if (kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('IsrReelsAudioLifecycle: deactivate audio session: $e');
    }
  }
}
