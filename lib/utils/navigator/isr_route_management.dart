import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

class IsrRouteManagement {
  IsrRouteManagement(this._navigationService);

  final IsrNavigationService _navigationService;

  void goToPostView({required BuildContext context}) {
    _navigationService.go(context, IsrAppRoutes.postView);
  }

  Future<Map<String, dynamic>?> goToCameraView({required BuildContext context}) async {
    final result = await _navigationService.pushNamed(context, IsrRouteNames.cameraView) as Map<String, dynamic>;
    return result;
  }

  void goToPostAttributeView({required BuildContext context, PostAttributeClass? postAttributeClass}) {
    _navigationService.pushNamed(
      context,
      IsrRouteNames.postAttributeView,
      arguments: {
        'postAttributeClass': postAttributeClass,
      },
    );
  }

  Future<PostAttributeClass?> goToVideoTrimView(
          {required BuildContext context, required PostAttributeClass postAttributeClass}) async =>
      await _navigationService.pushNamed<PostAttributeClass>(
        context,
        IsrRouteNames.videoTrimView,
        arguments: {
          'postAttributeClass': postAttributeClass,
        },
      );
}
