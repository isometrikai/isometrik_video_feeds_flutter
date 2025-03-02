// lib/di/module/use_case_injection.dart

import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

/// A class responsible for injecting use case dependencies into the service locator.
class UseCaseInjection {
  /// Registers all use case implementations with the dependency injection container.
  static void inject() {
    // Register use cases with their respective repositories

    IsmInjectionUtils.registerUseCase<LocalDataUseCase>(
        () => LocalDataUseCase(IsmInjectionUtils.getRepo<IsrLocalStorageRepository>()));
  }
}
