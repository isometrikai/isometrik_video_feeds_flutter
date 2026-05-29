import 'dart:async';

import 'package:ism_video_reel_player/domain/analytics/isr_social_analytics_delegate.dart';
import 'package:ism_video_reel_player/domain/analytics/isr_social_analytics_models.dart';

/// Coordinates social post analytics across feed, video player, and lifecycle.
class IsrSocialPostAnalyticsTracker {
  IsrSocialPostAnalyticsTracker._();

  static final IsrSocialPostAnalyticsTracker instance = IsrSocialPostAnalyticsTracker._();

  static const _impressionVisibilityThreshold = 0.5;
  static const _impressionDebounceMs = 500;
  static const _progressMilestones = [25, 50, 75, 95, 100];
  static const _videoCompletedThreshold = 95.0;

  IsrSocialAnalyticsDelegate? _delegate;

  String? _currentPostId;
  String? _previousPostId;
  ImpressionTrigger _nextImpressionTrigger = ImpressionTrigger.sessionStart;

  final Map<String, _PostAnalyticsSession> _sessions = {};

  void setDelegate(IsrSocialAnalyticsDelegate? delegate) {
    _delegate = delegate;
  }

  void setNextImpressionTrigger(ImpressionTrigger trigger) {
    _nextImpressionTrigger = trigger;
  }

  void onPostActivated({
    required String postId,
    required bool isAutoplay,
    required bool startsMuted,
    required bool isVideo,
    double? videoDurationSec,
  }) {
    _previousPostId = _currentPostId;
    _currentPostId = postId;

    final session = _sessions.putIfAbsent(postId, _PostAnalyticsSession.new);
    session
      ..isAutoplay = isAutoplay
      ..startsMuted = startsMuted
      ..isMuted = startsMuted
      ..isVideo = isVideo
      ..videoDurationSec = videoDurationSec
      ..activeSince ??= DateTime.now();
  }

  void onPostVisibilityChanged({
    required String postId,
    required double visibleFraction,
  }) {
    if (_delegate == null || postId != _currentPostId) return;

    final session = _sessions[postId];
    if (session == null) return;

    if (visibleFraction >= _impressionVisibilityThreshold) {
      if (session.impressionLogged) return;

      session.impressionTimer?.cancel();
      session.impressionTimer = Timer(
        const Duration(milliseconds: _impressionDebounceMs),
        () {
          if (session.impressionLogged || _currentPostId != postId) return;
          session.impressionLogged = true;
          _delegate?.onPostImpression(
            PostImpressionData(
              postId: postId,
              isAutoplay: session.isAutoplay,
              startsMuted: session.startsMuted,
              impressionTrigger: _nextImpressionTrigger.value,
              previousPostId: _previousPostId,
            ),
          );
        },
      );
    } else {
      session.impressionTimer?.cancel();
      session.impressionTimer = null;
    }
  }

  void onLeaveCurrentPost({
    required PostExitReason exitReason,
    PostSwipeDirection? swipeDirection,
  }) {
    final postId = _currentPostId;
    if (postId == null || _delegate == null) return;

    final session = _sessions[postId];
    if (session == null) return;

    session.impressionTimer?.cancel();
    session.impressionTimer = null;

    final watchDurationSec = _watchDurationSec(session);
    final videoPctWatched = _videoPctWatched(session);
    final resolvedDirection = swipeDirection ??
        (exitReason == PostExitReason.swipe ? PostSwipeDirection.next : PostSwipeDirection.next);

    _delegate?.onPostSwipe(
      PostSwipeData(
        postId: postId,
        swipeDirection: resolvedDirection.value,
        watchDurationSec: watchDurationSec,
        videoPctWatched: videoPctWatched,
        videoCompleted: videoPctWatched >= _videoCompletedThreshold,
        isMuted: session.isMuted,
        exitReason: exitReason.value,
      ),
    );

    if (exitReason == PostExitReason.appBackground) {
      session.impressionLogged = false;
    }

    _previousPostId = postId;
    _currentPostId = null;
    _sessions.remove(postId);
  }

  void onManualPause(String postId) {
    final session = _sessions[postId];
    if (session == null) return;
    session.pauseCount++;
  }

  void onUnmute(String postId) {
    final session = _sessions[postId];
    if (session == null) return;
    session.isMuted = false;
    session.hasUnmuted = true;
  }

  void onMute(String postId) {
    final session = _sessions[postId];
    if (session == null) return;
    session.isMuted = true;
  }

  void onVideoPositionUpdate({
    required String postId,
    required double currentTimeSec,
    required double durationSec,
    required bool isMuted,
  }) {
    if (_delegate == null || postId != _currentPostId) return;

    final session = _sessions[postId];
    if (session == null || !session.isVideo || durationSec <= 0) return;

    session.isMuted = isMuted;
    session.videoDurationSec = durationSec;

    if (session.lastPositionSec > 1 && currentTimeSec < 1) {
      session.replayCount++;
      session.loggedMilestones.clear();
    }
    session.lastPositionSec = currentTimeSec;

    if (currentTimeSec > session.maxWatchPositionSec) {
      session.maxWatchPositionSec = currentTimeSec;
    }

    final pctWatched = (session.maxWatchPositionSec / durationSec) * 100;
    for (final milestone in _progressMilestones) {
      if (pctWatched >= milestone && session.loggedMilestones.add(milestone)) {
        _delegate?.onVideoProgress(
          VideoProgressData(
            postId: postId,
            progressMilestone: milestone,
            watchDurationSec: _watchDurationSec(session),
            videoCurrentTimeSec: currentTimeSec,
            isMuted: session.isMuted,
            pauseCount: session.pauseCount,
            replayCount: session.replayCount,
            hasUnmuted: session.hasUnmuted,
          ),
        );
      }
    }
  }

  void onShopOpen({
    required String postId,
    required double videoCurrentTimeSec,
  }) {
    _delegate?.onShopOpen(
      ShopOpenData(
        postId: postId,
        videoCurrentTimeSec: videoCurrentTimeSec,
      ),
    );
  }

  double videoCurrentTimeSec(String postId) => _sessions[postId]?.lastPositionSec ?? 0;

  void clearSession(String postId) {
    final session = _sessions.remove(postId);
    session?.impressionTimer?.cancel();
  }

  void reset() {
    for (final session in _sessions.values) {
      session.impressionTimer?.cancel();
    }
    _sessions.clear();
    _currentPostId = null;
    _previousPostId = null;
    _nextImpressionTrigger = ImpressionTrigger.sessionStart;
  }

  double _watchDurationSec(_PostAnalyticsSession session) {
    if (session.activeSince == null) return 0;
    return DateTime.now().difference(session.activeSince!).inMilliseconds / 1000.0;
  }

  double _videoPctWatched(_PostAnalyticsSession session) {
    final duration = session.videoDurationSec;
    if (!session.isVideo || duration == null || duration <= 0) return 0;
    return (session.maxWatchPositionSec / duration) * 100;
  }
}

class _PostAnalyticsSession {
  bool isAutoplay = false;
  bool startsMuted = false;
  bool isMuted = false;
  bool hasUnmuted = false;
  bool isVideo = false;
  bool impressionLogged = false;
  int pauseCount = 0;
  int replayCount = 0;
  double maxWatchPositionSec = 0;
  double lastPositionSec = 0;
  double? videoDurationSec;
  DateTime? activeSince;
  Timer? impressionTimer;
  final Set<int> loggedMilestones = {};
}
