import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';
import 'package:ism_video_reel_player_example/res/res.dart';

/// A class responsible for injecting API service dependencies into the service locator.
class ApiServiceInjection {
  /// Registers all API service implementations with the dependency injection container.
  static void inject() {
    // Create instances of network clients with base URLs
    final networkClient = NetworkClient(baseUrl: AppUrl.appBaseUrl);
    final deviceInfoManager = InjectionUtils.getOtherClass<DeviceInfoManager>();
    final _localStorageManager = InjectionUtils.getOtherClass<LocalStorageManager>();

    // Register the API services with their respective providers
    InjectionUtils.registerApiService<AuthApiService>(() => AuthApiServiceProvider(deviceInfoManager, networkClient));
  }
}
