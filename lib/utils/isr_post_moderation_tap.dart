import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';
import 'package:ism_video_reel_player/utils/post_review_status_util.dart';

/// Default SDK handler for moderated posts (rejected, in review, scheduled).
class IsrPostModerationTap {
  IsrPostModerationTap._();

  /// Shows [PostDetailsBottomSheet] for moderated posts.
  ///
  /// Returns `true` when the tap was handled (sheet shown or reels opened when
  /// [postDataList] is provided). Returns `false` for normal published posts so
  /// the host app can open its own viewer.
  static Future<bool> handle(
    BuildContext context,
    TimeLineData post, {
    PostSectionType? postSectionType,
    List<TimeLineData>? postDataList,
    int? postIndex,
    PostDetailsSheetDelegate? delegate,
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
      );
      return true;
    }

    if (postDataList != null &&
        postIndex != null &&
        postIndex >= 0 &&
        postIndex < postDataList.length) {
      await IsrAppNavigator.navigateToReelsPlayer(
        context,
        postDataList: postDataList,
        startingPostIndex: postIndex,
        postSectionType: postSectionType ?? PostSectionType.forYou,
      );
      return true;
    }

    return false;
  }
}
