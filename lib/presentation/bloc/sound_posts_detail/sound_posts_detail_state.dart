part of 'sound_posts_detail_bloc.dart';

abstract class SoundPostsDetailState {
  const SoundPostsDetailState();
}

class SoundPostsDetailInitialState extends SoundPostsDetailState {
  const SoundPostsDetailInitialState();
}

class SoundPostsDetailLoadingState extends SoundPostsDetailState {
  const SoundPostsDetailLoadingState({required this.isLoading});

  final bool isLoading;
}

class SoundPostsDetailLoadedState extends SoundPostsDetailState {
  const SoundPostsDetailLoadedState({
    required this.posts,
    required this.hasMoreData,
    required this.currentPage,
    required this.soundId,
    this.totalPosts,
  });

  final List<TimeLineData> posts;
  final bool hasMoreData;
  final int currentPage;
  final String soundId;
  final int? totalPosts;
}

class SoundPostsDetailErrorState extends SoundPostsDetailState {
  const SoundPostsDetailErrorState({required this.error});

  final String error;
}
