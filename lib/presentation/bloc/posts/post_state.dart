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

// Posts States
class PostsLoadedState extends PostState {
  PostsLoadedState({required this.postsList, required this.timeLinePostList});
  final List<PostDataModel>? postsList;
  final List<TimeLineData>? timeLinePostList;
}

class PostLoadingState extends PostState {
  PostLoadingState({
    required this.userId,
  });
  final String userId;
}

class PostSuccessState extends PostState {
  PostSuccessState({
    required this.userId,
  });
  final String userId;
}
