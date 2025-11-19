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
  static void initialize({
    required String rudderStackWriteKey,
    required String rudderStackDataPlaneUrl,
  }) {
    _instance ??= LocalEventQueue();
    _instance!.init();
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
  static const _batchSize = 10;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<LocalEvent>(_boxName);
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

  Future<void> addEvent(Map<String, dynamic> payload) async {
    final box = Hive.box<LocalEvent>(_boxName);
    final event = LocalEvent(
      id: _uuid.v4(),
      payload: payload,
      timestamp: DateTime.now().toUtc(),
    );
    await box.add(event);
    if (box.length >= _batchSize) {
      final eventPayLoadList = <Map<String, dynamic>>[];
      for (final event in box.values.toList()) {
        eventPayLoadList.add(event.payload);
      }
      if (eventPayLoadList.isNotEmpty) {
        final rudderProperties = RudderProperty();
        for (final mapItem in eventPayLoadList) {
          rudderProperties.putValue(map: mapItem);
        }
        RudderController.instance.track(
          'watch-event',
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
  }

  Future<void> flush() async {
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
        return 'view';
      case EventType.watch:
        return 'watch';
    }
  }
}
