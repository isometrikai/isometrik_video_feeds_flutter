import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

part 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router = GoRouter(
    initialLocation: AppRoutes.cameraView,
    navigatorKey: kNavigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.cameraView,
        name: RouteNames.cameraView,
        builder: (_, state) => CameraView(),
      ),
    ],
  );
}
