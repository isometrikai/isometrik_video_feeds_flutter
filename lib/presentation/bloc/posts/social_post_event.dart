part of 'social_post_bloc.dart';

abstract class SocialPostEvent {
  const SocialPostEvent();
}

class StartPost extends SocialPostEvent {
  const StartPost();
}
