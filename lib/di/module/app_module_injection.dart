import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class AppModuleInjection {
  static void inject() {
    IsmInjectionUtils.registerOtherClass<DeviceInfoManager>(DeviceInfoManager.new);
    IsmInjectionUtils.registerOtherClass<SharedPreferencesManager>(SharedPreferencesManager.new);
    IsmInjectionUtils.registerOtherClass<LocalStorageManager>(
        () => LocalStorageManager(IsmInjectionUtils.getOtherClass<SharedPreferencesManager>()));
    IsmInjectionUtils.registerOtherClass<DataSource>(
        () => DataSourceImpl(IsmInjectionUtils.getOtherClass<LocalStorageManager>()));
    IsmInjectionUtils.registerOtherClass<IsrNavigationService>(
        () => IsrNavigationServiceImpl(ismNavigatorKey));
    IsmInjectionUtils.registerOtherClass<IsrRouteManagement>(
        () => IsrRouteManagement(IsmInjectionUtils.getOtherClass<IsrNavigationService>()));
  }
}
