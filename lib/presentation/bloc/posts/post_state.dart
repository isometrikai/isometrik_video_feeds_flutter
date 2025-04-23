part of 'post_bloc.dart';

abstract class PostState {}

class PostInitial extends PostState {
  PostInitial({required this.isLoading});

  final bool? isLoading;
}

class UserInformationLoaded extends PostState {
  UserInformationLoaded({this.userInfoClass, required this.userId});

  final UserInfoClass? userInfoClass;
  final String userId;
}

// Following Posts States
class FollowingPostsLoadedState extends PostState {
  FollowingPostsLoadedState({required this.followingPosts});
  final List<PostDataModel>? followingPosts;
}

// Trending Posts States
class TrendingPostsLoadedState extends PostState {
  TrendingPostsLoadedState({required this.trendingPosts});
  final List<PostDataModel>? trendingPosts;
}

class FollowLoadingState extends PostState {
  FollowLoadingState({
    required this.userId,
  });
  final String userId;
}

class FollowSuccessState extends PostState {
  FollowSuccessState({
    required this.userId,
  });
  final String userId;
}

class SavePostSuccessState extends PostState {
  SavePostSuccessState({
    required this.postId,
  });
  final String postId;
}

class LikeSuccessState extends PostState {
  // LikeSuccessState({
  //   required this.postId,
  //   required this.likeAction,
  // });
  // final String postId;
  // final LikeAction likeAction;
}

class MediaSelectedState extends PostState {
  // MediaSelectedState({
  //   this.postAttributeClass,
  // });
  // final PostAttributeClass? postAttributeClass;
}

class UploadingCoverImageState extends PostState {
  // Progress for cover image
  UploadingCoverImageState(this.progress);
  final double progress;
}

class UploadingMediaState extends PostState {
  // Progress for media
  UploadingMediaState(this.progress);
  final double progress;
}

class CoverImageSelected extends PostState {
  CoverImageSelected({
    this.coverImage,
  });
  final String? coverImage;
}
