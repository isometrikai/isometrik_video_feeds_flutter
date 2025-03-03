import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

final GlobalKey<NavigatorState> exNavigatorKey = GlobalKey<NavigatorState>();

class RouteManagement {
  RouteManagement(this._navigationService);

  final NavigationService _navigationService;

  void goToPostView() {
    _navigationService.go(RouteNames.postView);
  }

  void goToHomeScreen() {
    // _navigationService.goNamed(RouteNames.home);
    goToNavItem(NavbarType.home, true);
  }

  void goToNavItem(NavbarType type, bool isFirstTimeVisit) {
    _navigationService.go(type.route, arguments: {
      'title': type.label,
      'isFirstTimeVisit': isFirstTimeVisit,
    });
  }

  Future<void> goToLoginScreen() async {
    _navigationService.goNamed(RouteNames.login);
  }

  void goToOtpScreen({Object? arguments}) {
    _navigationService.pushNamed(RouteNames.otp, arguments: arguments);
  }

  Future<PostDataModel?> goToCreatePostView() async {
    final result = await _navigationService.pushNamed(
      RouteNames.createPostView,
    ) as PostDataModel?;
    return result;
  }

  Future<MediaInfoClass?> goToCameraView({required BuildContext context, MediaType mediaType = MediaType.photo}) async {
    final result = await _navigationService.pushNamed(
      RouteNames.cameraView,
      arguments: {'mediaType': mediaType},
    ) as MediaInfoClass?;
    return result;
  }

  Future<PostAttributeClass?> goToVideoTrimView({
    required BuildContext context,
    required PostAttributeClass postAttributeClass,
  }) async =>
      await _navigationService.pushNamed<PostAttributeClass>(
        RouteNames.videoTrimView,
        arguments: {
          'postAttributeClass': postAttributeClass,
        },
      );
}
