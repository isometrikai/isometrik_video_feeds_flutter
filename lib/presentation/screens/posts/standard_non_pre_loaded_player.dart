import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:video_player/video_player.dart';

class StandardVideoNonPreloadedController implements IVideoPlayerController {
  StandardVideoNonPreloadedController(this._controller) {
    _setupListeners();
  }

  final VideoPlayerController _controller;
  final ValueNotifier<bool> _playingStateNotifier = ValueNotifier(false);

  bool _isDisposed = false;
  bool _hasLoggedError = false;

  void _setupListeners() {
    _controller.addListener(() {
      if (_isDisposed) return;

      _playingStateNotifier.value = _controller.value.isPlaying;

      if (_controller.value.hasError && !_hasLoggedError) {
        _hasLoggedError = true;
        debugPrint('❌ Video error: ${_controller.value.errorDescription}');
      }
    });
  }

  // --- IVideoPlayerController impl ---

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Future<void> setLooping(bool looping) => _controller.setLooping(looping);

  @override
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  bool get isBuffering => _controller.value.isBuffering;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  bool get isDisposed => _isDisposed;

  @override
  Duration get duration => _controller.value.duration;

  @override
  Duration get position => _controller.value.position;

  @override
  Size get videoSize => _controller.value.size;

  @override
  double get aspectRatio => _controller.value.aspectRatio;

  @override
  ValueNotifier<bool> get playingStateNotifier => _playingStateNotifier;

  @override
  Widget buildVideoPlayerWidget() => VideoPlayer(_controller);

  @override
  Future<void> forceResume() async {
    if (_isDisposed) return;
    if (!_controller.value.isPlaying) {
      await _controller.play();
    }
  }

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _playingStateNotifier.dispose();
    await _controller.dispose();
  }
}

class StandardVideoNonPreloadedManager implements IVideoCacheManager {
  // ✅ Public factory
  factory StandardVideoNonPreloadedManager() => _instance;

  // 🔒 Private constructor
  StandardVideoNonPreloadedManager._internal();

  // ✅ Single instance
  static final StandardVideoNonPreloadedManager _instance =
      StandardVideoNonPreloadedManager._internal();

  @override
  Future<void> precacheVideos(
    List<String> videoUrls, {
    bool highPriority = false,
  }) async {
    // ❌ No-op (explicitly no preloading)
    for (final url in videoUrls) {
      if (url.endsWith('.m3u8')) {
        // if the URL is an HLS stream, precache the first segment
        unawaited(VideoMediaUtil.precacheFirstSegment(url));
      }
    }
  }

  // ❌ No cache → always return null
  @override
  IVideoPlayerController? getCachedController(String url) => null;

  @override
  Future<IVideoPlayerController?> precacheMediaAndReturnController(
          String url) => // for smooth transition
      Future<IVideoPlayerController?>.delayed(const Duration(milliseconds: 300),
          () => _createAndInitializeController(url));

  Future<StandardVideoNonPreloadedController?> _createAndInitializeController(String url) async {
    debugPrint(
        'StandardVideoCacheManager: _createAndInitializeController: $url');
    try {
      final controller = _createVideoPlayerController(url);

      // OPTIMIZATION: Add timeout to prevent hanging on slow networks
      // Increased timeout to 15 seconds for slow network connections
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
              '⚠️ StandardNonCacheVideoPlayer initialization timeout for: $url');
          throw TimeoutException(
              'Video initialization timeout', const Duration(seconds: 15));
        },
      );

      // Validate video initialization - check for decoding errors
      if (!controller.value.isInitialized) {
        debugPrint(
            '❌ StandardNonCacheVideoPlayer not initialized properly for: $url');
        await controller.dispose();
        return null;
      }

      if (controller.value.hasError) {
        debugPrint(
            '❌ StandardNonCacheVideoPlayer has error after initialization: ${controller.value.errorDescription}');
        debugPrint('❌ URL: $url');
        await controller.dispose();
        return null;
      }

      // Check for valid video dimensions (Size.zero indicates decoding failure)
      if (controller.value.size == Size.zero) {
        debugPrint(
            '❌ StandardNonCacheVideoPlayer has invalid size (0x0) - possible decoding failure for: $url');
        await controller.dispose();
        return null;
      }

      debugPrint(
          '✅ Video initialized successfully - Size: ${controller.value.size}, Duration: ${controller.value.duration}, URL: $url');

      // Set properties in parallel for faster setup
      await Future.wait([
        controller.setLooping(false),
        controller.setVolume(1.0),
      ]);

      return StandardVideoNonPreloadedController(controller);
    } catch (e, stackTrace) {
      debugPrintStack(
          label: 'StandardVideoCacheManager cached error $e',
          stackTrace: stackTrace);
      debugPrint('❌ Error creating video controller for URL: $url - Error: $e');
      // Let native side breathe
      await Future.delayed(const Duration(milliseconds: 300));
      return null;
    }
  }

  VideoPlayerController _createVideoPlayerController(String mediaUrl) {
    if (Utility.isLocalUrl(mediaUrl)) {
      return VideoPlayerController.file(
        File(mediaUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false, // Better resource management
        ),
      );
    }

    var url = mediaUrl;
    if (url.startsWith('http:')) {
      url = url.replaceFirst('http:', 'https:');
    }

    // For HLS streams, add specific headers and format hint
    final isHls = url.toLowerCase().endsWith('.m3u8');
    final isMp4 = url.toLowerCase().endsWith('.mp4');
    final headers = {
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      if (isHls)
        'X-Playback-Session-Id':
            DateTime.now().millisecondsSinceEpoch.toString()
      else if (isMp4)
        ...{
          'Cache-Control': 'no-cache',
        },
    };

    return VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback:
            false, // Better resource management to prevent decoding issues
      ),
      httpHeaders: headers,
      formatHint: isHls ? VideoFormat.hls : isMp4 ? VideoFormat.other : null,
    );
  }

  @override
  bool isVideoCached(String url) => false;

  @override
  bool isVideoInitializing(String url) => false;

  @override
  void markAsVisible(String url) {
    // ❌ No visibility tracking
  }

  @override
  void markAsNotVisible(String url) {
    // ❌ No visibility tracking
  }

  @override
  void detachedFromWidget(String url, IVideoPlayerController? controller) {
    Future.delayed(const Duration(milliseconds: 300), () async { // for smooth transition
      await controller?.pause();
      await controller?.seekTo(Duration.zero);
      await controller?.dispose();
    });
  }

  @override
  void clearVideo(String url) {
    // ❌ Nothing stored
  }

  @override
  void clearControllers() {
    // ❌ Nothing stored
  }

  @override
  void clearControllersOutsideRange(List<String> activeUrls) {
    // ❌ Nothing stored
  }

  @override
  Map<String, dynamic> getCacheStats() => const {
        'mode': 'non-cache',
        'cached_videos': 0,
        'initializing_videos': 0,
        'visible_videos': 0,
      };
}
