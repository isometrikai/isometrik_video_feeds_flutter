import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class AppModuleInjection {
  static void inject() {
    InjectionUtils.registerOtherClass<IsrSharedPreferencesManager>(IsrSharedPreferencesManager.new);
    InjectionUtils.registerOtherClass<IsrLocalStorageManager>(
        () => IsrLocalStorageManager(InjectionUtils.getOtherClass<IsrSharedPreferencesManager>()));
    InjectionUtils.registerOtherClass<DataSource>(
        () => DataSourceImpl(InjectionUtils.getOtherClass<IsrLocalStorageManager>()));
    InjectionUtils.registerOtherClass<IsrNavigationService>(() => IsrNavigationServiceImpl(ismNavigatorKey));
    InjectionUtils.registerOtherClass<IsrRouteManagement>(
        () => IsrRouteManagement(InjectionUtils.getOtherClass<IsrNavigationService>()));
  }
}
