import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

part 'ex_app_routes.dart';

class ExAppRouter {
  ExAppRouter._();

  static GoRouter router = GoRouter(
    initialLocation: ExAppRoutes.postView,
    navigatorKey: ismNavigatorKey,
    routes: [
      GoRoute(
        path: ExAppRoutes.postView,
        name: ExAppRoutes.postView,
        builder: (_, __) => const IsrPostView(),
      ),
    ],
  );
}
