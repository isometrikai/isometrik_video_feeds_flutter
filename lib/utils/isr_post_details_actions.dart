import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/data/ism_data_provider.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Default post-details sheet actions (edit flow + delete with confirmation).
class IsrPostDetailsActions {
  IsrPostDetailsActions._();

  static PostDetailsSheetDelegate delegateFor(
    BuildContext context, {
    required TimeLineData post,
    VoidCallback? onPostUpdated,
  }) =>
      PostDetailsSheetDelegate(
        onDeletePost: (data) => _deletePost(context, data, onPostUpdated),
        onEditAndResubmit: (data) => _editPost(context, data, onPostUpdated),
        onEditSubmission: (data) => _editPost(context, data, onPostUpdated),
        onWithdrawPost: (data) => _deletePost(context, data, onPostUpdated),
        onPublishNow: (data) => _publishNow(context, data, onPostUpdated),
      );

  /// Default actions with optional host overrides (withdraw uses delete API).
  static PostDetailsSheetDelegate resolve(
    BuildContext context, {
    required TimeLineData post,
    PostDetailsSheetDelegate? override,
    VoidCallback? onPostUpdated,
  }) {
    final defaults = delegateFor(
      context,
      post: post,
      onPostUpdated: onPostUpdated,
    );
    return override?.mergeWith(defaults) ?? defaults;
  }

  static Future<void> _editPost(
    BuildContext context,
    PostDetailsSheetData data,
    VoidCallback? onPostUpdated,
  ) async {
    final post = data.sourcePost;
    if (post == null || !context.mounted) return;

    final result = await IsrAppNavigator.goToEditPostView(
      context,
      postData: post,
    );
    if (result != null) {
      onPostUpdated?.call();
    }
  }

  static Future<void> _deletePost(
    BuildContext context,
    PostDetailsSheetData data,
    VoidCallback? onPostUpdated,
  ) async {
    if (!context.mounted) return;

    final confirmed = await PostDeleteConfirmationDialog.show(context);
    if (!confirmed || !context.mounted) return;

    final postId = data.sourcePost?.id ?? data.postId;
    if (postId.isEmpty) return;

    final completer = Completer<void>();

    await IsmDataProvider.instance.deletePost(
      postId: postId,
      isLoading: true,
      onSuccess: (_, __) {
        Utility.showToastMessage(IsrTranslationFile.postDeletedSuccessfully);
        onPostUpdated?.call();
        completer.complete();
      },
      onError: (message, _) {
        if (message.isNotEmpty) {
          Utility.showToastMessage(message);
        }
        completer.complete();
      },
    );

    return completer.future;
  }

  static Future<void> _publishNow(
    BuildContext context,
    PostDetailsSheetData data,
    VoidCallback? onPostUpdated,
  ) async {
    if (!context.mounted) return;

    final confirmed = await Utility.showAppDialog(
      dialogContext: context,
      titleText: IsrTranslationFile.postNow,
      message: IsrTranslationFile.postNowConfirmation,
      isTwoButtons: true,
      barrierDismissible: false,
      positiveButtonText: IsrTranslationFile.postNow,
      negativeButtonText: IsrTranslationFile.cancel,
    );
    if (confirmed != true || !context.mounted) return;

    final postId = data.sourcePost?.id ?? data.postId;
    if (postId.isEmpty) return;

    final completer = Completer<void>();

    await IsmDataProvider.instance.publishScheduledPost(
      postId: postId,
      isLoading: true,
      onSuccess: (_, __) {
        Utility.showToastMessage(
          IsrTranslationFile.yourPostHasBeenSuccessfullyPosted,
        );
        onPostUpdated?.call();
        completer.complete();
      },
      onError: (message, _) {
        if (message.isNotEmpty) {
          Utility.showToastMessage(message);
        }
        completer.complete();
      },
    );

    return completer.future;
  }
}
