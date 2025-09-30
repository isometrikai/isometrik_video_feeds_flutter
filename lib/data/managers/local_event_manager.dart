import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/data/data.dart';
import 'package:uuid/uuid.dart';

class EventQueueProvider {
  static final LocalEventQueue instance = LocalEventQueue(
    apiUrl: 'https://yourapi.com/reel-events',
  );
}

class LocalEventQueue with WidgetsBindingObserver {
  LocalEventQueue({
    required this.apiUrl,
    http.Client? client,
  }) : httpClient = client ?? http.Client();
  static const String _boxName = 'local_events';
  static const int _batchSize = 10;

  final String apiUrl;
  final http.Client httpClient;

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

  Future<void> addEvent(Map<String, dynamic> payload) async {
    final box = Hive.box<LocalEvent>(_boxName);

    final event = LocalEvent(
      id: const Uuid().v4(),
      payload: payload,
      timestamp: DateTime.now().toUtc(),
    );

    await box.add(event);

    debugPrint('${runtimeType.toString()} Box payload: ${event.payload}');
    debugPrint('${runtimeType.toString()} Event added: ${event.id}');
    debugPrint('${runtimeType.toString()} Box length: ${box.length}');

    if (box.length >= _batchSize) {
      await flush();
    }
  }

  Future<void> flush() async {
    final box = Hive.box<LocalEvent>(_boxName);
    final events = box.values.toList();

    if (events.isEmpty) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      debugPrint('${runtimeType.toString()} No internet, flush postponed.');
      return;
    }

    final body = events
        .map((e) => {
              'id': e.id,
              'payload': e.payload,
              'timestamp': e.timestamp.toIso8601String(),
            })
        .toList();

    try {
      final response = await httpClient.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await box.clear();
        debugPrint('${runtimeType.toString()} Events flushed successfully!');
      } else {
        debugPrint('${runtimeType.toString()} Server error: ${response.statusCode}');
        await _retryFlush(events);
      }
    } catch (e) {
      debugPrint('${runtimeType.toString()} Error sending events: $e');
      await _retryFlush(events);
    }
  }

  Future<void> _retryFlush(List<LocalEvent> events) async {
    final box = Hive.box<LocalEvent>(_boxName);

    /// remove these 3 lines later
    await box.clear();
    return;

    var delay = 2;
    for (var attempt = 1; attempt <= 3; attempt++) {
      await Future.delayed(Duration(seconds: delay));
      debugPrint('${runtimeType.toString()} Retry attempt $attempt...');

      try {
        final response = await httpClient.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(events
              .map((e) => {
                    'id': e.id,
                    'payload': e.payload,
                    'timestamp': e.timestamp.toIso8601String(),
                  })
              .toList()),
        );

        if (response.statusCode == 200) {
          final box = Hive.box<LocalEvent>(_boxName);
          await box.clear();
          debugPrint('Retry succeeded!');
          return;
        }
      } catch (e) {
        debugPrint('Retry failed: $e');
      }

      delay *= 2; // exponential backoff
    }
    debugPrint('All retries failed. Events kept in local queue.');
  }

  /// cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    httpClient.close();
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
