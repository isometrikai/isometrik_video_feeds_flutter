import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Custom Reels Player for both Video and Photo content with carousel support
class IsmReelsVideoPlayerView extends StatefulWidget {
  const IsmReelsVideoPlayerView({
    super.key,
    this.videoCacheManager,
    this.reelsData,
    this.onPressMoreButton,
    this.onCreatePost,
    this.onPressFollowButton,
    this.onPressLikeButton,
    this.onPressSaveButton,
    this.onDoubleTap,
    this.loggedInUserId,
    this.onVideoCompleted,
  });

  final VideoCacheManager? videoCacheManager;
  final ReelsData? reelsData;
  final VoidCallback? onPressMoreButton;
  final Future<void> Function()? onCreatePost;
  final Future<void> Function()? onPressFollowButton;
  final Future<void> Function()? onPressLikeButton;
  final Future<void> Function()? onPressSaveButton;
  final Future<void> Function()? onDoubleTap;
  final String? loggedInUserId;
  final VoidCallback? onVideoCompleted;

  @override
  State<IsmReelsVideoPlayerView> createState() => _IsmReelsVideoPlayerViewState();
}

class _IsmReelsVideoPlayerViewState extends State<IsmReelsVideoPlayerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Use MediaCacheFactory instead of direct VideoCacheManager
  VideoCacheManager get _videoCacheManager => widget.videoCacheManager ?? VideoCacheManager();

  // Add constants for media types
  static const int kPictureType = 0;
  static const int kVideoType = 1;

  // Carousel related variables
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  PageController? _pageController;

  TapGestureRecognizer? _tapGestureRecognizer;

  IVideoPlayerController? _videoPlayerController;
  final Set<String> _loggedMilestones = {}; // prevent duplicates

  var _isPlaying = true;
  var _isPlayPauseActioned = false;
  var _isDisposed = false;

  final ValueNotifier<bool> _isFollowLoading = ValueNotifier(false);
  final ValueNotifier<bool> _isExpandedDescription = ValueNotifier(false);
  final ValueNotifier<bool> _isSaveLoading = ValueNotifier(false);
  final ValueNotifier<bool> _isLikeLoading = ValueNotifier(false);

  // Change _isMuted to static
  static bool _isMuted = false;
  final _maxLengthToShow = 50;
  late ReelsData _reelData;

  bool _mentionsVisible = false;
  var _postDescription = '';
  List<MentionMetaData> _mentionedMetaDataList = [];
  List<MentionMetaData> _pageMentionMetaDataList = [];
  List<MentionMetaData> _mentionedDataList = [];
  List<MentionMetaData> _taggedDataList = [];

  bool _showLikeAnimation = false;
  Timer? _likeAnimationTimer;
  bool _showMuteAnimation = false;
  Timer? _muteAnimationTimer;
  double _muteIconScale = 1.0;

  // Track if video has completed one full cycle for auto-advance
  bool _hasCompletedOneCycle = false;

  @override
  void initState() {
    _onStartInit();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_isPlaying) {
        _togglePlayPause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isPlaying) {
        _togglePlayPause();
      }
    }
  }

  /// Returns true if the video controller is ready for playback.
  bool get _controllerReady =>
      _videoPlayerController != null && !_isDisposed && _videoPlayerController!.isInitialized;

  /// Returns true if the current post has multiple media items (carousel).
  bool get _hasMultipleMedia => _reelData.mediaMetaDataList.length > 1;

  void _onStartInit() async {
    _reelData = widget.reelsData!;
    _mentionedMetaDataList =
        _reelData.mentions?.where((mentionData) => mentionData.mediaPosition != null).toList() ??
            [];
    _pageMentionMetaDataList = _mentionedMetaDataList
        .where((mention) => mention.mediaPosition?.position == _currentPageNotifier.value + 1)
        .toList();
    _mentionedDataList =
        _reelData.mentions?.where((mentionData) => mentionData.textPosition != null).toList() ?? [];
    _taggedDataList =
        _reelData.tagDataList?.where((mentionData) => mentionData.textPosition != null).toList() ??
            [];
    _postDescription = _reelData.description ?? '';
    _tapGestureRecognizer = TapGestureRecognizer();

    // Initialize PageController for carousel
    _pageController = PageController(initialPage: 0);

    debugPrint(
        'IsmReelsVideoPlayerView ...Post by ...${_reelData.userName}\n Post url ${_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl}');

    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType) {
      await _initializeVideoPlayer();
      mountUpdate();
    }
  }

  /// Method For Update The Tree Carefully
  void mountUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  // Handle page change in carousel
  void _onPageChanged(int index) async {
    if (_currentPageNotifier.value == index) return;

    // Hide mentions when changing pages
    if (_mentionsVisible) {
      _mentionsVisible = false;
    }

    // Pause current video if playing
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType) {
      await _videoPlayerController?.pause();
      _disposeCurrentVideoController();
    }

    _currentPageNotifier.value = index;

    _pageMentionMetaDataList = _mentionedMetaDataList
        .where((mention) => mention.mediaPosition?.position == _currentPageNotifier.value + 1)
        .toList();
    _isPlaying = true;
    _isPlayPauseActioned = false;

    // Reset completion flag when changing pages
    _hasCompletedOneCycle = false;
    // mountUpdate();

    // Initialize new video if needed
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType) {
      // Parent widget (PostItemWidget) handles caching

      await _initializeVideoPlayer();
      mountUpdate();
    }
  }

  /// Dispose the current video controller
  void _disposeCurrentVideoController() {
    if (_videoPlayerController != null &&
        _reelData.mediaMetaDataList.isNotEmpty &&
        _currentPageNotifier.value < _reelData.mediaMetaDataList.length &&
        !_videoCacheManager
            .isMediaCached(_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl)) {
      _videoPlayerController?.dispose();
    }
    _videoPlayerController = null;
  }

  /// Initializes the video player controller for the current video.
  /// - Uses the cached controller if available and initialized.
  /// - If pre-caching is in progress, waits for the same initialization future.
  /// - Only creates a new controller if not cached or initializing.
  Future<void> _initializeVideoPlayer() async {
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl.isStringEmptyOrNull !=
        false) {
      return;
    }

    final videoUrl = _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl;
    debugPrint('IsmReelsVideoPlayerView....initializeVideoPlayer video url $videoUrl');

    try {
      // First try to get cached controller
      _videoPlayerController =
          _videoCacheManager.getCachedMedia(videoUrl) as IVideoPlayerController?;

      if (_videoPlayerController != null) {
        debugPrint('IsmReelsVideoPlayerView....Using cached video controller for $videoUrl');
        if (_videoPlayerController!.isInitialized) {
          await _setupVideoController();
          return;
        } else {
          // If controller exists but not initialized, dispose and recreate
          await _videoPlayerController!.dispose();
          _videoPlayerController = null;
        }
      }

      // If not cached or needs reinitializing, check if initialization is in progress
      if (_videoCacheManager.isMediaInitializing(videoUrl)) {
        debugPrint('IsmReelsVideoPlayerView....Video is being initialized, waiting...');
        // Wait for initialization with timeout
        for (var i = 0; i < 5; i++) {
          // Try up to 5 times
          await Future.delayed(const Duration(milliseconds: 200));
          if (!mounted || _isDisposed) return;

          _videoPlayerController =
              _videoCacheManager.getCachedMedia(videoUrl) as IVideoPlayerController?;
          if (_videoPlayerController != null && _videoPlayerController!.isInitialized) {
            debugPrint('IsmReelsVideoPlayerView....Found initialized controller after waiting');
            await _setupVideoController();
            return;
          }
        }
      }

      // If still not available, initialize normally (fallback)
      await _initializeVideoControllerNormally(videoUrl);
    } catch (e) {
      debugPrint(
          'IsmReelsVideoPlayerView...catch video url ${_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl}');
      IsrVideoReelUtility.debugCatchLog(error: e);
    }
  }

  /// Fallback initialization method for video controller.
  /// Only used if not cached or pre-caching is not in progress.
  Future<void> _initializeVideoControllerNormally(String videoUrl) async {
    debugPrint('IsmReelsVideoPlayerView....Initializing video controller normally $videoUrl');
    var mediaUrl = videoUrl;
    if (mediaUrl.startsWith('http:')) {
      mediaUrl = mediaUrl.replaceFirst('http:', 'https:');
    }

    // Try to get from cache first
    _videoPlayerController = _videoCacheManager.getCachedMedia(mediaUrl) as IVideoPlayerController?;

    if (_videoPlayerController == null) {
      // If not in cache, trigger precaching which will create a new controller
      await MediaCacheFactory.precacheMedia([mediaUrl], highPriority: true);
      _videoPlayerController =
          _videoCacheManager.getCachedMedia(mediaUrl) as IVideoPlayerController?;

      if (_videoPlayerController == null) return;
    }

    await _setupVideoController();
  }

  /// Sets up the video controller for playback, looping, and volume.
  Future<void> _setupVideoController() async {
    debugPrint('_setupVideoController....setup video controller');
    if (_isDisposed) return;

    try {
      if (_videoPlayerController == null) {
        debugPrint('⚠️ VideoController is null in setup');
        return;
      }

      // Make sure controller is initialized
      if (!_videoPlayerController!.isInitialized) {
        debugPrint('🔄 Initializing video controller in setup');
        await _videoPlayerController!.initialize();
      }

      // Reset to beginning
      await _videoPlayerController!.seekTo(Duration.zero);

      // Set up basic properties
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);

      // Reset completion flag for new video
      _hasCompletedOneCycle = false;

      // Start playback
      if (!_videoPlayerController!.isPlaying) {
        debugPrint('▶️ Starting video playback in setup');
        await _videoPlayerController!.play();
      }

      _videoPlayerController!.addListener(_handlePlaybackProgress);
      debugPrint('✅ Video controller setup complete');
    } catch (e) {
      debugPrint('❌ Error in setupVideoController: $e');
    }
  }

  /// Disposes the current video controller if not cached, and cleans up state.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _tapGestureRecognizer?.dispose();
    _pageController?.dispose();
    _likeAnimationTimer?.cancel();
    _muteAnimationTimer?.cancel();
    // Mark video as not visible for cache manager
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl.isStringEmptyOrNull ==
        false) {
      _videoCacheManager
          .markAsNotVisible(_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl);
    }
    // Dispose controller if not cached
    if (_videoPlayerController != null &&
        _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl.isStringEmptyOrNull ==
            false &&
        !_videoCacheManager
            .isMediaCached(_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl)) {
      _videoPlayerController?.removeListener(_handlePlaybackProgress);
      _videoPlayerController?.pause();
      _videoPlayerController?.dispose();
    } else {
      _videoPlayerController?.pause();
    }

    _videoPlayerController = null;
    super.dispose();
  }

  Widget _getImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    FilterQuality filterQuality = FilterQuality.high,
  }) {
    final isLocalUrl =
        imageUrl.isStringEmptyOrNull == false && IsrVideoReelUtility.isLocalUrl(imageUrl);
    return isLocalUrl
        ? AppImage.file(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
          )
        : AppImage.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
          );
  }

  Widget _buildMediaContent() {
    Widget mediaWidget;

    if (_reelData.showBlur == true) {
      mediaWidget = _getImageWidget(
        imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].thumbnailUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.contain,
      );
    } else if (_hasMultipleMedia) {
      mediaWidget = _buildMediaCarousel();
    } else {
      mediaWidget = _buildSingleMediaContent();
    }

    // Wrap media content with mentions overlay
    return Stack(
      children: [
        mediaWidget,

        // Mentions overlay with center area for tap-through
        if (_mentionsVisible && _pageMentionMetaDataList.isListEmptyOrNull == false)
          _buildMentionsOverlayWithCenterArea(),
      ],
    );
  }

  Widget _buildMediaCarousel() => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _toggleMentions,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              key: const PageStorageKey('media_pageview'),
              // Add a key
              onPageChanged: _onPageChanged,
              itemCount: _reelData.mediaMetaDataList.length,
              itemBuilder: (context, index) => _buildPageView(index),
            ),
          ),
          Positioned(
            bottom: IsrDimens.eighty,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, value, child) => _buildMediaIndicators(value),
            ),
          ),

          // Media counter
          Positioned(
            top: IsrDimens.sixty,
            right: IsrDimens.sixteen,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, value, child) => _buildMediaCounter(value),
            ),
          ),
        ],
      );

  Widget _buildSingleMediaContent() {
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
      return _getImageWidget(
        imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.cover,
      );
    } else {
      return _buildVideoContent();
    }
  }

  Widget _buildVideoContent() => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (_controllerReady) ...[
            // Video is ready, show the player
            RepaintBoundary(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  child: Builder(
                    builder: (context) {
                      final controller = _videoPlayerController;
                      if (controller == null) {
                        return const SizedBox.shrink();
                      }
                      final size = controller.videoSize;
                      final aspect = controller.aspectRatio;
                      return SizedBox(
                        height: size.height,
                        width: size.width,
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: _buildVideoPlayerWidget(controller),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ] else ...[
            // Video is not ready, show a thumbnail
            _getImageWidget(
              imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].thumbnailUrl,
              width: IsrDimens.getScreenWidth(context),
              height: IsrDimens.getScreenHeight(context),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
            ),
          ]
        ],
      );

  Widget _buildCarousalVideoContent() => Container(
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        color: Colors.black, // Black background like Instagram
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_controllerReady) ...[
              Center(
                child: RepaintBoundary(
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.aspectRatio,
                    child: _buildVideoPlayerWidget(_videoPlayerController!),
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: _getImageWidget(
                  imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].thumbnailUrl,
                  width: IsrDimens.getScreenWidth(context),
                  height: IsrDimens.getScreenHeight(context),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                ),
              ),
            ]
          ],
        ),
      );

  // New methods for mentions functionality
  List<Widget> _buildMentionsOverlay() => _pageMentionMetaDataList
      .map<Widget>((mention) => Positioned(
            left: ((mention.mediaPosition?.x ?? 0) / 100 * IsrDimens.getScreenWidth(context)) - 60,
            top: ((mention.mediaPosition?.y ?? 0) / 100 * IsrDimens.getScreenHeight(context)) - 30,
            child: _buildMentionTag(mention),
          ))
      .toList();

  Widget _buildMentionsOverlayWithCenterArea() {
    final screenWidth = IsrDimens.getScreenWidth(context);
    final screenHeight = IsrDimens.getScreenHeight(context);

    // Define center area dimensions (adjust as needed)
    final centerAreaWidth = screenWidth * 0.6; // 60% of screen width
    final centerAreaHeight = screenHeight * 0.6; // 60% of screen height
    final centerAreaLeft = (screenWidth - centerAreaWidth) / 2;
    final centerAreaTop = (screenHeight - centerAreaHeight) / 2;

    return Stack(
      children: [
        // Top area - captures taps
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: centerAreaTop,
          child: GestureDetector(
            onTap: _toggleMentions,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Bottom area - captures taps
        Positioned(
          left: 0,
          top: centerAreaTop + centerAreaHeight,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _toggleMentions,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Left area - captures taps
        Positioned(
          left: 0,
          top: centerAreaTop,
          width: centerAreaLeft,
          height: centerAreaHeight,
          child: GestureDetector(
            onTap: _toggleMentions,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Right area - captures taps
        Positioned(
          left: centerAreaLeft + centerAreaWidth,
          top: centerAreaTop,
          right: 0,
          height: centerAreaHeight,
          child: GestureDetector(
            onTap: _toggleMentions,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Center area - allows tap-through to mention tags
        Positioned(
          left: centerAreaLeft,
          top: centerAreaTop,
          width: centerAreaWidth,
          height: centerAreaHeight,
          child: IgnorePointer(
            child: Container(color: Colors.transparent),
          ),
        ),

        // Mention tags overlay
        ..._buildMentionsOverlay(),
      ],
    );
  }

  Widget _buildMentionTag(MentionMetaData mention) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: GestureDetector(
          onTap: () => _showMentionDetails(mention),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.changeOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppImage.network(
                        height: 30.responsiveDimension,
                        width: 30.responsiveDimension,
                        mention.avatarUrl ?? '',
                        isProfileImage: true,
                        name: mention.username ?? '',
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '@${mention.username}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.changeOpacity(0.5),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pointer triangle
                CustomPaint(
                  painter: TrianglePainter(
                    color: Colors.white,
                  ),
                  size: const Size(12, 8),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildMentionsToggleButton() => GestureDetector(
        onTap: () {
          setState(() {
            _mentionsVisible = !_mentionsVisible;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                _mentionsVisible ? Colors.blue.changeOpacity(0.9) : Colors.black.changeOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.changeOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.changeOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _mentionsVisible ? Icons.person_pin : Icons.person_pin_circle_outlined,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${_pageMentionMetaDataList.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.changeOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  void _toggleMentions() {
    if (_pageMentionMetaDataList.isListEmptyOrNull == false) {
      if (_mentionsVisible) {
        _autoHideMentions();
      } else {
        _toggleMuteAndUnMute();
      }
    } else {
      _toggleMuteAndUnMute();
      // _togglePlayPause();
    }
  }

  void _autoHideMentions() {
    if (_mentionsVisible) {
      setState(() {
        _mentionsVisible = false;
      });
    } else {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _mentionsVisible) {
          setState(() {
            _mentionsVisible = false;
          });
        }
      });
    }
  }

  void _showMentionDetails(MentionMetaData mention) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // User avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.changeOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  mention.username![0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Username
            Text(
              '@${mention.username}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reelData.onTapMentionTag?.call(mention);
                      // Add your profile navigation logic here
                      // Navigator.pushNamed(context, '/profile', arguments: mention.userId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaIndicators(int currentPage) {
    if (!_hasMultipleMedia) return const SizedBox.shrink();

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _reelData.mediaMetaDataList.length,
          (index) => Container(
            margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.two),
            width: IsrDimens.six,
            height: IsrDimens.six,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == currentPage ? IsrColors.white : IsrColors.white.changeOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCounter(int currentPage) {
    if (!_hasMultipleMedia) return const SizedBox.shrink();

    return Container(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.eight,
        vertical: IsrDimens.four,
      ),
      decoration: BoxDecoration(
        color: Colors.black.changeOpacity(0.6),
        borderRadius: BorderRadius.circular(IsrDimens.twelve),
      ),
      child: Text(
        '${currentPage + 1}/${_reelData.mediaMetaDataList.length}',
        style: IsrStyles.white12.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _togglePlayPause() {
    if (_reelData.showBlur == true ||
        _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
      return;
    }
    if (!_controllerReady) return;
    if (_isPlaying) {
      _videoPlayerController?.pause();
    } else {
      _videoPlayerController?.play();
    }
    _isPlaying = !_isPlaying;
    _isPlayPauseActioned = !_isPlayPauseActioned;
    mountUpdate();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Only the main GestureDetector as child of the outer Stack
          GestureDetector(
            onTap: _toggleMuteAndUnMute,
            onDoubleTap: () async {
              _triggerLikeAnimation(); // Always show animation
              if (_reelData.isLiked != true && widget.onDoubleTap != null) {
                await widget.onDoubleTap!();
              }
            },
            onLongPress: _togglePlayPause,
            onLongPressEnd: (_) => _togglePlayPause(),
            child: VisibilityDetector(
              key: Key(_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl),
              onVisibilityChanged: (info) {
                if (_isDisposed) return;
                if (_reelData.showBlur == true ||
                    _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType ==
                        kPictureType) {
                  return;
                }

                if (info.visibleFraction > 0.7) {
                  // Mark video as visible in cache manager
                  _videoCacheManager.markAsVisible(
                      _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl);

                  if (_controllerReady && !_videoPlayerController!.isPlaying) {
                    _videoPlayerController?.seekTo(Duration.zero);
                    _videoPlayerController?.play();
                    _isPlaying = true;
                    mountUpdate();
                  }
                } else {
                  // Mark video as not visible in cache manager
                  _videoCacheManager.markAsNotVisible(
                      _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl);

                  if (_controllerReady && _videoPlayerController!.isPlaying) {
                    _videoPlayerController?.pause();
                    _isPlaying = false;
                    _isPlayPauseActioned = false;
                    mountUpdate();
                  }
                }
              },
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  _buildMediaContent(),
                  if (_showLikeAnimation)
                    Center(
                      child: Lottie.asset(
                        AssetConstants.heartAnimation,
                        width: 250,
                        height: 250,
                        repeat: false,
                      ),
                    ),
                  if (_showMuteAnimation &&
                      _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType ==
                          kVideoType)
                    Center(
                      child: AnimatedScale(
                        scale: _muteIconScale,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.changeOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(24),
                          child: AppImage.svg(
                            _isMuted
                                ? AssetConstants.muteRoundedSvg
                                : AssetConstants.unMuteRoundedSvg,
                            width: 70,
                            height: 70,
                          ),
                        ),
                      ),
                    ),
                  // Move overlays here so they don't block taps
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _reelData.footerWidget?.child ?? _buildBottomSection()),
                      _reelData.actionWidget?.child ?? _buildRightSideActions(),
                    ],
                  ),
                  // (If you have any other overlays, move them here as well)
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildRightSideActions() => Padding(
        padding: IsrDimens.edgeInsets(bottom: IsrDimens.forty, right: IsrDimens.sixteen),
        child: Column(
          spacing: IsrDimens.twenty,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_reelData.postSetting?.isProfilePicVisible == true)
              TapHandler(
                borderRadius: IsrDimens.thirty,
                onTap: () {
                  if (_reelData.onTapUserProfile != null) {
                    _reelData.onTapUserProfile!(true);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(IsrDimens.thirty),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.changeOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AppImage.network(
                    _reelData.profilePhoto ?? '',
                    width: IsrDimens.thirtyFive,
                    height: IsrDimens.thirtyFive,
                    isProfileImage: true,
                    name: '${_reelData.firstName ?? ''} ${_reelData.lastName ?? ''}',
                  ),
                ),
              ),
            if (_reelData.postSetting?.isCreatePostButtonVisible == true) ...[
              Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        if (widget.onCreatePost != null) {
                          await widget.onCreatePost!();
                        }
                      },
                      icon: const Icon(
                        Icons.add,
                        color: IsrColors.white,
                      ),
                    ),
                  ),
                  IsrDimens.boxHeight(IsrDimens.ten),
                  Text(
                    IsrTranslationFile.create,
                    style: IsrStyles.white12,
                  ),
                ],
              ),
            ],
            if (_reelData.postSetting?.isLikeButtonVisible == true)
              ValueListenableBuilder(
                  valueListenable: _isLikeLoading,
                  builder: (context, value, child) => _buildActionButton(
                        icon: _reelData.isLiked == true
                            ? AssetConstants.icLikeSelected
                            : AssetConstants.icLikeUnSelected,
                        label: _reelData.likesCount.toString(),
                        onTap: _callLikeFunction,
                        isLoading: value,
                      )),
            if (_reelData.postSetting?.isCommentButtonVisible == true)
              StatefulBuilder(
                builder: (context, setBuilderState) => _buildActionButton(
                  icon: AssetConstants.icCommentIcon,
                  label: _reelData.commentCount.toString(),
                  onTap: () {
                    _handleCommentClick(setBuilderState);
                  },
                ),
              ),
            if (_reelData.postSetting?.isShareButtonVisible == true)
              _buildActionButton(
                icon: AssetConstants.icShareIcon,
                label: IsrTranslationFile.share,
                onTap: () {
                  if (_reelData.onTapShare != null) {
                    _reelData.onTapShare!();
                  }
                },
              ),
            if (_reelData.postStatus != 0 &&
                _reelData.postSetting?.isSaveButtonVisible == true) ...[
              ValueListenableBuilder<bool>(
                valueListenable: _isSaveLoading,
                builder: (context, value, child) => _buildActionButton(
                  icon: _reelData.isSavedPost == true
                      ? AssetConstants.icSaveSelected
                      : AssetConstants.icSaveUnSelected,
                  label: _reelData.isSavedPost == true
                      ? IsrTranslationFile.saved
                      : IsrTranslationFile.save,
                  onTap: _callSaveFunction,
                  isLoading: value,
                ),
              ),
            ],
            if (_reelData.postSetting?.isMoreButtonVisible == true)
              _buildActionButton(
                icon: AssetConstants.icMoreIcon,
                label: '',
                onTap: () async {
                  if (widget.onPressMoreButton != null) {
                    widget.onPressMoreButton!();
                  }
                },
              ),
          ],
        ),
      );

  Widget _buildActionButton({
    required String icon,
    String? label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: isLoading
                ? SizedBox(
                    width: IsrDimens.twentyFour,
                    height: IsrDimens.twentyFour,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  )
                : AppImage.asset(icon),
          ),
          if (label.isStringEmptyOrNull == false) ...[
            IsrDimens.boxHeight(IsrDimens.four),
            Text(
              label ?? '',
              style: IsrStyles.white12.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );

  Widget _buildBottomSection() => Padding(
        padding: IsrDimens.edgeInsets(
            left: IsrDimens.sixteen, right: IsrDimens.sixteen, bottom: IsrDimens.fifteen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((_reelData.productCount ?? 0) > 0) ...[
              TapHandler(
                onTap: () {
                  if (_reelData.onTapCartIcon != null) {
                    _reelData.onTapCartIcon!();
                  }
                },
                child: Container(
                  padding: IsrDimens.edgeInsetsSymmetric(
                    horizontal: IsrDimens.twelve,
                    vertical: IsrDimens.eight,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(IsrDimens.ten),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.changeOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppImage.svg(AssetConstants.icCartIcon),
                      IsrDimens.boxWidth(IsrDimens.eight),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            IsrTranslationFile.shop,
                            style: IsrStyles.primaryText12.copyWith(
                                color: IsrColors.color0F1E91, fontWeight: FontWeight.w700),
                          ),
                          IsrDimens.boxHeight(IsrDimens.four),
                          Text(
                            '${_reelData.productCount} ${_reelData.productCount == 1 ? IsrTranslationFile.product : IsrTranslationFile.products}',
                            style: IsrStyles.primaryText10.copyWith(
                                color: IsrColors.color0F1E91, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IsrDimens.boxHeight(IsrDimens.sixteen),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mentions toggle button (top-right)
                      if (_pageMentionMetaDataList.isListEmptyOrNull == false) ...[
                        _buildMentionsToggleButton(),
                        IsrDimens.boxHeight(IsrDimens.fifteen),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: TapHandler(
                                    onTap: () {
                                      if (_reelData.onTapUserProfile != null) {
                                        _reelData.onTapUserProfile!(false);
                                      }
                                    },
                                    child: Text(
                                      _reelData.userName ?? '',
                                      style: IsrStyles.white14.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                IsrDimens.boxWidth(IsrDimens.eight),
                                _buildFollowButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_postDescription.isStringEmptyOrNull == false) ...[
                        IsrDimens.boxHeight(IsrDimens.eight),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isExpandedDescription,
                          builder: (context, value, child) {
                            final fullDescription = _reelData.description ?? '';
                            final shouldTruncate = fullDescription.length > _maxLengthToShow;

                            // Show truncated version when collapsed, full version when expanded
                            final displayText = shouldTruncate && !value
                                ? fullDescription.substring(0, _maxLengthToShow)
                                : fullDescription;

                            return RichText(
                              text: TextSpan(
                                children: [
                                  _buildDescriptionTextSpan(
                                    displayText.trim(),
                                    _mentionedDataList,
                                    _taggedDataList,
                                    IsrStyles.white14
                                        .copyWith(color: IsrColors.white.changeOpacity(0.9)),
                                    (mention) {
                                      if (_reelData.onTapMentionTag != null) {
                                        _reelData.onTapMentionTag?.call(mention);
                                      }
                                    },
                                  ),
                                  if (shouldTruncate)
                                    TextSpan(
                                      text: value
                                          ? ' ${IsrTranslationFile.viewLess}'
                                          : '... ${IsrTranslationFile.viewMore}',
                                      style:
                                          IsrStyles.white14.copyWith(fontWeight: FontWeight.w700),
                                      recognizer: _tapGestureRecognizer
                                        ?..onTap = () {
                                          _isExpandedDescription.value =
                                              !_isExpandedDescription.value;
                                        },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      if (_reelData.placeDataList?.isListEmptyOrNull == false) ...[
                        IsrDimens.boxHeight(IsrDimens.eight),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: IsrDimens.fifteen),
                            IsrDimens.boxWidth(IsrDimens.five),
                            Expanded(
                              child: Row(
                                children: List.generate(
                                  _reelData.placeDataList?.length ?? 0,
                                  (index) => Text(
                                    _reelData.placeDataList?.first.placeName ?? '',
                                    style: IsrStyles.white14.copyWith(fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if ((_reelData.productCount ?? 0) > 0) ...[
              IsrDimens.boxHeight(IsrDimens.eight),
              _buildCommissionTag(),
            ],
          ],
        ),
      );

  Widget _buildCommissionTag() => Container(
        padding:
            IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.six, vertical: IsrDimens.three),
        decoration: BoxDecoration(
          color: Colors.black.changeOpacity(0.5),
          borderRadius: IsrDimens.borderRadiusAll(5),
        ),
        child: Text(
          IsrTranslationFile.creatorEarnsCommission,
          style: IsrStyles.white10.copyWith(
            color: IsrColors.colorF4F4F4,
          ),
        ),
      );

  Widget _buildFollowButton() {
    // Hide if it's self profile
    if (_reelData.isSelfProfile == true) return const SizedBox.shrink();

    // FOLLOW button
    if (_reelData.postSetting?.isFollowButtonVisible == true && _reelData.isFollow == false) {
      return ValueListenableBuilder<bool>(
        valueListenable: _isFollowLoading,
        builder: (context, isLoading, child) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  width: IsrDimens.sixty,
                  height: IsrDimens.twentyFour,
                  child: Center(
                    child: SizedBox(
                      width: IsrDimens.sixteen,
                      height: IsrDimens.sixteen,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Container(
                  height: IsrDimens.twentyFour,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(IsrDimens.twenty),
                  ),
                  child: MaterialButton(
                    minWidth: IsrDimens.sixty,
                    height: IsrDimens.twentyFour,
                    padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(IsrDimens.twenty)),
                    onPressed: _callFollowFunction,
                    child: Text(
                      IsrTranslationFile.follow,
                      style: IsrStyles.white12.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ),
      );
    }

    // FOLLOWING button (Unfollow option visible)
    if (_reelData.isFollow == true && _reelData.postSetting?.isUnFollowButtonVisible == true) {
      return Container(
        height: IsrDimens.twentyFour,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(IsrDimens.twenty),
        ),
        child: MaterialButton(
          minWidth: IsrDimens.sixty,
          height: IsrDimens.twentyFour,
          padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IsrDimens.twenty),
          ),
          onPressed: _callFollowFunction,
          // <-- your unfollow logic
          child: Text(
            IsrTranslationFile.following,
            style: IsrStyles.primaryText12.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Otherwise, show nothing
    return const SizedBox.shrink();
  }

  //calls api to follow and unfollow user
  Future<void> _callFollowFunction() async {
    if (widget.onPressFollowButton == null) return;
    _isFollowLoading.value = true;

    try {
      await widget.onPressFollowButton!();
    } finally {
      _isFollowLoading.value = false;
    }
  }

  Future<void> _callSaveFunction() async {
    if (widget.onPressSaveButton == null || _isSaveLoading.value) return;
    _isSaveLoading.value = true;

    try {
      await widget.onPressSaveButton!();
    } finally {
      _isSaveLoading.value = false;
    }
  }

  Future<void> _callLikeFunction() async {
    if (widget.onPressLikeButton == null || _isLikeLoading.value) return;
    _isLikeLoading.value = true;
    try {
      final wasLiked = _reelData.isLiked == true;
      await widget.onPressLikeButton!();
      // Only show animation if it was not liked before and is now liked
      if (!wasLiked && _reelData.isLiked == true) {
        _triggerLikeAnimation();
      }
      // If already liked, just do dislike (no animation)
    } finally {
      _isLikeLoading.value = false;
    }
  }

  void _triggerLikeAnimation() {
    _likeAnimationTimer?.cancel();
    setState(() {
      _showLikeAnimation = true;
    });
    _likeAnimationTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
  }

  void _triggerMuteAnimation() {
    _muteAnimationTimer?.cancel();
    setState(() {
      _showMuteAnimation = true;
      _muteIconScale = 1.3;
    });
    // Animate scale down after a short delay
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted && _showMuteAnimation) {
        setState(() {
          _muteIconScale = 1.0;
        });
      }
    });
    _muteAnimationTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showMuteAnimation = false;
        });
      }
    });
  }

  TextSpan _buildDescriptionTextSpan(
    String description,
    List<MentionMetaData> mentions,
    List<MentionMetaData> hashtags,
    TextStyle defaultStyle,
    void Function(MentionMetaData) onMentionTap,
  ) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(@[a-zA-Z0-9_]+)|(#[a-zA-Z0-9_]+)');
    final matches = pattern.allMatches(description).toList();

    var lastIndex = 0;

    // Process each match
    for (final match in matches) {
      final start = match.start;
      final end = match.end;
      final matchedText = match.group(0)!;

      // Add text before the match
      if (lastIndex < start) {
        final textBefore = description.substring(lastIndex, start);
        if (textBefore.isNotEmpty) {
          spans.add(TextSpan(
            text: textBefore,
            style: defaultStyle,
          ));
        }
      }

      // Process mentions (@username)
      if (matchedText.startsWith('@')) {
        final username = matchedText.substring(1); // Remove @ symbol
        final mention = mentions.firstWhere(
          (m) => m.username == username,
          orElse: MentionMetaData.new,
        );

        spans.add(TextSpan(
          text: matchedText,
          style: defaultStyle.copyWith(
            fontWeight: mention.username != null ? FontWeight.w800 : FontWeight.w400,
            color: mention.username != null ? Colors.white : Colors.white.changeOpacity(0.9),
          ),
          recognizer: mention.username != null
              ? (TapGestureRecognizer()..onTap = () => onMentionTap(mention))
              : null,
        ));
      }
      // Process hashtags (#tag)
      else if (matchedText.startsWith('#')) {
        final tag = matchedText.substring(1); // Remove # symbol
        final hashtag = hashtags.firstWhere(
          (h) => h.tag == tag,
          orElse: MentionMetaData.new,
        );

        spans.add(TextSpan(
          text: matchedText,
          style: defaultStyle.copyWith(
            fontWeight: hashtag.tag != null ? FontWeight.w800 : FontWeight.w400,
            color: hashtag.tag != null ? Colors.white : Colors.white.changeOpacity(0.9),
          ),
          recognizer: hashtag.tag != null
              ? (TapGestureRecognizer()..onTap = () => onMentionTap(hashtag))
              : null,
        ));
      }

      lastIndex = end;
    }

    // Add remaining text after the last match
    if (lastIndex < description.length) {
      final remainingText = description.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: defaultStyle,
        ));
      }
    }

    return TextSpan(children: spans);
  }

  void _handleCommentClick(StateSetter setBuilderState) async {
    if (_reelData.onTapComment != null) {
      final commentCount = await _reelData.onTapComment!(_reelData.commentCount ?? 0);
      if (commentCount != null) {
        _reelData.commentCount = commentCount;
      }
      setBuilderState.call(() {});
    }
  }

  Widget _buildPageView(int index) {
    final media = _reelData.mediaMetaDataList[index];
    debugPrint('index $index');
    debugPrint('mediaUrl ${media.mediaUrl}');
    if (media.mediaType == kPictureType) {
      return SizedBox(
        key: ValueKey('media_$index'), // Consistent key
        child: _getImageWidget(
          imageUrl: media.mediaUrl,
          width: IsrDimens.getScreenWidth(context),
          height: IsrDimens.getScreenHeight(context),
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Video content - only show video player for current index
      if (index == _currentPageNotifier.value) {
        return SizedBox(
          key: ValueKey('media_$index'), // Consistent key

          child: _buildCarousalVideoContent(),
        );
      } else {
        return SizedBox(
          key: ValueKey('media_$index'), // Consistent key

          child: _getImageWidget(
            imageUrl: media.thumbnailUrl,
            width: IsrDimens.getScreenWidth(context),
            height: IsrDimens.getScreenHeight(context),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          ),
        );
      }
    }
  }

  /// Handles mute/unmute toggle for videos only, with animation.
  void _toggleMuteAndUnMute() {
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType != kVideoType) {
      // Only allow mute/unmute for videos
      return;
    }
    setState(() {
      _isMuted = !_isMuted;
      _videoPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _triggerMuteAnimation();
  }

  /// Helper method to build the video player widget
  Widget _buildVideoPlayerWidget(IVideoPlayerController controller) => Container(
        color: Colors.black,
        child: Center(
          child: controller.buildVideoPlayerWidget(),
        ),
      );

  void _handlePlaybackProgress() {
    if (!mounted || _videoPlayerController == null || !_videoPlayerController!.isInitialized) {
      return;
    }

    final position = _videoPlayerController!.position;
    final duration = _videoPlayerController!.duration;
    final total = duration.inSeconds;
    final progress = position.inSeconds;
    final percent = (progress / total * 100).floor();

    // // Debug logging for video progress
    // if (progress % 5 == 0) {
    //   // Log every 5 seconds
    //   debugPrint(
    //       '🎬 Video progress: ${position.inSeconds}s / ${duration.inSeconds}s ($percent%)');
    // }

    // fire at specific milestones
    if (progress >= 3 && !_loggedMilestones.contains('3s')) {
      _loggedMilestones.add('3s');
      _logWatchEvent('progress', position: position, note: '3s');
    }

    if (progress >= 10 && !_loggedMilestones.contains('10s')) {
      _loggedMilestones.add('10s');
      _logWatchEvent('progress', position: position, note: '10s');
    }

    if (percent >= 25 && !_loggedMilestones.contains('25%')) {
      _loggedMilestones.add('25%');
      _logWatchEvent('progress', position: position, note: '25%');
    }
    if (percent >= 50 && !_loggedMilestones.contains('50%')) {
      _loggedMilestones.add('50%');
      _logWatchEvent('progress', position: position, note: '50%');
    }
    if (percent >= 75 && !_loggedMilestones.contains('75%')) {
      _loggedMilestones.add('75%');
      _logWatchEvent('progress', position: position, note: '75%');
    }

    // Check if video is near the end (within 1 second) or has reached the end
    final timeRemaining = duration - position;
    final isNearEnd = timeRemaining.inMilliseconds <= 1000; // Within 1 second
    final hasReachedEnd = position >= duration;

    // For looping videos, we need to detect when they complete one full cycle
    if ((isNearEnd || hasReachedEnd) && !_hasCompletedOneCycle) {
      _hasCompletedOneCycle = true;
      _loggedMilestones.add('complete');
      _logWatchEvent('complete', position: position);
      debugPrint(
          '🎬 Video completed one cycle! Position: ${position.inSeconds}s, Duration: ${duration.inSeconds}s, Time remaining: ${timeRemaining.inMilliseconds}ms');

      // Handle video completion - check if we should move to next video or next post
      _handleVideoCompletion();
    }
  }

  /// Handles video completion logic - either move to next video in carousel or next post
  void _handleVideoCompletion() {
    debugPrint('🎬 _handleVideoCompletion called - disposed: $_isDisposed, mounted: $mounted');

    if (_isDisposed || !mounted) {
      debugPrint('🎬 _handleVideoCompletion: Early return due to disposed or not mounted');
      return;
    }

    debugPrint(
        '🎬 _handleVideoCompletion: Has multiple media: $_hasMultipleMedia, current page: ${_currentPageNotifier.value}, total media: ${_reelData.mediaMetaDataList.length}');

    // Check if we have multiple media items (carousel)
    if (_hasMultipleMedia) {
      // If there's a next media item in the carousel, move to it
      if (_currentPageNotifier.value < _reelData.mediaMetaDataList.length - 1) {
        final nextIndex = _currentPageNotifier.value + 1;
        debugPrint('🎬 Video completed, moving to next media in carousel: $nextIndex');
        _pageController?.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      } else {
        debugPrint('🎬 Video completed, no more media in carousel');
      }
    }

    // If no next media in carousel or single video, notify parent to move to next post
    debugPrint(
        '🎬 Video completed, notifying parent to move to next post. Callback available: ${widget.onVideoCompleted != null}');
    widget.onVideoCompleted?.call();
  }

  void _logWatchEvent(String type, {required Duration position, String? note}) {
    EventQueueProvider.instance.addEvent({
      'type': EventType.watch.value,
      'postId': widget.reelsData?.postId,
      'userId': widget.loggedInUserId,
      'status': type, // start, progress, complete
      'position': position.inSeconds,
      'note': note, // optional (3s, 10s, 25%, etc.)
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

class TrianglePainter extends CustomPainter {
  TrianglePainter({this.color = Colors.white});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Add shadow
    canvas.drawShadow(
      path,
      Colors.black.changeOpacity(0.2),
      2.0,
      false,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
