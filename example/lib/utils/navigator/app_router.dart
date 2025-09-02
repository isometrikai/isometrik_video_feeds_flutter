import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/example_export.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

part 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: exNavigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        builder: (_, __) => LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: RouteNames.otp,
        builder: (_, state) {
          final extras = state.extra as Map<String, dynamic>;
          final mobileNumber = extras['mobileNumber'] as String;
          final otpId = extras['otpId'] as String;
          final countryCode = extras['countryCode'] as String;
          final loginType = extras['loginType'] as String;
          return OtpScreen(
              mobile: mobileNumber, countryCode: countryCode, loginType: loginType, otpId: otpId);
        },
      ),
      // GoRoute(
      //   path: AppRoutes.home,
      //   name: RouteNames.home,
      //   builder: (_, __) => const HomeScreen(),
      // ),
      GoRoute(
        path: AppRoutes.createPostView,
        name: RouteNames.createPostView,
        pageBuilder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final postData = extras['postData'] as TimeLineData?;
          return PageTransition(
            child: CreatePostView(postData: postData),
            transitionType: TransitionType.bottomToTop,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cameraView,
        name: RouteNames.cameraView,
        builder: (_, state) {
          final extras = state.extra as Map<String, dynamic>;
          final mediaType = extras['mediaType'] as MediaType? ?? MediaType.photo;
          return CameraView(mediaType: mediaType);
        },
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
      GoRoute(
        path: AppRoutes.searchUserScreen,
        name: RouteNames.searchUserScreen,
        pageBuilder: (context, state) => PageTransition(
          child: SearchUserView(),
          transitionType: TransitionType.rightToLeft,
        ),
      ),
      ..._landingRoutes,
    ],
  );

  static final List<RouteBase> _landingRoutes = [
    ShellRoute(
      navigatorKey: shallNavigatorKey,
      builder: (_, state, child) {
        final data = state.extra as Map? ?? {};
        final title = data['title'] as String? ?? '';
        return LandingView(title: title, child: child);
      },
      routes: [
        GoRoute(
          name: RouteNames.home,
          path: AppRoutes.home,
          pageBuilder: (_, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
          routes: [],
        ),
        GoRoute(
          name: RouteNames.profileView,
          path: AppRoutes.profileView,
          pageBuilder: (_, __) => NoTransitionPage(child: ProfileView()),
          routes: [],
        ),
      ],
    ),
  ];
}
