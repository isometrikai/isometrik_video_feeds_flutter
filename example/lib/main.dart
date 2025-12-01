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
  final appVersion = await Utility.getAppVersion();
  await isr.IsrVideoReelConfig.initializeSdk(
    baseUrl: AppUrl.appBaseUrl,
    userInfoClass: isr.UserInfoClass(
      userId: userId,
      userName: userName,
      firstName: firstName,
      lastName: lastName,
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
          BlocProvider(create: (context) => InjectionUtils.getBloc<CreatePostBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<NavItemCubit>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<ProfileBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<UploadProgressCubit>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<CommentActionCubit>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<SearchUserBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<SearchLocationBloc>()),
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
