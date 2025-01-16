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
