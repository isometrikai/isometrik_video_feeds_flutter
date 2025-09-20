part of 'home_bloc.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {
  HomeInitial();
}

class HomeLoading extends HomeState {
  HomeLoading({this.isLoading = false});

  final bool? isLoading;
}

class HomeLoaded extends HomeState {
  HomeLoaded({
    required this.timeLinePosts,
    required this.trendingPosts,
    required this.userId,
  });

  final List<TimeLineData>? timeLinePosts;
  final List<TimeLineData>? trendingPosts;
  final String userId;
}

class HomeError extends HomeState {
  HomeError(this.message);

  final String message;
}

class PostDetailsLoading extends HomeState {}

class PostDetailsLoaded extends HomeState {
  PostDetailsLoaded({
    required this.productList,
    required this.totalProductCount,
  });

  final List<ProductDataModel>? productList;
  final int totalProductCount;
}

class LoadPostCommentState extends HomeState {
  LoadPostCommentState({
    required this.postCommentsList,
    this.myUserId,
  });

  final List<CommentDataItem>? postCommentsList;
  final String? myUserId;
}

class LoadingPostComment extends HomeState {}
