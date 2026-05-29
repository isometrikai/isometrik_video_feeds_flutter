import 'package:ism_video_reel_player/data/managers/local_event_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

import 'package:ism_video_reel_player/data/analytics/social_analytics_constants.dart';
import 'package:ism_video_reel_player/data/analytics/social_analytics_context.dart';
import 'package:ism_video_reel_player/data/analytics/social_analytics_session.dart';

/// Central SDK analytics API — all standardized social events flow through here.
abstract final class SocialAnalyticsTracker {
  static final _session = SocialAnalyticsSession.instance;

  static void trackFeedTabSwitch({
    required PostSectionType fromTab,
    required PostSectionType toTab,
    required int postsSeenOnPreviousTab,
    required int timeOnPreviousTabSec,
  }) {
    _log(SocialAnalyticsEvents.socialFeedTabSwitch, {
      ...SocialAnalyticsContext.commonEnvelope(),
      SocialAnalyticsKeys.fromTab: fromTab.title,
      SocialAnalyticsKeys.toTab: toTab.title,
      SocialAnalyticsKeys.postsSeenOnPreviousTab: postsSeenOnPreviousTab,
      SocialAnalyticsKeys.timeOnPreviousTabSec: timeOnPreviousTabSec,
    });
    _session.onFeedTabEntered(toTab);
  }

  static void trackPostImpression({
    required ReelsData reels,
    required PostSectionType section,
    required bool isAutoplay,
    required bool startsMuted,
    String? previousPostId,
    SocialImpressionTrigger? trigger,
  }) {
    final feedType = section.title;
    final postId = reels.postId ?? '';
    if (postId.isEmpty) return;
    if (_session.hasImpressed(postId, feedType)) return;

    final impressionTrigger = trigger ?? _session.nextImpressionTrigger;
    _log(SocialAnalyticsEvents.socialPostImpression, {
      ...SocialAnalyticsContext.postContext(reels, section),
      SocialAnalyticsKeys.isAutoplay: isAutoplay,
      SocialAnalyticsKeys.startsMuted: startsMuted,
      if (previousPostId != null && previousPostId.isNotEmpty)
        SocialAnalyticsKeys.previousPostId: previousPostId,
      SocialAnalyticsKeys.impressionTrigger: impressionTrigger.value,
    });
    _session.markPostImpression(postId);
  }

  static void trackPostVideoProgress({
    required ReelsData reels,
    required PostSectionType section,
    required int progressMilestone,
    required double watchDurationSec,
    required double videoCurrentTimeSec,
    required bool isMuted,
    required int pauseCount,
    required int replayCount,
    required bool hasUnmuted,
  }) {
    _log(SocialAnalyticsEvents.socialPostVideoProgress, {
      ...SocialAnalyticsContext.postContext(reels, section),
      SocialAnalyticsKeys.progressMilestone: progressMilestone,
      SocialAnalyticsKeys.watchDurationSec: watchDurationSec,
      SocialAnalyticsKeys.videoCurrentTimeSec: videoCurrentTimeSec,
      SocialAnalyticsKeys.isMuted: isMuted,
      SocialAnalyticsKeys.pauseCount: pauseCount,
      SocialAnalyticsKeys.replayCount: replayCount,
      SocialAnalyticsKeys.hasUnmuted: hasUnmuted,
    });
  }

  static void trackPostSwipe({
    required ReelsData reels,
    required PostSectionType section,
    required SocialSwipeDirection swipeDirection,
    required double watchDurationSec,
    required int videoPctWatched,
    required bool videoCompleted,
    required bool isMuted,
    required SocialPostExitReason exitReason,
  }) {
    _log(SocialAnalyticsEvents.socialPostSwipe, {
      ...SocialAnalyticsContext.postContext(reels, section),
      SocialAnalyticsKeys.swipeDirection: swipeDirection.value,
      SocialAnalyticsKeys.watchDurationSec: watchDurationSec,
      SocialAnalyticsKeys.videoPctWatched: videoPctWatched,
      SocialAnalyticsKeys.videoCompleted: videoCompleted,
      SocialAnalyticsKeys.isMuted: isMuted,
      SocialAnalyticsKeys.exitReason: exitReason.value,
    });
  }

  static void trackPostInteract({
    required ReelsData reels,
    required PostSectionType section,
    required SocialPostInteractionType interactionType,
    int? commentTextLength,
    int? secSincePostImpression,
  }) {
    final postId = reels.postId ?? '';
    _log(SocialAnalyticsEvents.socialPostInteract, {
      ...SocialAnalyticsContext.postContext(reels, section),
      SocialAnalyticsKeys.interactionType: interactionType.value,
      SocialAnalyticsKeys.commentTextLength: commentTextLength,
      SocialAnalyticsKeys.secSincePostImpression:
          secSincePostImpression ?? _session.secondsSinceImpression(postId),
    });
  }

  static void trackCreatorFollow({
    required ReelsData reels,
    required bool isFollow,
    SocialCreatorFollowSource followSource = SocialCreatorFollowSource.socialPost,
    String? sourcePostId,
    String? sourceStreamId,
    num? creatorFollowerCountAfter,
  }) {
    final event = isFollow
        ? SocialAnalyticsEvents.creatorFollow
        : SocialAnalyticsEvents.creatorUnfollow;
    _log(
      event,
      SocialAnalyticsContext.creatorContext(
        reels,
        followerCountAfter: creatorFollowerCountAfter,
        followSource: followSource,
        sourcePostId: sourcePostId ?? reels.postId,
        sourceStreamId: sourceStreamId,
      ),
    );
  }

  static void _log(String eventName, Map<String, dynamic> payload) {
    EventQueueProvider.instance.logEvent(
      eventName,
      {...payload, SocialAnalyticsKeys.event: eventName},
    );
  }
}
