part of 'social_action_cubit.dart';

class IsmSocialActionState {}

// ---------------- Follow State ---------------- //
class IsmFollowUserState extends IsmSocialActionState {
  IsmFollowUserState({
    required this.userId,
    required this.isFollowing,
    this.isLoading = false,
  });

  final String userId;
  final bool isFollowing;
  final bool isLoading;

  IsmFollowUserState copyWith({
    String? userId,
    bool? isFollowing,
    bool? isLoading,
  }) =>
      IsmFollowUserState(
        userId: userId ?? this.userId,
        isFollowing: isFollowing ?? this.isFollowing,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ---------------- Like State ---------------- //
class IsmLikePostState extends IsmSocialActionState {
  IsmLikePostState({
    required this.postId,
    required this.likeCount,
    required this.isLiked,
    this.isLoading = false,
  });

  final String postId;
  final int likeCount;
  final bool isLiked;
  final bool isLoading;

  IsmLikePostState copyWith({
    String? postId,
    int? likeCount,
    bool? isLiked,
    bool? isLoading,
  }) =>
      IsmLikePostState(
        postId: postId ?? this.postId,
        likeCount: likeCount ?? this.likeCount,
        isLiked: isLiked ?? this.isLiked,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ---------------- Save State ---------------- //
class IsmSavePostState extends IsmSocialActionState {
  IsmSavePostState({
    required this.postId,
    required this.isSaved,
    this.isLoading = false,
  });

  final String postId;
  final bool isSaved;
  final bool isLoading;

  IsmSavePostState copyWith({
    String? postId,
    bool? isSaved,
    bool? isLoading,
  }) =>
      IsmSavePostState(
        postId: postId ?? this.postId,
        isSaved: isSaved ?? this.isSaved,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ---------------- Listener States ---------------- //
class IsmFollowActionListenerState extends IsmSocialActionState {
  IsmFollowActionListenerState({
    required this.userId,
    required this.isFollowing,
  });

  final String userId;
  final bool isFollowing;

  IsmFollowActionListenerState copyWith({
    String? userId,
    bool? isFollowing,
  }) =>
      IsmFollowActionListenerState(
        userId: userId ?? this.userId,
        isFollowing: isFollowing ?? this.isFollowing,
      );
}

class IsmLikeActionListenerState extends IsmSocialActionState {
  IsmLikeActionListenerState({
    required this.postId,
    required this.isLiked,
  });

  final String postId;
  final bool isLiked;

  IsmLikeActionListenerState copyWith({
    String? postId,
    bool? isLiked,
  }) =>
      IsmLikeActionListenerState(
        postId: postId ?? this.postId,
        isLiked: isLiked ?? this.isLiked,
      );
}

class IsmSaveActionListenerState extends IsmSocialActionState {
  IsmSaveActionListenerState({
    required this.postId,
    required this.isSaved,
  });

  final String postId;
  final bool isSaved;

  IsmSaveActionListenerState copyWith({
    String? postId,
    bool? isSaved,
  }) =>
      IsmSaveActionListenerState(
        postId: postId ?? this.postId,
        isSaved: isSaved ?? this.isSaved,
      );
}
