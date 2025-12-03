import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class FollowActionWidget extends StatefulWidget {
  const FollowActionWidget({
    super.key,
    required this.postId,
    required this.userId,
    required this.builder,
  });

  final String postId;
  final String userId;
  final Widget Function(bool isLoading, bool isFollowing, VoidCallback onTap)
      builder;

  @override
  State<FollowActionWidget> createState() => _FollowActionWidgetState();
}

class _FollowActionWidgetState extends State<FollowActionWidget> {
  late IsmSocialActionCubit cubit;

  bool isLoading = false;
  bool isFollowing = false;
  late String userId;
  late String postId;

  @override
  void initState() {
    super.initState();
    cubit = context.getOrCreateBloc<IsmSocialActionCubit>();
    userId = widget.userId;
    postId = widget.postId;
    cubit.loadPostFollowState(postId: widget.postId);
  }

  @override
  void dispose() {
    // IMPORTANT: Do NOT close the cubit here!
    // - The cubit is a singleton managed by the DI container
    // - BlocProvider.value does NOT close the cubit when the widget is disposed
    // - Closing it here would break the singleton pattern and affect other widgets
    super.dispose();
  }

  void _onTap() {
    if (isLoading) return;
    if (isFollowing) {
      cubit.unfollowUser(userId: userId);
    } else {
      cubit.followUser(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) => context.attachBlocIfNeeded<IsmSocialActionCubit>(
      child: BlocBuilder<IsmSocialActionCubit, IsmSocialActionState>(
        buildWhen: (previous, current) =>
            current is IsmFollowUserState && current.userId == userId,
        builder: (context, state) {
          if (state is IsmFollowUserState) {
            isLoading = state.isLoading;
            isFollowing = state.isFollowing;
          }
          return GestureDetector(
            onTap: isLoading ? null : _onTap,
            child: widget.builder(isLoading, isFollowing, _onTap),
          );
        },
      ),
    );
}
