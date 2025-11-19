import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:uuid/uuid.dart';

/// Callback that receives events before flushing and returns success status
typedef OnBeforeFlushCallback = Future<bool> Function(List<LocalEvent> events);

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
  static void initialize({OnBeforeFlushCallback? onBeforeFlush}) {
    _instance = LocalEventQueue(onBeforeFlush: onBeforeFlush);
    _instance?.init();
  }

  /// Check if the event queue is initialized
  static bool get isInitialized => _instance != null;
}

class LocalEventQueue with WidgetsBindingObserver {
  LocalEventQueue({
    this.onBeforeFlush,
  });

  static const String _boxName = 'local_events';
  static const int _batchSize = 1;

  final OnBeforeFlushCallback? onBeforeFlush;

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

    debugPrint(
        '${runtimeType.toString()} Event payload: ${jsonEncode(event.payload)}');
    debugPrint('${runtimeType.toString()} Event added: ${event.id}');
    debugPrint('${runtimeType.toString()} Box length: ${box.length}');

    if (box.length >= _batchSize) {
      // Get all events before flushing
      final events = box.values.toList();

      // Call the callback if provided
      if (onBeforeFlush != null) {
        try {
          final success = await onBeforeFlush!(events);
          if (success) {
            unawaited(flush());
          }
        } catch (e) {
          debugPrint(
              '${runtimeType.toString()} Error in callback: $e, skipping flush');
        }
      } else {
        // No callback, proceed with normal flush
        unawaited(flush());
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
