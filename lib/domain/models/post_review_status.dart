/// Review / moderation status for [PostDetailsBottomSheet].
import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';

enum PostReviewStatus {
  /// Post has rejected media items — show reasons and edit & resubmit.
  rejected,

  /// Post is waiting for admin review.
  inReview,

  /// Post is approved and scheduled for future publish.
  scheduled,

  /// User resubmitted replaced items; confirmation screen.
  resubmitted,

  /// Post media is still being processed server-side.
  processing,
}

/// Moderation state for an item in the rejected-post details carousel.
enum PostReviewMediaItemState {
  approved,
  rejected,
  replaced,
  removed,
}

/// A media slot shown in the rejected-post details flow (all items in post).
class PostReviewMediaItem {
  const PostReviewMediaItem({
    required this.mediaNumber,
    required this.sourceIndex,
    required this.state,
    this.thumbnailUrl,
    this.replacementLocalPath,
    this.isVideo = false,
    this.rejectionReason,
  });

  /// 1-based carousel label number (e.g. Image #2).
  final int mediaNumber;
  final int sourceIndex;
  final PostReviewMediaItemState state;
  final String? thumbnailUrl;
  final String? replacementLocalPath;
  final bool isVideo;
  final String? rejectionReason;

  bool get isRejected => state == PostReviewMediaItemState.rejected;
  bool get isReplaced => state == PostReviewMediaItemState.replaced;
  bool get isApproved => state == PostReviewMediaItemState.approved;
  bool get isRemoved => state == PostReviewMediaItemState.removed;

  PostReviewMediaItem copyWith({
    int? mediaNumber,
    int? sourceIndex,
    PostReviewMediaItemState? state,
    String? thumbnailUrl,
    String? replacementLocalPath,
    bool? isVideo,
    String? rejectionReason,
    bool clearReplacement = false,
  }) =>
      PostReviewMediaItem(
        mediaNumber: mediaNumber ?? this.mediaNumber,
        sourceIndex: sourceIndex ?? this.sourceIndex,
        state: state ?? this.state,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        replacementLocalPath: clearReplacement
            ? null
            : (replacementLocalPath ?? this.replacementLocalPath),
        isVideo: isVideo ?? this.isVideo,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );
}

/// A single rejected image or video inside a post.
class PostReviewRejectedItem {
  const PostReviewRejectedItem({
    required this.label,
    required this.reason,
    this.thumbnailUrl,
    this.isVideo = false,
    this.mediaNumber,
    this.sourceIndex,
  });

  /// e.g. `Image #2`, `Video #2`
  final String label;
  final String reason;
  final String? thumbnailUrl;
  final bool isVideo;
  final int? mediaNumber;
  final int? sourceIndex;
}

/// Input model for [PostDetailsBottomSheet].
class PostDetailsSheetData {
  const PostDetailsSheetData({
    required this.postId,
    required this.status,
    this.sourcePost,
    this.previewImageUrl,
    this.submittedAtLabel,
    this.reviewedAtLabel,
    this.scheduledForLabel,
    this.rejectedCount,
    this.totalMediaCount,
    this.rejectedItems = const [],
    this.resubmittedReplacedCount,
    this.resubmittedMessage,
    this.rejectionReason,
  });

  final String postId;
  final PostReviewStatus status;

  /// Original timeline post used to open edit flow and delete APIs.
  final TimeLineData? sourcePost;

  final String? previewImageUrl;

  /// e.g. `Submitted Apr 20`
  final String? submittedAtLabel;

  /// e.g. `Reviewed Apr 22`
  final String? reviewedAtLabel;

  /// e.g. `Scheduled for Apr 20`
  final String? scheduledForLabel;

  final int? rejectedCount;
  final int? totalMediaCount;
  final List<PostReviewRejectedItem> rejectedItems;

  /// Number of replaced items shown on the resubmitted screen.
  final int? resubmittedReplacedCount;

  /// Optional override for resubmitted body copy.
  final String? resubmittedMessage;

  /// Post-level rejection reason from API (`rejection_reason`).
  final String? rejectionReason;
}

/// Context passed to [RejectedPostResubmitSuccessBuilder] after inline resubmit.
class RejectedPostResubmitSuccessData {
  const RejectedPostResubmitSuccessData({
    required this.sheetData,
    required this.replacedCount,
    this.newPostId,
  });

  final PostDetailsSheetData sheetData;
  final int replacedCount;
  final String? newPostId;
}

/// Builds the success step shown after a rejected post is resubmitted inline.
typedef RejectedPostResubmitSuccessBuilder = Widget Function(
  BuildContext context,
  RejectedPostResubmitSuccessData data,
);

/// Host-app callbacks for [PostDetailsBottomSheet].
class PostDetailsSheetDelegate {
  const PostDetailsSheetDelegate({
    this.onClose,
    this.onDeletePost,
    this.onEditAndResubmit,
    this.onWithdrawPost,
    this.onEditSubmission,
    this.onPublishNow,
    this.buildRejectedResubmitSuccess,
  });

  final void Function(PostDetailsSheetData data)? onClose;
  final Future<void> Function(PostDetailsSheetData data)? onDeletePost;
  final Future<void> Function(PostDetailsSheetData data)? onEditAndResubmit;
  final Future<void> Function(PostDetailsSheetData data)? onWithdrawPost;
  final Future<void> Function(PostDetailsSheetData data)? onEditSubmission;
  final Future<void> Function(PostDetailsSheetData data)? onPublishNow;

  /// Optional custom success UI for the rejected-post inline resubmit flow.
  final RejectedPostResubmitSuccessBuilder? buildRejectedResubmitSuccess;

  /// Merges [override] on top of [defaults]; withdraw falls back to delete.
  PostDetailsSheetDelegate mergeWith(PostDetailsSheetDelegate defaults) =>
      PostDetailsSheetDelegate(
        onClose: onClose ?? defaults.onClose,
        onDeletePost: onDeletePost ?? defaults.onDeletePost,
        onEditAndResubmit: onEditAndResubmit ?? defaults.onEditAndResubmit,
        onWithdrawPost: onWithdrawPost ??
            onDeletePost ??
            defaults.onWithdrawPost ??
            defaults.onDeletePost,
        onEditSubmission: onEditSubmission ?? defaults.onEditSubmission,
        onPublishNow: onPublishNow ?? defaults.onPublishNow,
        buildRejectedResubmitSuccess: buildRejectedResubmitSuccess ??
            defaults.buildRejectedResubmitSuccess,
      );
}
