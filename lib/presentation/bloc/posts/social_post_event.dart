part of 'social_post_bloc.dart';

abstract class SocialPostEvent {
  const SocialPostEvent();
}

class StartPost extends SocialPostEvent {
  const StartPost({
    required this.postSections,
  });

  final List<PostTabAssistData> postSections;
}

class LoadPostData extends SocialPostEvent {
  const LoadPostData({
    required this.postSections,
    this.startTabIndex = 0,
  });

  final int startTabIndex;
  final List<PostTabAssistData> postSections;
}

/// Loads one home/reels tab without blocking other tabs (Following, Feeds, etc.).
class LoadHomeTabEvent extends SocialPostEvent {
  const LoadHomeTabEvent({
    required this.postSectionType,
  });

  final PostSectionType postSectionType;
}

class LoadPostsEvent extends SocialPostEvent {
  LoadPostsEvent({
    required this.postType,
    required this.postList,
  });

  final PostSectionType postType;
  final List<TimeLineData> postList;
}

class GetTimeLinePostEvent extends SocialPostEvent {
  GetTimeLinePostEvent({
    required this.isLoading,
    required this.isPagination,
    this.isRefresh = false,
    this.onComplete,
  });

  final bool isLoading;
  final bool isPagination;
  final bool isRefresh;
  final Function(List<TimeLineData>)? onComplete;
}

class GetTrendingPostEvent extends SocialPostEvent {
  GetTrendingPostEvent({
    required this.isLoading,
    this.isPagination = false,
    this.isRefresh = false,
    this.onComplete,
  });

  final bool isLoading;
  final bool isPagination;
  final bool isRefresh;
  final Function(List<TimeLineData>)? onComplete;
}

class GetCloudDetailsEvent extends SocialPostEvent {
  GetCloudDetailsEvent({
    required this.isLoading,
    required this.key,
    required this.value,
  });

  final bool isLoading;
  final String key;
  final String value;
}

class FollowUserEvent extends SocialPostEvent {
  const FollowUserEvent({
    required this.followingId,
    required this.onComplete,
    required this.followAction,
  });

  final String followingId;
  final Function(bool) onComplete;
  final FollowAction followAction;
}

/// Removes all posts by [userId] from Following/Feeds tabs and refreshes from API.
class PurgeAuthorFromFollowFeedsEvent extends SocialPostEvent {
  const PurgeAuthorFromFollowFeedsEvent(this.userId);

  final String userId;
}

class SavePostEvent extends SocialPostEvent {
  const SavePostEvent({
    required this.postId,
    required this.onComplete,
    required this.isSaved,
  });

  final String postId;
  final Function(bool) onComplete;
  final bool isSaved;
}

class LikePostEvent extends SocialPostEvent {
  const LikePostEvent({
    required this.postId,
    required this.userId,
    required this.likeAction,
    required this.onComplete,
  });

  final String postId;
  final String userId;
  final LikeAction likeAction;
  final Function(bool) onComplete;
}

class GetReasonEvent extends SocialPostEvent {
  GetReasonEvent({
    required this.onComplete,
    required this.reasonsFor,
  });

  final Function(List<ReportReason>?) onComplete;
  final ReasonsFor reasonsFor;
}

class ReportPostEvent extends SocialPostEvent {
  const ReportPostEvent({
    required this.postId,
    required this.message,
    required this.reason,
    required this.onComplete,
  });

  final String postId;
  final String message;
  final String reason;
  final Function(bool, String) onComplete;
}

class ReportEvent extends SocialPostEvent {
  const ReportEvent({
    required this.contentId,
    required this.reportReason,
    required this.onComplete,
    this.showToastOnSuccess = true,
  });

  final String contentId;
  final ReportReason reportReason;
  final bool showToastOnSuccess;
  final Function(bool isSuccess) onComplete;
}

class GetSocialProductsEvent extends SocialPostEvent {
  GetSocialProductsEvent({
    required this.postId,
    this.isFromPagination = false,
    this.productIds,
  });

  final String postId;
  final bool? isFromPagination;
  final List<String>? productIds;
}

class DeletePostEvent extends SocialPostEvent {
  DeletePostEvent({
    required this.onComplete,
    required this.postId,
  });

  final Function(bool) onComplete;
  final String postId;
}

class GetPostCommentsEvent extends SocialPostEvent {
  GetPostCommentsEvent({
    required this.postId,
    this.isLoading,
    this.createdComment,
    this.isPagination = false,
    this.onComplete,
    /// When true (e.g. floating comments on reel focus), host-cache mode may
    /// refresh post detail in the background after a successful comments fetch.
    this.refreshPostDetailAfterComments = false,
  });

  final String postId;
  final bool? isLoading;
  final bool isPagination;
  final CommentDataItem? createdComment;
  final Function(List<CommentDataItem> comments, {int total})? onComplete;
  final bool refreshPostDetailAfterComments;
}

class CommentActionEvent extends SocialPostEvent {
  CommentActionEvent({
    required this.postId,
    this.userId,
    this.commentId,
    required this.commentAction,
    this.isLoading,
    this.onComplete,
    this.replyText,
    this.postedBy,
    this.parentCommentId,
    this.reportReason,
    this.commentMessage,
    this.commentIds,
    this.postCommentList,
    this.commentTags,
    this.tabDataModel,
    this.postDataModel,
  });

  final String postId;
  final String? userId;
  final String? commentId;
  final List<String>? commentIds;
  final String? parentCommentId;
  final String? replyText;
  final String? postedBy;
  final CommentAction commentAction;
  final bool? isLoading;
  final Function(String, bool)? onComplete;
  final String? reportReason;
  final String? commentMessage;
  final List<CommentDataItem>? postCommentList;
  final Map<String, dynamic>? commentTags;
  final TimeLineData? postDataModel;
  final TabDataModel? tabDataModel;
}

class GetMorePostEvent extends SocialPostEvent {
  GetMorePostEvent({
    required this.isLoading,
    this.isPagination = false,
    this.isRefresh = false,
    this.onComplete,
    required this.postSectionType,
    this.memberUserId,
  });

  final bool isLoading;
  final bool isPagination;
  final bool isRefresh;
  final Function(List<TimeLineData>)? onComplete;
  final PostSectionType postSectionType;
  final String? memberUserId;
}

class GetPostCommentReplyEvent extends SocialPostEvent {
  GetPostCommentReplyEvent({
    required this.postId,
    required this.parentComment,
    this.isLoading,
  });

  final CommentDataItem parentComment;
  final String postId;
  final bool? isLoading;
}

class RemoveMentionEvent extends SocialPostEvent {
  RemoveMentionEvent({
    required this.postId,
    this.onComplete,
  });

  final String postId;
  final Function(bool)? onComplete;
}

class GetMentionedUserEvent extends SocialPostEvent {
  GetMentionedUserEvent({
    required this.postId,
    required this.page,
    this.onComplete,
  });

  final String postId;
  final int page;
  final Function(List<SocialUserData> users, bool hasMore)? onComplete;
}

class GetPostInsightDetailsEvent extends SocialPostEvent {
  GetPostInsightDetailsEvent({
    this.postId,
    this.data,
    this.isLoading = false,
    this.callPostDetailsApi = true,
    this.timeSeriesStart,
    this.timeSeriesEnd,
  });

  final String? postId;
  final TimeLineData? data;
  final bool isLoading;
  final bool callPostDetailsApi;
  final String? timeSeriesStart;
  final String? timeSeriesEnd;
}

class GetPostInsightTimeSeriesEvent extends SocialPostEvent {
  GetPostInsightTimeSeriesEvent({
    required this.postId,
    required this.start,
    required this.end,
    this.isLoading = false,
  });

  final String postId;
  final String start;
  final String end;
  final bool isLoading;
}

class GetTrendingSoundsEvent extends SocialPostEvent {
  GetTrendingSoundsEvent({
    required this.isLoading,
    this.page = 1,
    this.limit = 20,
  });

  final bool isLoading;
  final int page;
  final int limit;
}

class GetRecommendedSoundsEvent extends SocialPostEvent {
  GetRecommendedSoundsEvent({
    required this.isLoading,
    this.page = 1,
    this.limit = 20,
  });

  final bool isLoading;
  final int page;
  final int limit;
}

class GetSavedSoundsEvent extends SocialPostEvent {
  GetSavedSoundsEvent({
    required this.isLoading,
    this.skip = 0,
    this.limit = 20,
  });

  final bool isLoading;
  final int skip;
  final int limit;
}

class PlayPauseVideoEvent extends SocialPostEvent {
  PlayPauseVideoEvent({
    required this.play,
    this.pausePlayback = true,
    this.scopedPostSection,
  });

  bool play;

  /// When `false`, only blocks auto-advance to the next clip/post (overlay open)
  /// without pausing media — used for post-feed comment/share sheets.
  final bool pausePlayback;

  /// When set, only players for this home/overlay tab section react.
  /// Null broadcasts to every section (host pause/resume, tab handoff pause).
  final PostSectionType? scopedPostSection;
}

class OnShareSuccessEvent extends SocialPostEvent {
  OnShareSuccessEvent({required this.shareSuccessData});
  final OnShareRequest shareSuccessData;
}
