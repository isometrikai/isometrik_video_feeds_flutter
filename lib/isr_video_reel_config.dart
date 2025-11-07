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
import 'package:ism_video_reel_player/utils/utils.dart';

class IsrVideoReelConfig {
  static BuildContext? buildContext;
  static var isSdkInitialize = false;

  static Future<void> initializeSdk({
    required String baseUrl,
    PostInfoClass? postInfo,
    OnBeforeFlushCallback? onBeforeFlushCallback,
    required Map<String, dynamic> defaultHeaders,
  }) async {
    if (isSdkInitialize) {
      await _saveUserInformation(postInfo: postInfo);
      return;
    }
    AppUrl.appBaseUrl = baseUrl;
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    isrConfigureInjection();
    // ✅ Initialize SDK router
    IsrAppRouter.initializeRouter();
    await _storeHeaderValues(defaultHeaders);
    await _initializeHive(
      onBeforeFlushCallback: onBeforeFlushCallback,
    );
    Bloc.observer = IsrAppBlocObserver();
    await _saveUserInformation(postInfo: postInfo);
    isSdkInitialize = true;
  }

  static Future<void> _saveUserInformation({
    PostInfoClass? postInfo,
  }) async {
    final localStorageManager = IsmInjectionUtils.getOtherClass<LocalStorageManager>();
    final userInfoString = postInfo?.userInformation.toString();
    await localStorageManager.saveValueSecurely(
        LocalStorageKeys.accessToken, postInfo?.accessToken ?? '');
    await localStorageManager.saveValue(
        LocalStorageKeys.userInfo, userInfoString, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.userId, postInfo?.userInformation?.userId, SavedValueDataType.string);
  }

  static void precacheVideos(List<String> mediaUrls) async {
    debugPrint('IsrVideoReelConfig: precacheVideos: $mediaUrls');
    if (mediaUrls.isEmpty) return;
    await MediaCacheFactory.precacheMedia(mediaUrls, highPriority: false);
  }

  static Future<void> _initializeHive({
    OnBeforeFlushCallback? onBeforeFlushCallback,
  }) async {
    await Hive.initFlutter();
    Hive.registerAdapter(LocalEventAdapter());

    // Initialize EventQueueProvider with callback
    EventQueueProvider.initialize(onBeforeFlush: onBeforeFlushCallback);
  }

  static Future<void> _storeHeaderValues(Map<String, dynamic> defaultHeaders) async {
    final localStorageManager = IsmInjectionUtils.getOtherClass<LocalStorageManager>();
    final accessToken = defaultHeaders['Authorization'] as String? ?? '';
    final language = defaultHeaders['lan'] as String? ?? '';
    final city = defaultHeaders['city'] as String? ?? '';
    final state = defaultHeaders['state'] as String? ?? '';
    final country = defaultHeaders['country'] as String? ?? '';
    final ipAddress = defaultHeaders['ipaddress'] as String? ?? '';
    final version = defaultHeaders['version'] as String? ?? '';
    final currencySymbol = defaultHeaders['currencySymbol'] as String? ?? '';
    final currencyCode = defaultHeaders['currencyCode'] as String? ?? '';
    final platform = defaultHeaders['platform'] as String? ?? '';
    final latitude = defaultHeaders['latitude'] as double? ?? 0;
    final longitude = defaultHeaders['longitude'] as double? ?? 0;
    final xTenantId = defaultHeaders['x-tenant-id'] as String? ?? '';
    final xProjectId = defaultHeaders['x-project-id'] as String? ?? '';
    await localStorageManager.saveValueSecurely(LocalStorageKeys.accessToken, accessToken);
    await localStorageManager.saveValue(
        LocalStorageKeys.language, language, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.city, city, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.state, state, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.country, country, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.ipAddress, ipAddress, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.version, version, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.currencySymbol, currencySymbol, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.currencyCode, currencyCode, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.platform, platform, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.latitude, latitude, SavedValueDataType.double);
    await localStorageManager.saveValue(
        LocalStorageKeys.longitude, longitude, SavedValueDataType.double);
    await localStorageManager.saveValue(
        LocalStorageKeys.xTenantId, xTenantId, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.xProjectId, xProjectId, SavedValueDataType.string);
  }
}
