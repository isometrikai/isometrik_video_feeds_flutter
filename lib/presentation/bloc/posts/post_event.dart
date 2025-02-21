part of 'post_bloc.dart';

abstract class PostEvent {
  const PostEvent();
}

class StartPost extends PostEvent {
  const StartPost();
}

class GetFollowingPostEvent extends PostEvent {
  GetFollowingPostEvent({required this.isLoading});

  final bool isLoading;
}

class CreatePostEvent extends PostEvent {
  CreatePostEvent({required this.createPostRequest});

  final CreatePostRequest? createPostRequest;
}

class CameraEvent extends PostEvent {}
