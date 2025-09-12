import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class AppModuleInjection {
  static void inject() {
    InjectionUtils.registerOtherClass<DeviceInfoManager>(DeviceInfoManager.new);
    InjectionUtils.registerOtherClass<SharedPreferencesManager>(
        SharedPreferencesManager.new);
    InjectionUtils.registerOtherClass<LocalStorageManager>(() =>
        LocalStorageManager(
            InjectionUtils.getOtherClass<SharedPreferencesManager>()));
    InjectionUtils.registerOtherClass<SessionManager>(() =>
        SessionManager(InjectionUtils.getOtherClass<LocalStorageManager>()));
    InjectionUtils.registerOtherClass<DataSource>(() => DataSourceImpl(
        InjectionUtils.getOtherClass<LocalStorageManager>(),
        InjectionUtils.getOtherClass<SessionManager>()));
    InjectionUtils.registerOtherClass<NavigationService>(
        () => NavigationServiceImpl(exNavigatorKey));
    InjectionUtils.registerOtherClass<RouteManagement>(() =>
        RouteManagement(InjectionUtils.getOtherClass<NavigationService>()));
  }
}
