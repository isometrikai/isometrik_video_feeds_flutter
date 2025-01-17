import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

part 'isr_app_routes.dart';

class IsrAppRouter {
  IsrAppRouter._();

  static GoRouter router = GoRouter(
    initialLocation: IsrAppRoutes.postView,
    navigatorKey: ismNavigatorKey,
    routes: [
      GoRoute(
        path: IsrAppRoutes.landingView,
        name: IsrRouteNames.landingView,
        builder: (_, state) => IsrReelView(isFromExample: true),
      ),
      GoRoute(
        path: IsrAppRoutes.cameraView,
        name: IsrRouteNames.cameraView,
        builder: (_, state) => IsmCameraView(),
      ),
      GoRoute(
        path: IsrAppRoutes.postView,
        name: IsrRouteNames.postView,
        builder: (_, __) => const IsrPostView(),
      ),
      GoRoute(
        path: IsrAppRoutes.postAttributeView,
        name: IsrRouteNames.postAttributeView,
        builder: (_, state) {
          final extraMap = state.extra as Map;
          return IsrPostAttributeView(
            postAttributeClass: extraMap['postAttributeClass'] as PostAttributeClass?,
          );
        },
      ),
    ],
  );
}
