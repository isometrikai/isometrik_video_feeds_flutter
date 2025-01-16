import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/export.dart';

void main() async {
  await _initializeReelsSdk();
  runApp(const MyApp());
}

Future<void> _initializeReelsSdk() async {
  await IsmVideoReelConfig.initializeSdk(
    baseUrl: 'https://api-staging.meolaa.com',
    userInfo: UserInfoClass(
      userId: '37483783493',
      userName: 'asjad',
      firstName: 'Asjad',
      lastName: 'Ibrahim',
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
        useInheritedMediaQuery: true,
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) => child!,
        child: LayoutBuilder(
          builder: (context, constraints) => OrientationBuilder(
            builder: (context, orientation) {
              IsrSizeConfig().init(constraints, orientation);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: IsmVideoReelUtility.hideKeyboard,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: isrTheme,
                  routerConfig: IsrAppRouter.router,
                ),
              );
            },
          ),
        ),
      );
}
