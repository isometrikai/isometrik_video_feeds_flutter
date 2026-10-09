import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_trim/video_trim_screen.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/ffmpeg_video_limit_util.dart';
import 'package:video_compress/video_compress.dart';

class GalleryVideoTrimUtil {
  GalleryVideoTrimUtil._();

  static int get defaultMaxSeconds =>
      IsrVideoReelConfig.createEditPostConfig.postVideoMaxDurationSeconds;

  static MediaEditConfig defaultMediaEditConfig() => MediaEditConfig(
        primaryColor: IsrColors.appColor,
        primaryTextColor: IsrColors.primaryTextColor,
        backgroundColor: Colors.white,
        appBarColor: Colors.white,
        primaryFontFamily: IsrAppConstants.primaryFontFamily,
        mediaEditorStickersConfig:
            IsrVideoReelConfig.createEditPostConfig.mediaEditorStickersConfig,
      );

  static Future<int?> durationSeconds(String videoPath) async {
    final probed = await FfmpegVideoLimitUtil.probeDurationSeconds(videoPath);
    if (probed != null && probed > 0) return probed.round();
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
    int? maxSeconds,
    String outputFilename = 'gallery_trim.mp4',
    bool forceTrimUi = false,
    bool useRootNavigator = false,
    double? pixelsPerSecond,
  }) async {
    final effectiveMaxSeconds = maxSeconds ?? defaultMaxSeconds;
    final probed = await FfmpegVideoLimitUtil.probeDurationSeconds(videoPath);
    final withinLimit = probed != null && probed <= effectiveMaxSeconds;

    VideoTrimSelection? selection;
    if (forceTrimUi || !withinLimit) {
      if (!context.mounted) return null;
      final navigator = useRootNavigator
          ? Navigator.of(context, rootNavigator: true)
          : Navigator.of(context);
      selection = await navigator.push<VideoTrimSelection>(
        MaterialPageRoute<VideoTrimSelection>(
          builder: (ctx) => VideoTrimScreen(
            videoPath: videoPath,
            maxDuration: Duration(seconds: effectiveMaxSeconds),
            pixelsPerSecond: pixelsPerSecond,
          ),
        ),
      );
      if (selection == null) return null;
    }

    if (!context.mounted) return null;
    return FfmpegVideoLimitUtil.ensureWithinLimits(
      context: context,
      inputPath: selection?.videoPath ?? videoPath,
      start: selection?.start ?? Duration.zero,
      length: selection?.length,
      maxSeconds: effectiveMaxSeconds,
      outputFilename: outputFilename,
      userTrimmed: selection != null,
    );
  }
}
