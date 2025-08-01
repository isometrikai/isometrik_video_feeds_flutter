part of 'post_bloc.dart';

abstract class PostEvent {
  const PostEvent();
}

class StartPost extends PostEvent {
  const StartPost();
}

class PostsLoadedEvent extends PostEvent {
  PostsLoadedEvent(this.postsList, this.timeLinePostList);

  final List<PostDataModel>? postsList;
  final List<TimeLineData>? timeLinePostList;
}
