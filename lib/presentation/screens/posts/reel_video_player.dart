import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:video_player/video_player.dart';

// 1. Video Precache Manager - Handles all video caching logic
class VideoPrecacheManager {
  static final Map<String, VideoPlayerController> _controllers = {};
  static final Map<String, bool> _isInitialized = {};
  static final Map<String, bool> _isLoading = {};

  /// Precache a video and return the controller
  static Future<VideoPlayerController?> precacheVideo(String videoUrl) async {
    // Return existing controller if already cached
    if (_controllers.containsKey(videoUrl) && _isInitialized[videoUrl] == true) {
      return _controllers[videoUrl];
    }

    // Prevent multiple simultaneous loads of the same video
    if (_isLoading[videoUrl] == true) {
      // Wait for existing load to complete
      while (_isLoading[videoUrl] == true) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _controllers[videoUrl];
    }

    try {
      _isLoading[videoUrl] = true;

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true, // Allow multiple videos
          allowBackgroundPlayback: false,
        ),
      );

      await controller.initialize();

      _controllers[videoUrl] = controller;
      _isInitialized[videoUrl] = true;
      _isLoading[videoUrl] = false;

      debugPrint('Video precached: $videoUrl');
      return controller;
    } catch (e) {
      debugPrint('Failed to precache video $videoUrl: $e');
      _isInitialized[videoUrl] = false;
      _isLoading[videoUrl] = false;
      return null;
    }
  }

  /// Get cached controller for a video URL
  static VideoPlayerController? getController(String videoUrl) {
    if (_isInitialized[videoUrl] == true) {
      return _controllers[videoUrl];
    }
    return null;
  }

  /// Check if video is already cached
  static bool isVideoCached(String videoUrl) => _isInitialized[videoUrl] == true;

  /// Dispose a specific video controller
  static void disposeController(String videoUrl) {
    final controller = _controllers[videoUrl];
    if (controller != null) {
      controller.dispose();
      _controllers.remove(videoUrl);
      _isInitialized.remove(videoUrl);
      _isLoading.remove(videoUrl);
      debugPrint('Disposed video: $videoUrl');
    }
  }

  /// Dispose all cached videos
  static void disposeAll() {
    _controllers.values.forEach((controller) => controller.dispose());
    _controllers.clear();
    _isInitialized.clear();
    _isLoading.clear();
    debugPrint('Disposed all cached videos');
  }

  /// Get count of cached videos
  static int getCachedVideoCount() => _controllers.length;

  /// Pause all videos (useful when app goes to background)
  static void pauseAllVideos() {
    _controllers.values.forEach((controller) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    });
  }

  /// Resume a specific video
  static void resumeVideo(String videoUrl) {
    final controller = getController(videoUrl);
    if (controller != null && !controller.value.isPlaying) {
      controller.play();
    }
  }

  /// Get cache status for debugging
  static Map<String, dynamic> getCacheStatus() => {
        'cached_count': getCachedVideoCount(),
        'cached_urls': _controllers.keys.toList(),
        'initialized_videos':
            _isInitialized.entries.where((e) => e.value).map((e) => e.key).toList(),
        'loading_videos': _isLoading.entries.where((e) => e.value).map((e) => e.key).toList(),
      };
}

// 2. Reel Video Precaching Strategy
class ReelVideoPrecacher {
  static const int PRECACHE_AHEAD = 2;
  static const int PRECACHE_BEHIND = 1;
  static const int MAX_CACHED_VIDEOS = 5;
  static const int CLEANUP_THRESHOLD = 3;

  /// Precache videos around current index
  static Future<void> precacheNearbyVideos(
    int currentIndex,
    List<String> videoUrls,
  ) async {
    final List<Future> precacheFutures = [];

    // Precache videos around current index
    for (int i = currentIndex - PRECACHE_BEHIND; i <= currentIndex + PRECACHE_AHEAD; i++) {
      if (i >= 0 && i < videoUrls.length) {
        if (!VideoPrecacheManager.isVideoCached(videoUrls[i])) {
          precacheFutures.add(VideoPrecacheManager.precacheVideo(videoUrls[i]));
        }
      }
    }

    // Execute precaching
    if (precacheFutures.isNotEmpty) {
      try {
        await Future.wait(precacheFutures);
      } catch (e) {
        debugPrint('Error in precaching videos: $e');
      }
    }

    // Clean up distant videos to manage memory
    _cleanupDistantVideos(currentIndex, videoUrls);
  }

  /// Clean up videos that are far from current index
  static void _cleanupDistantVideos(int currentIndex, List<String> videoUrls) {
    for (int i = 0; i < videoUrls.length; i++) {
      final bool isDistant =
          (i < currentIndex - CLEANUP_THRESHOLD) || (i > currentIndex + CLEANUP_THRESHOLD);

      if (isDistant && VideoPrecacheManager.isVideoCached(videoUrls[i])) {
        VideoPrecacheManager.disposeController(videoUrls[i]);
      }
    }

    // Additional cleanup if we have too many cached videos
    if (VideoPrecacheManager.getCachedVideoCount() > MAX_CACHED_VIDEOS) {
      _forceCleanupOldestVideos(currentIndex, videoUrls);
    }
  }

  /// Force cleanup of videos that are not immediately relevant
  static void _forceCleanupOldestVideos(int currentIndex, List<String> videoUrls) {
    // Keep only the most relevant videos
    for (int i = 0; i < videoUrls.length; i++) {
      if (i < currentIndex - 2 || i > currentIndex + 2) {
        VideoPrecacheManager.disposeController(videoUrls[i]);
      }
    }
  }

  /// Preload a specific range of videos
  static Future<void> precacheVideoRange(
    List<String> videoUrls,
    int startIndex,
    int endIndex,
  ) async {
    final List<Future> futures = [];

    for (int i = startIndex; i <= endIndex && i < videoUrls.length; i++) {
      if (i >= 0 && !VideoPrecacheManager.isVideoCached(videoUrls[i])) {
        futures.add(VideoPrecacheManager.precacheVideo(videoUrls[i]));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Get precaching statistics
  static Map<String, dynamic> getPrecacheStats() => {
        'precache_ahead': PRECACHE_AHEAD,
        'precache_behind': PRECACHE_BEHIND,
        'max_cached_videos': MAX_CACHED_VIDEOS,
        'cleanup_threshold': CLEANUP_THRESHOLD,
        'current_cached_count': VideoPrecacheManager.getCachedVideoCount(),
      };
}

// 3. Reel Video Player Widget
class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final VoidCallback? onVideoReady;
  final VoidCallback? onVideoError;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const ReelVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.isActive,
    this.onVideoReady,
    this.onVideoError,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  Future<void> _setupVideo() async {
    try {
      // Try to get precached controller first
      _controller = VideoPrecacheManager.getController(widget.videoUrl);

      if (_controller != null) {
        // Video was precached
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
            _hasError = false;
          });
          _handleVideoPlayback();
          widget.onVideoReady?.call();
        }
      } else {
        // Video not precached, initialize now
        _controller = await VideoPrecacheManager.precacheVideo(widget.videoUrl);

        if (_controller != null && mounted) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
            _hasError = false;
          });
          _handleVideoPlayback();
          widget.onVideoReady?.call();
        } else {
          // Failed to initialize
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
            widget.onVideoError?.call();
          }
        }
      }
    } catch (e) {
      debugPrint('Error setting up video: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        widget.onVideoError?.call();
      }
    }
  }

  void _handleVideoPlayback() {
    if (_controller == null || !_isInitialized) return;

    if (widget.isActive) {
      _controller!.play();
      _controller!.setLooping(true);
    } else {
      _controller!.pause();
    }
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      _handleVideoPlayback();
    }
  }

  Widget _buildLoadingWidget() =>
      widget.loadingWidget ??
      Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );

  Widget _buildErrorWidget() =>
      widget.errorWidget ??
      Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError || !_isInitialized || _controller == null) {
      return _buildErrorWidget();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        if (_controller!.value.isBuffering)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    // Don't dispose controller here - let VideoPrecacheManager handle it
    super.dispose();
  }
}

// 4. Main Reel PageView Widget
class ReelPageView extends StatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;
  final Function(int)? onPageChanged;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const ReelPageView({
    Key? key,
    required this.videoUrls,
    this.initialIndex = 0,
    this.onPageChanged,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<ReelPageView> createState() => _ReelPageViewState();
}

class _ReelPageViewState extends State<ReelPageView> with WidgetsBindingObserver {
  late int _currentIndex;
  late PageController _pageController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addObserver(this);

    // Initial precaching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheVideos();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        VideoPrecacheManager.pauseAllVideos();
        break;
      case AppLifecycleState.resumed:
        if (_currentIndex < widget.videoUrls.length) {
          VideoPrecacheManager.resumeVideo(widget.videoUrls[_currentIndex]);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _precacheVideos() async {
    if (_isDisposed) return;

    try {
      await ReelVideoPrecacher.precacheNearbyVideos(_currentIndex, widget.videoUrls);
    } catch (e) {
      debugPrint('Error precaching videos: $e');
    }
  }

  void _onPageChanged(int index) {
    if (_isDisposed) return;

    setState(() {
      _currentIndex = index;
    });

    widget.onPageChanged?.call(index);

    // Precache videos around new current index
    _precacheVideos();
  }

  /// Jump to a specific video index
  void jumpToIndex(int index) {
    if (index >= 0 && index < widget.videoUrls.length && !_isDisposed) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Get current video index
  int getCurrentIndex() => _currentIndex;

  /// Get current video URL
  String getCurrentVideoUrl() {
    if (_currentIndex < widget.videoUrls.length) {
      return widget.videoUrls[_currentIndex];
    }
    return '';
  }

  /// Force refresh current video
  void refreshCurrentVideo() {
    if (_currentIndex < widget.videoUrls.length) {
      final currentUrl = widget.videoUrls[_currentIndex];
      VideoPrecacheManager.disposeController(currentUrl);
      _precacheVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrls.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'No videos available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: widget.videoUrls.length,
      itemBuilder: (context, index) => ReelVideoPlayer(
        videoUrl: widget.videoUrls[index],
        isActive: index == _currentIndex,
        loadingWidget: widget.loadingWidget,
        errorWidget: widget.errorWidget,
        onVideoReady: () {
          debugPrint('Video ready at index: $index');
        },
        onVideoError: () {
          debugPrint('Video error at index: $index');
        },
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();

    // Optional: Clean up all cached videos when leaving the reel screen
    // VideoPrecacheManager.disposeAll();

    super.dispose();
  }
}

// 5. State-Based Reel Screen Implementation
class ReelScreen extends StatefulWidget {
  const ReelScreen({Key? key}) : super(key: key);

  @override
  State<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> {
  final GlobalKey<_ReelPageViewState> _reelKey = GlobalKey<_ReelPageViewState>();

  // Your existing state variables
  List<dynamic> _postList = []; // Replace with your actual post type
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize your bloc/cubit here
    // context.read<PostBloc>().add(LoadPostsEvent());
  }

  // Extract video URLs from your post list
  List<String> _getVideoUrls() => _postList
      .where((post) => post.mediaType == 'video') // Adjust based on your model
      .map<String>((post) => '') // Adjust based on your model
      .where((url) => url.isNotEmpty)
      .toList();

  // Precache videos when posts are loaded
  void _precacheVideos(List<dynamic> postList) {
    final videoUrls = postList
        .where((post) => post.mediaType == 'video') // Adjust based on your model
        .map<String>((post) => '') // Adjust based on your model
        .where((url) => url.isNotEmpty)
        .toList();

    if (videoUrls.isNotEmpty) {
      // Start precaching from index 0
      ReelVideoPrecacher.precacheNearbyVideos(0, videoUrls);
    }
  }

  // Your existing image precaching method (keep as is)
  void _precacheImages(List<dynamic> postList) {
    // Your existing image precaching logic
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<PostBloc, PostState>(
          // Replace with your actual Bloc
          listener: (context, state) {
            if (state is PostsLoadedState) {
              if (_postList.isEmpty) {
                final postList = state.timeLinePostList ?? [];
                _precacheImages(postList); // Your existing method
                _precacheVideos(postList); // New video precaching
                setState(() {
                  _postList = postList;
                  _isLoading = false;
                });
              }
            }
          },
          builder: (context, state) {
            if (_isLoading || _postList.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }

            final videoUrls = _getVideoUrls();

            if (videoUrls.isEmpty) {
              return const Center(
                child: Text(
                  'No videos available',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return Stack(
              children: [
                ReelPageView(
                  key: _reelKey,
                  videoUrls: videoUrls,
                  initialIndex: 0,
                  onPageChanged: _onPageChanged,
                  loadingWidget: Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),

                // Video counter overlay
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${videoUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Debug info (remove in production)
                if (kDebugMode)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cached: ${VideoPrecacheManager.getCachedVideoCount()}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  @override
  void dispose() {
    // Clean up when leaving screen
    VideoPrecacheManager.disposeAll();
    super.dispose();
  }
}

// 6. Helper class for Post-based Video Management
class PostVideoManager {
  /// Extract video URLs from post list
  static List<String> extractVideoUrls(List<PostDataModel> postList) => postList
      .where(_isVideoPost)
      .map<String>(_getVideoUrl)
      .where((url) => url.isNotEmpty)
      .toList();

  /// Check if post contains video
  static bool _isVideoPost(PostDataModel post) =>
      post.mediaType1 == 2 || post.imageUrl1?.isStringEmptyOrNull == false;

  /// Get video URL from post
  static String _getVideoUrl(PostDataModel post) {
    // Adjust this based on your post model
    return post.imageUrl1 ?? post.imageUrl1 ?? '';
  }

  /// Precache videos from post list
  static Future<void> precacheVideosFromPosts(
    List<PostDataModel> postList, {
    int startIndex = 0,
  }) async {
    final videoUrls = extractVideoUrls(postList);
    if (videoUrls.isNotEmpty) {
      await ReelVideoPrecacher.precacheNearbyVideos(startIndex, videoUrls);
    }
  }

  /// Get video post at specific index
  static dynamic getVideoPostAt(List<PostDataModel> postList, int index) {
    final videoPosts = postList.where(_isVideoPost).toList();
    if (index >= 0 && index < videoPosts.length) {
      return videoPosts[index];
    }
    return null;
  }

  /// Get index of video post in original post list
  static int getOriginalPostIndex(List<dynamic> postList, dynamic videoPost) =>
      postList.indexOf(videoPost);
}
