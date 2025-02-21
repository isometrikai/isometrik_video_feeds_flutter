import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

final GlobalKey<NavigatorState> exNavigatorKey = GlobalKey<NavigatorState>();

class RouteManagement {
  RouteManagement(this._navigationService);

  final NavigationService _navigationService;
  void goToPostView() {
    _navigationService.go(RouteNames.postView);
  }

  void goToLoginScreen() {
    _navigationService.goNamed(RouteNames.login);
  }

  void goToOtpScreen({Object? arguments}) {
    _navigationService.pushNamed(RouteNames.otp, arguments: arguments);
  }

  void goToHomeScreen() {
    _navigationService.goNamed(RouteNames.home);
  }
}
