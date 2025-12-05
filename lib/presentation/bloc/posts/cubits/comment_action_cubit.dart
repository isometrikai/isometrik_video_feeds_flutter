import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CommentActionCubit extends Cubit<CommentActionState> {
  CommentActionCubit(
    this._localDataUseCase,
    this._commentUseCase,
  ) : super(CommentActionInitialState());

  final IsmLocalDataUseCase _localDataUseCase;
  final CommentActionUseCase _commentUseCase;

  /// add to wish list after calling api
  Future<void> doActionOnComment(
      CommentAction commentAction, String commentId, String postId, String userId) async {
    final finalAction =
        commentAction == CommentAction.like ? CommentAction.dislike : CommentAction.like;
    final commentRequest = CommentRequest(
      commentId: commentId,
      commentAction: commentAction,
      postId: postId,
      isNewLike: commentAction == CommentAction.like ? true : false,
    );
    emit(CommentActionLoadingState(commentId, commentAction));
    final apiResult = await _commentUseCase.executeCommentAction(
      isLoading: false,
      commentRequest: commentRequest.toJson(),
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      if (response != null && !response.hasError) {
        final message = response.data.isNotEmpty
            ? jsonDecode(response.data)['message'] == null
                ? ''
                : jsonDecode(response.data)['message'] as String
            : response.statusCode.toString();
        emit(CommentActionedState(
          commentId: commentId,
          postId: postId,
          commentAction: commentAction,
          message: message,
        ));
      } else {
        emit(CommentActionErrorState(
          response?.data.isNotEmpty ?? false
              ? jsonDecode(response?.data ?? '')['message'].toString()
              : IsrTranslationFile.failedToUpdateWishlistStatus,
          commentId,
          finalAction,
        ));
      }
    } else {
      emit(CommentActionErrorState(
        apiResult.error?.message ?? IsrTranslationFile.failedToUpdateWishlistStatus,
        commentId,
        commentAction,
      ));
      ErrorHandler.showAppError(appError: apiResult.error);
    }
  }

  /// checks whether user is logged in or not
  Future<bool> isLoggedIn() async => await _localDataUseCase.isLoggedIn();
}
