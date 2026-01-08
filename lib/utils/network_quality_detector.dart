import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network quality levels for adaptive video playback
enum NetworkQuality {
  excellent, // WiFi or 5G - best quality
  good, // 4G/LTE - high quality
  fair, // 3G - medium quality
  poor, // 2G or slow connection - low quality
  offline, // No connection
}

/// Network type detection
enum NetworkType {
  wifi,
  mobile4G,
  mobile3G,
  mobile2G,
  ethernet,
  unknown,
}

/// Adaptive video configuration based on network quality
class AdaptiveVideoConfig { // Number of videos to preload ahead

  const AdaptiveVideoConfig({
    required this.quality,
    required this.hlsBitrate,
    required this.networkTimeout,
    required this.cacheSeconds,
    required this.bufferSize,
    required this.useLowLatency,
    required this.preloadCount,
  });
  final NetworkQuality quality;
  final int hlsBitrate; // Bitrate in kbps (0 = auto/adaptive)
  final int networkTimeout; // Network timeout in seconds
  final int cacheSeconds; // Cache duration in seconds
  final int bufferSize; // Buffer size in MB
  final bool useLowLatency; // Use low latency mode
  final int preloadCount;

  /// Get configuration for network quality
  static AdaptiveVideoConfig forQuality(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return const AdaptiveVideoConfig(
          quality: NetworkQuality.excellent,
          hlsBitrate: 0, // Auto/adaptive - use max available
          networkTimeout: 10,
          cacheSeconds: 15,
          bufferSize: 16, // 16MB buffer
          useLowLatency: true,
          preloadCount: 3, // Preload 3 videos ahead
        );
      case NetworkQuality.good:
        return const AdaptiveVideoConfig(
          quality: NetworkQuality.good,
          hlsBitrate: 0, // Auto/adaptive
          networkTimeout: 15,
          cacheSeconds: 10,
          bufferSize: 12, // 12MB buffer
          useLowLatency: true,
          preloadCount: 2, // Preload 2 videos ahead
        );
      case NetworkQuality.fair:
        return const AdaptiveVideoConfig(
          quality: NetworkQuality.fair,
          hlsBitrate: 0, // Auto/adaptive - let HLS choose
          networkTimeout: 20,
          cacheSeconds: 8,
          bufferSize: 8, // 8MB buffer
          useLowLatency: false, // Disable low latency for stability
          preloadCount: 1, // Preload only 1 video ahead
        );
      case NetworkQuality.poor:
        return const AdaptiveVideoConfig(
          quality: NetworkQuality.poor,
          hlsBitrate: 0, // Auto/adaptive - will choose lowest
          networkTimeout: 30,
          cacheSeconds: 5,
          bufferSize: 4, // 4MB buffer
          useLowLatency: false,
          preloadCount: 0, // No preloading on poor network
        );
      case NetworkQuality.offline:
        return const AdaptiveVideoConfig(
          quality: NetworkQuality.offline,
          hlsBitrate: 0,
          networkTimeout: 5,
          cacheSeconds: 0,
          bufferSize: 0,
          useLowLatency: false,
          preloadCount: 0,
        );
    }
  }
}

/// Network quality detector with speed testing capabilities
class NetworkQualityDetector {
  NetworkQualityDetector._internal() {
    _init();
  }

  factory NetworkQualityDetector() => _instance;
  static final NetworkQualityDetector _instance = NetworkQualityDetector._internal();

  final Connectivity _connectivity = Connectivity();
  NetworkQuality _currentQuality = NetworkQuality.good;
  NetworkType _currentType = NetworkType.unknown;
  final StreamController<NetworkQuality> _qualityController =
      StreamController<NetworkQuality>.broadcast();
  
  Timer? _speedTestTimer;
  bool _isTestingSpeed = false;
  DateTime? _lastSpeedTestTime;
  static const Duration _speedTestInterval = Duration(minutes: 2);

  /// Get current network quality
  NetworkQuality get currentQuality => _currentQuality;

  /// Get current network type
  NetworkType get currentType => _currentType;

  /// Stream of network quality changes
  Stream<NetworkQuality> get qualityStream => _qualityController.stream;

  /// Get adaptive video configuration for current network
  AdaptiveVideoConfig get adaptiveConfig =>
      AdaptiveVideoConfig.forQuality(_currentQuality);

  void _init() {
    // Initial check
    _checkNetworkQuality();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.first == ConnectivityResult.none) {
      _updateQuality(NetworkQuality.offline, NetworkType.unknown);
      return;
    }

    final result = results.first;
    NetworkType type;
    
    switch (result) {
      case ConnectivityResult.wifi:
        type = NetworkType.wifi;
        break;
      case ConnectivityResult.mobile:
        // For mobile, we'll test speed to determine quality
        type = NetworkType.mobile4G; // Default assumption
        break;
      case ConnectivityResult.ethernet:
        type = NetworkType.ethernet;
        break;
      default:
        type = NetworkType.unknown;
    }

    // Test speed for mobile connections or if we haven't tested recently
    if (result == ConnectivityResult.mobile || 
        _lastSpeedTestTime == null ||
        DateTime.now().difference(_lastSpeedTestTime!) > _speedTestInterval) {
      await _testNetworkSpeed(type);
    } else {
      // For WiFi/Ethernet, assume excellent quality
      if (type == NetworkType.wifi || type == NetworkType.ethernet) {
        _updateQuality(NetworkQuality.excellent, type);
      }
    }
  }

  Future<void> _checkNetworkQuality() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.first == ConnectivityResult.none) {
        _updateQuality(NetworkQuality.offline, NetworkType.unknown);
        return;
      }

      final result = results.first;
      NetworkType type;
      
      switch (result) {
        case ConnectivityResult.wifi:
          type = NetworkType.wifi;
          _updateQuality(NetworkQuality.excellent, type);
          return;
        case ConnectivityResult.mobile:
          type = NetworkType.mobile4G; // Default assumption
          break;
        case ConnectivityResult.ethernet:
          type = NetworkType.ethernet;
          _updateQuality(NetworkQuality.excellent, type);
          return;
        default:
          type = NetworkType.unknown;
      }

      // Test speed for mobile
      if (result == ConnectivityResult.mobile) {
        await _testNetworkSpeed(type);
      }
    } catch (e) {
      debugPrint('⚠️ NetworkQualityDetector: Error checking network: $e');
      // Default to fair quality on error
      _updateQuality(NetworkQuality.fair, NetworkType.unknown);
    }
  }

  /// Test network speed using a lightweight approach
  Future<void> _testNetworkSpeed(NetworkType type) async {
    if (_isTestingSpeed) return;
    
    _isTestingSpeed = true;
    _lastSpeedTestTime = DateTime.now();

    try {
      // Use a small test file or ping approach
      // For simplicity, we'll use connectivity type as indicator
      // In production, you might want to do actual speed test
      
      // For mobile, check if we can determine 3G vs 4G
      // This is a simplified approach - in production, use actual speed test
      if (type == NetworkType.mobile4G) {
        // Assume 4G = good, 3G = fair
        // You can enhance this with actual speed measurement
        final speed = await _measureNetworkSpeed();
        
        if (speed > 5.0) {
          // > 5 Mbps = good quality
          _updateQuality(NetworkQuality.good, NetworkType.mobile4G);
        } else if (speed > 1.0) {
          // 1-5 Mbps = fair quality (3G)
          _updateQuality(NetworkQuality.fair, NetworkType.mobile3G);
        } else {
          // < 1 Mbps = poor quality (2G)
          _updateQuality(NetworkQuality.poor, NetworkType.mobile2G);
        }
      }
    } catch (e) {
      debugPrint('⚠️ NetworkQualityDetector: Error testing speed: $e');
      // Default to fair on error
      _updateQuality(NetworkQuality.fair, type);
    } finally {
      _isTestingSpeed = false;
    }
  }

  /// Measure network speed using a lightweight approach
  /// Returns speed in Mbps
  Future<double> _measureNetworkSpeed() async {
    HttpClient? client;
    try {
      // Use a small test endpoint to measure speed
      // This is a simplified version - in production, use proper speed test
      client = HttpClient();
      final stopwatch = Stopwatch()..start();
      
      final request = await client.getUrl(
        Uri.parse('https://www.google.com/favicon.ico'),
      );
      request.headers.set('Connection', 'close');
      
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      
      var bytesReceived = 0;
      await for (final data in response) {
        bytesReceived += data.length;
        if (bytesReceived > 10000) break; // Stop after 10KB
      }
      
      stopwatch.stop();
      final seconds = stopwatch.elapsedMilliseconds / 1000.0;
      final mbps = (bytesReceived * 8) / (seconds * 1000000);
      
      client.close();
      return mbps;
    } catch (e) {
      client?.close();
      debugPrint('⚠️ NetworkQualityDetector: Speed test failed: $e');
      // Return conservative estimate
      return 2.0; // Assume 2 Mbps
    }
  }

  void _updateQuality(NetworkQuality quality, NetworkType type) {
    if (_currentQuality != quality || _currentType != type) {
      _currentQuality = quality;
      _currentType = type;
      _qualityController.add(quality);
      debugPrint(
          '📡 NetworkQualityDetector: Quality changed to ${quality.name}, Type: ${type.name}');
    }
  }

  /// Force refresh network quality
  Future<void> refresh() async {
    await _checkNetworkQuality();
  }

  /// Dispose resources
  void dispose() {
    _speedTestTimer?.cancel();
    _qualityController.close();
  }
}
