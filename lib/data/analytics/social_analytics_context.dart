import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';

import 'package:ism_video_reel_player/data/analytics/social_analytics_constants.dart';

/// Builds shared analytics property maps from SDK models.
abstract final class SocialAnalyticsContext {
  static Map<String, dynamic> commonEnvelope() => {
        SocialAnalyticsKeys.appName: IsrVideoReelConfig.appName,
        SocialAnalyticsKeys.timestamp: DateTime.now().toUtc().toIso8601String(),
      };

  static String resolvePostType(ReelsData reels) {
    final media = reels.mediaMetaDataList;
    if (media.length > 1) return 'carousel';
    if (media.isEmpty) {
      final timeline = _timeline(reels);
      final timelineMedia = timeline?.media;
      if (timelineMedia != null && timelineMedia.length > 1) {
        return 'carousel';
      }
      if (_isVideoMediaType(timelineMedia?.first.mediaType)) {
        return 'video';
      }
      return 'image';
    }
    return media.first.mediaType == 1 ? 'video' : 'image';
  }

  static bool postHasVideo(ReelsData reels) {
    if (reels.mediaMetaDataList.any((m) => m.mediaType == 1)) return true;
    final timeline = _timeline(reels);
    return timeline?.media?.any((m) => _isVideoMediaType(m.mediaType)) == true;
  }

  static List<String> resolveHashtags(ReelsData reels) {
    final tags = reels.tags?.hashtags;
    if (tags == null || tags.isEmpty) return const [];
    return tags
        .map((t) {
          final tag = (t.tag ?? '').trim();
          if (tag.isEmpty) return '';
          return tag.startsWith('#') ? tag : '#$tag';
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> postContext(
    ReelsData reels,
    PostSectionType? section,
  ) {
    final timeline = _timeline(reels);
    return {
      ...commonEnvelope(),
      SocialAnalyticsKeys.postId: reels.postId ?? '',
      SocialAnalyticsKeys.postAuthorId: reels.userId ?? '',
      SocialAnalyticsKeys.postType: resolvePostType(reels),
      SocialAnalyticsKeys.feedType: section?.title ?? 'for_you',
      SocialAnalyticsKeys.hashtags: resolveHashtags(reels),
      SocialAnalyticsKeys.interests: reels.interests ?? timeline?.interests ?? [],
    };
  }

  static String formatCreatorHandle(String? userName) {
    final raw = (userName ?? '').trim();
    if (raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  static String resolveCreatorName(ReelsData reels) {
    final first = (reels.firstName ?? '').trim();
    final last = (reels.lastName ?? '').trim();
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    return (reels.userName ?? '').trim();
  }

  static String resolveCreatorType(ReelsData reels) {
    final timeline = _timeline(reels);
    final profileType = (timeline?.user?.profileType ?? '').trim().toLowerCase();
    if (profileType.isNotEmpty) return profileType;
    return 'creator';
  }

  static Map<String, dynamic> creatorContext(
    ReelsData reels, {
    num? followerCountAfter,
    SocialCreatorFollowSource followSource = SocialCreatorFollowSource.socialPost,
    String? sourcePostId,
    String? sourceStreamId,
  }) =>
      {
        ...commonEnvelope(),
        SocialAnalyticsKeys.creatorId: reels.userId ?? '',
        SocialAnalyticsKeys.creatorHandle: formatCreatorHandle(reels.userName),
        SocialAnalyticsKeys.creatorName: resolveCreatorName(reels),
        SocialAnalyticsKeys.creatorType: resolveCreatorType(reels),
        SocialAnalyticsKeys.followSource: followSource.value,
        SocialAnalyticsKeys.sourcePostId: sourcePostId,
        SocialAnalyticsKeys.sourceStreamId: sourceStreamId,
        if (followerCountAfter != null)
          SocialAnalyticsKeys.creatorFollowerCountAfter:
              followerCountAfter.toInt(),
      };

  static TimeLineData? _timeline(ReelsData reels) =>
      reels.postData is TimeLineData ? reels.postData as TimeLineData : null;

  static bool _isVideoMediaType(String? mediaType) {
    final normalized = (mediaType ?? '').toLowerCase();
    return normalized == 'video' || normalized == '1';
  }
}
