import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post_multimedia/create_post_flow_coordinator.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_compose_view.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_image_cropper.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/widgets/add_to_story_bottom_sheet.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class _StoryResolvedMedia {
  const _StoryResolvedMedia({
    required this.file,
    required this.mediaType,
  });

  final File file;
  final String mediaType;
}

class StoryCreateFlow {
  const StoryCreateFlow._();

  static Future<void> open(BuildContext context) async {
    // Free keep-alive reel decoders before story camera / DeepAR.
    await IsrVideoReelConfig.releaseFeedDecodersForHeavyOverlay();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!context.mounted) return;

    try {
      final storyConfig = IsrVideoReelConfig.storyConfig;
      final custom = storyConfig?.storyCallbackConfig.navigateToCreateStory;
      if (custom != null) {
        await custom(context);
        return;
      }

      final pick = await AddToStoryBottomSheet.show(context);
      if (pick == null || !context.mounted) return;

      final media = await _resolveMedia(context, pick);
      if (media == null || !context.mounted) return;

      await _openComposeView(
        context,
        mediaFile: media.file,
        mediaType: media.mediaType,
      );
    } finally {
      IsrVideoReelConfig.releasePlaybackSuppression();
    }
  }

  static Future<_StoryResolvedMedia?> _resolveMedia(
    BuildContext context,
    StoryMediaPick pick,
  ) async {
    try {
      if (pick.isCamera) {
        return _captureFromCamera(context);
      }
      return _pickFromGallery(context);
    } catch (error, stackTrace) {
      debugPrint('StoryCreateFlow: failed to resolve media — $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  static Future<_StoryResolvedMedia?> _captureFromCamera(
    BuildContext context,
  ) async {
    final capture = await IsrAppNavigator.presentCameraCapture(
      context,
      mediaType: MediaType.both.name,
      initialDurationSeconds: StoryMediaPick.storyVideoMaxDuration.inSeconds,
    );
    if (!context.mounted) return null;
    if (capture == null || capture.mediaPath.isEmpty) return null;

    final file = File(capture.mediaPath);
    if (!await file.exists()) return null;

    return _prepareMediaFile(
      context,
      path: capture.mediaPath,
      file: file,
      isVideo: capture.mediaPath.isVideoFile,
    );
  }

  /// Opens the in-app [MediaSelectionView] gallery grid (same as create-post).
  static Future<_StoryResolvedMedia?> _pickFromGallery(
    BuildContext context,
  ) async {
    final selected = await IsrAppNavigator.presentCreatePostMediaSelector(
      context,
      config: CreatePostFlowCoordinator.defaultMediaSelectionConfig(
        isMultiSelect: false,
        mediaLimit: 1,
        imageMediaLimit: 1,
        videoMediaLimit: 1,
        selectMediaTitle: IsrTranslationFile.newStory,
        doneButtonText: IsrTranslationFile.next,
        mediaListType: ms.MediaListType.imageVideo,
      ),
    );
    if (!context.mounted) return null;
    if (selected == null || selected.isEmpty) return null;

    final asset = selected.first;
    final path = asset.localPath;
    if (path == null || path.isEmpty) return null;

    final file = asset.file ?? File(path);
    if (!await file.exists()) return null;

    final isVideo = asset.mediaType == ms.SelectedMediaType.video ||
        path.isVideoFile;

    return _prepareMediaFile(
      context,
      path: path,
      file: file,
      isVideo: isVideo,
    );
  }

  static Future<_StoryResolvedMedia?> _prepareMediaFile(
    BuildContext context, {
    required String path,
    required File file,
    required bool isVideo,
  }) async {
    if (isVideo) {
      return _StoryResolvedMedia(file: file, mediaType: 'video');
    }

    final cropped = await StoryImageCropper.crop(path);
    if (!context.mounted || cropped == null) return null;
    return _StoryResolvedMedia(file: cropped, mediaType: 'image');
  }

  static Future<void> _openComposeView(
    BuildContext context, {
    required File mediaFile,
    required String mediaType,
  }) async {
    final cubit = IsrAppNavigator.hasStoryCubitInContext(context)
        ? context.read<StoryCubit>()
        : IsmInjectionUtils.getBloc<StoryCubit>();

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<StoryCubit>.value(
          value: cubit,
          child: StoryComposeView(
            file: mediaFile,
            mediaType: mediaType,
          ),
        ),
      ),
    );
  }
}
