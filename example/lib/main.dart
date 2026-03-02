import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

export 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  configureInjection();
  await _initializeReelsSdk();
  runApp(MyApp());
}

Future<void> _initializeReelsSdk() async {
  final _localDataUseCase = InjectionUtils.getUseCase<LocalDataUseCase>();
  final accessToken = await _localDataUseCase.getAccessToken();
  final userId = await _localDataUseCase.getUserId();
  final userName = await _localDataUseCase.getFirstName();
  final firstName = await _localDataUseCase.getFirstName();
  final lastName = await _localDataUseCase.getLastName();
  final profilePic = await _localDataUseCase.getProfilePic();
  final email = await _localDataUseCase.getEmail();
  final dialCode = await _localDataUseCase.getDialCode();
  final mobileNumber = await _localDataUseCase.getPhoneNumber();
  final appVersion = await Utility.getAppVersion();
  await isr.IsrVideoReelConfig.initializeSdk(
    baseUrl: AppUrl.appBaseUrl,
    gumletUrl: AppUrl.gumletUrl,
    postConfig: const isr.PostConfig(
      autoMoveToNextMedia: true,
      autoMoveToNextPost: true,
    ),
    tabConfig: const isr.TabConfig(),
    createEditPostConfig: const isr.CreateEditPostConfig(),
    userInfoClass: isr.UserInfoClass(
      userId: userId,
      userName: userName,
      firstName: firstName,
      lastName: lastName,
      profilePic: profilePic,
      email: email,
      dialCode: dialCode,
      mobileNumber: mobileNumber,
    ),
    rudderStackDataPlaneUrl: 'https://houseofappobxa.dataplane.rudderstack.com',
    rudderStackWriteKey: '360M58NTcDMelJWL0b5F4hYE4av',
    googleServiceJsonPath: AssetConstants.googleServiceJson,
    getCurrentBuildContext: () => exNavigatorKey.currentContext,
    defaultHeaders: {
      'Authorization': accessToken,
      'Accept': 'application/json',
      'Content-Type': AppConstants.headerContentType,
      'lan': 'en',
      'city': 'Bengaluru',
      'state': 'karnataka',
      'country': 'India',
      'ipaddress': '192.168.1.1',
      'version': appVersion,
      'currencySymbol': '\$',
      'currencyCode': 'USD',
      'platform': Utility.platFormType().platformText,
      'latitude': DefaultValues.defaultLatitude,
      'longitude': DefaultValues.defaultLongitude,
      'x-tenant-id': AppConstants.tenantId,
      'x-project-id': AppConstants.projectId,
    },
    socialConfig: isr.SocialConfig(
      // Theme Configuration
      themeConfig: isr.ThemeConfig(
        primaryColor: const Color(0xFF006CD8), // Main brand color
        secondaryColor: const Color(0xFF851E91), // Secondary brand color
        scaffoldBackgroundColor: Colors.white, // Background color
        appBarColor: Colors.white, // App bar background
        brightness: Brightness.light, // Light or dark theme
        splashColor: const Color(0xFF006CD8).withValues(alpha: 0.5), // Splash effect color
      ),

      // Toast Configuration
      toastConfig: const isr.ToastConfig(
        backgroundColor: Colors.black87, // Toast background
        textColor: Colors.white, // Toast text color
        gravity: isr.ToastGravityType.bottom, // Position on screen
        duration: Duration(seconds: 3), // How long to show
      ),

      // Dialog Configuration
      dialogConfig: const isr.DialogConfig(
        backgroundColor: Colors.white, // Dialog background
        borderRadius: 12.0, // Rounded corners
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28), // Internal padding
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
        ), // Title text style
        messageTextStyle: TextStyle(
          fontSize: 14,
          color: Color(0xFF4A4A4A),
        ), // Message text style
      ),

      // Button Configurations
      primaryButton: const isr.ButtonConfig(
        backgroundColor: Color(0xFF006CD8), // Button background
        textColor: Colors.white, // Button text color
        borderColor: Colors.transparent, // Stroke color
        borderRadius: 8.0, // Corner radius
        elevation: 0, // Shadow elevation
      ),

      secondaryButton: const isr.ButtonConfig(
        backgroundColor: Colors.transparent, // Button background
        textColor: Color(0xFF006CD8), // Button text color
        borderColor: Color(0xFF006CD8), // Stroke color
        borderRadius: 8.0, // Corner radius
        elevation: 0, // Shadow elevation
      ),

      tertiaryButton: const isr.ButtonConfig(
        backgroundColor: Colors.transparent, // Button background
        textColor: Color(0xFF333333), // Button text color
        borderColor: Color(0xFF006CD8), // Stroke color
        borderRadius: 8.0, // Corner radius
        elevation: 0, // Shadow elevation
      ),

      // Text Size Configuration
      textSizeConfig: const isr.TextSizeConfig(
        textSize8: 8.0, // Very small text
        textSize10: 10.0, // Small text
        textSize12: 12.0, // Small-medium text
        textSize14: 14.0, // Medium text (most common)
        textSize16: 16.0, // Medium-large text
        textSize18: 18.0, // Large text
        textSize20: 20.0, // Extra large text
        textSize22: 22.0, // Headline text
        textSize24: 24.0, // Large headline text
      ),

      // Font Configuration
      fontConfig: const isr.FontConfig(
        primaryFontFamily: 'Inter', // Main font family
        secondaryFontFamily: 'Inter', // Secondary font family
      ),

      // Colors Configuration
      colorsConfig: const isr.ColorsConfig(
        primaryTextColor: Color(0xFF333333), // Main text color
        secondaryTextColor: Color(0xFF505050), // Secondary text color
        buttonBackgroundColor: Color(0xFF006CD8), // Default button background
        buttonDisabledBackgroundColor: Color(0xFF808688), // Disabled button
        buttonTextColor: Colors.white, // Button text color
        dialogColor: Colors.white, // Dialog background
        errorColor: Color(0xFFE30000), // Error/delete actions
        successColor: Color(0xFF00A86B), // Success messages
        white: Colors.white, // White color
        black: Color(0xFF182028), // Black color
        grey: MaterialColor(0xFF829CB6, {
          // Grey shades
          100: Color(0xFFEBF0F5),
          300: Color(0xFFD1DBE6),
          500: Color(0xFF829CB6),
          700: Color(0xFF627B92),
          900: Color(0xFF4C6680),
        }),
        dividerColor: Color(0xFFEFEFEF), // Divider lines
        bottomSheetBackgroundColor: Colors.white, // Bottom sheet background
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => InjectionUtils.getBloc<SplashBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<LandingBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<AuthBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<HomeBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<NavItemCubit>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<ProfileBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<UploadProgressCubit>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<CommentActionCubit>()),
          ...isr.IsrVideoReelConfig.getIsmSingletonBlocProviders(),
        ],
        child: ScreenUtilInit(
          useInheritedMediaQuery: true,
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, child) => child!,
          child: LayoutBuilder(
            builder: (context, constraints) => OrientationBuilder(
              builder: (context, orientation) {
                SizeConfig().init(constraints, orientation);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: Utility.hideKeyboard,
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: appTheme,
                    routerConfig: AppRouter.router,
                  ),
                );
              },
            ),
          ),
        ),
      );
}
