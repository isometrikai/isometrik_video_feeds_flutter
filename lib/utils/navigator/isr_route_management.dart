import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsrRouteManagement {
  IsrRouteManagement(this._navigationService);

  final IsrNavigationService _navigationService;

  void goToPostView({required BuildContext context}) {
    _navigationService.go(context, IsrAppRoutes.postView);
  }

  Future<String?> goToCreatePostView() async {
    final result = await _navigationService.pushNamed(
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

  Future<void> goToPlaceDetailsView({
    required String placeId,
    required String placeName,
    double? lat,
    double? long,
  }) async {
    await _navigationService.pushNamed(
      IsrRouteNames.placeDetailsView,
      arguments: {
        'placeId': placeId,
        'placeName': placeName,
        'lat': lat,
        'long': long,
      },
    );
  }

  Future<void> goToTagDetailsView({required String tagValue, required TagType tagType}) async {
    await _navigationService.pushNamed(
      IsrRouteNames.tagDetailsView,
      arguments: {'tagValue': tagValue, 'tagType': tagType},
    );
  }

  Future<void> goToPostListingScreen({required String tagValue, required TagType tagType}) async {
    await _navigationService.pushNamed(IsrRouteNames.postListingScreen,
        arguments: {'tagValue': tagValue, 'tagType': tagType});
  }
}
