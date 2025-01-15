// sdk_config.dart
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class IsmVideoReelConfig {
  static var isSdkInitialize = false;

  static Future<void> initializeSdk({
    required String baseUrl,
    UserInfoClass? userInfo,
  }) async {
    AppUrl.appBaseUrl = baseUrl;
    WidgetsFlutterBinding.ensureInitialized();
    configureInjection();
    // await kGetIt<SharedPreferencesManager>().init();
    // await _saveUserInformation(userInfo: userInfo);
    isSdkInitialize = true;
  }

  static Future<void> _saveUserInformation({UserInfoClass? userInfo}) async {
    final _localStorageManager = kGetIt<LocalStorageManager>();
    final userInfoString = userInfo.toString();
    _localStorageManager.saveValue(LocalStorageKeys.userInfo, userInfoString, SavedValueDataType.string);
  }
}
