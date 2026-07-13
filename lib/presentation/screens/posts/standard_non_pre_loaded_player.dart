import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/media_kit_video_player.dart';
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
  Future<void> setPlaybackSpeed(double speed) =>
      _controller.setPlaybackSpeed(speed);

  @override
  double get playbackSpeed => _controller.value.playbackSpeed;

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
  factory StandardVideoNonPreloadedManager() => _instance;

  StandardVideoNonPreloadedManager._internal();

  static final StandardVideoNonPreloadedManager _instance =
      StandardVideoNonPreloadedManager._internal();

  static const Duration _sizeWaitTimeout = Duration(milliseconds: 800);

  @override
  Future<void> precacheVideos(
    List<String> videoUrls, {
    bool highPriority = false,
  }) async {
    for (final url in videoUrls) {
      if (url.endsWith('.m3u8')) {
        unawaited(VideoMediaUtil.precacheFirstSegment(url));
      }
    }
  }

  @override
  IVideoPlayerController? getCachedController(String url) => null;

  @override
  Future<IVideoPlayerController?> precacheMediaAndReturnController(
          String url) =>
      Future<IVideoPlayerController?>.delayed(
        const Duration(milliseconds: 300),
        () => _createAndInitializeController(url),
      );

  Future<IVideoPlayerController?> _createAndInitializeController(
      String url) async {
    debugPrint(
        'StandardVideoCacheManager: _createAndInitializeController: $url');
    VideoPlayerController? controller;
    try {
      controller = _createVideoPlayerController(url);

      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
              '⚠️ StandardNonCacheVideoPlayer initialization timeout for: $url');
          throw TimeoutException(
              'Video initialization timeout', const Duration(seconds: 15));
        },
      );

      if (!controller.value.isInitialized) {
        debugPrint(
            '❌ StandardNonCacheVideoPlayer not initialized properly for: $url');
        await controller.dispose();
        return _fallbackToMediaKit(url, reason: 'not initialized');
      }

      if (controller.value.hasError) {
        debugPrint(
            '❌ StandardNonCacheVideoPlayer has error after initialization: ${controller.value.errorDescription}');
        debugPrint('❌ URL: $url');
        await controller.dispose();
        return _fallbackToMediaKit(url, reason: 'hasError');
      }

      // Size can be 0x0 briefly then become valid — wait before treating as failure.
      final size = await _waitForValidSize(controller);
      if (size == Size.zero) {
        debugPrint(
            '⚠️ StandardNonCacheVideoPlayer size still 0x0 after wait for: $url');
        await controller.dispose();
        controller = null;
        return _fallbackToMediaKit(url, reason: 'zero size after wait');
      }

      debugPrint(
          '✅ Video initialized successfully - Size: $size, Duration: ${controller.value.duration}, URL: $url');

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
      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 300));
      return _fallbackToMediaKit(url, reason: 'exception');
    }
  }

  /// Waits for non-zero dimensions; many URLs report 0x0 right after [initialize].
  Future<Size> _waitForValidSize(VideoPlayerController controller) async {
    if (controller.value.size != Size.zero) {
      return controller.value.size;
    }

    final completer = Completer<Size>();
    Timer? timeoutTimer;

    void listener() {
      final size = controller.value.size;
      if (size != Size.zero) {
        controller.removeListener(listener);
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(size);
        }
      }
    }

    controller.addListener(listener);
    timeoutTimer = Timer(_sizeWaitTimeout, () {
      controller.removeListener(listener);
      if (!completer.isCompleted) {
        completer.complete(controller.value.size);
      }
    });

    return completer.future;
  }

  Future<IVideoPlayerController?> _fallbackToMediaKit(
    String url, {
    required String reason,
  }) async {
    debugPrint('🔄 Standard player failed ($reason), trying MediaKit: $url');
    await Future.delayed(const Duration(milliseconds: 150));
    return MediaKitCacheManager().createEphemeralFallbackController(url);
  }

  VideoPlayerController _createVideoPlayerController(String mediaUrl) {
    if (Utility.isLocalUrl(mediaUrl)) {
      return VideoPlayerController.file(
        File(mediaUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
    }

    var url = mediaUrl;
    if (url.startsWith('http:')) {
      url = url.replaceFirst('http:', 'https:');
    }

    final isHls = url.toLowerCase().endsWith('.m3u8');
    final headers = {
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      if (isHls)
        'X-Playback-Session-Id':
            DateTime.now().millisecondsSinceEpoch.toString(),
    };

    return VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
      httpHeaders: headers,
      formatHint: isHls ? VideoFormat.hls : null,
    );
  }

  @override
  bool isVideoCached(String url) => false;

  @override
  bool isVideoInitializing(String url) => false;

  @override
  void markAsVisible(String url) {}

  @override
  void markAsNotVisible(String url) {}

  @override
  void detachedFromWidget(String url, IVideoPlayerController? controller) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      await controller?.pause();
      await controller?.seekTo(Duration.zero);
      await controller?.dispose();
    });
  }

  @override
  void clearVideo(String url) {}

  @override
  void clearControllers() {}

  @override
  Map<String, dynamic> getCacheStats() => const {
        'mode': 'non-cache',
        'cached_videos': 0,
        'initializing_videos': 0,
        'visible_videos': 0,
      };
}
