import 'package:ism_video_reel_player/presentation/presentation.dart';

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
        return StandardVideoCacheManager();
    }
  }
}
