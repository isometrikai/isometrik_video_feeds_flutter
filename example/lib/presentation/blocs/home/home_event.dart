part of 'home_bloc.dart';

abstract class HomeEvent {
  const HomeEvent();
}

class LoadHomeData extends HomeEvent {
  LoadHomeData();
}

class LoadPostsEvent extends HomeEvent {
  LoadPostsEvent({
    required this.timeLinePostList,
    required this.trendingPosts,
  });

  final List<TimeLineData> timeLinePostList;
  final List<TimeLineData> trendingPosts;
}

class GetTimeLinePostEvent extends HomeEvent {
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

class GetTrendingPostEvent extends HomeEvent {
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

class GetCloudDetailsEvent extends HomeEvent {
  GetCloudDetailsEvent({
    required this.isLoading,
    required this.key,
    required this.value,
  });

  final bool isLoading;
  final String key;
  final String value;
}

class FollowUserEvent extends HomeEvent {
  const FollowUserEvent({
    required this.followingId,
    required this.onComplete,
    required this.followAction,
  });

  final String followingId;
  final Function(bool) onComplete;
  final FollowAction followAction;
}

class SavePostEvent extends HomeEvent {
  const SavePostEvent({
    required this.postId,
    required this.onComplete,
    required this.isSaved,
  });

  final String postId;
  final Function(bool) onComplete;
  final bool isSaved;
}

class LikePostEvent extends HomeEvent {
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

class GetReasonEvent extends HomeEvent {
  GetReasonEvent({
    required this.onComplete,
    this.reasonsFor,
  });

  final Function(List<String>?) onComplete;
  final ReasonsFor? reasonsFor;
}

class ReportPostEvent extends HomeEvent {
  const ReportPostEvent({
    required this.postId,
    required this.message,
    required this.reason,
    required this.onComplete,
  });

  final String postId;
  final String message;
  final String reason;
  final Function(bool) onComplete;
}

class GetPostDetailsEvent extends HomeEvent {
  GetPostDetailsEvent({
    this.isFromPagination = false,
    this.productIds,
  });

  final bool? isFromPagination;
  final List<String>? productIds;
}

class DeletePostEvent extends HomeEvent {
  DeletePostEvent({
    required this.onComplete,
    required this.postId,
  });

  final Function(bool) onComplete;
  final String postId;
}

class GetPostCommentsEvent extends HomeEvent {
  GetPostCommentsEvent({
    required this.postId,
    this.isLoading,
  });

  final String postId;
  final bool? isLoading;
}

class CommentActionEvent extends HomeEvent {
  CommentActionEvent({
    this.postId,
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
  });

  final String? postId;
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
}
