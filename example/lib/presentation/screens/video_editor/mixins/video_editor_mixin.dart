import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/presentation/screens/video_editor/video_editor_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/core/enums/editor_mode.dart';
import 'package:pro_image_editor/core/models/complete_parameters.dart';
import 'package:pro_image_editor/core/models/editor_configs/video_editor_configs.dart';
import 'package:pro_image_editor/core/models/video/trim_duration_span_model.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';
import 'package:pro_image_editor/shared/controllers/video_controller.dart';
import 'package:pro_video_editor/core/models/thumbnail/key_frames_configs.model.dart';
import 'package:pro_video_editor/core/models/thumbnail/thumbnail_box_fit.model.dart';
import 'package:pro_video_editor/core/models/thumbnail/thumbnail_configs.model.dart';
import 'package:pro_video_editor/core/models/thumbnail/thumbnail_format.model.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/core/models/video/export_transform_model.dart';
import 'package:pro_video_editor/core/models/video/render_video_model.dart';
import 'package:pro_video_editor/core/models/video/video_metadata_model.dart';
import 'package:pro_video_editor/pro_video_editor_platform_interface.dart';
import 'package:universal_io/io.dart';
import 'package:video_player/video_player.dart';

mixin VideoEditorMixin on State<VideoEditorView> {
  TrimDurationSpan? _durationSpan;

  final taskId = DateTime.now().microsecondsSinceEpoch.toString();

  String? _outputPath;

  TrimDurationSpan? _tempDurationSpan;

  var _isSeeking = false;

  late VideoPlayerController videoController;

  ProVideoController? proVideoController;

  late final _video = EditorVideo.file(widget.videoPath);

  final editor = GlobalKey<ProImageEditorState>();

  final videoConfigs = const VideoEditorConfigs(
    initialMuted: true,
    initialPlay: false,
    isAudioSupported: true,
    minTrimDuration: Duration(seconds: 7),
  );

  late VideoMetadata _videoMetadata;

  List<ImageProvider>? _thumbnails;

  final _thumbnailCount = 7;

  Future<void> generateVideo(CompleteParameters parameters) async {
    unawaited(videoController.pause());
    final exportModel = RenderVideoModel(
      id: taskId,
      video: EditorVideo.file(File(widget.videoPath)),
      outputFormat: VideoOutputFormat.mp4,
      enableAudio: proVideoController?.isAudioEnabled ?? true,
      imageBytes: parameters.layers.isNotEmpty ? parameters.image : null,
      blur: parameters.blur,
      colorMatrixList: parameters.colorFilters,
      startTime: parameters.startTime,
      endTime: parameters.endTime,
      transform: parameters.isTransformed
          ? ExportTransform(
              width: parameters.cropWidth,
              height: parameters.cropHeight,
              rotateTurns: parameters.rotateTurns,
              x: parameters.cropX,
              y: parameters.cropY,
              flipX: parameters.flipX,
              flipY: parameters.flipY,
            )
          : null,
      // bitrate: _videoMetadata.bitrate,
    );
    final directory = await getTemporaryDirectory();
    final now = DateTime.now().millisecondsSinceEpoch;
    _outputPath = await ProVideoEditor.instance.renderVideoToFile(
      '${directory.path}/my_video_$now.mp4',
      exportModel,
    );
  }

  Future<void> seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;
    if (_isSeeking) {
      _tempDurationSpan = span;
      return;
    }
    _isSeeking = true;
    proVideoController!.pause();
    proVideoController!.setPlayTime(_durationSpan!.start);
    await videoController.pause();
    await videoController.seekTo(span.start);
    _isSeeking = false;
    if (_tempDurationSpan != null) {
      final nextSeek = _tempDurationSpan!;
      _tempDurationSpan = null;
      await seekToPosition(nextSeek);
    }
  }

  void onCloseEditor(EditorMode editorMode) async {
    if (editorMode != EditorMode.main) return Navigator.pop(context);
    if (_outputPath != null && _outputPath!.isNotEmpty) {
      Navigator.pop(context, _outputPath);
      _outputPath = null;
    } else {
      return Navigator.pop(context);
    }
  }

  void initializePlayer() async {
    await _setMetadata();
    _generateThumbnails();
    videoController = VideoPlayerController.file(File(widget.videoPath));
    await Future.wait([
      videoController.initialize(),
      videoController.setLooping(false),
      videoController.setVolume(videoConfigs.initialMuted ? 0 : 100),
      videoConfigs.initialPlay
          ? videoController.play()
          : videoController.pause(),
    ]);
    if (!mounted) return;
    proVideoController = ProVideoController(
      videoPlayer: Center(
        child: AspectRatio(
          aspectRatio: videoController.value.size.aspectRatio,
          child: VideoPlayer(
            videoController,
          ),
        ),
      ),
      initialResolution: _videoMetadata.resolution,
      videoDuration: _videoMetadata.duration,
      fileSize: _videoMetadata.fileSize,
      thumbnails: _thumbnails,
    );
    videoController.addListener(_onDurationChange);
    setState(() {});
  }

  /// Loads and sets _videoMetadata for the given _video.
  Future<void> _setMetadata() async =>
      _videoMetadata = await ProVideoEditor.instance.getMetadata(_video);

  void _generateThumbnails() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final imageWidth = MediaQuery.sizeOf(context).width /
          _thumbnailCount *
          MediaQuery.devicePixelRatioOf(context);

      var thumbnailList = <Uint8List>[];

      /// On android `getKeyFrames` is a way faster than `getThumbnails` but
      /// the timestamps are more "random". If you want the best results i
      /// recommend you to use only `getThumbnails`.
      if (!kIsWeb && Platform.isAndroid) {
        thumbnailList = await ProVideoEditor.instance.getKeyFrames(
          KeyFramesConfigs(
            video: _video,
            outputSize: Size.square(imageWidth),
            boxFit: ThumbnailBoxFit.cover,
            maxOutputFrames: _thumbnailCount,
            outputFormat: ThumbnailFormat.jpeg,
          ),
        );
      } else {
        final duration = _videoMetadata.duration;
        final segmentDuration = duration.inMilliseconds / _thumbnailCount;
        thumbnailList = await ProVideoEditor.instance.getThumbnails(
          ThumbnailConfigs(
            video: _video,
            outputSize: Size.square(imageWidth),
            boxFit: ThumbnailBoxFit.cover,
            timestamps: List.generate(_thumbnailCount, (i) {
              final midpointMs = (i + 0.5) * segmentDuration;
              return Duration(milliseconds: midpointMs.round());
            }),
            outputFormat: ThumbnailFormat.jpeg,
          ),
        );
      }

      final temporaryThumbnails = thumbnailList.map(MemoryImage.new).toList();

      /// Optional precache every thumbnail
      final cacheList = temporaryThumbnails.map(
        (item) => precacheImage(item, context),
      );
      await Future.wait(cacheList);
      _thumbnails = temporaryThumbnails;
      if (proVideoController != null) {
        proVideoController!.thumbnails = _thumbnails;
      }
    });
  }

  void _onDurationChange() {
    final totalVideoDuration = _videoMetadata.duration;
    final duration = videoController.value.position;
    proVideoController!.setPlayTime(duration);
    if (_durationSpan != null && duration >= _durationSpan!.end) {
      seekToPosition(_durationSpan!);
    } else if (duration >= totalVideoDuration) {
      seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: totalVideoDuration),
      );
    }
  }
}
