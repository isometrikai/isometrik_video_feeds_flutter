import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

class IsrNavigationServiceImpl implements IsrNavigationService {
  IsrNavigationServiceImpl(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<T?> pushNamed<T>(BuildContext context, String routeName, {Object? arguments}) async {
    final result = await IsrVideoReelConfig.buildContext?.pushNamed(routeName, extra: arguments);
    return result as T?; // Cast the result to the expected type
  }

  @override
  void pushReplacementNamed<T>(BuildContext context, String routeName, {Object? arguments}) async {
    IsrVideoReelConfig.buildContext?.pushReplacementNamed(routeName, extra: arguments);
  }

  @override
  void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }

  @override
  void popUntil(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  @override
  void goNamed(BuildContext context, String routeName, {Object? arguments}) {
    IsrVideoReelConfig.buildContext?.goNamed(routeName, extra: arguments);
  }

  @override
  void go(BuildContext context, String routeName, {Object? arguments}) {
    IsrVideoReelConfig.buildContext?.go(
      routeName,
      extra: arguments,
    );
  }
}
