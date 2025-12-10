import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class SaveActionWidget extends StatefulWidget {
  const SaveActionWidget({
    super.key,
    required this.postId,
    required this.builder,
  });

  final String postId;
  final Widget Function(
    bool isLoading,
    bool isSaved,
    Future<bool> Function({
      ReelsData? reelData,
      PostSectionType? postSectionType,
      int? watchDuration,
      Future<bool> Function()? apiCallBack,
    }) onTap,
  ) builder;

  @override
  State<SaveActionWidget> createState() => _SaveActionWidgetState();
}

class _SaveActionWidgetState extends State<SaveActionWidget> {
  late IsmSocialActionCubit cubit;

  bool isLoading = false;
  bool isSaved = false;
  late String postId;

  @override
  void initState() {
    super.initState();
    cubit = context.getOrCreateBloc<IsmSocialActionCubit>();
    postId = widget.postId;
    cubit.loadPostSaveState(widget.postId);
  }

  @override
  void didUpdateWidget(SaveActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload state if postId changed
    if (oldWidget.postId != widget.postId) {
      postId = widget.postId;
      cubit.loadPostSaveState(postId);
    }
  }

  Future<bool> _onTap({
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    if (isLoading) return false;
    if (isSaved) {
      return await cubit.unSavePost(
        postId,
        reelData: reelData,
        postSectionType: postSectionType,
        watchDuration: watchDuration,
        apiCallBack: apiCallBack,
      );
    } else {
      return await cubit.savePost(
        postId,
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
        child: BlocBuilder<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: (previous, current) {
            // Listen to both IsmSavePostState and IsmSaveActionListenerState
            // This ensures updates from outside the package are reflected
            if (current is IsmSavePostState && current.postId == postId) {
              return true;
            }
            if (current is IsmSaveActionListenerState &&
                current.postId == postId) {
              return true;
            }
            return false;
          },
          builder: (context, state) {
            if (state is IsmSavePostState && state.postId == postId) {
              isLoading = state.isLoading;
              isSaved = state.isSaved;
            } else if (state is IsmSaveActionListenerState &&
                state.postId == postId) {
              // Update state from listener state (emitted after save/unsave actions)
              isSaved = state.isSaved;
              isLoading = false; // Listener state means action is complete
            }
            return GestureDetector(
              onTap: isLoading ? null : _onTap,
              child: widget.builder(isLoading, isSaved, _onTap),
            );
          },
        ),
      );
}
