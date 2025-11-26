import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:ism_video_reel_player/data/data.dart';
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
  }) async {
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
    RudderController.instance.initialize(
      rudderStackWriteKey,
      config: builder.build(),
    );
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

        // OPTION 1: Send as batch with list of maps
        // final eventPayLoadList = events
        //     .map((e) => {
        //           'event_name': e.eventName,
        //           'event_id': e.id,
        //           'timestamp': e.timestamp.toIso8601String(),
        //           ...e.payload,
        //         })
        //     .toList();
        //
        // if (eventPayLoadList.isNotEmpty) {
        //   final rudderProperties = RudderProperty();
        //   rudderProperties.put('events', eventPayLoadList);
        //   RudderController.instance.track(
        //     'Batch Events',
        //     properties: rudderProperties,
        //   );
        // }

        // OPTION 2: Send each event individually (uncomment if you prefer this approach)
        for (final event in events) {
          final rudderProperties = RudderProperty();
          rudderProperties.putValue(map: event.payload);
          RudderController.instance.track(
            'Post Viewed',
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
    debugPrint('${runtimeType.toString()} Box length before flushing: ${box.length}');

    final events = box.values.toList();

    if (events.isEmpty) return;

    await box.clear();
    debugPrint('${runtimeType.toString()} Box length after flushing: ${box.length}');
  }

  /// cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

enum EventType {
  like,
  save,
  follow,
  view,
  watch, // for playback progress
}

extension EventTypeExtension on EventType {
  String get value {
    switch (this) {
      case EventType.like:
        return 'like';
      case EventType.save:
        return 'save';
      case EventType.follow:
        return 'follow';
      case EventType.view:
        return 'Post Viewed';
      case EventType.watch:
        return 'watch';
    }
  }
}
