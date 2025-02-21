import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

class IsrRouteManagement {
  IsrRouteManagement(this._navigationService);

  final IsrNavigationService _navigationService;

  void goToPostView() {
    _navigationService.go(IsrAppRoutes.postView);
  }

  Future<Map<String, dynamic>?> goToCameraView() async {
    final result = await _navigationService.pushNamed(IsrRouteNames.cameraView) as Map<String, dynamic>;
    return result;
  }

  void goToPostAttributeView({PostAttributeClass? postAttributeClass}) {
    ismNavigatorKey.currentContext!.pushNamed(
      IsrRouteNames.postAttributeView,
      extra: {
        'postAttributeClass': postAttributeClass,
      },
    );
  }

  Future<PostAttributeClass?> goToVideoTrimView({required PostAttributeClass postAttributeClass}) async =>
      await _navigationService.pushNamed<PostAttributeClass>(
        IsrRouteNames.videoTrimView,
        arguments: {
          'postAttributeClass': postAttributeClass,
        },
      );
}
