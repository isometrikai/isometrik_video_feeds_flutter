import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

class RouteManagement {
  RouteManagement._();

  static Future<Map<String, dynamic>?> goToCameraView() async {
    final result = kNavigatorKey.currentContext!.pushNamed<Map<String, dynamic>>(RouteNames.cameraView);
    return result;
  }

  static void goToPostAttributeView({PostAttributeClass? postAttributeClass}) {
    kNavigatorKey.currentContext!.pushNamed(
      RouteNames.postAttributeView,
      extra: {
        'postAttributeClass': postAttributeClass,
      },
    );
  }

  static Future<PostAttributeClass?> goToVideoTrimView({required PostAttributeClass postAttributeClass}) async =>
      await kNavigatorKey.currentContext!.pushNamed<PostAttributeClass>(
        RouteNames.videoTrimView,
        extra: {
          'postAttributeClass': postAttributeClass,
        },
      );
}
