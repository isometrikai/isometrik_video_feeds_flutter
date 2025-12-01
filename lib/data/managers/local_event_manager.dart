import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:rudder_sdk_flutter/RudderController.dart';
import 'package:rudder_sdk_flutter_platform_interface/platform.dart';
import 'package:uuid/uuid.dart';

class EventQueueProvider {
  static LocalEventQueue? _instance;

  static LocalEventQueue get instance {
    if (_instance == null) {
      throw Exception(
          'EventQueueProvider not initialized. Call EventQueueProvider.initialize() first.');
    }
    return _instance!;
  }

  /// Initialize the event queue with optional callback
  static Future<void> initialize({
    required String rudderStackWriteKey,
    required String rudderStackDataPlaneUrl,
    required String userId,
  }) async {
    final localDataUseCase =
        IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>();
    final deviceInfoManager =
        IsmInjectionUtils.getOtherClass<DeviceInfoManager>();

    // Fetch all required data
    final tenantId = await localDataUseCase.getTenantId();
    final projectId = await localDataUseCase.getProjectId();
    final latitude = await localDataUseCase.getLatitude();
    final longitude = await localDataUseCase.getLongitude();
    final country = await localDataUseCase.getCountry();
    final state = await localDataUseCase.getState();
    final city = await localDataUseCase.getCity();

    _instance ??= LocalEventQueue();
    await _instance!.init();
    if (rudderStackWriteKey.isEmpty || rudderStackDataPlaneUrl.isEmpty) return;
    RudderLogger.init(RudderLogger.VERBOSE);
    final builder = RudderConfigBuilder();
    builder.withDataPlaneUrl(rudderStackDataPlaneUrl);
    builder.withFlushQueueSize(10);
    builder.withLogLevel(RudderLogger.VERBOSE);
    final mobileConfig = MobileConfig(
      trackDeepLinks: true,
      trackLifecycleEvents: true,
    );
    builder.withMobileConfig(mobileConfig);
    final rudderOptions = RudderOption();

    rudderOptions.customContexts = {
      'workspace': {
        'tenant_id': tenantId,
        'project_id': projectId,
      },
      'device': {
        'id': deviceInfoManager.deviceId ?? '',
        'manufacturer': deviceInfoManager.deviceManufacturer,
        'model': deviceInfoManager.deviceModel ?? '',
        'os': deviceInfoManager.deviceOs,
        'os_version': deviceInfoManager.deviceOsVersion,
        'type': deviceInfoManager.deviceType,
        'name':
            '${deviceInfoManager.deviceManufacturer} ${deviceInfoManager.deviceModel}',
      },
      'location': {
        'city': city,
        'state': state,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': DateTime.now().timeZoneName,
      },
    };

    if (userId.isEmptyOrNull == false) {
      RudderController.instance.putAnonymousId(userId);
    }
    RudderController.instance.initialize(
      rudderStackWriteKey,
      config: builder.build(),
      options: rudderOptions,
    );
    RudderController.instance.identify(userId);
  }

  /// Check if the event queue is initialized
  static bool get isInitialized => _instance != null;
}

class LocalEventQueue with WidgetsBindingObserver {
  LocalEventQueue();

  static const _boxName = 'local_events';
  static const _batchSize = 1;

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        debugPrint('LocalEventQueue: Opening Hive box: $_boxName');
        await Hive.openBox<LocalEvent>(_boxName);
        debugPrint('LocalEventQueue: Hive box opened successfully');
      } else {
        debugPrint('LocalEventQueue: Hive box already open');
      }
    } catch (e) {
      debugPrint('LocalEventQueue: Error opening Hive box: $e');
      rethrow;
    }

    // observe app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // observe connectivity changes
    Connectivity().onConnectivityChanged.listen((status) async {
      if (status.contains(ConnectivityResult.none)) {
        await flush();
      }
    });
  }

  /// Called when app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      flush();
    }
  }

  final Uuid _uuid = const Uuid();

  Future<void> addEvent(String eventName, Map<String, dynamic> payload) async {
    try {
      // Ensure box is open before accessing
      if (!Hive.isBoxOpen(_boxName)) {
        debugPrint('LocalEventQueue.addEvent: Box not open, opening now...');
        await Hive.openBox<LocalEvent>(_boxName);
        debugPrint('LocalEventQueue.addEvent: Box opened successfully');
      }
      final box = Hive.box<LocalEvent>(_boxName);
      final event = LocalEvent(
        id: _uuid.v4(),
        eventName: eventName,
        payload: payload,
        timestamp: DateTime.now().toUtc(),
      );
      await box.add(event);
      if (box.length >= _batchSize) {
        final events = box.values.toList();

        // OPTION 2: Send each event individually (uncomment if you prefer this approach)
        for (final event in events) {
          final rudderProperties = RudderProperty();
          rudderProperties.putValue(map: event.payload);
          RudderController.instance.track(
            event.eventName,
            properties: rudderProperties,
          );
        }

        try {
          unawaited(flush());
        } catch (e) {
          debugPrint(
            '${runtimeType.toString()} Error in callback: $e, skipping flush',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('LocalEventQueue.addEvent: Error adding event: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> flush() async {
    // Ensure box is open before accessing
    if (!Hive.isBoxOpen(_boxName)) {
      return;
    }
    final box = Hive.box<LocalEvent>(_boxName);
    debugPrint(
        '${runtimeType.toString()} Box length before flushing: ${box.length}');

    final events = box.values.toList();

    if (events.isEmpty) return;

    await box.clear();
    debugPrint(
        '${runtimeType.toString()} Box length after flushing: ${box.length}');
  }

  /// cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

enum EventType {
  postViewed, // Triggered by viewport detection (1 sec visible)
  postLiked, // Instant UI feedback when user taps heart
  postUnliked, // Instant UI feedback
  postShared, // User shares via device share sheet
  postSaved, // User bookmarks post
  postHidden, // when user taps not interested
  postReported, // User submits report form
  commentCreated, // Fires immediately when user submits comment
  commentLiked, // Instant UI feedback when user taps heart
  userFollowed, // User taps "Follow" button
  userUnFollowed, // User taps "Unfollow" button
  videoStarted, // Video player starts playback
  videoProgress, // Video player hits 25%, 50%, 75%, 100%
  videoPaused, // Video Paused
  videoSoundToggled, // User mutes/unmutes
  profileViewed, // User navigates to profile screen/page
}

extension EventTypeExtension on EventType {
  String get value {
    switch (this) {
      case EventType.postViewed:
        return 'Post Viewed';
      case EventType.postLiked:
        return 'Post Liked';
      case EventType.postUnliked:
        return 'Post Unliked';
      case EventType.postSaved:
        return 'Post Saved';
      case EventType.postShared:
        return 'Post Shared';
      case EventType.postHidden:
        return 'Post Hidden';
      case EventType.postReported:
        return 'Post Reported';
      case EventType.userFollowed:
        return 'User Followed';
      case EventType.userUnFollowed:
        return 'User Unfollowed';
      case EventType.commentCreated:
        return 'Comment Created';
      case EventType.commentLiked:
        return 'Comment Liked';
      case EventType.videoStarted:
        return 'Video Started';
      case EventType.videoProgress:
        return 'Video Progress';
      case EventType.videoPaused:
        return 'Video Paused';
      case EventType.videoSoundToggled:
        return 'Video Sound Toggled';
      case EventType.profileViewed:
        return 'Profile Viewed';
    }
  }
}

enum EventCategory {
  userIdentity,
  navigation,
  postEngagement,
  socialGraph,
  videoEngagement,
}

extension EventCategoryExtension on EventCategory {
  String get value {
    switch (this) {
      case EventCategory.userIdentity:
        return 'User Identity';
      case EventCategory.navigation:
        return 'Navigation';
      case EventCategory.postEngagement:
        return 'Post Engagement';
      case EventCategory.socialGraph:
        return 'Social Graph';
      case EventCategory.videoEngagement:
        return 'Video Engagement';
    }
  }
}
