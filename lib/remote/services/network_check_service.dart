import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkCheckService {
  NetworkCheckService() {
    _connectivity.onConnectivityChanged.listen((result) {
      _controller.add(result.isNotEmpty && result.first != ConnectivityResult.none);
    });
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController.broadcast();

  Stream<bool> get isConnected => _controller.stream;

  void dispose() {
    _controller.close();
  }
}
