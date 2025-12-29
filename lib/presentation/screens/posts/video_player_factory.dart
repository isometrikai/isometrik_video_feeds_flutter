import 'package:ism_video_reel_player/presentation/screens/posts/cached_video_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/media_kit_video_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/standard_video_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';

/// Enum to specify the video player type
enum VideoPlayerType {
  standard,
  cached,
  mediaKit,
}

/// Factory class to create appropriate video cache manager
class VideoPlayerFactory {
  /// Default video player type - change this to switch implementations
  static const VideoPlayerType defaultType = VideoPlayerType.mediaKit;

  static IVideoCacheManager create([VideoPlayerType? type]) {
    final playerType = type ?? defaultType;
    switch (playerType) {
      case VideoPlayerType.standard:
        return StandardVideoCacheManager();
      case VideoPlayerType.cached:
        return CachedVideoCacheManager();
      case VideoPlayerType.mediaKit:
        return MediaKitCacheManager();
    }
  }
}
