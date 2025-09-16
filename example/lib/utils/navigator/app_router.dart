import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/main.dart';
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
              mobile: mobileNumber,
              countryCode: countryCode,
              loginType: loginType,
              otpId: otpId);
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
          final mediaType =
              extras['mediaType'] as MediaType? ?? MediaType.photo;
          return CameraView(mediaType: mediaType);
        },
      ),
      GoRoute(
        path: AppRoutes.postAttributeView,
        name: RouteNames.postAttributeView,
        builder: (_, state) {
          final extraMap = state.extra as Map;
          return PostAttributeView(
            postAttributeClass:
                extraMap['postAttributeClass'] as PostAttributeClass?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.searchUserScreen,
        name: RouteNames.searchUserScreen,
        pageBuilder: (context, state) {
          final extraMap = state.extra as Map;
          final socialUserList =
              extraMap['socialUserList'] as List<SocialUserData>? ?? [];
          return PageTransition(
            child: SearchUserView(socialUserList: socialUserList),
            transitionType: TransitionType.rightToLeft,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tagPeopleScreen,
        name: RouteNames.tagPeopleScreen,
        pageBuilder: (context, state) {
          final extraMap = state.extra as Map;
          final postAttributeClass =
              extraMap['postAttributeClass'] as PostAttributeClass;
          return PageTransition(
            child: TagPeopleScreen(postAttributeClass: postAttributeClass),
            transitionType: TransitionType.rightToLeft,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.searchLocationScreen,
        name: RouteNames.searchLocationScreen,
        pageBuilder: (context, state) => PageTransition(
          child: const SearchLocationScreen(),
          transitionType: TransitionType.rightToLeft,
        ),
      ),
      GoRoute(
        path: RouteNames.imageEditorView,
        name: RouteNames.imageEditorView,
        pageBuilder: (context, state) => PageTransition(
          child: ImageEditorView(imagePath: state.extra as String),
          transitionType: TransitionType.rightToLeft,
        ),
      ),
      GoRoute(
        path: RouteNames.videoEditorView,
        name: RouteNames.videoEditorView,
        pageBuilder: (context, state) => PageTransition(
          child: VideoEditorView(videoPath: state.extra as String),
          transitionType: TransitionType.rightToLeft,
        ),
      ),
      GoRoute(
        path: RouteNames.cameraPickerView,
        name: RouteNames.cameraPickerView,
        pageBuilder: (context, state) => PageTransition(
          transitionType: TransitionType.rightToLeft,
          child: const SizedBox(),
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
