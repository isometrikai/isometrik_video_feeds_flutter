import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

/// Listens to [IsmSocialActionCubit] comment count updates for one post.
class CommentCountActionWidget extends StatefulWidget {
  const CommentCountActionWidget({
    super.key,
    required this.postId,
    required this.builder,
  });

  final String postId;
  final Widget Function(int commentCount) builder;

  @override
  State<CommentCountActionWidget> createState() =>
      _CommentCountActionWidgetState();
}

class _CommentCountActionWidgetState extends State<CommentCountActionWidget> {
  late IsmSocialActionCubit _cubit;
  int _commentCount = 0;
  late String _postId;

  @override
  void initState() {
    super.initState();
    _cubit = context.getOrCreateBloc<IsmSocialActionCubit>();
    _postId = widget.postId;
    _cubit.loadPostCommentState(_postId);
  }

  @override
  void didUpdateWidget(CommentCountActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _postId = widget.postId;
      _cubit.loadPostCommentState(_postId);
    }
  }

  @override
  Widget build(BuildContext context) =>
      context.attachBlocIfNeeded<IsmSocialActionCubit>(
        child: BlocBuilder<IsmSocialActionCubit, IsmSocialActionState>(
          buildWhen: (previous, current) {
            if (current is IsmCommentPostState && current.postId == _postId) {
              return true;
            }
            if (current is IsmCommentActionListenerState &&
                current.postId == _postId) {
              return true;
            }
            return false;
          },
          builder: (context, state) {
            if (state is IsmCommentPostState && state.postId == _postId) {
              _commentCount = state.commentCount;
            } else if (state is IsmCommentActionListenerState &&
                state.postId == _postId) {
              _commentCount = state.commentCount;
            }
            return widget.builder(_commentCount);
          },
        ),
      );
}
