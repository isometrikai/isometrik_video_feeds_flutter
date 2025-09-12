import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    InjectionUtils.getBloc<SplashBloc>().add(InitializeSplash());
  }

  @override
  Widget build(BuildContext context) => BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashCompleted) {
            if (state.isLoggedIn) {
              InjectionUtils.getCubit<NavItemCubit>()
                  .onTap(NavbarType.home, isFirstTime: true);
            } else {
              InjectionUtils.getRouteManagement().goToLoginScreen();
            }
          }
        },
        child: Scaffold(
          body: BlocBuilder<SplashBloc, SplashState>(
            builder: (context, state) {
              if (state is SplashError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add your logo or branding here
                    AppImage.svg(AssetConstants.icAppLogo),
                    SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      );
}
