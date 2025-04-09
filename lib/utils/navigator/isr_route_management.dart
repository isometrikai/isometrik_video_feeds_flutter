import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class IsrRouteManagement {
  IsrRouteManagement(this._navigationService);

  final IsrNavigationService _navigationService;

  void goToPostView({required BuildContext context}) {
    _navigationService.go(context, IsrAppRoutes.postView);
  }

  Future<String?> goToCreatePostView() async {
    final result = await _navigationService.pushNamed(
      IsrVideoReelConfig.buildContext!,
      IsrRouteNames.createPostView,
    ) as String?;
    return result;
  }

  // void goToPostAttributeView({required BuildContext context, PostAttributeClass? postAttributeClass}) {
  //   _navigationService.pushNamed(
  //     context,
  //     IsrRouteNames.postAttributeView,
  //     arguments: {
  //       'postAttributeClass': postAttributeClass,
  //     },
  //   );
  // }
}
