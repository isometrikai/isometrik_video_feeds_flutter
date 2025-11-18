import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_media_util.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
// import '../../custom_pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:video_player/video_player.dart';

import '../media_edit_config.dart';
import 'pro_video_assist/mixins/video_editor_mixin.dart';
import 'pro_video_assist/widgets/video_initializing_widget.dart';

class ProVideoEditorWrapper extends StatefulWidget {
  const ProVideoEditorWrapper({
    super.key,
    required this.mediaPath,
    required this.mediaEditConfig,
    this.title,
    this.filename,
    this.editingMode,
    this.saveLocally = false, // Default to temp save
  });

  final String mediaPath;
  final MediaEditConfig mediaEditConfig;
  final String? title;
  final String? filename;
  final String? editingMode;
  final bool saveLocally; // true = save locally, false = save in temp/cache

  @override
  State<ProVideoEditorWrapper> createState() => _ProVideoEditorWrapperState();
}

class _ProVideoEditorWrapperState extends State<ProVideoEditorWrapper>
    with VideoEditorMixin {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    videoConfigs = VideoEditorConfigs(
      initialMuted: false,
      initialPlay: false,
      isAudioSupported: true,
      enablePlayButton: true,
      minTrimDuration: const Duration(seconds: 5),
      controlsPosition: VideoEditorControlPosition.bottom,
      style: VideoEditorStyle(
        trimBarBackground: widget.mediaEditConfig.primaryColor,
          trimBarBorderWidth: 2,
        trimBarColor: widget.mediaEditConfig.primaryColor,
        toolbarPadding: EdgeInsets.only(bottom: 16.responsiveDimension, top: 16.responsiveDimension, left: 12.responsiveDimension, right: 12.responsiveDimension),
        trimBarPadding: EdgeInsets.only(bottom: 16.responsiveDimension, top: 16.responsiveDimension),
        muteButtonBackground: widget.mediaEditConfig.blackColor.withValues(alpha: 0.4),
        muteButtonColor: widget.mediaEditConfig.whiteColor,
        trimDurationBackground: widget.mediaEditConfig.blackColor.withValues(alpha: 0.4),
        trimDurationTextColor: widget.mediaEditConfig.whiteColor,
        playIndicatorBackground: widget.mediaEditConfig.blackColor.withValues(alpha: 0.4),
        playIndicatorColor: widget.mediaEditConfig.whiteColor,
      ),
      // maxTrimDuration: Duration(seconds: 15),
    );
    generateThumbnails();
    video = EditorVideo.file(File(widget.mediaPath));
    _videoController =
        VideoPlayerController.file(File(widget.mediaPath));

    await Future.wait([
      setMetadata(),
      _videoController.initialize(),
      _videoController.setLooping(false),
      _videoController.setVolume(videoConfigs.initialMuted ? 0 : 100),
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
  }

  void _onDurationChange() {
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
  Widget build(BuildContext context) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: proVideoController == null
          ? const VideoInitializingWidget()
          : _buildEditor(),
    );

  Widget _buildEditor() => ProImageEditor.video(
      proVideoController!,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: _saveEditedVideo,
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: _videoController.pause,
          onPlay: _videoController.play,
          onMuteToggle: (isMuted) {
            _videoController.setVolume(isMuted ? 0 : 100);
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
      widgets: MainEditorWidgets(
        removeLayerArea: (
            removeAreaKey,
            editor,
            rebuildStream,
            isLayerBeingTransformed,
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

    final _paintEditorConfig = paintEditorConfigs(widget.mediaEditConfig).copyWith(
      tools: const [
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
      ]
    );
    var _videoConfig = videoConfigs.copyWith(
      playTimeSmoothingDuration: const Duration(milliseconds: 600),
      showTrimBar: false,
    );

    var _proConfig = proImageEditorConfigs(widget.mediaEditConfig);

    // Configure based on editing mode
    switch (widget.editingMode) {
      case 'Trim':
        _mainEditorConfig = _mainEditorConfig.copyWith(
          tools: [],
          showUndoRedoActions: false
        );
        _proConfig = _proConfig.copyWith(
          layerInteraction: const LayerInteractionConfigs(
            hideBottomToolbar: true,
            hideToolbarOnInteraction: true
          )
        );
        _videoConfig = _videoConfig.copyWith(
          showTrimBar: true,
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

  /// Builds the sticker picker interface
  Widget _buildStickerPicker(
      Function(WidgetLayer) setLayer,
      ScrollController scrollController,
      ) => Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stickers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _getStickerCount(),
              itemBuilder: (context, index) => _buildStickerItem(index, setLayer),
            ),
          ),
        ],
      ),
    );

  /// Returns the number of available stickers
  int _getStickerCount() {
    // For now, return a simple count of placeholder stickers
    // In a real implementation, this would come from your sticker assets or API
    return 20;
  }

  /// Builds individual sticker items
  Widget _buildStickerItem(int index, Function(WidgetLayer) setLayer) => GestureDetector(
      onTap: () {
        // Create a simple text-based sticker for demonstration
        // In a real implementation, you would use actual sticker images
        final stickerWidget = Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Center(
            child: Text(
              '😊', // Simple emoji as placeholder
              style: TextStyle(fontSize: 40),
            ),
          ),
        );

        // Create a WidgetLayer with the sticker
        final widgetLayer = WidgetLayer(
          widget: stickerWidget,
          exportConfigs: const WidgetLayerExportConfigs(),
        );

        // Set the layer and close the picker
        setLayer(widgetLayer);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text(
            '😊', // Placeholder emoji
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
    );

  Widget _buildVideoPlayer() => Center(
      child: AspectRatio(
        aspectRatio: _videoController.value.size.aspectRatio,
        child: VideoPlayer(
          _videoController,
        ),
      ),
    );

  Future<void> _saveEditedVideo(CompleteParameters parameters) async {
    try {
      // 1️⃣ Generate the edited video file path
      final outputPath = await generateVideo(parameters);
      if (outputPath == null) {
        return; // nothing to save
      }
      final outputFile = File(outputPath);
      debugPrint('Video editing complete, output: $outputPath');

      // 2️⃣ Save video locally if requested
      if (widget.saveLocally) {
        try {
          // Save video to gallery using PhotoManager
          // Pass the file or bytes of the video
          final pm.AssetEntity? asset = await pm.PhotoManager.editor.saveVideo(
            outputFile, // pass File here
            title: widget.title ?? 'edited_video.mp4',
          );

          if (asset != null) {
            debugPrint('Got Video AssetEntity: ${asset.id}');
            final editedFile = await asset.file;

            _navigateBack({
              'success': true,
              'asset': asset,
              'file': editedFile ?? outputFile,
              'outputPath': outputPath,
              'mediaType': 'video',
              'savedLocally': true,
            });
          } else {
            debugPrint('Failed to create Video AssetEntity, using file directly');
            _navigateBack({
              'success': true,
              'file': outputFile,
              'outputPath': outputPath,
              'mediaType': 'video',
              'savedLocally': false,
            });
          }
        } catch (e) {
          debugPrint('Error saving video to gallery: $e');
          _navigateBack({
            'success': true,
            'file': outputFile,
            'outputPath': outputPath,
            'mediaType': 'video',
            'savedLocally': false,
          });
        }
      } else {
        // 3️⃣ Only return the temp file if not saving locally
        _navigateBack({
          'success': true,
          'file': outputFile,
          'outputPath': outputPath,
          'mediaType': 'video',
          'savedLocally': false,
        });
      }
    } catch (e) {
      debugPrint('Error saving edited video: $e');
      _navigateBack({
        'success': false,
        'error': 'Failed to save edited video: $e',
      });
    }
  }

  bool _hasNavigated = false;
  void _navigateBack(Map<String, dynamic> result) {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      Navigator.pop(context, result);
    }
  }
}
