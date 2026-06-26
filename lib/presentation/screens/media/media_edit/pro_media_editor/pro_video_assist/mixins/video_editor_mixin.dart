import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/utils/media_util.dart';
import 'package:path_provider/path_provider.dart';
// import '../../../../custom_pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart' as pve;

/// A mixin for handling video editing states.
mixin VideoEditorMixin<T extends StatefulWidget> on State<T> {
  /// The target format for the exported video.
  final outputFormat = pve.VideoOutputFormat.mp4;

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
  late pve.VideoMetadata videoMetadata;

  /// Number of thumbnails to generate across the video timeline.
  final int thumbnailCount = 10;

  /// The video currently loaded in the editor.
  late pve.EditorVideo video;

  String? _outputPath;

  /// The duration it took to generate the exported video.
  Duration videoGenerationTime = Duration.zero;

  /// The task ID used for rendering the video.
  /// It's optional, but when multiple operations run simultaneously,
  /// it allows tracking each task individually.
  final taskId = DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void dispose() {
    proVideoController?.dispose();

    super.dispose();
  }

  /// Loads and sets [videoMetadata] for the given [video].
  Future<void> setMetadata() async {
    await video.safeFilePath();
    videoMetadata = await pve.ProVideoEditor.instance.getMetadata(video);
  }

  /// Generates thumbnails for the given [video].
  void generateThumbnails() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || (!kIsWeb && (Platform.isLinux || Platform.isWindows))) {
        thumbnails = [];

        if (proVideoController != null) {
          proVideoController!.thumbnails = thumbnails;
        }
        return;
      }

      try {
        final imageWidth = MediaQuery.sizeOf(context).width /
            thumbnailCount *
            MediaQuery.devicePixelRatioOf(context);

        /// `getKeyFrames` is faster than `getThumbnails` but the timestamp is
        /// more "random".
        final thumbnailList = await pve.ProVideoEditor.instance.getKeyFrames(
          pve.KeyFramesConfigs(
            video: video,
            outputSize: Size.square(imageWidth),
            boxFit: pve.ThumbnailBoxFit.cover,
            maxOutputFrames: thumbnailCount,
            outputFormat: pve.ThumbnailFormat.jpeg,
          ),
        );

        final List<ImageProvider> temporaryThumbnails =
            thumbnailList.map(MemoryImage.new).toList();

        /// Optional precache every thumbnail
        final cacheList =
            temporaryThumbnails.map((item) => precacheImage(item, context));
        await Future.wait(cacheList);
        thumbnails = temporaryThumbnails;

        if (proVideoController != null) {
          proVideoController!.thumbnails = thumbnails;
        }
      } catch (e) {
        // Handle MissingPluginException or any other errors gracefully
        debugPrint('Error generating thumbnails: $e');

        // Set empty thumbnails to prevent crashes
        thumbnails = [];

        if (proVideoController != null) {
          proVideoController!.thumbnails = thumbnails;
        }

        // Log the error for debugging but don't crash the app
        if (e.toString().contains('MissingPluginException')) {
          debugPrint(
              'ProVideoEditor plugin not available on this platform. Thumbnails will be empty.');
        }
      }
    });
  }

  /// Returns a safe bitrate for export, or `null` to let the native encoder
  /// choose a preset (required on iOS when metadata bitrate is missing/invalid).
  int? resolveExportBitrate() => MediaUtil.resolveVideoExportBitrate(
        metadataBitrate: videoMetadata.bitrate,
        resolution: videoMetadata.resolution,
      );

  /// Generates the final video based on the given [parameters].
  ///
  /// Applies blur, color filters, cropping, rotation, flipping, and trimming
  /// before exporting. Measures and stores the generation time.
  Future<String?> generateVideo(CompleteParameters parameters) async {
    final stopwatch = Stopwatch()..start();

    final startTime = parameters.startTime;
    final endTime = parameters.endTime;
    if (startTime != null &&
        endTime != null &&
        startTime >= endTime) {
      debugPrint(
        'Video export skipped: invalid trim range '
        '($startTime -> $endTime)',
      );
      return null;
    }

    final exportModel = pve.VideoRenderData(
      id: taskId,
      videoSegments: [pve.VideoSegment(video: video)],
      imageLayers: parameters.layers.isNotEmpty
          ? [pve.ImageLayer(image: pve.EditorLayerImage.memory(parameters.image))]
          : const [],
      blur: parameters.blur,
      colorFilters: [
        pve.ColorFilter(matrix: parameters.colorFiltersCombined),
      ],
      startTime: startTime,
      endTime: endTime,
      transform: parameters.isTransformed
          ? pve.ExportTransform(
              width: parameters.cropWidth,
              height: parameters.cropHeight,
              rotateTurns: 4 - parameters.rotateTurns,
              x: parameters.cropX,
              y: parameters.cropY,
              flipX: parameters.flipX,
              flipY: parameters.flipY,
            )
          : null,
      enableAudio: proVideoController?.isAudioEnabled ?? true,
      outputFormat: outputFormat,
      bitrate: resolveExportBitrate(),
      shouldOptimizeForNetworkUse: true,
    );
    final directory = await getTemporaryDirectory();

    final now = DateTime.now().millisecondsSinceEpoch;
    _outputPath = await pve.ProVideoEditor.instance.renderVideoToFile(
      '${directory.path}/my_video_$now.mp4',
      exportModel,
    );
    videoGenerationTime = stopwatch.elapsed;
    return _outputPath;
  }
}
