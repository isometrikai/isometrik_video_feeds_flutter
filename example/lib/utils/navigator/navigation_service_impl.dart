import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class NavigationServiceImpl implements NavigationService {
  NavigationServiceImpl(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) async {
    final result = await navigatorKey.currentContext!
        .pushNamed(routeName, extra: arguments);
    return result as T?; // Cast the result to the expected type
  }

  @override
  void pushReplacementNamed<T>(String routeName, {Object? arguments}) async {
    navigatorKey.currentContext!
        .pushReplacementNamed(routeName, extra: arguments);
  }

  @override
  void pop([Object? result]) {
    Navigator.pop(navigatorKey.currentContext!, result);
  }

  @override
  void popUntil(String routeName, {Object? arguments}) {
    Navigator.popUntil(
        navigatorKey.currentContext!, ModalRoute.withName(routeName));
  }

  @override
  void goNamed(String routeName, {Object? arguments}) {
    navigatorKey.currentContext!.goNamed(routeName, extra: arguments);
  }

  @override
  void go(String routeName, {Object? arguments}) {
    navigatorKey.currentContext!.go(
      routeName,
      extra: arguments,
    );
  }
}
