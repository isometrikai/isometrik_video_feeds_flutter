/// Impression trigger for [PostImpressionData.impressionTrigger].
enum ImpressionTrigger {
  scroll('scroll'),
  deeplink('deeplink'),
  tabSwitch('tab_switch'),
  sessionStart('session_start');

  const ImpressionTrigger(this.value);

  final String value;
}

/// Swipe direction for [PostSwipeData.swipeDirection].
enum PostSwipeDirection {
  next('next'),
  previous('previous');

  const PostSwipeDirection(this.value);

  final String value;
}

/// Exit reason for [PostSwipeData.exitReason].
enum PostExitReason {
  swipe('swipe'),
  tapOtherTab('tap_other_tab'),
  navigatedAway('navigated_away'),
  appBackground('app_background');

  const PostExitReason(this.value);

  final String value;
}

/// Data emitted when a post impression is logged.
class PostImpressionData {
  const PostImpressionData({
    required this.postId,
    required this.isAutoplay,
    required this.startsMuted,
    required this.impressionTrigger,
    this.previousPostId,
  });

  final String postId;
  final bool isAutoplay;
  final bool startsMuted;
  final String impressionTrigger;
  final String? previousPostId;
}

/// Data emitted when the user leaves a post.
class PostSwipeData {
  const PostSwipeData({
    required this.postId,
    required this.swipeDirection,
    required this.watchDurationSec,
    required this.videoPctWatched,
    required this.videoCompleted,
    required this.isMuted,
    required this.exitReason,
  });

  final String postId;
  final String swipeDirection;
  final double watchDurationSec;
  final double videoPctWatched;
  final bool videoCompleted;
  final bool isMuted;
  final String exitReason;
}

/// Data emitted at video progress milestones (25, 50, 75, 95, 100).
class VideoProgressData {
  const VideoProgressData({
    required this.postId,
    required this.progressMilestone,
    required this.watchDurationSec,
    required this.videoCurrentTimeSec,
    required this.isMuted,
    required this.pauseCount,
    required this.replayCount,
    required this.hasUnmuted,
  });

  final String postId;
  final int progressMilestone;
  final double watchDurationSec;
  final double videoCurrentTimeSec;
  final bool isMuted;
  final int pauseCount;
  final int replayCount;
  final bool hasUnmuted;
}

/// Data emitted when the shop chip is tapped.
class ShopOpenData {
  const ShopOpenData({
    required this.postId,
    required this.videoCurrentTimeSec,
  });

  final String postId;
  final double videoCurrentTimeSec;
}
