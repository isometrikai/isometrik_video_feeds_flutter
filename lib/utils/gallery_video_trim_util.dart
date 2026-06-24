import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_video_editor_wrapper.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:video_compress/video_compress.dart';

class GalleryVideoTrimUtil {
  GalleryVideoTrimUtil._();

  static const int defaultMaxSeconds = 60;

  static MediaEditConfig defaultMediaEditConfig() {
    final hostConfig = IsrVideoReelConfig
        .createEditPostConfig.createEditPostUIConfig?.mediaEditConfig;
    if (hostConfig != null) return hostConfig;

    return MediaEditConfig(
      primaryColor: IsrColors.appColor,
      primaryTextColor: IsrColors.primaryTextColor,
      backgroundColor: IsrColors.scaffoldColor,
      appBarColor: IsrColors.appBarColor,
      primaryFontFamily: AppConstants.primaryFontFamily,
      mediaEditorStickersConfig:
          IsrVideoReelConfig.createEditPostConfig.mediaEditorStickersConfig,
    );
  }

  static Future<int?> durationSeconds(String videoPath) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoPath);
      final ms = info.duration ?? 0;
      if (ms <= 0) return null;
      return (ms / 1000).round();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> trimVideo(
    BuildContext context, {
    required String videoPath,
    int maxSeconds = defaultMaxSeconds,
    String outputFilename = 'gallery_trim.mp4',
    bool forceTrimUi = false,
    bool useRootNavigator = false,
  }) async {
    if (!forceTrimUi) {
      final seconds = await durationSeconds(videoPath);
      if (seconds != null && seconds <= maxSeconds) {
        return videoPath;
      }
    }

    if (!context.mounted) return null;

    final navigator = useRootNavigator
        ? Navigator.of(context, rootNavigator: true)
        : Navigator.of(context);
    final result = await navigator.push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (ctx) => ProVideoEditorWrapper(
          mediaPath: videoPath,
          mediaEditConfig: defaultMediaEditConfig(),
          title: 'Trim video',
          filename: outputFilename,
          editingMode: 'Trim',
          maxTrimDuration: Duration(seconds: maxSeconds),
          minTrimDuration: const Duration(seconds: 1),
        ),
      ),
    );

    if (result == null || result['success'] != true) return null;
    final outputPath = result['outputPath'] as String?;
    if (outputPath != null && outputPath.isNotEmpty) return outputPath;
    final file = result['file'];
    if (file is File) return file.path;
    return null;
  }
}
