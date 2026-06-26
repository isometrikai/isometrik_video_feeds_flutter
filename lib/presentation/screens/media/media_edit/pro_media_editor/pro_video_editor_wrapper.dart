import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_media_util.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_video_assist/mixins/video_editor_mixin.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_video_assist/widgets/video_initializing_widget.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
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
  late VideoPlayerController _videoController;
  Map<String, dynamic>? _pendingNavigationResult;
  bool _isExportingVideo = false;

  @override
  void initState() {
    super.initState();
    _applySystemUiOverlay();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _applySystemUiOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      mediaEditorUiOverlay(widget.mediaEditConfig),
    );
  }

  void _initializePlayer() async {
    videoConfigs = VideoEditorConfigs(
      initialMuted: false,
      initialPlay: false,
      isAudioSupported: true,
      enablePlayButton: true,
      minTrimDuration:
          widget.minTrimDuration ?? const Duration(seconds: 5),
      maxTrimDuration: widget.maxTrimDuration,
      controlsPosition: VideoEditorControlPosition.bottom,
      style: VideoEditorStyle(
        trimBarBackground: widget.mediaEditConfig.primaryColor,
        trimBarBorderWidth: 2,
        trimBarColor: widget.mediaEditConfig.primaryColor,
        toolbarPadding: EdgeInsets.only(
            bottom: 16.responsiveDimension,
            top: 16.responsiveDimension,
            left: 12.responsiveDimension,
            right: 12.responsiveDimension),
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
    generateThumbnails();
    video = EditorVideo.file(File(widget.mediaPath));
    _videoController = VideoPlayerController.file(File(widget.mediaPath));

    await Future.wait([
      setMetadata(),
      _videoController.initialize(),
      _videoController.setLooping(false),
      _videoController.setVolume(videoConfigs.initialMuted ? 0 : 1),
      videoConfigs.initialPlay
          ? _videoController.play()
          : _videoController.pause(),
    ]);
    if (!mounted) return;

    // Check if videoMetadata was successfully initialized
    proVideoController = ProVideoController(
      videoPlayer: _buildVideoPlayer(),
      initialResolution: videoMetadata.resolution,
      videoDuration: videoMetadata.duration,
      fileSize: videoMetadata.fileSize,
      bitrate: videoMetadata.bitrate,
      thumbnails: thumbnails,
    );

    _videoController.addListener(_onDurationChange);

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applySystemUiOverlay();
    });
  }

  void _onDurationChange() {
    if (_isExportingVideo) return;

    // Use videoMetadata duration if available, otherwise use controller duration
    final totalVideoDuration = videoMetadata.duration;
    final duration = _videoController.value.position;
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

    await _videoController.pause();
    await _videoController.seekTo(span.start);

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
            child: proVideoController == null
                ? const VideoInitializingWidget()
                : _buildEditor(),
          ),
        ),
      );

  Widget _buildEditor() => ProImageEditor.video(
        proVideoController!,
        callbacks: ProImageEditorCallbacks(
          onCompleteWithParameters: _saveEditedVideo,
          onCloseEditor: _onCloseEditor,
          videoEditorCallbacks: VideoEditorCallbacks(
            onPause: _videoController.pause,
            onPlay: _videoController.play,
            onMuteToggle: (isMuted) {
              _videoController.setVolume(isMuted ? 0 : 1);
            },
            onTrimSpanUpdate: (durationSpan) {
              if (_videoController.value.isPlaying) {
                proVideoController!.pause();
              }
            },
            onTrimSpanEnd: _seekToPosition,
          ),
        ),
        configs: _getEditorConfigs(),
      );

  /// Get editor configuration based on editing mode
  ProImageEditorConfigs _getEditorConfigs() {
    var _mainEditorConfig = mainEditorConfig(widget.mediaEditConfig).copyWith(
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

    final _paintEditorConfig =
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
    var _videoConfig = videoConfigs.copyWith(
      playTimeSmoothingDuration: const Duration(milliseconds: 600),
      enableTrimBar: false,
    );

    var _proConfig = proImageEditorConfigs(widget.mediaEditConfig);

    // Configure based on editing mode
    switch (widget.editingMode) {
      case 'Trim':
        _mainEditorConfig = _mainEditorConfig.copyWith(
          tools: [],
          captureImageOnDone: false,
          captureLayersOnDone: false,
          widgets: buildMainEditorWidgets(
            widget.mediaEditConfig,
            hideBottomBar: true,
            hideUndoRedoActions: true,
            removeLayerArea: _mainEditorConfig.widgets.removeLayerArea,
          ),
        );
        _proConfig = _proConfig.copyWith(
          layerInteraction: const LayerInteractionConfigs(
            hideToolbarOnInteraction: true,
          ),
        );
        _videoConfig = _videoConfig.copyWith(
          enableTrimBar: true,
        );
        break;

      case 'filter':
        _mainEditorConfig = _mainEditorConfig.copyWith(
          tools: [
            SubEditorMode.tune,
            SubEditorMode.filter,
            SubEditorMode.blur,
          ],
        );
        break;
    }
    return _proConfig.copyWith(
      mainEditor: _mainEditorConfig,
      paintEditor: _paintEditorConfig,
      videoEditor: _videoConfig,
    );
  }

  Widget _buildVideoPlayer() => Center(
        child: AspectRatio(
          aspectRatio: _videoController.value.size.aspectRatio,
          child: VideoPlayer(
            _videoController,
          ),
        ),
      );

  /// Releases playback resources before native export to reduce iOS decoder
  /// pressure while the loading overlay is still visible.
  Future<void> _prepareForVideoExport() async {
    _isExportingVideo = true;
    _videoController.removeListener(_onDurationChange);
    await _videoController.pause();
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

      final outputPath = await generateVideo(parameters);
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
}
