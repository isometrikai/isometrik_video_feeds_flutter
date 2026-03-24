import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class FollowActionWidget extends StatefulWidget {
  const FollowActionWidget({
    super.key,
    this.postId,
    required this.userId,
    required this.builder,
    this.isFollowing,
    this.callProfileApi = false,
  });

  final String? postId;
  final String userId;
  final bool? isFollowing;
  final bool callProfileApi;
  final Widget Function(
    bool isLoading,
    bool isFollowing,
    Function({
      ReelsData? reelData,
      PostSectionType? postSectionType,
      int? watchDuration,
      Future<bool> Function()? apiCallBack,
    }) onTap,
  ) builder;

  @override
  State<FollowActionWidget> createState() => _FollowActionWidgetState();
}

class _FollowActionWidgetState extends State<FollowActionWidget> {
  late IsmSocialActionCubit cubit;

  bool isLoading = false;
  bool isFollowing = false;
  late String userId;
  late String? postId;
  late String loggedInUserId;

  @override
  void initState() {
    super.initState();
    cubit = context.getOrCreateBloc<IsmSocialActionCubit>();
    userId = widget.userId;
    postId = widget.postId;
    loggedInUserId = cubit.userId;
    isFollowing = widget.isFollowing ?? false;
    debugPrint('FollowActionWidget:- initState:- userId: $userId, loggedInUserId: $loggedInUserId, isFollowing: $isFollowing, isLoading: $isLoading');
    _updateFollowState();
  }

  _updateFollowState() async {
    userId = widget.userId;
    postId = widget.postId;
    loggedInUserId = cubit.userId;
    isFollowing = widget.isFollowing ?? false;
    var updatedFollowState = isFollowing;
    if (postId != null) {
      final postData = cubit.getPostById(postId!);
      updatedFollowState = postData?.isFollowing ?? updatedFollowState;
    } else if (widget.callProfileApi) {
      cubit.getUserFollowState(userId, isFollowing: isFollowing);
    }
    if (mounted && isFollowing != updatedFollowState) {
      setState(() {
        isFollowing = updatedFollowState;
      });
    }
    debugPrint('FollowActionWidget:- _updateFollowState:- userId: $userId, isFollowing: $isFollowing, isLoading: $isLoading');
  }

  @override
  void didUpdateWidget(FollowActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload state if userId or postId changed, or if widget isFollowing prop changed
    if (oldWidget.userId != widget.userId ||
        oldWidget.postId != widget.postId ||
        oldWidget.isFollowing != widget.isFollowing) {
      _updateFollowState();
    }
  }

  Future<void> _onTap({
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    debugPrint('IsmSocialActionCubit hashCode -> ${cubit.hashCode}');
    if (isLoading) return;
    var isUserLoggedIn = await cubit.isUserLoggedIn;
    if (!isUserLoggedIn) {
      await IsrVideoReelConfig.socialConfig.socialCallBackConfig?.onLoginInvoked?.call();
    }
    isUserLoggedIn = await cubit.isUserLoggedIn;
    if (!isUserLoggedIn) return;
    if (isFollowing) {
      cubit.unfollowUser(userId,
          reelData: reelData,
          postSectionType: postSectionType,
          watchDuration: watchDuration,
          apiCallBack: apiCallBack);
    } else {
      cubit.followUser(userId,
          reelData: reelData,
          postSectionType: postSectionType,
          watchDuration: watchDuration,
          apiCallBack: apiCallBack);
    }
  }

  @override
  Widget build(BuildContext context) =>
      context.attachBlocIfNeeded<IsmSocialActionCubit>(
        child: BlocConsumer<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: (previous, current) {
            // Listen to IsmFollowUserState, IsmFollowActionListenerState, and IsmFollowErrorState
            // This ensures updates from outside the package (like profile page) are reflected
            if (current is IsmFollowUserState && current.userId == userId) {
              return true;
            }
            if (current is IsmFollowActionListenerState && current.userId == userId) {
              return true;
            }
            if (current is IsmFollowErrorState && current.userId == userId) {
              return true;
            }
            if (current is IsmUserChangedActionListenerState) {
              return true;
            }
            return false;
          },
          listenWhen: (previous, current) => current is IsmUserChangedActionListenerState,
          listener: (context, state) {
            if (state is IsmUserChangedActionListenerState) {
              loggedInUserId = state.userId;
              debugPrint('FollowActionWidget IsmUserChangedActionListenerState -> ${state.userId}');
            }
          },
          builder: (context, state) {
            if (state is IsmFollowUserState && state.userId == userId) {
              isLoading = state.isLoading;
              isFollowing = state.isFollowing;
            } else if (state is IsmFollowActionListenerState && state.userId == userId) {
              // debugPrint('FollowActionWidget:- builder :- state: $state, stateUserId: ${state.userId}, userId: $userId, isFollowing: $isFollowing, isLoading: $isLoading');
              // Update state from listener state (emitted after follow/unfollow actions)
              isFollowing = state.isFollowing;
              isLoading = false; // Listener state means action is complete
            } else if (state is IsmFollowErrorState && state.userId == userId) {
              // Handle error state - reset loading, keep previous following state
              isLoading = false;
              isFollowing = state.wasFollowing;
              // Error message is already shown via ErrorHandler in Cubit
              debugPrint('❌ Follow/Unfollow error: ${state.errorMessage}');
            }
            debugPrint('FollowActionWidget:- builder :- state: $state, userId: $userId, isFollowing: $isFollowing, isLoading: $isLoading');
            debugPrint('IsmSocialActionCubit hashCode -> ${cubit.hashCode}');
            if (userId == loggedInUserId) { // self user
                return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: isLoading ? null : _onTap,
              child: widget.builder(isLoading, isFollowing, _onTap),
            );
          },
        ),
      );
}
