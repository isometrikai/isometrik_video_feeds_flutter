import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../media_selection.dart';

enum VideoLoadingState {
  idle,
  loading,
  loaded,
  error,
}

class MediaPreviewWidget extends StatefulWidget {
  const MediaPreviewWidget({
    super.key,
    required this.mediaSelectionConfig,
    required this.mediaData,
    required this.currentIndex,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
  });

  final MediaSelectionConfig mediaSelectionConfig;
  final MediaAssetData mediaData;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget>
    with TickerProviderStateMixin {
  // Controllers moved from MediaSelectionView
  VideoPlayerController? _videoController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonOpacityAnimation;
  final PhotoViewController _photoViewController = PhotoViewController();
  final PhotoViewScaleStateController _scaleStateController = PhotoViewScaleStateController();

  // State management
  bool _showPlayPauseButton = true;
  VideoLoadingState _videoLoadingState = VideoLoadingState.idle;
  String? _videoError;
  bool _isVideoVisible = true;
  bool _wasPlayingBeforeVisibilityChange = false;

  // Constants
  static const Duration _buttonHideDelay = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoIfNeeded();
  }

  @override
  void didUpdateWidget(MediaPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the media data has changed
    if (oldWidget.mediaData.assetId != widget.mediaData.assetId ||
        oldWidget.mediaData.localPath != widget.mediaData.localPath) {
      _initializeVideoIfNeeded();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoErrorListener);
    _videoController?.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeOut,
    ));
  }

  void _initializeVideoIfNeeded() {
    if (widget.mediaData.mediaType == SelectedMediaType.video &&
        widget.mediaData.localPath != null) {
      // Check if we need to initialize the video controller
      final needsInitialization = _videoController == null ||
          !_videoController!.value.isInitialized ||
          _videoController!.dataSource != widget.mediaData.localPath;

      if (needsInitialization) {
        setState(() {
          _videoLoadingState = VideoLoadingState.loading;
          _videoError = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeVideo(widget.mediaData.localPath!);
        });
      }
    }
  }

  Future<void> _initializeVideo(String videoPath) async {
    try {
      debugPrint('Initializing video: $videoPath');

      // Check if file exists
      final file = File(videoPath);
      if (!await file.exists()) {
        debugPrint('Video file does not exist: $videoPath');
        if (mounted) {
          setState(() {
            _videoLoadingState = VideoLoadingState.error;
            _videoError = 'Video file not found';
          });
        }
        return;
      }

      // Dispose existing controller
      await _videoController?.dispose();

      // Create new controller
      _videoController = VideoPlayerController.file(file);

      // Add error listener
      _videoController!.addListener(_videoErrorListener);

      // Add timeout for initialization
      await _videoController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Video initialization timeout');
          throw Exception(
              'Video initialization timeout - file may be corrupted or too large');
        },
      );

      debugPrint(
          'Video controller initialized: ${_videoController!.value.isInitialized}');

      if (_videoController!.value.isInitialized) {
        await _videoController!.setLooping(true);
        await _videoController!.play();

        // Hide play/pause button after delay when playing
        _hidePlayPauseButtonAfterDelay();

        if (mounted) {
          setState(() {
            _videoLoadingState = VideoLoadingState.loaded;
            _videoError = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _videoLoadingState = VideoLoadingState.error;
            _videoError = 'Failed to initialize video player';
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _videoLoadingState = VideoLoadingState.error;
          _videoError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _videoErrorListener() {
    if (_videoController != null && _videoController!.value.hasError) {
      debugPrint(
          'Video player error: ${_videoController!.value.errorDescription}');
      if (mounted) {
        setState(() {
          _videoLoadingState = VideoLoadingState.error;
          _videoError =
              _videoController!.value.errorDescription ?? 'Unknown video error';
        });
      }
    }
  }

  void _hidePlayPauseButtonAfterDelay() {
    Future.delayed(_buttonHideDelay, () {
      if (_videoController != null && _videoController!.value.isPlaying) {
        _buttonAnimationController.forward().then((_) {
          if (mounted) {
            setState(() => _showPlayPauseButton = false);
          }
        });
      }
    });
  }

  void _handleVideoTap() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        setState(() => _showPlayPauseButton = true);
        _buttonAnimationController.reset();
      } else {
        _videoController!.play();
        setState(() => _showPlayPauseButton = true);
        _buttonAnimationController.reset();
        _hidePlayPauseButtonAfterDelay();
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo visibilityInfo) {
    final isVisible = visibilityInfo.visibleFraction >= 1.0; // Fully visible
    
    if (_isVideoVisible != isVisible) {
      _isVideoVisible = isVisible;
      
      if (_videoController != null && _videoController!.value.isInitialized) {
        if (!isVisible && _videoController!.value.isPlaying) {
          // Video is not fully visible and is playing - pause it
          _wasPlayingBeforeVisibilityChange = true;
          _videoController!.pause();
          setState(() => _showPlayPauseButton = true);
          _buttonAnimationController.reset();
        } else if (isVisible && _wasPlayingBeforeVisibilityChange) {
          // Video is fully visible again and was playing before - resume it
          _wasPlayingBeforeVisibilityChange = false;
          _videoController!.play();
          setState(() => _showPlayPauseButton = true);
          _buttonAnimationController.reset();
          _hidePlayPauseButtonAfterDelay();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ClipRRect(
          child: Stack(
            children: [
              // Main media content
              widget.mediaData.mediaType == SelectedMediaType.video
                  ? _buildVideoPreview()
                  : _buildImageContent(),

              // Navigation controls
              if (widget.totalCount > 1) _buildNavigationControls(),
            ],
          ),
        ),
      );

  Widget _buildVideoPreview() => VisibilityDetector(
        key: Key('video_${widget.mediaData.assetId}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onTap: _handleVideoTap,
                child: _buildVideoContent(),
              ),
            ),
            // Play/Pause button overlay
            if (_videoController != null &&
                _videoController!.value.isInitialized &&
                _videoLoadingState == VideoLoadingState.loaded &&
                _showPlayPauseButton)
              Center(
                child: AnimatedBuilder(
                  animation: _buttonOpacityAnimation,
                  builder: (context, child) => Opacity(
                      opacity: _buttonOpacityAnimation.value,
                      child: _videoController!.value.isPlaying
                          ? widget.mediaSelectionConfig.pauseIcon
                          : widget.mediaSelectionConfig.playIcon),
                ),
              ),
          ],
        ),
      );

  Widget _buildVideoContent() {
    switch (_videoLoadingState) {
      case VideoLoadingState.loading:
        return _buildVideoLoadingState();
      case VideoLoadingState.error:
        return _buildVideoErrorState();
      case VideoLoadingState.loaded:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          );
        }
        return _buildVideoLoadingState();
      case VideoLoadingState.idle:
        return _buildVideoLoadingState();
    }
  }

  Widget _buildVideoLoadingState() => Container(
        color: widget.mediaSelectionConfig.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: widget.mediaSelectionConfig.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                    color: widget.mediaSelectionConfig.primaryTextColor),
              ),
            ],
          ),
        ),
      );

  Widget _buildVideoErrorState() => Container(
        color: widget.mediaSelectionConfig.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load video',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_videoError != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _videoError!,
                    style: TextStyle(
                      color: widget.mediaSelectionConfig.primaryTextColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.mediaData.localPath != null) {
                    setState(() {
                      _videoLoadingState = VideoLoadingState.loading;
                      _videoError = null;
                    });
                    _initializeVideo(widget.mediaData.localPath!);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Path: ${widget.mediaData.localPath ?? 'No path'}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildImageContent() => PhotoView(
    imageProvider: FileImage(File(widget.mediaData.localPath ?? '')),
    minScale: PhotoViewComputedScale.contained,
    maxScale: PhotoViewComputedScale.covered * 2,
    backgroundDecoration: const BoxDecoration(color: Colors.white),
  );

  Widget _buildNavigationControls() => Positioned(
        bottom: 16,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous button
            _buildNavigationButton(
              icon: Icons.chevron_left,
              onTap: widget.currentIndex > 0 ? widget.onPrevious : null,
              isEnabled: widget.currentIndex > 0,
            ),

            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.currentIndex + 1} of ${widget.totalCount}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.responsiveDimension,
                  fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Next button
            _buildNavigationButton(
              icon: Icons.chevron_right,
              onTap: widget.currentIndex < widget.totalCount - 1
                  ? widget.onNext
                  : null,
              isEnabled: widget.currentIndex < widget.totalCount - 1,
            ),
          ],
        ),
      );

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isEnabled,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.grey,
            size: 24,
          ),
        ),
      );
}
