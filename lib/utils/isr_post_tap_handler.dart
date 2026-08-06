import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/isr_post_details_actions.dart';
import 'package:ism_video_reel_player/utils/isr_post_moderation_tap.dart';
import 'package:ism_video_reel_player/utils/post_review_status_util.dart';

typedef IsrOnTapPostCallback = Future<bool> Function(
  BuildContext context,
  TimeLineData postData, {
  PostSectionType? postSectionType,
  List<TimeLineData>? postDataList,
  int? postIndex,
});

/// Central post-tap routing for moderated posts and optional host overrides.
class IsrPostTapHandler {
  IsrPostTapHandler._();

  static PostDetailsSheetDelegate? _detailsDelegate;
  static IsrOnTapPostCallback? _onTapPost;

  /// Optional delegate for post details bottom sheet actions.
  static PostDetailsSheetDelegate? get detailsDelegate => _detailsDelegate;

  /// Optional full override; when null the SDK uses [IsrPostModerationTap].
  static IsrOnTapPostCallback? get onTapPost => _onTapPost;

  /// Configure post-tap behavior for the host app.
  static void configure({
    PostDetailsSheetDelegate? detailsDelegate,
    IsrOnTapPostCallback? onTapPost,
  }) {
    _detailsDelegate = detailsDelegate;
    _onTapPost = onTapPost;
  }

  static void reset() {
    _detailsDelegate = null;
    _onTapPost = null;
  }

  /// Whether the post can be opened from the grid (e.g. not processing).
  static bool isTappable(TimeLineData postData) =>
      !PostReviewStatusUtil.isProcessing(postData);

  /// Returns `true` when the tap was handled by the SDK or host callback.
  static Future<bool> tryHandleTap(
    BuildContext context, {
    required TimeLineData postData,
    PostSectionType? postSectionType,
    List<TimeLineData>? postDataList,
    int? postIndex,
    VoidCallback? onPostUpdated,
  }) async {
    if (!isTappable(postData)) {
      return true;
    }

    final handler = _onTapPost;
    if (handler != null) {
      return handler(
        context,
        postData,
        postSectionType: postSectionType,
        postDataList: postDataList,
        postIndex: postIndex,
      );
    }

    return IsrPostModerationTap.handle(
      context,
      postData,
      postSectionType: postSectionType,
      postDataList: postDataList,
      postIndex: postIndex,
      delegate: IsrPostDetailsActions.resolve(
        context,
        post: postData,
        override: _detailsDelegate,
        onPostUpdated: onPostUpdated,
      ),
    );
  }
}
