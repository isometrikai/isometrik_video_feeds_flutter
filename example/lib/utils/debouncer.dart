import 'dart:async';

import 'package:flutter/material.dart';

/// Class to call the api after specific amount of time
class DeBouncer {
  DeBouncer({this.duration});

  VoidCallback? action;
  Timer? _timer;
  final Duration? duration;

  void run(VoidCallback action) {
    if (null != _timer) {
      _timer!.cancel();
    }
    _timer = Timer(duration ?? const Duration(milliseconds: 750), action);
  }
}
