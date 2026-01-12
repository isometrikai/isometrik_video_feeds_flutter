part of 'social_post_bloc.dart';

abstract class SocialPostState {}

class PostLoadingState extends SocialPostState {
  PostLoadingState({
    required this.isLoading,
    this.postType,
  });

  final bool? isLoading;
  final PostSectionType? postType;
}

class SocialPostLoadedState extends SocialPostState {
  SocialPostLoadedState({
    required this.postType,
    required this.postList,
    required this.userId,
  });

  final PostSectionType postType;
  final List<TimeLineData> postList;
  final String userId;
}

class PostSuccessState extends SocialPostState {
  PostSuccessState({
    required this.userId,
  });
  final String userId;
}

class SocialPostError extends SocialPostState {
  SocialPostError(this.message);

  final String message;
}

class SocialProductsLoading extends SocialPostState {}

class SocialProductsLoaded extends SocialPostState {
  SocialProductsLoaded({
    required this.productList,
    required this.totalProductCount,
  });

  final List<ProductDataModel>? productList;
  final int totalProductCount;
}

class LoadPostCommentState extends SocialPostState {
  LoadPostCommentState({
    required this.postCommentsList,
    this.myUserId,
  });

  final List<CommentDataItem>? postCommentsList;
  final String? myUserId;
}

class LoadPostCommentRepliesState extends SocialPostState {
  LoadPostCommentRepliesState({
    required this.postCommentRepliesList,
    this.myUserId,
    required this.parentCommentId,
  });

  final List<CommentDataItem>? postCommentRepliesList;
  final String? myUserId;
  final String parentCommentId;
}

class LoadingPostComment extends SocialPostState {}

class LoadingPostCommentReplies extends SocialPostState {
  LoadingPostCommentReplies({required this.parentCommentId});
  final String parentCommentId;
}

class PostInsightDetailsLoading extends SocialPostState {
  PostInsightDetailsLoading({this.postId, this.postData});
  String? postId;
  TimeLineData? postData;
}

class PostInsightDetails extends SocialPostState {
  PostInsightDetails({this.postId, this.postData, this.insightData});
  String? postId;
  TimeLineData? postData;
  InsightsResponse? insightData;
}

class PlayPauseVideoState extends SocialPostState {
  PlayPauseVideoState({required this.play});
  bool play;
}
