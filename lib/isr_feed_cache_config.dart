import 'package:ism_video_reel_player/cache/isr_feed_cache_section.dart';

/// Host-app knobs for SDK follow-sensitive feed persistence (Following + Feeds tabs).
class IsrFeedCacheConfig {
  const IsrFeedCacheConfig({
    this.maxItemsPerSection = 50,
    this.followSensitiveTtl = const Duration(minutes: 5),
    this.enabledSections = const {
      IsrFeedCacheSection.following,
      IsrFeedCacheSection.feeds,
    },
    this.cacheVersion = 1,
  });

  final int maxItemsPerSection;

  /// Shorter TTL for Following / Feeds so unfollows and new posts reconcile quickly.
  final Duration followSensitiveTtl;

  final Set<IsrFeedCacheSection> enabledSections;
  final int cacheVersion;

  Duration ttlFor(IsrFeedCacheSection section) => followSensitiveTtl;
}
