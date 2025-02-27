import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  configureInjection();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => InjectionUtils.getBloc<SplashBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<AuthBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<HomeBloc>()),
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
