import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class LikeActionWidget extends StatefulWidget {
  const LikeActionWidget({
    super.key,
    required this.postId,
    required this.builder,
    this.initialLikeCount,
    this.initialIsLiked,
  });

  final String postId;
  final int? initialLikeCount;
  final bool? initialIsLiked;
  final Widget Function(
    bool isLoading,
    bool isLiked,
    int likeCount,
    Function({
      ReelsData? reelData,
      PostSectionType? postSectionType,
      int? watchDuration,
      Future<bool> Function()? apiCallBack,
    }) onTap,
  ) builder;

  @override
  State<LikeActionWidget> createState() => _LikeActionWidgetState();
}

class _LikeActionWidgetState extends State<LikeActionWidget> {
  late IsmSocialActionCubit cubit;

  bool isLoading = false;
  bool isLiked = false;
  int likeCount = 0;
  late String postId;

  @override
  void initState() {
    super.initState();
    cubit = context.getOrCreateBloc<IsmSocialActionCubit>();
    postId = widget.postId;
    likeCount = widget.initialLikeCount ?? 0;
    isLiked = widget.initialIsLiked ?? false;
    cubit.loadPostLikeState(widget.postId);
  }

  @override
  void didUpdateWidget(LikeActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload state if postId changed
    if (oldWidget.postId != widget.postId) {
      postId = widget.postId;
      cubit.loadPostLikeState(postId);
    }
  }

  @override
  void dispose() {
    // IMPORTANT: Do NOT close the cubit here!
    // - The cubit is a singleton managed by the DI container
    // - BlocProvider.value does NOT close the cubit when the widget is disposed
    // - Closing it here would break the singleton pattern and affect other widgets
    super.dispose();
  }

  void _onTap({
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    if (isLoading) return;
    var isUserLoggedIn = await cubit.isUserLoggedIn;
    if (!isUserLoggedIn) {
      await IsrVideoReelConfig.socialConfig.socialCallBackConfig?.onLoginInvoked
          ?.call();
    }
    isUserLoggedIn = await cubit.isUserLoggedIn;
    if (!isUserLoggedIn) return;
    if (isLiked) {
      cubit.unLikePost(
        postId,
        likeCount,
        reelData: reelData,
        watchDuration: watchDuration,
        postSectionType: postSectionType,
        apiCallBack: apiCallBack,
      );
    } else {
      cubit.likePost(
        postId,
        likeCount,
        reelData: reelData,
        watchDuration: watchDuration,
        postSectionType: postSectionType,
        apiCallBack: apiCallBack,
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      context.attachBlocIfNeeded<IsmSocialActionCubit>(
        child: BlocConsumer<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: (previous, current) {
            // Listen to both IsmLikePostState and IsmLikeActionListenerState
            // This ensures updates from outside the package are reflected
            if (current is IsmLikePostState && current.postId == postId) {
              return true;
            }
            if (current is IsmLikeActionListenerState &&
                current.postId == postId) {
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
              isLiked = false;
              if (state.userId.isNotEmpty) { // not guest get like state
                cubit.loadPostLikeState(widget.postId);
              }
            }
          },
          builder: (context, state) {
            if (state is IsmLikePostState && state.postId == postId) {
              isLoading = state.isLoading;
              isLiked = state.isLiked;
              likeCount = state.likeCount;
            } else if (state is IsmLikeActionListenerState &&
                state.postId == postId) {
              // Update state from listener state (emitted after like/unlike actions)
              // Note: Listener state doesn't have likeCount, so we keep the current value
              isLiked = state.isLiked;
              isLoading = false; // Listener state means action is complete
              likeCount = state.likeCount;
            }
            return widget.builder(isLoading, isLiked, likeCount, _onTap);
          },
        ),
      );
}
