import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';

class AppModuleInjection {
  static void inject() {
    IsmInjectionUtils.registerOtherClass<DeviceInfoManager>(DeviceInfoManager.new);
    IsmInjectionUtils.registerOtherClass<SharedPreferencesManager>(SharedPreferencesManager.new);
    IsmInjectionUtils.registerOtherClass<LocalStorageManager>(
        () => LocalStorageManager(IsmInjectionUtils.getOtherClass<SharedPreferencesManager>()));
    IsmInjectionUtils.registerOtherClass<DataSource>(
        () => DataSourceImpl(IsmInjectionUtils.getOtherClass<LocalStorageManager>()));
  }
}
