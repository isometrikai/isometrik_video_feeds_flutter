// lib/di/module/repository_injection.dart

import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

/// A class responsible for injecting repository dependencies into the service locator.
class RepositoryInjection {
  /// Registers all repository implementations with the dependency injection container.
  static void inject() {
    final dataSource = IsmInjectionUtils.getOtherClass<DataSource>();

    // Retrieve the data source instance from the service locator
    final localStorageManager =
        IsmInjectionUtils.getOtherClass<LocalStorageManager>();

    // Register the repositories with their respective implementations
    IsmInjectionUtils.registerRepo<IsrLocalStorageRepository>(
        () => IsrLocalStorageRepositoryImpl(localStorageManager));

    IsmInjectionUtils.registerRepo<SocialRepository>(() => SocialRepositoryImpl(
        IsmInjectionUtils.getApiService<SocialApiService>(), dataSource));
    IsmInjectionUtils.registerRepo<GoogleRepository>(() => GoogleRepositoryImpl(
        IsmInjectionUtils.getApiService<GoogleApiService>()));
  }
}
