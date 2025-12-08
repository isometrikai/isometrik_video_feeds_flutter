import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class LikeActionWidget extends StatefulWidget {
  const LikeActionWidget({
    super.key,
    required this.postId,
    required this.builder,
  });

  final String postId;
  final Widget Function(bool isLoading, bool isLiked, int likeCount,
      Function({ReelsData? reelData, int? watchDuration}) onTap) builder;

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
    cubit.loadPostLikeState(widget.postId);
  }

  @override
  void dispose() {
    // IMPORTANT: Do NOT close the cubit here!
    // - The cubit is a singleton managed by the DI container
    // - BlocProvider.value does NOT close the cubit when the widget is disposed
    // - Closing it here would break the singleton pattern and affect other widgets
    super.dispose();
  }

  void _onTap({ReelsData? reelData, int? watchDuration}) {
    if (isLoading) return;
    if (isLiked) {
      cubit.unLikePost(postId, likeCount,
          reelData: reelData, watchDuration: watchDuration);
    } else {
      cubit.likePost(postId, likeCount,
          reelData: reelData, watchDuration: watchDuration);
    }
  }

  @override
  Widget build(BuildContext context) =>
      context.attachBlocIfNeeded<IsmSocialActionCubit>(
        child: BlocBuilder<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: (previous, current) =>
              current is IsmLikePostState && current.postId == postId,
          builder: (context, state) {
            if (state is IsmLikePostState && state.postId == postId) {
              isLoading = state.isLoading;
              isLiked = state.isLiked;
              likeCount = state.likeCount;
            }
            return GestureDetector(
              onTap: isLoading
                  ? null
                  : ({ReelsData? reelsData, int? watchDuration}) =>
                      _onTap(reelData: reelsData, watchDuration: watchDuration),
              child: widget.builder(isLoading, isLiked, likeCount, _onTap),
            );
          },
        ),
      );
}
