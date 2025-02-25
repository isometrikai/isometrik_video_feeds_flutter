part of 'post_bloc.dart';

abstract class PostEvent {
  const PostEvent();
}

class StartPost extends PostEvent {
  const StartPost();
}

class GetFollowingPostEvent extends PostEvent {
  GetFollowingPostEvent({
    required this.isLoading,
    required this.isPagination,
    this.isRefresh = false,
  });

  final bool isLoading;
  final bool isPagination;
  final bool isRefresh;
}

class GetTrendingPostEvent extends PostEvent {
  GetTrendingPostEvent({
    required this.isLoading,
    this.isPagination = false,
    this.isRefresh = false,
  });

  final bool isLoading;
  final bool isPagination;
  final bool isRefresh;
}

class FollowUserEvent extends PostEvent {
  const FollowUserEvent({
    required this.followingId,
    required this.onComplete,
  });
  final String followingId;
  final Function(bool) onComplete;
}

class CreatePostEvent extends PostEvent {
  CreatePostEvent({required this.createPostRequest});

  final CreatePostRequest? createPostRequest;
}

class CameraEvent extends PostEvent {
  CameraEvent({required this.context});
  final BuildContext context;
}

class SavePostEvent extends PostEvent {
  const SavePostEvent({
    required this.postId,
    required this.onComplete,
  });
  final String postId;
  final Function(bool) onComplete;
}

class LikePostEvent extends PostEvent {
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

class GetReasonEvent extends PostEvent {
  const GetReasonEvent({required this.onComplete});
  final Function(List<String>?) onComplete;
}

class ReportPostEvent extends PostEvent {
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
