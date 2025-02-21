// lib/di/module/bloc_injection.dart

import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

/// A class responsible for injecting Bloc dependencies into the service locator.
class BlocInjection {
  /// Registers all Bloc implementations with the dependency injection container.
  static void inject() {
    final _localDataUseCase = InjectionUtils.getUseCase<LocalDataUseCase>();

    InjectionUtils.registerBloc<AuthBloc>(() => AuthBloc(
          InjectionUtils.getUseCase<LoginUseCase>(),
          InjectionUtils.getUseCase<VerifyOtpUseCase>(),
          InjectionUtils.getUseCase<GuestLoginUseCase>(),
          _localDataUseCase,
        ));

    InjectionUtils.registerBloc<SplashBloc>(() => SplashBloc(_localDataUseCase));
    InjectionUtils.registerBloc<HomeBloc>(() => HomeBloc(_localDataUseCase));
  }
}
