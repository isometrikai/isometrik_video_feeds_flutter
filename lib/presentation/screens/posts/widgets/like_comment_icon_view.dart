import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class LikeCommentIconView extends StatefulWidget {
  const LikeCommentIconView({
    super.key,
    required this.postId,
    required this.userId,
    required this.commentId,
    required this.isLiked,
    required this.onLikeDisLikeComment,
  });

  final String postId;
  final String userId;
  final String commentId;
  final bool isLiked;
  final Function(bool isLiked) onLikeDisLikeComment;

  @override
  State<LikeCommentIconView> createState() => _LikeCommentIconViewState();
}

class _LikeCommentIconViewState extends State<LikeCommentIconView> {
  var commentAction = CommentAction.dislike;
  final iconSize = 20.responsiveDimension;

  @override
  void initState() {
    commentAction = widget.isLiked ? CommentAction.like : CommentAction.dislike;
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CommentActionCubit, CommentActionState>(
        listenWhen: (previous, current) {
          if (current is CommentActionedState) {
            if (current.commentId == widget.commentId) {
              commentAction = current.commentAction;
              return true;
            }
          } else if (current is CommentActionErrorState) {
            if (current.commentId == widget.commentId) {
              commentAction = current.commentAction;
              return true;
            }
          }
          return false;
        },
        listener: (context, state) {
          if (state is CommentActionErrorState &&
              state.commentId == widget.commentId) {
            Utility.showInSnackBar(state.errorMsg, context,
                isSuccessIcon: true);
          }
        },
        buildWhen: (previous, current) {
          if (current is CommentActionedState) {
            if (current.commentId == widget.commentId) {
              widget.onLikeDisLikeComment(
                  current.commentAction == CommentAction.like);
              return true;
            }
          } else if (current is CommentActionLoadingState) {
            if (current.commentId == widget.commentId) {
              return true;
            }
          } else if (current is CommentActionErrorState) {
            if (current.commentId == widget.commentId) {
              return true;
            }
          }
          return false;
        },
        builder: (context, state) => AnimatedCrossFade(
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 500),
          firstCurve: Curves.fastOutSlowIn,
          secondCurve: Curves.fastOutSlowIn,
          crossFadeState: state is CommentActionLoadingState
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: SizedBox(
            height: iconSize,
            width: iconSize,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: IsrDimens.two,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          secondChild: SizedBox(
            height: iconSize,
            width: iconSize,
            child: TapHandler(
              onTap: () {
                context.getOrCreateBloc<CommentActionCubit>().doActionOnComment(
                      commentAction == CommentAction.like
                          ? CommentAction.dislike
                          : CommentAction.like,
                      widget.commentId,
                      widget.postId,
                      widget.userId,
                    );
              },
              child: AppImage.svg(
                commentAction == CommentAction.like
                    ? AssetConstants.icHeartIconSelected
                    : AssetConstants.icHeartIconUnSelected,
              ),
            ),
          ),
        ),
      );
}
