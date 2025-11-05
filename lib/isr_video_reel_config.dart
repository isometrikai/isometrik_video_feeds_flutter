// sdk_config.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    String? eventQueueApiUrl,
    OnBeforeFlushCallback? onBeforeFlushCallback,
  }) async {
    if (isSdkInitialize) {
      await _saveUserInformation(postInfo: postInfo);
      return;
    }
    AppUrl.appBaseUrl = baseUrl;
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    isrConfigureInjection();
    await _initializeHive(
      eventQueueApiUrl: eventQueueApiUrl,
      onBeforeFlushCallback: onBeforeFlushCallback,
    );
    Bloc.observer = IsrAppBlocObserver();
    await _saveUserInformation(postInfo: postInfo);
    isSdkInitialize = true;
  }

  static Future<void> _saveUserInformation({
    PostInfoClass? postInfo,
  }) async {
    final localStorageManager = IsmInjectionUtils.getOtherClass<IsrLocalStorageManager>();
    final userInfoString = postInfo?.userInformation.toString();
    await localStorageManager.saveValueSecurely(
        IsrLocalStorageKeys.accessToken, postInfo?.accessToken ?? '');
    await localStorageManager.saveValue(
        IsrLocalStorageKeys.userInfo, userInfoString, SavedValueDataType.string);
    await localStorageManager.saveValue(
        IsrLocalStorageKeys.userId, postInfo?.userInformation?.userId, SavedValueDataType.string);
  }

  static void precacheVideos(List<String> mediaUrls) async {
    debugPrint('IsrVideoReelConfig: precacheVideos: $mediaUrls');
    if (mediaUrls.isEmpty) return;
    await MediaCacheFactory.precacheMedia(mediaUrls, highPriority: false);
  }

  static Future<void> _initializeHive({
    String? eventQueueApiUrl,
    OnBeforeFlushCallback? onBeforeFlushCallback,
  }) async {
    await Hive.initFlutter();
    Hive.registerAdapter(LocalEventAdapter());

    // Initialize EventQueueProvider with callback
    EventQueueProvider.initialize(onBeforeFlush: onBeforeFlushCallback);
  }
}
