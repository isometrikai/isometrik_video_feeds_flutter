import 'package:ism_video_reel_player/domain/models/create_edit_post_config.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';

/// Resolves create-post media upload limits from [CreateEditPostConfig].
///
/// Host apps configure limits via [CreateEditPostConfig.postMediaUploadLimits].
/// Video count is capped at [PostMediaUploadLimits.absoluteMaxVideoMediaLimit] (5).
class PostMediaLimits {
  PostMediaLimits._();

  /// Hard ceiling for videos per post — host config cannot exceed this.
  static const int absoluteMaxVideoMediaLimit = 5;

  static const int defaultVideoMediaLimit = 3;
  static const int defaultImageMediaLimit = 10;
  static const int defaultTotalMediaLimit = 5;

  static PostMediaUploadLimits get _config =>
      IsrVideoReelConfig.createEditPostConfig.postMediaUploadLimits;

  static int get videoMediaLimit => _config.resolvedVideoMediaLimit;

  static int get imageMediaLimit => _config.resolvedImageMediaLimit;

  static int get totalMediaLimit => _config.resolvedTotalMediaLimit;
}
