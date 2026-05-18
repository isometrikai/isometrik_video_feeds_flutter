import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:rudder_sdk_flutter/RudderController.dart';
import 'package:rudder_sdk_flutter_platform_interface/platform.dart';
import 'package:talker/talker.dart';
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
  }) async {
    final localDataUseCase =
        IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>();
    final deviceInfoManager =
        IsmInjectionUtils.getOtherClass<DeviceInfoManager>();

    // Fetch all required data
    final userId = await localDataUseCase.getUserId();
    final tenantId = await localDataUseCase.getTenantId();
    final projectId = await localDataUseCase.getProjectId();
    final latitude = await localDataUseCase.getLatitude();
    final longitude = await localDataUseCase.getLongitude();
    final country = await localDataUseCase.getCountry();
    final state = await localDataUseCase.getState();
    final city = await localDataUseCase.getCity();
    final firstName = await localDataUseCase.getFirstName();
    final lastName = await localDataUseCase.getLastName();
    final userName = await localDataUseCase.getUserName();
    final emailAddress = await localDataUseCase.getEmail();
    final profilePic = await localDataUseCase.getProfilePic();
    final phoneNumber = await localDataUseCase.getPhoneNumber();
    final dialCode = await localDataUseCase.getDialCode();

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
    final rudderTraits = RudderTraits();
    rudderTraits.put('first_name', firstName);
    rudderTraits.put('last_name', lastName);
    rudderTraits.put('user_name', userName);
    rudderTraits.put('profile_pic', profilePic);
    rudderTraits.put('dialCode', dialCode);
    rudderTraits.put('phoneNumber', phoneNumber);
    rudderTraits.putEmail(emailAddress);
    RudderController.instance.identify(userId, traits: rudderTraits);
  }

  /// Check if the event queue is initialized
  static bool get isInitialized => _instance != null;
}

class LocalEventQueue with WidgetsBindingObserver {
  LocalEventQueue();

  static const _boxName = 'isometrik_social_local_events';
  static const _batchSize = 10;
  static const _batchTimerDuration = AppConstants
      .impressionDataApiLogTimeDuration; // need to change to 10 mins

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _batchTimer;
  bool _isSending = false;
  bool _sendAgainAfterCurrent = false;

  Talker? get _talker => IsmInjectionUtils.getOtherClassIfPresent();

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
    await _connectivitySubscription?.cancel();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((status) async {
      if (!status.contains(ConnectivityResult.none)) {
        await sendPendingEventsToBackend();
      }
    });
  }

  /// Called when app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      sendPendingEventsToBackend();
    }
  }

  final Uuid _uuid = const Uuid();

  Future<void> _addBackendEvent(
    String eventName,
    Map<String, dynamic> payload,
  ) async {
    try {
      final box = await _openBox();
      final event = LocalEvent(
        id: _uuid.v4(),
        eventName: eventName,
        payload: payload,
        timestamp: DateTime.now().toUtc(),
      );
      await box.add(event);
      debugPrint(
          '${runtimeType.toString()}:Event Name: $eventName added with\n Event Data : ${jsonEncode(payload)}');
      debugPrint('${runtimeType.toString()}:Box length: ${box.length}');

      if (eventName == EventType.postViewed.value) {
        _talker?.info(
            '${runtimeType.toString()}:Event Name: $eventName added with\n Event Data : ${jsonEncode(payload)}');
        if (box.length >= _batchSize) {
          await sendPendingEventsToBackend();
          return;
        }
        _scheduleBatchTimerIfNeeded();
      }
    } catch (e, stackTrace) {
      debugPrint('LocalEventQueue.addEvent: Error adding event: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<Box<LocalEvent>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      debugPrint('LocalEventQueue.addEvent: Box not open, opening now...');
      await Hive.openBox<LocalEvent>(_boxName);
      debugPrint('LocalEventQueue.addEvent: Box opened successfully');
    }
    return Hive.box<LocalEvent>(_boxName);
  }

  void _scheduleBatchTimerIfNeeded() {
    if (_batchTimer != null) return;
    final box = Hive.isBoxOpen(_boxName) ? Hive.box<LocalEvent>(_boxName) : null;
    if (box == null || box.isEmpty) return;

    _batchTimer = Timer(_batchTimerDuration, () {
      _batchTimer = null;
      sendPendingEventsToBackend();
    });
    debugPrint(
      '${runtimeType.toString()}: Started ${_batchTimerDuration.inMinutes}-min batch timer',
    );
  }

  void _cancelBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  final _rudderIncludedEvents = [
    EventType.userFollowed.value,
    EventType.userUnFollowed.value,
    EventType.videoStarted.value,
    EventType.videoProgress.value,
    EventType.videoPaused.value,
    EventType.videoSoundToggled.value,
    EventType.profileViewed.value,
    EventType.hashTagClicked.value,
    EventType.searchPerformed.value,
    EventType.searchResultClicked.value,
  ];

  final _backendEvents = [EventType.postViewed.value];

  void logEvent(String eventName, Map<String, dynamic> payload) {
    debugPrint(
        'Logging Event -> Event Triggered: $eventName\n Event Data : ${jsonEncode(payload)}');
    final eventType = EventType.fromValue(eventName);
    final socialEventModel = SocialEventModel(
      event: eventName,
      properties: Map<String, dynamic>.from(payload),
      category: _resolveEventCategory(eventType),
      isSdkEvent: eventType != null,
    );
    IsrVideoReelConfig.socialConfig.socialCallBackConfig?.onSocialEventTriggered
        ?.call(socialEventModel);
    if (_backendEvents.contains(eventName)) {
      unawaited(_addBackendEvent(eventName, payload));
    }
    if (_rudderIncludedEvents.contains(eventName)) {
      final rudderProperties = RudderProperty();
      rudderProperties.putValue(map: payload);
      RudderController.instance.track(
        eventName,
        properties: rudderProperties,
      );
    }
  }

  EventCategory _resolveEventCategory(EventType? eventType) {
    if (eventType == null) {
      return EventCategory.system;
    }
    switch (eventType) {
      case EventType.postLiked:
      case EventType.postUnliked:
      case EventType.postShared:
      case EventType.postSaved:
      case EventType.postUnsaved:
      case EventType.postHidden:
      case EventType.postReported:
      case EventType.commentCreated:
      case EventType.commentLiked:
      case EventType.userFollowed:
      case EventType.userUnFollowed:
      case EventType.profileViewed:
      case EventType.hashTagClicked:
      case EventType.searchPerformed:
      case EventType.searchResultClicked:
        return EventCategory.userAction;
      case EventType.postViewed:
      case EventType.videoStarted:
      case EventType.videoProgress:
      case EventType.videoPaused:
      case EventType.videoSoundToggled:
        return EventCategory.system;
    }
  }

  Future<void> sendPendingEventsToBackend() async {
    if (_isSending) {
      _sendAgainAfterCurrent = true;
      return;
    }

    _isSending = true;
    try {
      do {
        _sendAgainAfterCurrent = false;
        _cancelBatchTimer();

        if (!Hive.isBoxOpen(_boxName)) {
          debugPrint('${runtimeType.toString()}: Box not open, opening now...');
          await Hive.openBox<LocalEvent>(_boxName);
        }
        final box = Hive.box<LocalEvent>(_boxName);
        final events = box.values.toList();
        if (events.isEmpty) break;

        final sentEventIds = events.map((e) => e.id).toList();
        final eventPayLoadList = events.map((e) => e.payload).toList();

        try {
          _talker?.info(
              '${runtimeType.toString()}: Sending ${events.length} event(s) -> $eventPayLoadList');
          final socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
          debugPrint(
              '${runtimeType.toString()}: API Call Init -> count: ${events.length}, payload:- $eventPayLoadList');
          final result =
              await socialPostBloc.sendEventsToBackend(eventPayLoadList);
          _talker?.info(
              '${runtimeType.toString()}: Sending Event -> Event result status : ${result.statusCode}, isSuccess: ${result.isSuccess}, errorIfAny: ${result.error?.message}');
          debugPrint(
              '${runtimeType.toString()}: API Call result -> ${result.statusCode}, isSuccess: ${result.isSuccess}, errorIfAny: ${result.error?.message}');
          if (result.isSuccess || result.statusCode == 422) {
            await _removeSentEvents(sentEventIds);
            debugPrint(
                '${runtimeType.toString()}: Removed ${sentEventIds.length} sent event(s), box length: ${box.length}',
            );
          }
        } catch (e) {
          debugPrint(
              '${runtimeType.toString()} sendPendingEventsToBackend: $e',
          );
          break;
        }
      } while (_sendAgainAfterCurrent);

      _scheduleBatchTimerIfNeeded();
    } finally {
      _isSending = false;
    }
  }

  Future<void> _removeSentEvents(List<String> eventIds) async {
    if (!Hive.isBoxOpen(_boxName) || eventIds.isEmpty) return;

    final box = Hive.box<LocalEvent>(_boxName);
    final idsToRemove = eventIds.toSet();
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final event = box.get(key);
      if (event != null && idsToRemove.contains(event.id)) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isEmpty) return;

    await box.deleteAll(keysToDelete);
  }

  /// cleanup
  void dispose() {
    _cancelBatchTimer();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    WidgetsBinding.instance.removeObserver(this);
  }
}

class SocialEventModel {
  const SocialEventModel({
    required this.event,
    required this.properties,
    required this.category,
    required this.isSdkEvent,
  });

  final String event;
  final Map<String, dynamic> properties;
  final EventCategory category;
  final bool isSdkEvent;

  Map<String, dynamic> toMap() => {
        'event': event,
        'category': category.value,
        'properties': properties,
        'is_sdk_event': isSdkEvent,
      };
}

enum EventCategory {
  userAction('user_action'),
  system('system'),
  api('api'),
  error('error');

  const EventCategory(this.value);

  final String value;
}

enum EventType {
  postViewed('Post Viewed'),
  postLiked('Post Liked'),
  postUnliked('Post Unliked'),
  postShared('Post Shared'),
  postSaved('Post Saved'),
  postUnsaved('Post Unsaved'),
  postHidden('Post Hidden'),
  postReported('Post Reported'),
  commentCreated('Comment Created'),
  commentLiked('Comment Liked'),
  userFollowed('User Followed'),
  userUnFollowed('User Unfollowed'),
  videoStarted('Video Started'),
  videoProgress('Video Progress'),
  videoPaused('Video Paused'),
  videoSoundToggled('Video Sound Toggled'),
  profileViewed('Profile Viewed'),
  hashTagClicked('Hashtag Clicked'),
  searchPerformed('Search Performed'),
  searchResultClicked('Search Result Clicked');

  const EventType(this.value);

  final String value;

  static EventType? fromValue(String value) {
    for (final type in EventType.values) {
      if (type.value == value) return type;
    }
    return null; // or throw if you prefer strict behavior
  }
}
