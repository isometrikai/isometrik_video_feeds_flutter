import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/post_review_status_util.dart';

/// Default SDK handler for moderated posts (rejected, in review, scheduled).
class IsrPostModerationTap {
  IsrPostModerationTap._();

  /// Shows [PostDetailsBottomSheet] for moderated posts.
  ///
  /// Returns `true` when a moderated post sheet was shown.
  /// Returns `false` for published posts so the caller can open reels with its
  /// own [postConfig] (overlay padding, icons, etc.).
  static Future<bool> handle(
    BuildContext context,
    TimeLineData post, {
    PostSectionType? postSectionType,
    List<TimeLineData>? postDataList,
    int? postIndex,
    PostDetailsSheetDelegate? delegate,
    RejectedPostResubmitSuccessBuilder? rejectedResubmitSuccessBuilder,
  }) async {
    final reviewStatus = PostReviewStatusUtil.fromTimeLineData(post) ??
        (PostReviewStatusUtil.isPublished(post)
            ? null
            : PostReviewStatusUtil.moderationStatusForGrid(post));
    if (reviewStatus != null) {
      await PostDetailsBottomSheet.show(
        context: context,
        data: PostReviewStatusUtil.sheetDataFromTimeLineData(
          post,
          reviewStatus,
        ),
        delegate: delegate,
        rejectedResubmitSuccessBuilder: rejectedResubmitSuccessBuilder,
      );
      return true;
    }

    // Published posts: let the caller's [navigateToReelsPlayer] proceed so
    // host-provided [postConfig] (e.g. reduced overlay padding from Explore /
    // Profile) is not replaced by a nested navigation using global config.
    return false;
  }
}
