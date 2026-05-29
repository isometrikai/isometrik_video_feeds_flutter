import 'package:ism_video_reel_player/domain/analytics/isr_social_analytics_models.dart';

/// Host-app analytics delegate for social post tracking.
///
/// Implement this in the host app and register via `IsrVideoReelConfig.setUpConfig`
/// or `IsrVideoReelConfig.initializeSdk`.
abstract class IsrSocialAnalyticsDelegate {
  void onPostImpression(PostImpressionData data);

  void onPostSwipe(PostSwipeData data);

  void onVideoProgress(VideoProgressData data);

  void onShopOpen(ShopOpenData data);
}
