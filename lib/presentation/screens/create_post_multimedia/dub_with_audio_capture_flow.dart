import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart'
    as me;
import 'package:ism_video_reel_player/res/res.dart';
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

    final capture = await IsrAppNavigator.presentCameraCapture(
      context,
      mediaType: MediaType.video.name,
      dubWithAudioMode: true,
      initialCameraMusic: musicEvent,
      dubSoundPickerTracks: [track],
      onDismissEntireFlow: () => IsrAppNavigator.pop(context),
    );

    if (!context.mounted) return;
    if (capture == null || capture.mediaPath.isEmpty) return;

    final thumb = await _resolvePreviewThumbnail(
      videoPath: capture.mediaPath,
      reelThumbnailUrl: track.thumbnailUrl,
    );
    final editItem = me.MediaEditItem(
      originalPath: capture.mediaPath,
      mediaType: me.EditMediaType.video,
      width: 0,
      height: 0,
      duration: track.duration.inSeconds,
      thumbnailPath: thumb,
    );

    final edited = await IsrAppNavigator.presentCreatePostMediaEditor(
      context,
      mediaItems: [editItem],
      allowAddMoreMedia: false,
      onDismissEntireFlow: () => IsrAppNavigator.pop(context),
    );
    if (!context.mounted) return;
    if (edited == null || edited.isEmpty) return;

    final mediaDataList = CreatePostFlowCoordinator.mediaDataFromEditItems(edited);
    await IsrAppNavigator.presentCreatePostFromMedia(
      context,
      mediaDataList: mediaDataList,
    );
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
