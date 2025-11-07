part of 'social_post_bloc.dart';

abstract class SocialPostState {}

class PostInitial extends SocialPostState {
  PostInitial({required this.isLoading});

  final bool? isLoading;
}

class UserInformationLoaded extends SocialPostState {
  UserInformationLoaded({this.userInfoClass, required this.userId});

  final UserInfoClass? userInfoClass;
  final String userId;
}

class PostLoadingState extends SocialPostState {
  PostLoadingState({
    required this.userId,
  });
  final String userId;
}

class PostSuccessState extends SocialPostState {
  PostSuccessState({
    required this.userId,
  });
  final String userId;
}
