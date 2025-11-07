// lib/di/module/bloc_injection.dart

import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';

/// A class responsible for injecting Bloc dependencies into the service locator.
class BlocInjection {
  /// Registers all Bloc implementations with the dependency injection container.
  static void inject() {
    final localDataUseCase = IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>();

    // Check if IsmLandingBloc is already registered
    IsmInjectionUtils.registerBloc<IsmLandingBloc>(
      IsmLandingBloc.new,
    );

    // Check if PostBloc is already registered
    IsmInjectionUtils.registerBloc<SocialPostBloc>(
      () => SocialPostBloc(localDataUseCase),
    );
  }
}
