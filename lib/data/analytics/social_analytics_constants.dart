/// Canonical social analytics event names and property keys for all host apps.
abstract final class SocialAnalyticsEvents {
  static const socialFeedTabSwitch = 'social_feed_tab_switch';
  static const socialPostImpression = 'social_post_impression';
  static const socialPostVideoProgress = 'social_post_video_progress';
  static const socialPostSwipe = 'social_post_swipe';
  static const socialPostInteract = 'social_post_interact';
  static const creatorFollow = 'creator_follow';
  static const creatorUnfollow = 'creator_unfollow';
}

abstract final class SocialAnalyticsKeys {
  static const event = 'event';

  // Feed / session
  static const feedType = 'feed_type';
  static const appName = 'app_name';
  static const timestamp = 'timestamp';

  // Post context (common)
  static const postId = 'post_id';
  static const postAuthorId = 'post_author_id';
  static const postType = 'post_type';
  static const hashtags = 'hashtags';
  static const interests = 'interests';

  // social_feed_tab_switch
  static const fromTab = 'from_tab';
  static const toTab = 'to_tab';
  static const postsSeenOnPreviousTab = 'posts_seen_on_previous_tab';
  static const timeOnPreviousTabSec = 'time_on_previous_tab_sec';

  // social_post_impression
  static const isAutoplay = 'is_autoplay';
  static const startsMuted = 'starts_muted';
  static const previousPostId = 'previous_post_id';
  static const impressionTrigger = 'impression_trigger';

  // social_post_video_progress
  static const progressMilestone = 'progress_milestone';
  static const watchDurationSec = 'watch_duration_sec';
  static const videoCurrentTimeSec = 'video_current_time_sec';
  static const isMuted = 'is_muted';
  static const pauseCount = 'pause_count';
  static const replayCount = 'replay_count';
  static const hasUnmuted = 'has_unmuted';

  // social_post_swipe
  static const swipeDirection = 'swipe_direction';
  static const videoPctWatched = 'video_pct_watched';
  static const videoCompleted = 'video_completed';
  static const exitReason = 'exit_reason';

  // social_post_interact
  static const interactionType = 'interaction_type';
  static const commentTextLength = 'comment_text_length';
  static const secSincePostImpression = 'sec_since_post_impression';

  // creator_follow / creator_unfollow
  static const creatorId = 'creator_id';
  static const creatorHandle = 'creator_handle';
  static const creatorName = 'creator_name';
  static const creatorType = 'creator_type';
  static const followSource = 'follow_source';
  static const sourcePostId = 'source_post_id';
  static const sourceStreamId = 'source_stream_id';
  static const creatorFollowerCountAfter = 'creator_follower_count_after';
}

/// How the user reached the current post impression.
enum SocialImpressionTrigger {
  scroll('scroll'),
  deeplink('deeplink'),
  tabSwitch('tab_switch'),
  sessionStart('session_start');

  const SocialImpressionTrigger(this.value);
  final String value;
}

enum SocialSwipeDirection {
  next('next'),
  previous('previous');

  const SocialSwipeDirection(this.value);
  final String value;
}

enum SocialPostExitReason {
  swipe('swipe'),
  tapOtherTab('tap_other_tab'),
  navigatedAway('navigated_away'),
  appBackground('app_background');

  const SocialPostExitReason(this.value);
  final String value;
}

enum SocialPostInteractionType {
  like('like'),
  unlike('unlike'),
  commentOpen('comment_open'),
  commentSubmit('comment_submit'),
  save('save'),
  unsave('unsave'),
  shareOpen('share_open');

  const SocialPostInteractionType(this.value);
  final String value;
}

enum SocialCreatorFollowSource {
  socialPost('social_post'),
  creatorProfile('creator_profile'),
  liveStream('live_stream'),
  search('search');

  const SocialCreatorFollowSource(this.value);
  final String value;
}
