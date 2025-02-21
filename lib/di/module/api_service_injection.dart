// lib/di/module/api_service_injection.dart

import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// A class responsible for injecting API service dependencies into the service locator.
class ApiServiceInjection {
  /// Registers all API service implementations with the dependency injection container.
  static void inject() {
    // Create instances of network clients with base URLs
    final networkClient = NetworkClient(baseUrl: AppUrl.appBaseUrl);
    final _localStorageManager = InjectionUtils.getOtherClass<IsrLocalStorageManager>();

    // Register the API services with their respective providers
    InjectionUtils.registerApiService<PostApiService>(() => PostApiServiceProvider(networkClient: networkClient));
  }
}
