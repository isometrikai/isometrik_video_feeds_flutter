import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class _LikeActionViewModel {
  const _LikeActionViewModel({
    required this.syncedFromCubit,
    required this.isLoading,
    required this.isLiked,
    required this.likeCount,
  });

  /// Distinguishes reel seed data from cubit-confirmed data so a load that
  /// resolves to the same count (e.g. 0) still triggers a repaint.
  final bool syncedFromCubit;
  final bool isLoading;
  final bool isLiked;
  final int likeCount;

  @override
  bool operator ==(Object other) =>
      other is _LikeActionViewModel &&
      other.syncedFromCubit == syncedFromCubit &&
      other.isLoading == isLoading &&
      other.isLiked == isLiked &&
      other.likeCount == likeCount;

  @override
  int get hashCode =>
      Object.hash(syncedFromCubit, isLoading, isLiked, likeCount);
}

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
  _LikeActionViewModel? _lastSyncedForPost;

  @override
  void initState() {
    super.initState();
    cubit = context.getOrCreateBloc<IsmSocialActionCubit>();
    cubit.loadPostLikeState(widget.postId);
  }

  @override
  void didUpdateWidget(LikeActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _lastSyncedForPost = null;
      cubit.loadPostLikeState(widget.postId);
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

  _LikeActionViewModel _fallbackViewModel() => _LikeActionViewModel(
        syncedFromCubit: false,
        isLoading: false,
        isLiked: widget.initialIsLiked ?? false,
        likeCount: widget.initialLikeCount ?? 0,
      );

  _LikeActionViewModel _selectLikeState(IsmSocialActionState state) {
    if (state is IsmLikePostState && state.postId == widget.postId) {
      _lastSyncedForPost = _LikeActionViewModel(
        syncedFromCubit: true,
        isLoading: state.isLoading,
        isLiked: state.isLiked,
        likeCount: state.likeCount,
      );
      return _lastSyncedForPost!;
    }
    if (state is IsmLikeActionListenerState && state.postId == widget.postId) {
      _lastSyncedForPost = _LikeActionViewModel(
        syncedFromCubit: true,
        isLoading: false,
        isLiked: state.isLiked,
        likeCount: state.likeCount,
      );
      return _lastSyncedForPost!;
    }
    return _lastSyncedForPost ?? _fallbackViewModel();
  }

  void _onTap({
    required _LikeActionViewModel viewModel,
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    if (viewModel.isLoading) return;
    var isUserLoggedIn = await cubit.isUserLoggedIn;
    if (!isUserLoggedIn) {
      await IsrVideoReelConfig.socialConfig.socialCallBackConfig?.onLoginInvoked
          ?.call();
    }
    isUserLoggedIn = await cubit.isUserLoggedIn;
    if (!isUserLoggedIn) return;
    if (viewModel.isLiked) {
      cubit.unLikePost(
        widget.postId,
        viewModel.likeCount,
        reelData: reelData,
        watchDuration: watchDuration,
        postSectionType: postSectionType,
        apiCallBack: apiCallBack,
      );
    } else {
      cubit.likePost(
        widget.postId,
        viewModel.likeCount,
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
        child: BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
          listenWhen: (previous, current) =>
              current is IsmUserChangedActionListenerState,
          listener: (context, state) {
            if (state is IsmUserChangedActionListenerState &&
                state.userId.isNotEmpty) {
              cubit.loadPostLikeState(widget.postId);
            }
          },
          child: BlocSelector<IsmSocialActionCubit, IsmSocialActionState,
              _LikeActionViewModel>(
            selector: _selectLikeState,
            builder: (context, viewModel) => widget.builder(
              viewModel.isLoading,
              viewModel.isLiked,
              viewModel.likeCount,
              ({
                ReelsData? reelData,
                PostSectionType? postSectionType,
                int? watchDuration,
                Future<bool> Function()? apiCallBack,
              }) =>
                  _onTap(
                viewModel: viewModel,
                reelData: reelData,
                watchDuration: watchDuration,
                postSectionType: postSectionType,
                apiCallBack: apiCallBack,
              ),
            ),
          ),
        ),
      );
}
