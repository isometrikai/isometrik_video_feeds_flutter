import 'dart:async';
import 'dart:convert';

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

/// SDK configuration and initialization entrypoint.
///
/// Call [initializeSdk] once during app startup (before rendering the SDK UI).
/// You may call it again later to refresh headers/user context; repeated calls
/// are treated as re-initialization.
class IsrVideoReelConfig {
  /// A fallback context reference used by parts of the SDK.
  ///
  /// Prefer passing [getBuildContext] (via [initializeSdk]) instead of storing
  /// a global [BuildContext], to reduce the risk of retaining disposed contexts.
  static BuildContext? buildContext;

  /// Whether the SDK has completed one-time initialization.
  static var isSdkInitialize = false;

  /// Optional callback used by the SDK to resolve a current [BuildContext].
  ///
  /// This is useful when the host app maintains navigation/context outside the
  /// SDK modules.
  static BuildContext? Function()? getBuildContext;

  /// Optional path to `google-services.json` (Android) used by some integrations.
  static String? googleServiceJsonPath;

  /// Social configuration used by SDK modules.
  static SocialConfig? socialConfig;

  /// Convenience accessor for the SDK's singleton [IsmSocialActionCubit].
  static IsmSocialActionCubit get socialActionCubit =>
      IsmInjectionUtils.getBloc<IsmSocialActionCubit>();

  /// Helper method to check if context is available
  static bool get isContextAvailable => buildContext != null;

  /// Initializes the SDK.
  ///
  /// Required parameters:
  /// - [baseUrl]: Base URL used for SDK API calls.
  /// - [rudderStackWriteKey]: RudderStack write key for analytics/event tracking.
  /// - [rudderStackDataPlaneUrl]: RudderStack dataplane URL.
  /// - [defaultHeaders]: Default headers to be persisted for SDK requests
  ///   (for example `Authorization`, `x-tenant-id`, etc.).
  /// - [socialConfig]: Social module configuration.
  ///
  /// Optional parameters:
  /// - [userInfoClass]: Initial user context persisted by the SDK.
  /// - [googleServiceJsonPath]: Optional path to Google services config.
  /// - [getCurrentBuildContext]: Callback to resolve the current [BuildContext].
  ///
  /// If called again after initialization, the SDK will update stored headers
  /// and user info, and notify internal state to refresh.
  static Future<void> initializeSdk({
    required String baseUrl,
    required String rudderStackWriteKey,
    required String rudderStackDataPlaneUrl,
    UserInfoClass? userInfoClass,
    required Map<String, dynamic> defaultHeaders,
    required SocialConfig socialConfig,
    String? googleServiceJsonPath,
    BuildContext? Function()? getCurrentBuildContext,
  }) async {
    if (isSdkInitialize) {
      await _storeHeaderValues(defaultHeaders);
      await _saveUserInformation(userInfoClass: userInfoClass);
      IsrVideoReelConfig.socialConfig = socialConfig;
      debugPrint('IsrVideoReelConfig: initializeSdk: ${userInfoClass?.userId}');
      socialActionCubit.onSdkReinitializeChanged(
        userId: userInfoClass?.userId,
        userInfoClass: userInfoClass,
      );
      return;
    }
    IsrVideoReelConfig.googleServiceJsonPath = googleServiceJsonPath;
    getBuildContext = getCurrentBuildContext;
    AppUrl.appBaseUrl = baseUrl;
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    isrConfigureInjection();
    // ✅ Initialize SDK router
    await _storeHeaderValues(defaultHeaders);
    await _initializeHive();
    Bloc.observer = IsrAppBlocObserver();
    await _saveUserInformation(userInfoClass: userInfoClass);
    await _initializeRudderStack(
      rudderStackWriteKey: rudderStackWriteKey,
      rudderStackDataPlaneUrl: rudderStackDataPlaneUrl,
    );
    isSdkInitialize = true;
  }

  /// Persists [userInfoClass] (if provided) to local storage.
  static Future<void> _saveUserInformation({
    UserInfoClass? userInfoClass,
  }) async {
    final localStorageManager =
        IsmInjectionUtils.getOtherClass<LocalStorageManager>();
    final userInfoString = jsonEncode(userInfoClass);
    await localStorageManager.saveValue(
        LocalStorageKeys.userInfo, userInfoString, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.userId,
        userInfoClass?.userId, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.userName,
        userInfoClass?.userName, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.firstName,
        userInfoClass?.firstName, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.lastName,
        userInfoClass?.lastName, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.profilePic,
        userInfoClass?.profilePic, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.email,
        userInfoClass?.email, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.phoneNumber,
        userInfoClass?.mobileNumber, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.dialCode,
        userInfoClass?.dialCode, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.isLoggedIn,
        userInfoClass?.userId?.trim().isNotEmpty == true, SavedValueDataType.bool);
  }

  /// Triggers background precaching for the given [mediaUrls].
  ///
  /// Notes:
  /// - This is a best-effort optimization. It may be skipped depending on cache
  ///   policy, network conditions, or platform capabilities.
  /// - The operation is started asynchronously; callers don't need to await it.
  static void precacheVideos(List<String> mediaUrls) {
    debugPrint('IsrVideoReelConfig: precacheVideos: $mediaUrls');
    if (mediaUrls.isEmpty) return;
    unawaited(MediaCacheFactory.precacheMedia(mediaUrls, highPriority: false));
  }

  /// Dispose all video players - call this before hot restart to prevent crashes
  /// This is only needed during development when using hot restart on iOS with MediaKit
  static Future<void> disposeVideoPlayers() async {
    debugPrint('IsrVideoReelConfig: Disposing all video players...');
    await VideoCacheManager.disposeAll();
    debugPrint('IsrVideoReelConfig: Video players disposed');
  }

  static Future<void> _initializeHive() async {
    debugPrint('IsrVideoReelConfig: Initializing Hive...');
    await Hive.initFlutter();
    debugPrint('IsrVideoReelConfig: Registering LocalEventAdapter...');
    Hive.registerAdapter(LocalEventAdapter());
    debugPrint('IsrVideoReelConfig: Hive initialization complete');
  }

  static Future<void> _initializeRudderStack({
    required String rudderStackWriteKey,
    required String rudderStackDataPlaneUrl,
  }) async {
    // Initialize EventQueueProvider with callback
    await EventQueueProvider.initialize(
      rudderStackWriteKey: rudderStackWriteKey,
      rudderStackDataPlaneUrl: rudderStackDataPlaneUrl,
    );
  }

  static Future<void> _storeHeaderValues(
      Map<String, dynamic> defaultHeaders) async {
    final localStorageManager =
        IsmInjectionUtils.getOtherClass<LocalStorageManager>();
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
    await localStorageManager.saveValueSecurely(
        LocalStorageKeys.accessToken, accessToken);
    await localStorageManager.saveValue(
        LocalStorageKeys.language, language, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.city, city, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.state, state, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.country, country, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.ipAddress, ipAddress, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.version, version, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.currencySymbol,
        currencySymbol, SavedValueDataType.string);
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

  /// Logs an analytics/event entry via the configured event provider.
  ///
  /// - [eventName]: Logical name of the event (for example `"post_viewed"`).
  /// - [eventData]: Event payload. Empty values are removed before sending.
  static void logEvent(String eventName, Map<String, dynamic> eventData) {
    EventQueueProvider.instance.logEvent(
      eventName,
      eventData.removeEmptyValues(),
    );
  }

  /// Returns SDK-wide singleton [BlocProvider] instances required by the SDK.
  static List<BlocProvider> getIsmSingletonBlocProviders() => [
        BlocProvider(
            create: (_) => IsmInjectionUtils.getBloc<IsmSocialActionCubit>()),
      ];
}
