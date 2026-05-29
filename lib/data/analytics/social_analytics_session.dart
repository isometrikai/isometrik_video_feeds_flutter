import 'package:ism_video_reel_player/domain/domain.dart';

import 'package:ism_video_reel_player/data/analytics/social_analytics_constants.dart';

/// In-memory session state for feed tabs, impressions, and swipe context.
class SocialAnalyticsSession {
  SocialAnalyticsSession._();

  static final SocialAnalyticsSession instance = SocialAnalyticsSession._();

  SocialImpressionTrigger _nextImpressionTrigger = SocialImpressionTrigger.sessionStart;
  String? _lastViewedPostId;
  String? _activeFeedTabKey;
  DateTime? _activeTabEnteredAt;
  int _postsSeenOnActiveTab = 0;
  final Map<String, DateTime> _postImpressionAt = {};
  final Set<String> _impressedPostKeys = {};

  SocialImpressionTrigger get nextImpressionTrigger => _nextImpressionTrigger;
  String? get lastViewedPostId => _lastViewedPostId;

  void setNextImpressionTrigger(SocialImpressionTrigger trigger) {
    _nextImpressionTrigger = trigger;
  }

  void markPostImpression(String postId) {
    if (postId.isEmpty) return;
    final now = DateTime.now();
    _postImpressionAt[postId] = now;
    _impressedPostKeys.add(_impressionKey(postId));
    _lastViewedPostId = postId;
    _postsSeenOnActiveTab += 1;
    _nextImpressionTrigger = SocialImpressionTrigger.scroll;
  }

  bool hasImpressed(String postId, String feedType) =>
      _impressedPostKeys.contains(_impressionKey(postId, feedType: feedType));

  int? secondsSinceImpression(String postId) {
    final at = _postImpressionAt[postId];
    if (at == null) return null;
    return DateTime.now().difference(at).inSeconds;
  }

  void onFeedTabEntered(PostSectionType section) {
    final key = section.title;
    if (_activeFeedTabKey == key) return;
    _activeFeedTabKey = key;
    _activeTabEnteredAt = DateTime.now();
    _postsSeenOnActiveTab = 0;
    setNextImpressionTrigger(SocialImpressionTrigger.tabSwitch);
  }

  ({int postsSeen, int secondsOnTab}) consumeTabSessionMetrics() {
    final entered = _activeTabEnteredAt;
    final seconds = entered == null
        ? 0
        : DateTime.now().difference(entered).inSeconds;
    final seen = _postsSeenOnActiveTab;
    _activeTabEnteredAt = DateTime.now();
    _postsSeenOnActiveTab = 0;
    return (postsSeen: seen, secondsOnTab: seconds);
  }

  String _impressionKey(String postId, {String? feedType}) =>
      '${feedType ?? _activeFeedTabKey ?? 'feed'}::$postId';
}
