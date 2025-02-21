import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/example_export.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

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
          return OtpScreen(mobile: mobileNumber, countryCode: countryCode, loginType: loginType, otpId: otpId);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: RouteNames.home,
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
}
