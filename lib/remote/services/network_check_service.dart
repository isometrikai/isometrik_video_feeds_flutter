import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkCheckService {
  NetworkCheckService() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _controller
          .add(result.isNotEmpty && result.first != ConnectivityResult.none);
    });
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get isConnected => _controller.stream;

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }
}
