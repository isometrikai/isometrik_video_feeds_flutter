import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/export.dart';

void main() {
  _initializeReelsSdk();
  runApp(const MyApp());
}

void _initializeReelsSdk() async {
  IsmVideoReelConfig.initializeSdk(
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
  String _platformVersion = 'Unknown';
  final _ismVideoReelPlayerPlugin = IsmVideoReelPlayer();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _ismVideoReelPlayerPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
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
              SizeConfig().init(constraints, orientation);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: Utility.hideKeyboard,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: kTheme,
                  routerConfig: AppRouter.router,
                ),
              );
            },
          ),
        ),
      );
}
