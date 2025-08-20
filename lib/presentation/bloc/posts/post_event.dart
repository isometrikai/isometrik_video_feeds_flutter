part of 'post_bloc.dart';

abstract class PostEvent {
  const PostEvent();
}

class StartPost extends PostEvent {
  const StartPost();
}
