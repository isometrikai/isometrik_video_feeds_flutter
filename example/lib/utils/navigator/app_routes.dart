part of 'app_router.dart';

class AppRoutes {
  const AppRoutes._();
  static const String splash = '/splash';
  static const String login = '/${RouteNames.login}';
  static const String otp = '/${RouteNames.otp}';
  static const String landingView = '/${RouteNames.landingView}';
  static const String home = '$landingView/${RouteNames.home}';
  static const String cameraView = '/${RouteNames.cameraView}';
  static const String profileView = '$landingView/${RouteNames.profileView}';
  static const String postView = '/${RouteNames.postView}';
  static const String videoTrimView = '/${RouteNames.videoTrimView}';
  static const String postAttributeView = '/${RouteNames.postAttributeView}';
  static const String createPostView = '/${RouteNames.createPostView}';
  static const String tagPeopleScreen = '/${RouteNames.tagPeopleScreen}';
  static const String searchUserScreen = '/${RouteNames.searchUserScreen}';
  static const String searchLocationScreen = '/${RouteNames.searchLocationScreen}';
}

class RouteNames {
  RouteNames._();
  static const String login = 'loginView';
  static const String otp = 'otpView';
  static const String home = 'homeView';
  static const String profileView = 'profileView';
  static const String landingView = 'landingView';
  static const String cameraView = 'CameraView';
  static const String postView = 'postView';
  static const String videoTrimView = 'videoTrimView';
  static const String postAttributeView = 'postAttributeView';
  static const String createPostView = 'createPostView';
  static const String tagPeopleScreen = 'tagPeopleScreen';
  static const String searchUserScreen = 'searchUserScreen';
  static const String searchLocationScreen = 'searchLocationScreen';
}
