import 'package:ism_video_reel_player/domain/domain.dart';

/// Persisted feed slices managed by [IsrFeedCacheRepository].
enum IsrFeedCacheSection {
  following,
  feeds,
}

extension IsrFeedCacheSectionMapping on IsrFeedCacheSection {
  static IsrFeedCacheSection? fromPostSectionType(PostSectionType type) {
    switch (type) {
      case PostSectionType.following:
        return IsrFeedCacheSection.following;
      case PostSectionType.feeds:
        return IsrFeedCacheSection.feeds;
      default:
        return null;
    }
  }

  PostSectionType get postSectionType {
    switch (this) {
      case IsrFeedCacheSection.following:
        return PostSectionType.following;
      case IsrFeedCacheSection.feeds:
        return PostSectionType.feeds;
    }
  }
}

bool isrFollowSensitivePostSection(PostSectionType type) =>
    type == PostSectionType.following || type == PostSectionType.feeds;
