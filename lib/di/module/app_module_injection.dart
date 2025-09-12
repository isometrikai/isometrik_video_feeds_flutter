import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class AppModuleInjection {
  static void inject() {
    IsmInjectionUtils.registerOtherClass<IsrSharedPreferencesManager>(
        IsrSharedPreferencesManager.new);
    IsmInjectionUtils.registerOtherClass<IsrLocalStorageManager>(() =>
        IsrLocalStorageManager(
            IsmInjectionUtils.getOtherClass<IsrSharedPreferencesManager>()));
    IsmInjectionUtils.registerOtherClass<DataSource>(() => DataSourceImpl(
        IsmInjectionUtils.getOtherClass<IsrLocalStorageManager>()));
    IsmInjectionUtils.registerOtherClass<IsrNavigationService>(
        () => IsrNavigationServiceImpl(ismNavigatorKey));
    IsmInjectionUtils.registerOtherClass<IsrRouteManagement>(() =>
        IsrRouteManagement(
            IsmInjectionUtils.getOtherClass<IsrNavigationService>()));
  }
}
