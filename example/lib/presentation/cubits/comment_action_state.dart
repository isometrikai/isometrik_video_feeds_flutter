part of 'comment_action_cubit.dart';

abstract class CommentActionState {}

class CommentActionInitialState extends CommentActionState {
  CommentActionInitialState({this.commentAction = CommentAction.dislike});

  final CommentAction commentAction;
}

class CommentActionedState extends CommentActionState {
  CommentActionedState({
    required this.commentAction,
    required this.postId,
    required this.commentId,
    required this.message,
  });

  final CommentAction commentAction;
  final String? postId;
  final String commentId;
  final String message;
}

class CommentActionLoadingState extends CommentActionState {
  CommentActionLoadingState(this.commentId, this.commentAction);

  final String commentId;
  final CommentAction commentAction;
}

class CommentActionErrorState extends CommentActionState {
  CommentActionErrorState(
    this.errorMsg,
    this.commentId,
    this.commentAction,
  );

  final CommentAction commentAction;
  final String errorMsg;
  final String commentId;
}
