part of 'post_bloc.dart';

abstract class PostState {}

class PostInitial extends PostState {
  PostInitial({required this.isLoading});

  final bool? isLoading;
}

class PostDataLoadedState extends PostState {
  PostDataLoadedState({required this.postDataList});

  final List<PostData> postDataList;
}

class UserInformationLoaded extends PostState {
  UserInformationLoaded({this.userInfoClass});

  final UserInfoClass? userInfoClass;
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
  LikeSuccessState({
    required this.postId,
    required this.likeAction,
  });
  final String postId;
  final LikeAction likeAction;
}
