import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

part 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router = GoRouter(
    initialLocation: AppRoutes.landingView,
    navigatorKey: ismNavigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.landingView,
        name: RouteNames.landingView,
        builder: (_, state) => const IsmLandingView(isFromExample: true),
      ),
      GoRoute(
        path: AppRoutes.cameraView,
        name: RouteNames.cameraView,
        builder: (_, state) => IsmCameraView(),
      ),
      GoRoute(
        path: AppRoutes.postView,
        name: RouteNames.postView,
        builder: (_, __) => const IsmPostView(),
      ),
      GoRoute(
        path: AppRoutes.postAttributeView,
        name: RouteNames.postAttributeView,
        builder: (_, state) {
          final extraMap = state.extra as Map;
          return PostAttributeView(
            postAttributeClass: extraMap['postAttributeClass'] as PostAttributeClass?,
          );
        },
      ),
    ],
  );
}
