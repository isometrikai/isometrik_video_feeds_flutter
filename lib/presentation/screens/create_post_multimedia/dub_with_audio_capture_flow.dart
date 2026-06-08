import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart'
    as mc;
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart'
    as me;
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/utils/post_sound_util.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DubWithAudioCaptureCoordinator {
  DubWithAudioCaptureCoordinator._();

  static Future<void> handleFromPost(
    BuildContext context,
    TimeLineData post, {
    DubWithAudioConfig? config,
    Future<void> Function(TimeLineData post)? customHandler,
  }) async {
    if (customHandler != null) {
      await customHandler(post);
      return;
    }

    if (!context.mounted) return;

    if (post.isLocked == true) {
      if (config?.onLockedPost != null) {
        config!.onLockedPost!(context, post);
      } else {
        Utility.showToastMessage(IsrTranslationFile.dubLockedPostMessage);
      }
      return;
    }

    final canStart = config?.canStart;
    if (canStart != null) {
      final allowed = await canStart(context, post);
      if (!allowed || !context.mounted) return;
    }

    final videoUrl = ReelDubAudioUtil.reelVideoUrlForDub(post);
    if (videoUrl == null) {
      Utility.showToastMessage(IsrTranslationFile.dubNoVideoMessage);
      return;
    }

    final audioPath = await _extractAudioWithLoader(context, videoUrl);
    if (!context.mounted) return;

    if (audioPath == null) {
      Utility.showToastMessage(IsrTranslationFile.dubExtractAudioFailedMessage);
      return;
    }

    await start(
      context,
      CreatePostLaunchConfig.dubWithExtractedAudio(
        dubAudioFilePath: audioPath,
        dubSoundTrack: ReelDubAudioUtil.dubSoundTrackForPost(
          audioFilePath: audioPath,
          post: post,
          durationSeconds: ReelDubAudioUtil.reelVideoDurationSecondsForDub(post),
        ),
      ),
    );
  }

  static Future<void> start(
    BuildContext context,
    CreatePostLaunchConfig launchConfig,
  ) async {
    final track = launchConfig.dubSoundTrack;
    final audioPath = launchConfig.dubAudioFilePath;
    if (track == null || audioPath == null || audioPath.isEmpty) return;

    final musicEvent = CameraSetMusicEvent(
      musicId: track.id,
      musicName: track.title,
      musicArtist: track.author,
      musicThumbnailUrl: track.thumbnailUrl,
      musicDurationSeconds: track.duration.inSeconds,
      musicPreviewUrl: audioPath,
    );

    final capture = await Navigator.of(context, rootNavigator: true)
        .push<CameraCaptureResult>(
      MaterialPageRoute(
        settings: const RouteSettings(name: IsrRouteNames.cameraView),
        builder: (_) => mc.CameraCaptureView(
          mediaType: MediaType.video,
          dubWithAudioMode: true,
          initialCameraMusic: musicEvent,
          dubSoundPickerTracks: [track],
          onDismissEntireFlow: () =>
              IsrAppNavigator.dismissCreatePostFlow(context),
          onAddSoundTap: IsrVideoReelConfig.createEditPostConfig
              .createEditPostCallBackConfig?.onAddSoundFromCamera,
        ),
      ),
    );

    if (capture == null || capture.mediaPath.isEmpty) return;
    final videoPath = capture.mediaPath;

    final mediaEditConfig = GalleryVideoTrimUtil.defaultMediaEditConfig();

    final thumb = await _resolvePreviewThumbnail(
      videoPath: videoPath,
      reelThumbnailUrl: track.thumbnailUrl,
    );
    final soundItem = PostSoundUtil.soundItemFromTrack(track);
    final editItem = me.MediaEditItem(
      originalPath: videoPath,
      mediaType: me.EditMediaType.video,
      width: 0,
      height: 0,
      duration: track.duration.inSeconds,
      thumbnailPath: thumb,
      sound: soundItem,
    );

    await Navigator.of(context, rootNavigator: true).push<List<me.MediaEditItem>>(
      MaterialPageRoute(
        settings: const RouteSettings(name: IsrRouteNames.mediaEditView),
        builder: (ctx) => me.MediaEditView(
          mediaDataList: [editItem],
          onComplete: (edited) =>
              _onMediaEditComplete(context, edited, soundItem),
          onDismissEntireFlow: () =>
              IsrAppNavigator.dismissCreatePostFlow(context),
          addMoreMedia: (_) async => null,
          mediaEditConfig: mediaEditConfig,
          pickCoverPic: () => _pickCoverPic(context),
        ),
      ),
    );
  }

  static Future<bool> _onMediaEditComplete(
    BuildContext context,
    List<me.MediaEditItem> editedMedia,
    MediaEditSoundItem fallbackSound,
  ) async {
    if (editedMedia.isEmpty) return false;
    final selectedSound = editedMedia
            .map((e) => e.sound)
            .where((s) => PostSoundUtil.isLibrarySoundId(s?.soundId))
            .map((s) => s!)
            .firstOrNull ??
        fallbackSound;
    final mediaDataList = editedMedia
        .map(
          (editItem) => MediaData(
            assetId: '',
            mediaType: editItem.mediaType.toJson(),
            url: editItem.editedPath ?? editItem.originalPath,
            localPath: editItem.editedPath ?? editItem.originalPath,
            previewUrl: editItem.thumbnailPath ??
                editItem.editedPath ??
                editItem.originalPath,
            coverFileLocalPath: editItem.thumbnailPath ??
                editItem.editedPath ??
                editItem.originalPath,
            width: editItem.width,
            height: editItem.height,
            duration: editItem.duration,
            fileName: '',
            postType: editItem.mediaType == me.EditMediaType.video
                ? PostType.video
                : PostType.photo,
            position: editedMedia.indexOf(editItem) + 1,
            fileExtension: path.extension(
              editItem.editedPath ?? editItem.originalPath,
            ),
          ),
        )
        .toList();

    await IsrAppNavigator.goToCreatePostAttributionView(
      context,
      newMediaDataList: mediaDataList,
      selectedSound: selectedSound,
      dismissEntireFlowOnClose: true,
    );
    IsrAppNavigator.dismissCreatePostFlow(context);
    return false;
  }

  static Future<String?> _pickCoverPic(BuildContext context) async {
    final coverPickerConfig = ms.MediaSelectionConfig(
      isMultiSelect: true,
      imageMediaLimit: AppConstants.imageMediaLimit,
      videoMediaLimit: AppConstants.videoMediaLimit,
      mediaLimit: AppConstants.totalMediaLimit,
      singleSelectModeIcon:
          const AppImage.svg(AssetConstants.icMediaSelectSingle),
      multiSelectModeIcon:
          const AppImage.svg(AssetConstants.icMediaSelectMultiple),
      doneButtonText: IsrTranslationFile.next,
      selectMediaTitle: IsrTranslationFile.addCover,
      primaryColor: IsrColors.appColor,
      primaryTextColor: IsrColors.primaryTextColor,
      backgroundColor: Colors.white,
      appBarColor: Colors.white,
      primaryFontFamily: AppConstants.primaryFontFamily,
      mediaListType: ms.MediaListType.image,
    );

    final res = await Navigator.push<List<ms.MediaAssetData>>(
      context,
      MaterialPageRoute(
        builder: (context) => ms.MediaSelectionView(
          mediaSelectionConfig: coverPickerConfig,
          onCaptureMedia: (_) async => null,
        ),
      ),
    );
    if (res == null || res.isEmpty) return null;
    return res.first.localPath;
  }

  static Future<String> _resolvePreviewThumbnail({
    required String videoPath,
    required String reelThumbnailUrl,
  }) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final thumbDir = path.join(documentsDir.path, 'media', 'dub_thumbs');
    final fromVideo = await MediaUtil.pickBestVideoThumbnailPath(
      videoPath: videoPath,
      thumbnailPath: thumbDir,
      quality: 75,
    );
    if (fromVideo != null) return fromVideo;

    final fromReel = await _cacheReelThumbnail(reelThumbnailUrl);
    if (fromReel != null) return fromReel;

    return videoPath;
  }

  static Future<String?> _extractAudioWithLoader(
    BuildContext context,
    String videoUrl,
  ) async {
    try {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(child: AppLoader()),
          ),
        ),
      );
      return await MediaUtil.extractAudioFromVideoToM4a(videoUrl);
    } finally {
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
    }
  }

  static Future<String?> _cacheReelThumbnail(String url) async {
    final trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final file = File(trimmed);
      if (await file.exists()) return trimmed;
      return null;
    }
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri == null) return null;
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final tempDir = await getTemporaryDirectory();
      final ext = path.extension(uri.path);
      final suffix = ext.isNotEmpty && ext.length <= 6 ? ext : '.jpg';
      final file = File(
        path.join(
          tempDir.path,
          'dub_reel_thumb_${DateTime.now().millisecondsSinceEpoch}$suffix',
        ),
      );
      await file.writeAsBytes(response.bodyBytes);
      if (await file.length() > 64) return file.path;
    } catch (e) {
      debugPrint('DubWithAudioCaptureCoordinator: reel thumb download: $e');
    }
    return null;
  }
}
