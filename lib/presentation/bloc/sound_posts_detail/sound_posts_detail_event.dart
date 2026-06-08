part of 'sound_posts_detail_bloc.dart';

abstract class SoundPostsDetailEvent {
  const SoundPostsDetailEvent();
}

class GetSoundPostsDetailEvent extends SoundPostsDetailEvent {
  const GetSoundPostsDetailEvent({
    required this.soundId,
    this.isFromPagination = false,
  });

  final String soundId;
  final bool isFromPagination;
}

class RefreshSoundPostsDetailEvent extends SoundPostsDetailEvent {
  const RefreshSoundPostsDetailEvent({required this.soundId});

  final String soundId;
}
