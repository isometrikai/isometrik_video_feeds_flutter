// lib/di/module/repository_injection.dart

import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';

/// A class responsible for injecting repository dependencies into the service locator.
class RepositoryInjection {
  /// Registers all repository implementations with the dependency injection container.
  static void inject() {
    // Retrieve the data source instance from the service locator
    final dataSource = InjectionUtils.getOtherClass<DataSource>();
    final sessionManager = InjectionUtils.getOtherClass<SessionManager>();
    final _localStorageManager = InjectionUtils.getOtherClass<LocalStorageManager>();

    InjectionUtils.registerRepo<LocalStorageRepository>(
        () => LocalStorageRepositoryImpl(_localStorageManager));
    InjectionUtils.registerRepo<AuthRepository>(() => AuthRepositoryImpl(
        InjectionUtils.getApiService<AuthApiService>(), dataSource, sessionManager));
    InjectionUtils.registerRepo<PostRepository>(
        () => PostRepositoryImpl(InjectionUtils.getApiService<PostApiService>(), dataSource));
    InjectionUtils.registerRepo<SocialRepository>(
        () => SocialRepositoryImpl(InjectionUtils.getApiService<SocialApiService>(), dataSource));
    InjectionUtils.registerRepo<GoogleRepository>(
        () => GoogleRepositoryImpl(InjectionUtils.getApiService<GoogleApiService>()));
  }
}
