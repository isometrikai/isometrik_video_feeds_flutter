import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

final GlobalKey<NavigatorState> exNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shallNavigatorKey = GlobalKey<NavigatorState>();

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

  Future<String?> goToCreatePostView({TimeLineData? postData}) async {
    final result = await _navigationService
        .pushNamed(RouteNames.createPostView, arguments: {
      'postData': postData,
    }) as String?;
    return result;
  }

  Future<MediaInfoClass?> goToCameraView({
    required BuildContext context,
    MediaType mediaType = MediaType.photo,
  }) async {
    final result = await _navigationService.pushNamed(
      RouteNames.cameraView,
      arguments: {'mediaType': mediaType},
    ) as MediaInfoClass?;
    return result;
  }

  Future<PostAttributeClass?> goToPostAttributionView({
    PostAttributeClass? postAttributeClass,
  }) async =>
      await _navigationService.pushNamed<PostAttributeClass>(
        RouteNames.postAttributeView,
        arguments: {
          'postAttributeClass': postAttributeClass,
        },
      );

  Future<PostAttributeClass?> goToTagPeopleScreen({
    PostAttributeClass? postAttributeClass,
  }) async =>
      await _navigationService.pushNamed<PostAttributeClass>(
        RouteNames.tagPeopleScreen,
        arguments: {
          'postAttributeClass': postAttributeClass,
        },
      );

  Future<List<dynamic>> goToSearchUserScreen(
      {List<SocialUserData>? socialUserList}) async {
    final result = await _navigationService.pushNamed(
        RouteNames.searchUserScreen,
        arguments: {'socialUserList': socialUserList}) as List<dynamic>?;
    return result == null ? [] : result;
  }

  Future<List<TaggedPlace>?> goToSearchLocationScreen() async {
    final result =
        await _navigationService.pushNamed(RouteNames.searchLocationScreen);
    return result as List<TaggedPlace>?;
  }

  Future<XFile?> goToImageEditorView({required String filePath}) async =>
      await _navigationService.pushNamed(
        RouteNames.imageEditorView,
        arguments: filePath,
      );

  Future<String?> goToVideoEditorView({required String filePath}) async =>
      await _navigationService.pushNamed(
        RouteNames.videoEditorView,
        arguments: filePath,
      );

  Future<XFile?> goToCameraRecordingScreen() =>
      _navigationService.pushNamed(RouteNames.cameraRecordingScreen);
}
