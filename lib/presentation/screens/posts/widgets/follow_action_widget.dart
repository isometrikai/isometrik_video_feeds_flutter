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
    this.isTargetPrivate = false,
    this.initialFollowStatus,
    this.initialIsRequested,
  });

  final String? postId;
  final String userId;
  final bool? isFollowing;
  final bool callProfileApi;

  /// When true, the follow API will send `is_private: 1` and labels use "Request" / "Requested".
  final bool isTargetPrivate;

  /// [FollowRelationshipStatus] from host or API (0 none, 1 following, 2 requested).
  final num? initialFollowStatus;

  /// From [`is_requested`] / [`isRequested`] when backend sends it; keeps UI correct without model churn.
  final bool? initialIsRequested;

  final Widget Function(
    bool isLoading,
    bool isFollowing,
    bool followRequestPending,
    Future<void> Function({
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
  bool followRequestPending = false;
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
    followRequestPending = FollowRelationshipUi.isRelationshipRequested(
      isRequested: widget.initialIsRequested,
      followStatus: widget.initialFollowStatus,
    );
    debugPrint(
      'FollowActionWidget:- initState:- userId: $userId, loggedInUserId: $loggedInUserId, isFollowing: $isFollowing, isLoading: $isLoading, pending: $followRequestPending',
    );
    _updateFollowState();
  }

  _updateFollowState() async {
    userId = widget.userId;
    postId = widget.postId;
    loggedInUserId = cubit.userId;
    isFollowing = widget.isFollowing ?? false;
    followRequestPending = FollowRelationshipUi.isRelationshipRequested(
      isRequested: widget.initialIsRequested,
      followStatus: widget.initialFollowStatus,
    );
    var updatedFollowState = isFollowing;
    var updatedPending = followRequestPending;
    if (postId != null) {
      final postData = cubit.getPostById(postId!);
      final u = postData?.user;
      updatedFollowState = postData?.isFollowing ?? updatedFollowState;
      updatedPending = FollowRelationshipUi.isRelationshipRequested(
        isRequested: u?.isRequested ?? widget.initialIsRequested,
        followStatus: u?.followStatus ?? widget.initialFollowStatus,
      );
      final fs = u?.followStatus?.toInt();
      if (fs != null) {
        if (fs == FollowRelationshipStatus.following) {
          updatedFollowState = true;
        } else if (updatedPending) {
          updatedFollowState = false;
        }
      }
    } else if (widget.callProfileApi) {
      cubit.getUserFollowState(userId, isFollowing: isFollowing);
    }
    if (mounted) {
      setState(() {
        isFollowing = updatedFollowState;
        followRequestPending = updatedPending;
      });
    }
    debugPrint(
      'FollowActionWidget:- _updateFollowState:- userId: $userId, isFollowing: $isFollowing, isLoading: $isLoading, pending: $followRequestPending',
    );
  }

  @override
  void didUpdateWidget(FollowActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.postId != widget.postId ||
        oldWidget.isFollowing != widget.isFollowing ||
        oldWidget.initialFollowStatus != widget.initialFollowStatus ||
        oldWidget.initialIsRequested != widget.initialIsRequested) {
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
      await IsrVideoReelConfig.socialConfig.socialCallBackConfig?.onLoginInvoked
          ?.call();
    }
    isUserLoggedIn = await cubit.isUserLoggedIn;
    if (!isUserLoggedIn) return;

    if (followRequestPending) {
      await cubit.unfollowUser(
        userId,
        fromPendingRequest: true,
        reelData: reelData,
        postSectionType: postSectionType,
        watchDuration: watchDuration,
        apiCallBack: apiCallBack,
      );
    } else if (isFollowing) {
      cubit.unfollowUser(
        userId,
        reelData: reelData,
        postSectionType: postSectionType,
        watchDuration: watchDuration,
        apiCallBack: apiCallBack,
      );
    } else {
      await cubit.followUser(
        userId,
        reelData: reelData,
        postSectionType: postSectionType,
        watchDuration: watchDuration,
        apiCallBack: apiCallBack,
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      context.attachBlocIfNeeded<IsmSocialActionCubit>(
        child: BlocConsumer<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: (previous, current) {
            if (current is IsmFollowUserState && current.userId == userId) {
              return true;
            }
            if (current is IsmFollowActionListenerState &&
                current.userId == userId) {
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
          listenWhen: (previous, current) =>
              current is IsmUserChangedActionListenerState,
          listener: (context, state) {
            if (state is IsmUserChangedActionListenerState) {
              loggedInUserId = state.userId;
              debugPrint(
                'FollowActionWidget IsmUserChangedActionListenerState -> ${state.userId}',
              );
            }
          },
          builder: (context, state) {
            if (state is IsmFollowUserState && state.userId == userId) {
              isLoading = state.isLoading;
              isFollowing = state.isFollowing;
              followRequestPending = state.followRequestPending;
            } else if (state is IsmFollowActionListenerState &&
                state.userId == userId) {
              isFollowing = state.isFollowing;
              followRequestPending = state.followRequestPending;
              isLoading = false;
            } else if (state is IsmFollowErrorState && state.userId == userId) {
              isLoading = false;
              isFollowing = state.wasFollowing;
              followRequestPending = state.wasRequestPending;
              debugPrint('❌ Follow/Unfollow error: ${state.errorMessage}');
            }
            debugPrint(
              'FollowActionWidget:- builder :- state: $state, userId: $userId, isFollowing: $isFollowing, pending: $followRequestPending, isLoading: $isLoading',
            );
            if (userId == loggedInUserId) {
              return const SizedBox.shrink();
            }
            return widget.builder(
                isLoading, isFollowing, followRequestPending, _onTap);
          },
        ),
      );
}
