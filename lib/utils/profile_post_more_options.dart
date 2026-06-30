import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/bloc/posts/social_post_bloc.dart';
import 'package:ism_video_reel_player/presentation/cubits/social_action/social_action_cubit.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/more_options_bottom_sheet.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';
import 'package:ism_video_reel_player/utils/reel_download_util.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// More-options sheet for profile text post cards (outside [IsmPostView]).
abstract final class ProfilePostMoreOptions {
  ProfilePostMoreOptions._();

  static Future<void> show({
    required BuildContext context,
    required TimeLineData post,
    required PostSectionType postSectionType,
    String? loggedInUserId,
  }) async {
    final canAct =
        await IsrVideoReelConfig.socialConfig.socialCallBackConfig
            ?.onLoginInvoked
            ?.call() ??
        true;
    if (!canAct || !context.mounted) return;

    final userId = loggedInUserId ?? '';
    final socialActionCubit = context.getOrCreateBloc<IsmSocialActionCubit>();
    final postData =
        await socialActionCubit.getAsyncPostById(post.id ?? '') ?? post;
    final tabData = TabDataModel(
      title: '',
      postSectionType: postSectionType,
      reelsDataList: [postData],
    );
    final postConfig = IsrVideoReelConfig.postConfig;
    final isOwner = postData.user?.id == userId;

    final sheetResult = await Utility.showBottomSheet<String?>(
      isDismissible: true,
      child: MoreOptionsBottomSheet(
        showDubWithAudio: _shouldOfferDubWithAudio(postData, userId, postConfig),
        showDownload: ReelDownloadUtil.isPostDownloadAllowed(
          postConfig: postConfig,
          post: postData,
        ),
        showRemoveMeFromPost: !isOwner && _isCurrentUserMentioned(postData, userId),
        isSelfProfile: isOwner,
      ),
    );

    if (!context.mounted) return;

    switch (sheetResult) {
      case MoreOptionsSheetResult.dubWithAudio:
        await DubWithAudioCaptureCoordinator.handleFromPost(
          context,
          postData,
          config: postConfig.dubWithAudioConfig,
          customHandler: postConfig.postCallBackConfig?.onDubWithAudio,
        );
      case MoreOptionsSheetResult.removeMeFromPost:
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!context.mounted) return;
        await _removeMentionFromPost(context, postData.id ?? '');
      case MoreOptionsSheetResult.report:
        await _reportPost(context, postData, tabData);
      case MoreOptionsSheetResult.delete:
        await _deletePost(context, postData);
      case MoreOptionsSheetResult.edit:
        await IsrAppNavigator.goToEditPostView(context, postData: postData);
      case MoreOptionsSheetResult.insight:
        IsrAppNavigator.goToPostInsight(
          context,
          postId: postData.id ?? '',
          postData: postData,
        );
      case MoreOptionsSheetResult.download:
        await _downloadPost(context, postData, postConfig);
      default:
        break;
    }
  }

  static bool _shouldOfferDubWithAudio(
    TimeLineData post,
    String loggedInUserId,
    PostConfig postConfig,
  ) {
    if (!postConfig.enableDubWithAudio) return false;
    if (post.user?.id == loggedInUserId) return false;
    final media = post.media;
    if (media == null || media.isEmpty) return false;
    return media.any(
      (m) =>
          m.postType == PostType.video ||
          (m.mediaType?.toLowerCase().contains('video') ?? false),
    );
  }

  static bool _isCurrentUserMentioned(TimeLineData post, String loggedInUserId) {
    if (loggedInUserId.isEmpty) return false;
    final mentions = post.tags?.mentions;
    if (mentions == null || mentions.isEmpty) return false;
    return mentions.any((m) => m.userId == loggedInUserId);
  }

  static Future<void> _reportPost(
    BuildContext context,
    TimeLineData post,
    TabDataModel tabData,
  ) async {
    final completer = Completer<void>();
    await showDialog<void>(
      context: context,
      builder: (_) => ReportReasonDialog(
        reasonFor: ReasonsFor.socialPost,
        contentId: post.id ?? '',
        onReportInvoked: (_) => completer.complete(),
        onReportCanceled: (_) => completer.complete(),
        onReportSuccess: (_) {},
      ),
    );
    await completer.future;
  }

  static Future<void> _deletePost(
    BuildContext context,
    TimeLineData post,
  ) async {
    final confirmed = await Utility.showAppDialog(
      dialogContext: context,
      titleText: IsrTranslationFile.deletePost,
      message: IsrTranslationFile.deletePostConfirmation,
      isTwoButtons: true,
      barrierDismissible: false,
      positiveButtonText: IsrTranslationFile.delete,
      negativeButtonText: IsrTranslationFile.cancel,
    );
    if (confirmed != true || !context.mounted) return;

    context.read<SocialPostBloc>().add(
          DeletePostEvent(
            postId: post.id ?? '',
            onComplete: (success) {
              if (success) {
                Utility.showToastMessage(
                  IsrTranslationFile.postDeletedSuccessfully,
                );
              }
            },
          ),
        );
  }

  static Future<void> _removeMentionFromPost(
    BuildContext context,
    String postId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return;

    final confirmed = await Utility.showRemoveMeFromPostConfirmDialog();
    if (confirmed != true || !context.mounted) return;

    final completer = Completer<void>();
    context.read<SocialPostBloc>().add(
          RemoveMentionEvent(
            postId: postId,
            onComplete: (success) {
              if (success) {
                Utility.showToastMessage(
                  IsrTranslationFile.mentionRemovedSuccessfully,
                );
              }
              if (!completer.isCompleted) completer.complete();
            },
          ),
        );
    await completer.future;
  }

  static Future<void> _downloadPost(
    BuildContext context,
    TimeLineData post,
    PostConfig postConfig,
  ) async {
    if (!ReelDownloadUtil.isPostDownloadAllowed(
      postConfig: postConfig,
      post: post,
    )) {
      Utility.showToastMessage(IsrTranslationFile.downloadNotAllowed);
      return;
    }
    Utility.showToastMessage(IsrTranslationFile.downloading);
    final outcome = await ReelDownloadUtil.downloadPostMedia(post);
    if (!context.mounted) return;
    switch (outcome) {
      case ReelDownloadOutcome.saved:
        Utility.showToastMessage(IsrTranslationFile.downloadSavedToGallery);
      case ReelDownloadOutcome.permissionDenied:
        Utility.showToastMessage(IsrTranslationFile.downloadPermissionDenied);
      case ReelDownloadOutcome.failed:
        Utility.showToastMessage(IsrTranslationFile.downloadFailed);
    }
  }
}
