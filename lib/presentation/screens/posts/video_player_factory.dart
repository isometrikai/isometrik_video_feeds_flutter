import 'dart:io';

import 'package:ism_video_reel_player/presentation/presentation.dart';

/// Enum to specify the video player type
enum VideoPlayerType {
  standard,
  standardNonPreload,
  cached,
  mediaKit,
}

/// Factory class to create appropriate video cache manager
class VideoPlayerFactory {
  /// Default video player type - change this to switch implementations
  static final VideoPlayerType defaultType =
      Platform.isAndroid ? VideoPlayerType.standardNonPreload : VideoPlayerType.standardNonPreload;

  static IVideoCacheManager create([VideoPlayerType? type]) {
    final playerType = type ?? defaultType;
    switch (playerType) {
      case VideoPlayerType.standard:
        return StandardVideoCacheManager();
      case VideoPlayerType.cached:
        return CachedVideoCacheManager();
      case VideoPlayerType.mediaKit:
        return MediaKitCacheManager();
      case VideoPlayerType.standardNonPreload:
        return StandardVideoNonPreloadedManager();
    }
  }
}
