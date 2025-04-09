// sdk_config.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

class IsrVideoReelConfig {
  static BuildContext? buildContext;
  static var isSdkInitialize = false;

  static Future<void> initializeSdk({
    required String baseUrl,
    PostInfoClass? postInfo,
  }) async {
    AppUrl.appBaseUrl = baseUrl;
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    isrConfigureInjection();
    Bloc.observer = IsrAppBlocObserver();
    await _saveUserInformation(postInfo: postInfo);
    isSdkInitialize = true;
  }

  static Future<void> _saveUserInformation({
    PostInfoClass? postInfo,
  }) async {
    final localStorageManager = IsmInjectionUtils.getOtherClass<IsrLocalStorageManager>();
    final userInfoString = postInfo?.userInformation.toString();
    await localStorageManager.saveValueSecurely(IsrLocalStorageKeys.accessToken, postInfo?.accessToken ?? '');
    await localStorageManager.saveValue(IsrLocalStorageKeys.userInfo, userInfoString, SavedValueDataType.string);
  }
}
