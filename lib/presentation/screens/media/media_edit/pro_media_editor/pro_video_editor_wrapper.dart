import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_media_util.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_video_assist/mixins/video_editor_mixin.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_video_assist/widgets/video_initializing_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/widgets/isr_video_editor_trim_bar.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:video_player/video_player.dart';

class ProVideoEditorWrapper extends StatefulWidget {
  const ProVideoEditorWrapper({
    super.key,
    required this.mediaPath,
    required this.mediaEditConfig,
    this.title,
    this.filename,
    this.editingMode,
    this.saveLocally = false, // Default to temp save
    this.maxTrimDuration,
    this.minTrimDuration,
  });

  final String mediaPath;
  final MediaEditConfig mediaEditConfig;
  final String? title;
  final String? filename;
  final String? editingMode;
  final bool saveLocally; // true = save locally, false = save in temp/cache
  final Duration? maxTrimDuration;
  final Duration? minTrimDuration;

  @override
  State<ProVideoEditorWrapper> createState() => _ProVideoEditorWrapperState();
}

class _ProVideoEditorWrapperState extends State<ProVideoEditorWrapper>
    with VideoEditorMixin {
  VideoPlayerController? _videoController;
  String? _initError;
  Map<String, dynamic>? _pendingNavigationResult;
  bool _isExportingVideo = false;
  ProImageEditorConfigs? _editorConfigs;

  @override
  void initState() {
    super.initState();
    _applySystemUiOverlay();
    unawaited(_initializePlayer());
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _applySystemUiOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      mediaEditorUiOverlay(widget.mediaEditConfig),
    );
  }

  Future<void> _initializePlayer() async {
    try {
      video = EditorVideo.file(File(widget.mediaPath));
      _videoController = VideoPlayerController.file(File(widget.mediaPath));

      await video.safeFilePath();
      videoMetadata = await ProVideoEditor.instance.getMetadata(video);

      final trimBarMaxScale = _trimBarMaxScaleFor(
        widget.maxTrimDuration ?? videoMetadata.duration,
        videoMetadata.duration,
      );
      final minTrimDuration = _effectiveMinTrimDuration(
        videoMetadata.duration,
        widget.minTrimDuration,
      );
      const trimBarHandlerButtonSize = 12.0;
      final toolbarHorizontalPadding = max(
        trimBarHandlerButtonSize,
        16.responsiveDimension,
      );

      videoConfigs = VideoEditorConfigs(
        initialMuted: false,
        initialPlay: false,
        isAudioSupported: true,
        enablePlayButton: true,
        minTrimDuration: minTrimDuration,
        maxTrimDuration: widget.maxTrimDuration,
        trimBarMinScale: 1,
        trimBarMaxScale: trimBarMaxScale,
        controlsPosition: VideoEditorControlPosition.bottom,
        widgets: const VideoEditorWidgets(
          trimBar: IsrVideoEditorTrimBar(),
        ),
        style: VideoEditorStyle(
          trimBarBackground: widget.mediaEditConfig.primaryColor,
          trimBarBorderWidth: 2.5,
          trimBarColor: widget.mediaEditConfig.primaryColor,
          trimBarHeight: 56,
          trimBarHandlerWidth: 32,
          trimBarHandlerButtonSize: trimBarHandlerButtonSize,
          toolbarPadding: EdgeInsets.only(
            bottom: 16.responsiveDimension,
            top: 16.responsiveDimension,
            left: toolbarHorizontalPadding,
            right: toolbarHorizontalPadding,
          ),
          muteButtonBackground:
              widget.mediaEditConfig.blackColor.withValues(alpha: 0.4),
          muteButtonColor: widget.mediaEditConfig.whiteColor,
          trimDurationBackground:
              widget.mediaEditConfig.blackColor.withValues(alpha: 0.4),
          trimDurationTextColor: widget.mediaEditConfig.whiteColor,
          playIndicatorBackground:
              widget.mediaEditConfig.blackColor.withValues(alpha: 0.4),
          playIndicatorColor: widget.mediaEditConfig.whiteColor,
        ),
      );

      generateThumbnails(trimBarMaxScale: trimBarMaxScale);

      await _videoController!.initialize();
      await _videoController!.setLooping(false);
      await _videoController!.setVolume(videoConfigs.initialMuted ? 0 : 1);
      if (videoConfigs.initialPlay) {
        await _videoController!.play();
      } else {
        await _videoController!.pause();
      }

      if (!mounted) return;

      final playerSize = _videoController!.value.size;
      final effectiveResolution = playerSize.width > 0 && playerSize.height > 0
          ? playerSize
          : videoMetadata.resolution;

      proVideoController = ProVideoController(
        videoPlayer: _buildVideoPlayer(),
        initialResolution: effectiveResolution,
        videoDuration: videoMetadata.duration,
        fileSize: videoMetadata.fileSize,
        bitrate: videoMetadata.bitrate,
        thumbnails: thumbnails,
      );

      final controller = _videoController!;
      controller.addListener(_onDurationChange);

      _editorConfigs = _createEditorConfigs();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applySystemUiOverlay();
      });
    } catch (e, st) {
      debugPrint('ProVideoEditorWrapper init failed: $e\n$st');
      if (!mounted) return;
      setState(() => _initError = e.toString());
    }
  }

  void _onDurationChange() {
    if (_isExportingVideo) return;

    final controller = _videoController;
    if (controller == null || proVideoController == null) return;
    // Use videoMetadata duration if available, otherwise use controller duration
    final totalVideoDuration = videoMetadata.duration;
    final duration = controller.value.position;
    proVideoController!.setPlayTime(duration);

    if (durationSpan != null && duration >= durationSpan!.end) {
      _seekToPosition(durationSpan!);
    } else if (duration >= totalVideoDuration) {
      _seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: totalVideoDuration),
      );
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    durationSpan = span;

    if (isSeeking) {
      tempDurationSpan = span; // Store the latest seek request
      return;
    }
    isSeeking = true;

    proVideoController!.pause();
    proVideoController!.setPlayTime(durationSpan!.start);

    await _videoController!.pause();
    await _videoController!.seekTo(span.start);

    isSeeking = false;

    // Check if there's a pending seek request
    if (tempDurationSpan != null) {
      final nextSeek = tempDurationSpan!;
      tempDurationSpan = null; // Clear the pending seek
      await _seekToPosition(nextSeek); // Process the latest request
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: mediaEditorUiOverlay(widget.mediaEditConfig),
        child: Scaffold(
          backgroundColor: widget.mediaEditConfig.whiteColor,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _initError != null
                ? _buildInitError()
                : proVideoController == null
                    ? const VideoInitializingWidget()
                    : _buildEditor(),
          ),
        ),
      );

  Widget _buildInitError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Could not open video editor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.mediaEditConfig.primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEditor() => ProImageEditor.video(
        proVideoController!,
        callbacks: ProImageEditorCallbacks(
          onCompleteWithParameters: _saveEditedVideo,
          onCloseEditor: _onCloseEditor,
          videoEditorCallbacks: VideoEditorCallbacks(
            onPause: () => _videoController?.pause(),
            onPlay: () => _videoController?.play(),
            onMuteToggle: (isMuted) {
              _videoController?.setVolume(isMuted ? 0 : 1);
            },
            onTrimSpanUpdate: (durationSpan) {
              if (_videoController?.value.isPlaying ?? false) {
                proVideoController!.pause();
              }
            },
            onTrimSpanEnd: _seekToPosition,
          ),
        ),
        configs: _editorConfigs!,
      );

  /// Get editor configuration based on editing mode
  ProImageEditorConfigs _createEditorConfigs() {
    var mainEditor = mainEditorConfig(widget.mediaEditConfig).copyWith(
      widgets: buildMainEditorWidgets(
        widget.mediaEditConfig,
        removeLayerArea: (
          GlobalKey removeAreaKey,
          ProImageEditorState editor,
          Stream<void> rebuildStream,
          bool isLayerBeingTransformed,
        ) =>
            VideoEditorRemoveArea(
          removeAreaKey: removeAreaKey,
          editor: editor,
          rebuildStream: rebuildStream,
          isLayerBeingTransformed: isLayerBeingTransformed,
        ),
      ),
      tools: [
        SubEditorMode.paint,
        SubEditorMode.text,
        SubEditorMode.tune,
        SubEditorMode.filter,
        SubEditorMode.blur,
        SubEditorMode.emoji,
        SubEditorMode.sticker,
      ],
    );

    final paintEditorConfig =
        paintEditorConfigs(widget.mediaEditConfig).copyWith(tools: const [
      PaintMode.moveAndZoom,
      PaintMode.freeStyle,
      PaintMode.arrow,
      PaintMode.line,
      PaintMode.rect,
      PaintMode.circle,
      PaintMode.dashLine,
      PaintMode.dashDotLine,
      PaintMode.polygon,
      PaintMode.eraser,
    ]);
    var videoConfig = videoConfigs.copyWith(
      playTimeSmoothingDuration: const Duration(milliseconds: 600),
      enableTrimBar: false,
    );

    var proConfig = proImageEditorConfigs(widget.mediaEditConfig);

    // Configure based on editing mode
    switch (widget.editingMode) {
      case 'Trim':
        mainEditor = mainEditor.copyWith(
          tools: [],
          captureImageOnDone: false,
          captureLayersOnDone: false,
          widgets: buildMainEditorWidgets(
            widget.mediaEditConfig,
            hideBottomBar: true,
            hideUndoRedoActions: true,
            removeLayerArea: mainEditor.widgets.removeLayerArea,
          ),
        );
        proConfig = proConfig.copyWith(
          layerInteraction: const LayerInteractionConfigs(
            hideToolbarOnInteraction: true,
          ),
        );
        videoConfig = videoConfig.copyWith(
          enableTrimBar: true,
        );
        break;

      case 'filter':
        mainEditor = mainEditor.copyWith(
          tools: [
            SubEditorMode.tune,
            SubEditorMode.filter,
            SubEditorMode.blur,
          ],
        );
        break;
    }
    return proConfig.copyWith(
      mainEditor: mainEditor,
      paintEditor: paintEditorConfig,
      videoEditor: videoConfig,
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _videoController!;
    final videoSize = controller.value.size;
    if (videoSize.width <= 0 || videoSize.height <= 0) {
      return const ColoredBox(color: Colors.black);
    }

    // Render at native video resolution so pro_image_editor's FittedBox only
    // scales down (sharp), never upscales a tiny texture.
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: videoSize.width,
        height: videoSize.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  /// Releases playback resources before native export to reduce iOS decoder
  /// pressure while the loading overlay is still visible.
  Future<void> _prepareForVideoExport() async {
    _isExportingVideo = true;
    final controller = _videoController;
    if (controller == null) return;

    controller.removeListener(_onDurationChange);
    await controller.pause();
    proVideoController?.pause();

    thumbnails = [];
    proVideoController?.thumbnails = thumbnails;

    if (Platform.isIOS) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _saveEditedVideo(CompleteParameters parameters) async {
    try {
      await _prepareForVideoExport();

      final outputPath = widget.editingMode == 'Trim'
          ? await _exportTrimOnly(parameters)
          : await generateVideo(parameters);
      if (outputPath == null) {
        _pendingNavigationResult = {
          'success': false,
          'error': 'Video export produced no output',
        };
        return;
      }
      final outputFile = File(outputPath);
      debugPrint('Video editing complete, output: $outputPath');

      if (widget.saveLocally) {
        try {
          final pm.AssetEntity? asset = await pm.PhotoManager.editor.saveVideo(
            outputFile,
            title: widget.title ?? 'edited_video.mp4',
          );

          if (asset != null) {
            debugPrint('Got Video AssetEntity: ${asset.id}');
            final editedFile = await asset.file;

            _pendingNavigationResult = {
              'success': true,
              'asset': asset,
              'file': editedFile ?? outputFile,
              'outputPath': outputPath,
              'mediaType': 'video',
              'savedLocally': true,
            };
          } else {
            debugPrint(
                'Failed to create Video AssetEntity, using file directly');
            _pendingNavigationResult = {
              'success': true,
              'file': outputFile,
              'outputPath': outputPath,
              'mediaType': 'video',
              'savedLocally': false,
            };
          }
        } catch (e) {
          debugPrint('Error saving video to gallery: $e');
          _pendingNavigationResult = {
            'success': true,
            'file': outputFile,
            'outputPath': outputPath,
            'mediaType': 'video',
            'savedLocally': false,
          };
        }
      } else {
        _pendingNavigationResult = {
          'success': true,
          'file': outputFile,
          'outputPath': outputPath,
          'mediaType': 'video',
          'savedLocally': false,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving edited video: $e');
      debugPrint('$stackTrace');
      _pendingNavigationResult = {
        'success': false,
        'error': 'Failed to save edited video: $e',
      };
    } finally {
      _isExportingVideo = false;
    }
  }

  Future<String?> _exportTrimOnly(CompleteParameters parameters) async {
    final start =
        parameters.startTime ?? proVideoController?.startTime ?? Duration.zero;
    final end = parameters.endTime ??
        proVideoController?.endTime ??
        videoMetadata.duration;

    if (end <= start) return null;

    const slack = Duration(milliseconds: 250);
    if (start <= Duration.zero && end >= videoMetadata.duration - slack) {
      return widget.mediaPath;
    }

    return MediaUtil.trimVideoSegment(
      inputPath: widget.mediaPath,
      start: start,
      end: end,
    );
  }

  /// Called by [ProImageEditor] after export completes. Navigation is deferred
  /// so the editor can dismiss its loading overlay before this route pops.
  void _onCloseEditor(EditorMode editorMode) {
    if (editorMode != EditorMode.main) {
      Navigator.pop(context);
      return;
    }

    final result = _pendingNavigationResult;
    _pendingNavigationResult = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context, result);
    });
  }

  /// Allows pinch-zooming enough that short clips (e.g. 15s) fill the bar.
  static double _trimBarMaxScaleFor(Duration maxTrim, Duration videoDuration) {
    final videoUs = videoDuration.inMicroseconds;
    final trimUs = maxTrim.inMicroseconds;
    if (videoUs <= 0 || trimUs <= 0) return 12;
    final ratio = trimUs / videoUs;
    if (ratio >= 0.45) return 5;
    return (0.58 / ratio).clamp(5, 24);
  }

  static Duration _effectiveMinTrimDuration(
    Duration videoDuration,
    Duration? requestedMinTrim,
  ) {
    final requested = requestedMinTrim ?? const Duration(seconds: 1);
    if (videoDuration <= Duration.zero) return requested;
    if (requested > videoDuration) return videoDuration;
    if (requested <= Duration.zero) {
      return const Duration(milliseconds: 500);
    }
    return requested;
  }
}
