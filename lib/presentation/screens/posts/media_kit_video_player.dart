import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_interface.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Wrapper for media_kit Player implementing IVideoPlayerController
class MediaKitVideoPlayerWrapper implements IVideoPlayerController {
  MediaKitVideoPlayerWrapper(this._player, this._videoController) {
    _setupListeners();
  }

  final Player _player;
  final VideoController _videoController;
  final ValueNotifier<bool> _playingStateNotifier = ValueNotifier<bool>(false);
  bool _isDisposed = false;
  bool _hasLoggedError = false;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<String>? _errorSubscription;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  final List<VoidCallback> _listeners = [];

  void _setupListeners() {
    // Listen to playing state changes
    _playingSubscription = _player.stream.playing.listen((playing) {
      if (!_isDisposed) {
        _playingStateNotifier.value = playing;
        _notifyListeners();
      }
    });

    // Listen to error stream
    _errorSubscription = _player.stream.error.listen((error) {
      if (!_isDisposed && error.isNotEmpty && !_hasLoggedError) {
        _hasLoggedError = true;
        debugPrint('❌ MediaKit playback error detected during runtime');
        debugPrint('❌ Error description: $error');
        debugPrint('❌ Position: $_position');
        debugPrint('❌ Duration: $_duration');
      }
    });

    // Listen to position changes - throttled to reduce UI overhead
    _positionSubscription = _player.stream.position
        .distinct((prev, next) => (next - prev).inMilliseconds.abs() < 250)
        .listen((pos) {
      if (!_isDisposed) {
        _position = pos;
        _notifyListeners();
      }
    });

    // Listen to duration changes
    _durationSubscription = _player.stream.duration.listen((dur) {
      if (!_isDisposed) {
        _duration = dur;
        _notifyListeners();
      }
    });
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  Future<void> initialize() async {
    // media_kit initializes automatically when opening media
    // Wait for the player to be ready
    await _player.stream.completed.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
  }

  @override
  Future<void> setLooping(bool looping) async {
    await _player
        .setPlaylistMode(looping ? PlaylistMode.single : PlaylistMode.none);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100); // media_kit uses 0-100 scale
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  @override
  Duration get position =>
      _position > Duration.zero ? _position : _player.state.position;

  @override
  Duration get duration =>
      _duration > Duration.zero ? _duration : _player.state.duration;

  @override
  bool get isPlaying => _player.state.playing;

  /// For HLS streams, dimensions may not be available until playback starts
  /// Consider initialized if we have dimensions OR duration OR media is loaded
  @override
  bool get isInitialized =>
      (_player.state.width != null && _player.state.height != null) ||
      _player.state.duration > Duration.zero ||
      _player.state.playlist.medias.isNotEmpty;

  @override
  bool get isDisposed => _isDisposed;

  @override
  ValueNotifier<bool> get playingStateNotifier => _playingStateNotifier;

  @override
  Size get videoSize {
    final width = _player.state.width?.toDouble() ?? 0;
    final height = _player.state.height?.toDouble() ?? 0;
    return Size(width, height);
  }

  @override
  double get aspectRatio {
    final size = videoSize;
    if (size.height == 0) return 16 / 9; // Default aspect ratio
    return size.width / size.height;
  }

  @override
  Widget buildVideoPlayerWidget() => Video(
        controller: _videoController,
        controls: null, // No controls - handled externally
      );

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    try {
      await _playingSubscription?.cancel();
      await _errorSubscription?.cancel();
      await _positionSubscription?.cancel();
      await _durationSubscription?.cancel();
    } catch (e) {
      debugPrint('⚠️ Error cancelling subscriptions: $e');
    }

    try {
      _playingStateNotifier.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing playing state notifier: $e');
    }

    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing media_kit player: $e');
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

/// Cache manager implementation for media_kit
class MediaKitCacheManager implements IVideoCacheManager {
  factory MediaKitCacheManager() {
    _ensureInitialized();
    return _instance;
  }

  MediaKitCacheManager._internal();

  static final MediaKitCacheManager _instance =
      MediaKitCacheManager._internal();

  static bool _isInitialized = false;
  static bool _isAudioSessionConfigured = false;

  final Map<String, MediaKitVideoPlayerWrapper> _videoControllerCache = {};
  final Map<String, Future<MediaKitVideoPlayerWrapper?>> _initializationCache =
      {};
  final Queue<String> _lruQueue = Queue<String>();
  final Set<String> _visibleVideos = <String>{};

  // OPTIMIZATION: Platform-specific cache size for memory management
  // Increased Android cache for smoother scrolling (Instagram-like experience)
  static int get _maxCacheSize => Platform.isAndroid ? 10 : 30;

  // Track memory errors to adaptively reduce cache
  int _memoryErrorCount = 0;

  /// Lazy initialization - called automatically when accessing the singleton
  static void _ensureInitialized() {
    if (!_isInitialized) {
      MediaKit.ensureInitialized();
      _isInitialized = true;
    }
  }

  /// Configure audio session for iOS - MUST be called before playing audio
  static Future<void> _configureAudioSession() async {
    if (_isAudioSessionConfigured) return;

    try {
      final session = await AudioSession.instance;

      // Configure for video playback with audio
      // Using default options (no mixWithOthers) for better audio device initialization
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Activate the audio session
      await session.setActive(true);

      // Small delay to ensure audio device is ready
      await Future.delayed(const Duration(milliseconds: 50));

      _isAudioSessionConfigured = true;
      debugPrint('✅ Audio session configured successfully for video playback');
    } catch (e) {
      debugPrint('❌ Error configuring audio session: $e');
    }
  }

  Future<(Player, VideoController)> _createVideoPlayerController(
      String mediaUrl) async {
    var url = mediaUrl;

    // Handle local files
    if (Utility.isLocalUrl(mediaUrl)) {
      url = mediaUrl;
    } else if (url.startsWith('http:')) {
      url = url.replaceFirst('http:', 'https:');
    }

    // OPTIMIZATION: Configure player for smooth playback
    final player = Player(
      configuration: const PlayerConfiguration(
        // Buffer more video ahead for smoother playback
        bufferSize: 32 * 1024 * 1024, // 32MB buffer
      ),
    );

    final videoController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        // Enable hardware acceleration for smoother playback
        enableHardwareAcceleration: true,
      ),
    );

    // Set up headers for network requests
    final headers = {
      'User-Agent': 'FlutterVideoPlayer',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };

    // Open the media
    if (Utility.isLocalUrl(mediaUrl)) {
      await player.open(Media(url), play: false);
    } else {
      await player.open(
        Media(url, httpHeaders: headers),
        play: false,
      );
    }

    // Note: Removed auto-play on buffering end - this was causing unwanted playback
    // Visibility-based play/pause is now the only playback control mechanism

    return (player, videoController);
  }

  Future<MediaKitVideoPlayerWrapper?> _initializeVideoController(
      String url) async {
    // If already initializing, wait for existing initialization
    if (_initializationCache.containsKey(url)) {
      return _initializationCache[url];
    }

    // ANDROID FIX: Clear stuck initializations if cache is getting full
    if (Platform.isAndroid && _initializationCache.length > 2) {
      debugPrint(
          '⚠️ Too many concurrent initializations (${_initializationCache.length}), clearing cache');
      await _clearNonVisibleVideos();

      // Give system time to release resources
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final initFuture = _createAndInitializeController(url);
    _initializationCache[url] = initFuture;

    try {
      final controller = await initFuture;
      if (controller != null) {
        _addToCache(url, controller);
      }
      return controller;
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
      return null;
    } finally {
      // Intentionally not awaiting - just removing from cache
      unawaited(_initializationCache.remove(url) ?? Future.value());
    }
  }

  Future<MediaKitVideoPlayerWrapper?> _createAndInitializeController(
      String url) async {
    try {
      // CRITICAL: Configure audio session BEFORE creating player (especially for iOS)
      await _configureAudioSession();

      // CRITICAL: Proactive cache management for Android BEFORE initialization
      if (Platform.isAndroid) {
        if (_videoControllerCache.length >= _maxCacheSize - 1) {
          debugPrint(
              '🔥 Proactive: Clearing cache before initialization (at limit)');
          // Non-blocking cache clear - don't wait for it
          unawaited(_clearNonVisibleVideos());
        }

        if (_memoryErrorCount > 0) {
          // OPTIMIZATION: Reduced delay from 500ms to 100ms per error
          final delay = 100 * _memoryErrorCount.clamp(1, 3);
          debugPrint(
              '⏳ Adding ${delay}ms delay before initialization (error count: $_memoryErrorCount)');
          await Future.delayed(Duration(milliseconds: delay));
        }
      }

      final timeoutDuration = Duration(seconds: Platform.isAndroid ? 3 : 20);

      late Player player;
      late VideoController videoController;

      try {
        final result = await _createVideoPlayerController(url).timeout(
          timeoutDuration,
          onTimeout: () {
            debugPrint('⚠️ MediaKit initialization timeout for: $url');
            throw TimeoutException(
                'Video initialization timeout', timeoutDuration);
          },
        );
        player = result.$1;
        videoController = result.$2;
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        final isMemoryError = Platform.isAndroid &&
            (errorMsg.contains('no_memory') ||
                errorMsg.contains('decoder init failed') ||
                errorMsg.contains('mediacodec') ||
                errorMsg.contains('videoerror'));

        if (isMemoryError) {
          _memoryErrorCount++;
          debugPrint(
              '🔥 CRITICAL: Memory/Decoder error detected! (Count: $_memoryErrorCount)');
          debugPrint('🔥 Error: $e');
          debugPrint('🔥 Clearing cache and retrying...');

          await _clearNonVisibleVideos();

          // Retry initialization
          try {
            final retryResult = await _createVideoPlayerController(url).timeout(
              timeoutDuration,
              onTimeout: () {
                debugPrint(
                    '⚠️ MediaKit retry initialization timeout for: $url');
                throw TimeoutException(
                    'Video retry initialization timeout', timeoutDuration);
              },
            );
            player = retryResult.$1;
            videoController = retryResult.$2;
            debugPrint('✅ Video initialized successfully after cache clear!');
            if (_memoryErrorCount > 0) _memoryErrorCount--;
          } catch (retryError) {
            debugPrint('❌ Retry failed after cache clear: $retryError');
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      // Wait for video to actually be ready (width or duration available)
      // HLS streams may take a moment to parse the manifest
      try {
        await Future.any([
          player.stream.width.where((w) => w != null).first,
          player.stream.duration.where((d) => d > Duration.zero).first,
        ]).timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
      } catch (_) {
        // Ignore timeout - check state below
      }

      final wrapper = MediaKitVideoPlayerWrapper(player, videoController);

      // Check if video is actually ready to play
      final hasValidState = player.state.width != null ||
          player.state.duration > Duration.zero ||
          player.state.playlist.medias.isNotEmpty;

      if (!hasValidState) {
        debugPrint('❌ MediaKit not initialized properly for: $url');
        debugPrint(
            '❌ State: width=${player.state.width}, duration=${player.state.duration}');
        await wrapper.dispose();
        return null;
      }

      debugPrint(
          '✅ MediaKit initialized - Width: ${player.state.width}, Duration: ${player.state.duration}, URL: $url');

      // OPTIMIZATION: Run setup in parallel for faster ready state
      await Future.wait([
        wrapper.setLooping(false),
        wrapper.setVolume(1.0),
      ]);
      return wrapper;
    } catch (e, stackTrace) {
      debugPrint('❌ MediaKit Error creating video controller for URL: $url');
      debugPrint('❌ MediaKit Error details: $e');
      debugPrint('❌ MediaKit Stack trace: $stackTrace');
      return null;
    }
  }

  /// CRITICAL: Clear all non-visible videos to free up decoder memory
  Future<void> _clearNonVisibleVideos() async {
    final urlsToRemove = <String>[];

    for (final url in _videoControllerCache.keys) {
      if (!_visibleVideos.contains(url)) {
        urlsToRemove.add(url);
      }
    }

    final disposeFutures = <Future<void>>[];
    for (final url in urlsToRemove) {
      final controller = _videoControllerCache.remove(url);
      if (controller != null) {
        disposeFutures.add(controller.dispose().catchError((e) {
          debugPrint('⚠️ Error disposing controller for $url: $e');
        }));
        _lruQueue.remove(url);
        debugPrint('🗑️ Emergency: Clearing video from cache: $url');
      }
    }

    if (disposeFutures.isNotEmpty) {
      await Future.wait(disposeFutures);
    }

    debugPrint(
        '🔥 Emergency cache clear: Removed ${urlsToRemove.length} videos, ${_videoControllerCache.length} remaining');
  }

  void _addToCache(String url, MediaKitVideoPlayerWrapper controller) {
    _lruQueue.remove(url);
    _lruQueue.addFirst(url);
    _videoControllerCache[url] = controller;
    _evictIfNeeded();
  }

  void _evictIfNeeded() {
    while (_lruQueue.length > _maxCacheSize) {
      final url = _lruQueue.removeLast();

      if (_visibleVideos.contains(url)) {
        _lruQueue.addFirst(url);
        continue;
      }

      final controller = _videoControllerCache.remove(url);
      if (controller != null) {
        unawaited(controller.dispose());
        debugPrint('🗑️ MediaKitCache: Evicted video from cache: $url');
      }
    }
  }

  @override
  Future<void> precacheVideos(List<String> videoUrls,
      {bool highPriority = false}) async {
    final futures = <Future<void>>[];

    for (final url in videoUrls) {
      if (url.isEmpty) continue;
      if (_videoControllerCache.containsKey(url)) continue;

      final future = _initializeVideoController(url);
      if (highPriority) {
        futures.add(future);
      } else {
        unawaited(future);
      }
    }

    if (highPriority && futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  @override
  IVideoPlayerController? getCachedController(String url) {
    final controller = _videoControllerCache[url];
    if (controller != null) {
      _lruQueue.remove(url);
      _lruQueue.addFirst(url);
    }
    return controller;
  }

  @override
  void markAsVisible(String url) => _visibleVideos.add(url);

  @override
  void markAsNotVisible(String url) => _visibleVideos.remove(url);

  @override
  bool isVideoCached(String url) {
    final controller = _videoControllerCache[url];
    return controller != null && controller.isInitialized;
  }

  @override
  bool isVideoInitializing(String url) => _initializationCache.containsKey(url);

  @override
  void clearVideo(String url) {
    _visibleVideos.remove(url);
    _lruQueue.remove(url);
    final controller = _videoControllerCache.remove(url);
    controller?.dispose();
    _initializationCache.remove(url);
  }

  @override
  void clearControllers() {
    for (final controller in _videoControllerCache.values) {
      controller.dispose();
    }
    _videoControllerCache.clear();
    _initializationCache.clear();
    _lruQueue.clear();
    _visibleVideos.clear();
  }

  @override
  void clearControllersOutsideRange(List<String> activeUrls) {
    final urlsToKeep = Set<String>.from(activeUrls);
    final urlsToRemove = _videoControllerCache.keys
        .where((url) => !urlsToKeep.contains(url))
        .toList();

    for (final url in urlsToRemove) {
      clearVideo(url);
    }
  }

  @override
  Map<String, dynamic> getCacheStats() => {
        'cached_videos': _videoControllerCache.length,
        'initializing_videos': _initializationCache.length,
        'visible_videos': _visibleVideos.length,
        'lru_queue_size': _lruQueue.length,
      };
}
