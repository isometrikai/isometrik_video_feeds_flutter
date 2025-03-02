// lib/di/module/repository_injection.dart

import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

/// A class responsible for injecting repository dependencies into the service locator.
class RepositoryInjection {
  /// Registers all repository implementations with the dependency injection container.
  static void inject() {
    // Retrieve the data source instance from the service locator
    final dataSource = IsmInjectionUtils.getOtherClass<DataSource>();
    final localStorageManager = IsmInjectionUtils.getOtherClass<IsrLocalStorageManager>();

    // Register the repositories with their respective implementations
    IsmInjectionUtils.registerRepo<IsrLocalStorageRepository>(() => IsrLocalStorageRepositoryImpl(localStorageManager));
  }
}
