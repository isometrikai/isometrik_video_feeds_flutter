import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/utils/ffmpeg_media_ops.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Duration, size, resolution, and bitrate for the open video.
class EditorVideoMetadata {
  const EditorVideoMetadata({
    required this.bitrate,
    required this.duration,
    required this.fileSize,
    required this.resolution,
  });

  final int bitrate;
  final Duration duration;
  final int fileSize;
  final Size resolution;
}

/// A mixin for handling video editing states.
mixin VideoEditorMixin<T extends StatefulWidget> on State<T> {
  /// Video editor configuration settings.
  late final VideoEditorConfigs videoConfigs;

  /// Indicates whether a seek operation is in progress.
  bool isSeeking = false;

  /// Stores the currently selected trim duration span.
  TrimDurationSpan? durationSpan;

  /// Temporarily stores a pending trim duration span.
  TrimDurationSpan? tempDurationSpan;

  /// Controls video playback and trimming functionalities.
  ProVideoController? proVideoController;

  /// Stores generated thumbnails for the trimmer bar and filter background.
  List<ImageProvider>? thumbnails;

  /// Holds information about the selected video.
  ///
  /// This will be populated via [setMetadata].
  late EditorVideoMetadata videoMetadata;

  /// Number of thumbnails to generate across the video timeline.
  final int thumbnailCount = 10;

  /// Local path of the video loaded in the editor.
  late String videoPath;

  String? _outputPath;

  /// The duration it took to generate the exported video.
  Duration videoGenerationTime = Duration.zero;

  @override
  void dispose() {
    proVideoController?.dispose();

    super.dispose();
  }

  /// Loads and sets [videoMetadata] for [videoPath].
  Future<void> setMetadata() async {
    final file = File(videoPath);
    final info = await FfmpegMediaOps.probe(videoPath);
    final length = await file.exists() ? await file.length() : 0;
    videoMetadata = EditorVideoMetadata(
      duration: Duration(milliseconds: info?.durationMs ?? 0),
      fileSize: length,
      resolution: Size(
        (info?.width ?? 0).toDouble(),
        (info?.height ?? 0).toDouble(),
      ),
      bitrate: info?.bitrate ?? 0,
    );
  }

  /// Generates thumbnails for [videoPath].
  Future<List<ImageProvider>> generateThumbnails() async {
    if (!mounted || (!kIsWeb && (Platform.isLinux || Platform.isWindows))) {
      return [];
    }

    try {
      final imageWidth = MediaQuery.sizeOf(context).width /
          thumbnailCount *
          MediaQuery.devicePixelRatioOf(context);
      final frames = await FfmpegMediaOps.keyFrameBytes(
        videoPath: videoPath,
        count: thumbnailCount,
        duration: videoMetadata.duration,
        side: imageWidth.round().clamp(2, 512),
      );
      final temporaryThumbnails = frames.map(MemoryImage.new).toList();
      if (!mounted || temporaryThumbnails.isEmpty) return temporaryThumbnails;
      await Future.wait(
        temporaryThumbnails.map((item) => precacheImage(item, context)),
      );
      return temporaryThumbnails;
    } catch (e) {
      debugPrint('Error generating thumbnails: $e');
      return [];
    }
  }

  /// Writes the selected time range to a new file.
  ///
  /// Filter, text, and sticker baking is applied by a later edit step.
  Future<String?> generateVideo(CompleteParameters parameters) async {
    final stopwatch = Stopwatch()..start();

    final startTime = parameters.startTime ?? Duration.zero;
    final endTime = parameters.endTime ?? videoMetadata.duration;
    if (startTime >= endTime) {
      debugPrint(
        'Video export skipped: invalid trim range '
        '($startTime -> $endTime)',
      );
      return null;
    }

    final directory = await getTemporaryDirectory();
    final now = DateTime.now().millisecondsSinceEpoch;
    _outputPath = await FfmpegMediaOps.encodeRange(
      inputPath: videoPath,
      outputPath: '${directory.path}/my_video_$now.mp4',
      start: startTime,
      end: endTime,
      enableAudio: proVideoController?.isAudioEnabled ?? true,
    );
    videoGenerationTime = stopwatch.elapsed;
    return _outputPath;
  }
}
