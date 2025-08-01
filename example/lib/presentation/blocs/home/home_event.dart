part of 'home_bloc.dart';

abstract class HomeEvent {
  const HomeEvent();
}

class LoadHomeData extends HomeEvent {
  LoadHomeData();
}

class GetFollowingPostEvent extends HomeEvent {
  GetFollowingPostEvent({
    required this.isLoading,
    required this.isPagination,
    this.isRefresh = false,
    this.onComplete,
  });

  final bool isLoading;
  final bool isPagination;
  final bool isRefresh;
  final Function(List<isr.PostDataModel>)? onComplete;
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
  final Function(List<isr.TimeLineData>)? onComplete;
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
  final Function(List<isr.PostDataModel>)? onComplete;
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
  });

  final String followingId;
  final Function(bool) onComplete;
}

class SavePostEvent extends HomeEvent {
  const SavePostEvent({
    required this.postId,
    required this.onComplete,
  });

  final String postId;
  final Function(bool) onComplete;
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
  const GetReasonEvent({required this.onComplete});

  final Function(List<String>?) onComplete;
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
