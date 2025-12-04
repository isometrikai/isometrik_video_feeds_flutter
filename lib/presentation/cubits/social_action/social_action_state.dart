part of 'social_action_cubit.dart';

class IsmSocialActionState {}

class IsmFollowUserState extends IsmSocialActionState{
  IsmFollowUserState({required this.isFollowing, this.isLoading = false, required this.userId});
  String userId;
  bool isFollowing;
  bool isLoading;
}

class IsmLikePostState extends IsmSocialActionState{
  IsmLikePostState({required this.isLiked, this.isLoading = false, required this.postId});
  String postId;
  bool isLiked;
  bool isLoading;
}

class IsmSavePostState extends IsmSocialActionState{
  IsmSavePostState({required this.isSaved, this.isLoading = false, required this.postId});
  String postId;
  bool isSaved;
  bool isLoading;
}

class IsmFollowActionListenerState extends IsmSocialActionState {
  IsmFollowActionListenerState({required this.isFollowing, required this.userId});

  String userId;
  bool isFollowing;
}

