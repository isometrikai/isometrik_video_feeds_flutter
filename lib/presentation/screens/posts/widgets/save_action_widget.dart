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
          buildWhen: (previous, current) =>
              current is IsmSavePostState && current.postId == postId,
          builder: (context, state) {
            if (state is IsmSavePostState && state.postId == postId) {
              isLoading = state.isLoading;
              isSaved = state.isSaved;
            }
            return GestureDetector(
              onTap: isLoading ? null : _onTap,
              child: widget.builder(isLoading, isSaved, _onTap),
            );
          },
        ),
      );
}
