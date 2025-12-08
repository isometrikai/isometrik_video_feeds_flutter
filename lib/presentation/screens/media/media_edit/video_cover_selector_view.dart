import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

enum FrameGenerationState {
  pending,
  generating,
  completed,
  failed,
}

class FrameState {
  FrameState({
    required this.timestamp,
    required this.state,
    this.filePath,
    this.progress = 0.0,
  });
  final int timestamp;
  final FrameGenerationState state;
  final String? filePath;
  final double progress;

  FrameState copyWith({
    FrameGenerationState? state,
    String? filePath,
    double? progress,
  }) =>
      FrameState(
        timestamp: timestamp,
        state: state ?? this.state,
        filePath: filePath ?? this.filePath,
        progress: progress ?? this.progress,
      );
}

/// Video Cover Selector View
///
/// This widget allows users to select a cover image for a video by:
/// 1. Playing the video with play/pause controls
/// 2. Showing multiple video frames as thumbnails for selection
/// 3. Allowing selection from device gallery
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<File>(
///   context,
///   MaterialPageRoute(
///     builder: (context) => VideoCoverSelectorView(
///       file: File(videoPath),
///     ),
///   ),
/// );
///
/// if (result != null) {
///   // Use the selected cover image file
///   print('Selected cover: ${result.path}');
/// }
/// ```
///
/// Returns: File? - The selected cover image file, or null if cancelled
class VideoCoverSelectorView extends StatefulWidget {
  const VideoCoverSelectorView({
    super.key,
    required this.file,
    required this.mediaEditConfig,
    this.pickCoverPic,
  });

  final File file;
  final MediaEditConfig mediaEditConfig;
  final Future<String?> Function()? pickCoverPic;

  @override
  State<VideoCoverSelectorView> createState() => _VideoCoverSelectorViewState();
}

class _VideoCoverSelectorViewState extends State<VideoCoverSelectorView> {
  VideoPlayerController? _videoController;
  List<String> _videoFrames = [];
  int _selectedFrameIndex = -1; // -1 means no frame selected
  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentVideoPosition = 0; // Current video position in seconds
  int _totalVideoDuration = 0; // Total video duration in seconds
  bool _isGeneratingFrames = false;
  final ScrollController _frameScrollController = ScrollController();

  // Track individual frame states
  List<FrameState> _frameStates = [];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _extractThumbnails(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final outputDir = '${tempDir.path}/frames';
    await Directory(outputDir).create(recursive: true);

    // Initialize frame states for all timestamps
    final timestamps = List.generate(_totalVideoDuration, (index) => index);
    _frameStates = timestamps
        .map((timestamp) => FrameState(
            timestamp: timestamp, state: FrameGenerationState.pending))
        .toList();

    // Update UI to show the list immediately
    if (mounted) {
      setState(() {
        _videoFrames = List.filled(_totalVideoDuration, ''); // Placeholder list
      });
    }

    // Limit concurrency to prevent memory overload
    const maxConcurrency = 4;

    // Process timestamps in batches
    for (var i = 0; i < timestamps.length; i += maxConcurrency) {
      final batch = timestamps.skip(i).take(maxConcurrency).toList();

      // Generate thumbnails for current batch in parallel
      final batchFutures = batch
          .map((timestamp) => _extractSingleThumbnailWithProgress(
              videoPath, outputDir, timestamp))
          .toList();

      // Wait for all thumbnails in current batch to complete
      await Future.wait(batchFutures);

      // Small delay between batches to prevent overwhelming the system
      if (i + maxConcurrency < timestamps.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Update final video frames list with completed frames
    if (mounted) {
      setState(() {
        _videoFrames = _frameStates
            .where((frame) =>
                frame.state == FrameGenerationState.completed &&
                frame.filePath != null)
            .map((frame) => frame.filePath!)
            .toList();
      });
    }
  }

  /// Extract a single thumbnail at a specific timestamp with progress tracking
  Future<void> _extractSingleThumbnailWithProgress(
      String videoPath, String outputDir, int timestamp) async {
    // Update state to generating
    _updateFrameState(timestamp, FrameGenerationState.generating,
        progress: 0.0);

    try {
      final thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: outputDir,
        quality: 75,
        timeMs: timestamp * 1000, // Convert seconds to milliseconds
      );

      if (thumbnailFile.path.isNotEmpty) {
        // Rename the file to have a consistent naming pattern
        final newPath =
            '$outputDir/frame_${timestamp.toString().padLeft(4, '0')}.jpg';
        final file = File(thumbnailFile.path);
        if (await file.exists()) {
          await file.rename(newPath);
          _updateFrameState(timestamp, FrameGenerationState.completed,
              filePath: newPath, progress: 1.0);
        } else {
          _updateFrameState(timestamp, FrameGenerationState.failed);
        }
      } else {
        _updateFrameState(timestamp, FrameGenerationState.failed);
      }
    } catch (e) {
      debugPrint('Error extracting frame at ${timestamp}s: $e');
      _updateFrameState(timestamp, FrameGenerationState.failed);
    }
  }

  /// Update frame state and trigger UI update
  void _updateFrameState(int timestamp, FrameGenerationState state,
      {String? filePath, double progress = 0.0}) {
    if (!mounted) return;

    final index =
        _frameStates.indexWhere((frame) => frame.timestamp == timestamp);
    if (index != -1) {
      setState(() {
        _frameStates[index] = _frameStates[index].copyWith(
          state: state,
          filePath: filePath,
          progress: progress,
        );
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _frameScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(widget.file);
      await _videoController!.initialize();
      _videoController!.addListener(_videoListener);

      // Get video duration
      _totalVideoDuration = _videoController!.value.duration.inSeconds;

      setState(() {
        _isLoading = false;
      });

      // Start generating frames progressively
      unawaited(_generateFramesProgressively());
    } catch (e) {
      debugPrint('Error initializing video: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _videoListener() {
    if (_videoController != null) {
      final currentPosition = _videoController!.value.position.inSeconds;
      setState(() {
        _isPlaying = _videoController!.value.isPlaying;
        _currentVideoPosition = currentPosition;

        // Auto-select frame based on current video position
        _updateSelectedFrameBasedOnPosition();
      });
    }
  }

  Future<void> _generateFramesProgressively() async {
    if (_isGeneratingFrames || _totalVideoDuration == 0) return;

    setState(() => _isGeneratingFrames = true);

    final videoPath = widget.file.path;

    // Verify video file exists
    if (!await File(videoPath).exists()) {
      debugPrint('Video file does not exist: $videoPath');
      setState(() {
        _isGeneratingFrames = false;
      });
      return;
    }

    debugPrint(
        'Extracting frames using get_thumbnail_video (parallel) for video: $videoPath');
    debugPrint('Video duration: $_totalVideoDuration seconds');

    try {
      // Use parallel thumbnail extraction with progressive loading
      await _extractThumbnails(videoPath);

      setState(() {
        _isGeneratingFrames = false;
      });

      debugPrint(
          'Successfully extracted ${_videoFrames.length} frames using parallel get_thumbnail_video');
    } catch (e) {
      debugPrint('Error extracting frames with get_thumbnail_video: $e');
      setState(() {
        _isGeneratingFrames = false;
      });
    }
  }

  void _updateSelectedFrameBasedOnPosition() {
    if (_frameStates.isEmpty) return;

    // Find the closest completed frame to current video position
    final closestFrameIndex =
        _currentVideoPosition.clamp(0, _frameStates.length - 1);

    // Only auto-select if the frame is completed
    if (closestFrameIndex != _selectedFrameIndex &&
        closestFrameIndex < _frameStates.length &&
        _frameStates[closestFrameIndex].state ==
            FrameGenerationState.completed) {
      setState(() {
        _selectedFrameIndex = closestFrameIndex;
      });

      // Auto-scroll to the selected frame
      _scrollToSelectedFrame(closestFrameIndex);
    }
  }

  void _scrollToSelectedFrame(int index) {
    if (!_frameScrollController.hasClients) return;

    // Calculate the position to scroll to
    // Each frame is 80px wide + 8px margin = 88px per frame
    const frameWidth = 88.0;
    const padding = 16.0; // Horizontal padding of the ListView

    final targetOffset = (index * frameWidth) - padding;
    final maxOffset = _frameScrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxOffset);

    _frameScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _selectFrame(int index) {
    // Only allow selection of completed frames
    if (index < _frameStates.length &&
        _frameStates[index].state == FrameGenerationState.completed) {
      setState(() {
        _selectedFrameIndex = index;
      });

      // Seek video to the selected frame position
      if (_videoController != null && _videoController!.value.isInitialized) {
        _videoController!.seekTo(Duration(seconds: index));
      }

      // Scroll to the selected frame
      _scrollToSelectedFrame(index);
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      if (widget.pickCoverPic != null) {
        final coverPath = await widget.pickCoverPic!();
        if (coverPath?.isNotEmpty == true) {
          Navigator.pop(context, File(coverPath!));
        }
      } else {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );

        if (image != null) {
          // Return the selected image file
          Navigator.pop(context, File(image.path));
        }
      }
    } catch (e) {
      debugPrint('Error selecting from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmSelection() {
    if (_selectedFrameIndex >= 0 &&
        _selectedFrameIndex < _frameStates.length &&
        _frameStates[_selectedFrameIndex].state ==
            FrameGenerationState.completed &&
        _frameStates[_selectedFrameIndex].filePath != null) {
      // Return the selected frame file
      Navigator.pop(context, File(_frameStates[_selectedFrameIndex].filePath!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.mediaEditConfig.selectFrameMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: widget.mediaEditConfig.whiteColor,
        appBar: AppBar(
          backgroundColor: widget.mediaEditConfig.whiteColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close,
                color: widget.mediaEditConfig.blackColor, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.mediaEditConfig.editCoverTitle,
            style: TextStyle(
              color: widget.mediaEditConfig.blackColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.check,
                color: _selectedFrameIndex >= 0
                    ? widget.mediaEditConfig.primaryColor
                    : widget.mediaEditConfig.greyColor,
                size: 24,
              ),
              onPressed: _selectedFrameIndex >= 0 ? _confirmSelection : null,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: widget.mediaEditConfig.primaryColor),
                )
              : Column(
                  children: [
                    // Main video preview area
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[900],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildVideoPreview(),
                        ),
                      ),
                    ),

                    // Video frames strip
                    Expanded(
                      flex: 1,
                      child: _buildFramesStrip(),
                    ),

                    // Add from Gallery button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _selectFromGallery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.mediaEditConfig.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          widget.mediaEditConfig.addFromGalleryText,
                          style: widget.mediaEditConfig.primaryText14.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
            color: widget.mediaEditConfig.primaryColor),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),

          // Play/Pause overlay
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramesStrip() => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            // Frames list
            Expanded(
              child: _frameStates.isEmpty
                  ? Center(
                      child: Text(
                        'Preparing frames...',
                        style:
                            TextStyle(color: widget.mediaEditConfig.greyColor),
                      ),
                    )
                  : ListView.builder(
                      controller: _frameScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: _frameStates.length,
                      itemBuilder: (context, index) {
                        final frameState = _frameStates[index];
                        final isSelected = index == _selectedFrameIndex;

                        return GestureDetector(
                          onTap: () => _selectFrame(index),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? widget.mediaEditConfig.primaryColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: _buildFrameWidget(frameState, index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );

  Widget _buildFrameWidget(FrameState frameState, int index) {
    switch (frameState.state) {
      case FrameGenerationState.pending:
        return Container(
          color: widget.mediaEditConfig.greyColor.withValues(alpha: 0.1),
          child: Center(
            child: Icon(
              Icons.schedule,
              color: widget.mediaEditConfig.greyColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
        );

      case FrameGenerationState.generating:
        return Container(
          color: widget.mediaEditConfig.greyColor.withValues(alpha: 0.1),
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.mediaEditConfig.primaryColor,
                  ),
                ),
              ),
              // Progress bar at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: frameState.progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.mediaEditConfig.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );

      case FrameGenerationState.completed:
        if (frameState.filePath != null) {
          return Image.file(
            File(frameState.filePath!),
            fit: BoxFit.cover,
            width: 76.responsiveDimension,
            height: 76.responsiveDimension,
            errorBuilder: (context, error, stackTrace) => Container(
              color: widget.mediaEditConfig.greyColor.withValues(alpha: 0.3),
              child: Icon(
                Icons.image,
                color: widget.mediaEditConfig.greyColor,
              ),
            ),
          );
        } else {
          return Container(
            color: widget.mediaEditConfig.greyColor.withValues(alpha: 0.3),
            child: Icon(
              Icons.image,
              color: widget.mediaEditConfig.greyColor,
            ),
          );
        }

      case FrameGenerationState.failed:
        return Container(
          color: widget.mediaEditConfig.greyColor.withValues(alpha: 0.1),
          child: Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.red.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        );
    }
  }
}
