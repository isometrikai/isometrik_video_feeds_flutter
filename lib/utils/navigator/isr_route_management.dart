import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

class RouteManagement {
  RouteManagement._();

  static void goToPostView() {
    ismNavigatorKey.currentContext?.go(IsrAppRoutes.postView);
  }

  static Future<Map<String, dynamic>?> goToCameraView() async {
    final result = ismNavigatorKey.currentContext?.pushNamed<Map<String, dynamic>>(IsrRouteNames.cameraView);
    return result;
  }

  static void goToPostAttributeView({PostAttributeClass? postAttributeClass}) {
    ismNavigatorKey.currentContext!.pushNamed(
      IsrRouteNames.postAttributeView,
      extra: {
        'postAttributeClass': postAttributeClass,
      },
    );
  }

  static Future<PostAttributeClass?> goToVideoTrimView({required PostAttributeClass postAttributeClass}) async =>
      await ismNavigatorKey.currentContext!.pushNamed<PostAttributeClass>(
        IsrRouteNames.videoTrimView,
        extra: {
          'postAttributeClass': postAttributeClass,
        },
      );
}
