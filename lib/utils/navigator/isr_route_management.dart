import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

class IsrRouteManagement {
  IsrRouteManagement(this._navigationService);

  final IsrNavigationService _navigationService;

  void goToPostView({required BuildContext context}) {
    _navigationService.go(context, IsrAppRoutes.postView);
  }

  Future<MediaInfoClass?> goToCameraView({required BuildContext context, MediaType mediaType = MediaType.photo}) async {
    final result = await _navigationService.pushNamed(
      context,
      IsrRouteNames.cameraView,
      arguments: {'mediaType': mediaType},
    ) as MediaInfoClass?;
    return result;
  }

  void goToCreatePostView() {
    _navigationService.pushNamed(
      IsrVideoReelConfig.buildContext!,
      IsrRouteNames.createPostView,
    );
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
