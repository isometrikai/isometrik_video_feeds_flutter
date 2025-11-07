import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'isr_app_routes.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

class IsrAppRouter {
  IsrAppRouter._();

  static late final GoRouter _router;

  static GoRouter get router => _router;

  static void initializeRouter() {
    _router = GoRouter(
      navigatorKey: ismNavigatorKey,
      initialLocation: IsrAppRoutes.postListingScreen,
      routes: getRoutes(),
    );
  }

  static List<RouteBase> getRoutes() => [
        GoRoute(
          path: IsrAppRoutes.postView,
          name: IsrRouteNames.postView,
          builder: (_, __) => const SizedBox(),
        ),
        // GoRoute(
        //   path: IsrAppRoutes.createPostView,
        //   name: IsrRouteNames.createPostView,
        //   builder: (context, __) => const IsmCreatePostView(),
        // ),
        // GoRoute(
        //   path: IsrAppRoutes.landingView,
        //   name: IsrRouteNames.landingView,
        //   builder: (_, state) => IsrReelView(isFromExample: true),
        // ),
        // GoRoute(
        //   path: IsrAppRoutes.cameraView,
        //   name: IsrRouteNames.cameraView,
        //   builder: (_, state) {
        //     final extras = state.extra as Map<String, dynamic>;
        //     final mediaType = extras['mediaType'] as MediaType? ?? MediaType.photo;
        //     return IsmCameraView(mediaType: mediaType);
        //   },
        // ),
        // GoRoute(
        //   path: IsrAppRoutes.postAttributeView,
        //   name: IsrRouteNames.postAttributeView,
        //   builder: (_, state) {
        //     final extraMap = state.extra as Map;
        //     return IsrPostAttributeView(
        //       postAttributeClass: extraMap['postAttributeClass'] as PostAttributeClass?,
        //     );
        //   },
        // ),
        GoRoute(
          path: IsrAppRoutes.postListingScreen,
          name: IsrRouteNames.postListingScreen,
          pageBuilder: (context, state) {
            final extraMap = state.extra as Map? ?? {};
            final tagValue = extraMap['tagValue'] as String;
            final tagType = extraMap['tagType'] as TagType;
            return IsmPageTransition(
              child: PostListingView(
                tagValue: tagValue,
                tagType: tagType,
              ),
              transitionType: TransitionType.rightToLeft,
            );
          },
        ),
        GoRoute(
          path: IsrAppRoutes.placeDetailsView,
          name: IsrRouteNames.placeDetailsView,
          pageBuilder: (context, state) {
            final extraMap = state.extra as Map;
            final placeId = extraMap['placeId'] as String;
            final placeName = extraMap['placeName'] as String;
            final lat = extraMap['lat'] as double;
            final long = extraMap['long'] as double;
            return IsmPageTransition(
              child: PlaceDetailsView(
                placeId: placeId,
                placeName: placeName,
                latitude: lat,
                longitude: long,
              ),
              transitionType: TransitionType.rightToLeft,
            );
          },
        ),
      ];
}
