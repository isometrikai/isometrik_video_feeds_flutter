part of 'post_bloc.dart';

abstract class PostEvent {
  const PostEvent();
}

class StartPost extends PostEvent {
  const StartPost();
}

class FollowingPostsLoadedEvent extends PostEvent {
  FollowingPostsLoadedEvent(this.followingPosts);

  final List<PostDataModel>? followingPosts;
}

class TrendingPostsLoadedEvent extends PostEvent {
  TrendingPostsLoadedEvent(this.trendingPosts);

  final List<PostDataModel>? trendingPosts;
}
