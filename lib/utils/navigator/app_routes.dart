part of 'app_router.dart';

class AppRoutes {
  const AppRoutes._();
  static const String cameraView = '/${RouteNames.cameraView}';
  static const String postView = '/${RouteNames.postView}';
  static const String videoTrimView = '/${RouteNames.videoTrimView}';
  static const String postAttributeView = '/${RouteNames.postAttributeView}';
}

class RouteNames {
  RouteNames._();
  static const String cameraView = 'CameraView';
  static const String postView = 'postView';
  static const String videoTrimView = 'videoTrimView';
  static const String postAttributeView = 'postAttributeView';
}
