import 'package:ism_video_reel_player/presentation/screens/posts/cached_video_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/standard_video_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';

/// Enum to specify the video player type
enum VideoPlayerType {
  standard,
  cached,
}

/// Factory class to create appropriate video cache manager
class VideoPlayerFactory {
  static IVideoCacheManager create(VideoPlayerType type) {
    switch (type) {
      case VideoPlayerType.standard:
        return StandardVideoCacheManager();
      case VideoPlayerType.cached:
        return CachedVideoCacheManager();
    }
  }
}
