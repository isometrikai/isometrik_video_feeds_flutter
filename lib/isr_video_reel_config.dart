import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ism_video_reel_player/cache/isr_feed_cache.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_feed_cache_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/isr_active_video_player_registry.dart';
import 'package:ism_video_reel_player/utils/isr_image_sound_registry.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:talker/talker.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

  /// base url
  static String? baseUrl;

  /// tenantId
  static String? tenantId;

  /// projectId
  static String? projectId;

  /// appName or identifier
  static String appName = 'IsmVideoReel';

  /// additional header
  static Map<String, String>? additionalHeader;

  /// Social configuration used by SDK modules.
  static SocialConfig socialConfig = const SocialConfig();

  /// Network configuration used by SDK modules.
  static NetworkConfig? networkConfig;

  /// Post configuration used by SDK modules.
  static PostConfig postConfig = const PostConfig();

  /// Tab configuration used by SDK modules.
  static TabConfig tabConfig = const TabConfig();

  /// comment configuration used by SDK modules.
  static CommentConfig commentConfig = const CommentConfig();

  /// Create, edit post configuration used by SDK modules.
  static CreateEditPostConfig createEditPostConfig =
      const CreateEditPostConfig();

  /// Tag people configuration used by SDK modules.
  static TagDetailsConfig tagDetailsConfig = const TagDetailsConfig();

  /// Search Screen configuration used by SDK modules.
  static SearchScreenConfig searchScreenConfig = const SearchScreenConfig();

  /// Blocked users screen configuration used by SDK modules.
  static BlockedUsersConfig blockedUsersConfig = const BlockedUsersConfig();

  /// Story configuration used by SDK modules; when null, stories stay hidden.
  static StoryConfig? storyConfig;

  /// When non-null, the host app may persist feed slices (e.g. Hive) alongside the SDK.
  static IsrFeedCacheConfig? feedCacheConfig;

  /// Optional UI locale (same idea as `IsmLiveApp.initialize(..., locale: ...)`).
  ///
  /// Used for API `lan` and as the suggested [EasyLocalization] start locale.
  /// When the host changes language via EasyLocalization (`context.setLocale`),
  /// SDK strings follow automatically through `.tr()`.
  static Locale? locale;

  /// Host-provided currency code (e.g. `XAF`) from [initializeSdk] headers.
  static String currencyCode = '';

  /// Host-provided currency symbol (e.g. `FCFA`) from [initializeSdk] headers.
  static String currencySymbol = '';

  /// Locales the host typically provides in its EasyLocalization JSON files.
  /// The SDK itself does not ship locale catalogs — host translations drive UI.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// Set only by the host via [pauseFeedPlayback] / [resumeFeedPlayback].
  static bool isHostFeedTabVisible = true;

  static int _overlayReelsPlayerCount = 0;

  /// Section for the topmost overlay player (explore/profile grid reels).
  static PostSectionType? _activeOverlaySection;

  /// In-SDK routes (sound detail, capture flow) that must pause media without
  /// clearing [isHostFeedTabVisible] — otherwise profile/explore can bleed audio.
  static int _playbackSuppressionCount = 0;

  /// Set while the OS has the app in background — blocks resume without clearing
  /// [isHostFeedTabVisible] (user may still be on the reels shell tab).
  static bool _appInBackground = false;

  /// True after lifecycle paused media; cleared on [resumeFromAppForeground].
  static bool _lifecyclePlaybackSuspended = false;

  static AppLifecycleState? _lastLifecycleState;

  /// Ignores destructive `inactive` handling right after [resumed] (iOS often
  /// delivers `resumed` then `inactive` when returning to foreground).
  static DateTime? _ignoreInactiveUntil;

  static bool get isAppInBackground => _appInBackground;

  /// True when an overlay reels player is active, or the host reels tab is
  /// visible and nothing is suppressing host playback.
  ///
  /// Overlay players are allowed even while [suppressPlayback] is held (e.g.
  /// sound detail under a nested overlay), so only the underlying host feed
  /// stays silenced.
  static bool get allowsPlayback =>
      !_appInBackground &&
      (_overlayReelsPlayerCount > 0 ||
          (isHostFeedTabVisible && _playbackSuppressionCount == 0));

  static bool get isOverlayReelsPlayerActive => _overlayReelsPlayerCount > 0;

  /// Whether [state] should be handled by a player in [section].
  /// Null scope on the state applies to every section (host-wide pause/resume).
  static bool playPauseAppliesToSection(
    PostSectionType section,
    PlayPauseVideoState state,
  ) {
    final scope = state.scopedPostSection;
    return scope == null || scope == section;
  }

  static void _emitPlayPause({required bool play}) {
    try {
      final bloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
      bloc.add(PlayPauseVideoEvent(play: play));
    } catch (e) {
      debugPrint('IsrVideoReelConfig._emitPlayPause: $e');
    }
    if (play) {
      VisibilityDetectorController.instance.notifyNow();
    }
  }

  /// Opens a full-screen overlay player (explore/profile grid, notifications).
  ///
  /// Pauses the kept-alive home [IsmPostView] first, then resumes only the
  /// overlay tab section — a global `play: true` was waking background audio.
  static void enterOverlayReelsPlayer({
    PostSectionType? overlaySection,
  }) {
    _emitPlayPause(play: false);
    _overlayReelsPlayerCount++;
    if (overlaySection != null) {
      _activeOverlaySection = overlaySection;
    }

    void resumeOverlayOnly() {
      if (_overlayReelsPlayerCount == 0 ||
          _appInBackground ||
          !allowsPlayback) {
        return;
      }
      try {
        final bloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
        bloc.add(
          PlayPauseVideoEvent(
            play: true,
            scopedPostSection: overlaySection,
          ),
        );
      } catch (e) {
        debugPrint('IsrVideoReelConfig.enterOverlayReelsPlayer: $e');
      }
      VisibilityDetectorController.instance.notifyNow();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => resumeOverlayOnly());
  }

  static void exitOverlayReelsPlayer() {
    if (_overlayReelsPlayerCount > 0) _overlayReelsPlayerCount--;
    if (_overlayReelsPlayerCount == 0) {
      _activeOverlaySection = null;
      if (!isHostFeedTabVisible) {
        _emitPlayPause(play: false);
      }
    }
  }

  /// Optional hook for [IsmPostView] to refresh tab visibility when the host returns to reels.
  static VoidCallback? onHostFeedTabResumed;

  /// Returns the host home tab section (For You / Following / Feed) for scoped resume.
  static PostSectionType? Function()? getActiveHostPostSection;

  static final List<VoidCallback> _appForegroundResumedListeners =
      <VoidCallback>[];

  static final Map<PostSectionType, VoidCallback>
      _sectionForegroundResumeHandlers = <PostSectionType, VoidCallback>{};

  /// Registers a listener for app foreground return (host + overlay players).
  static void registerAppForegroundResumedListener(VoidCallback listener) {
    if (!_appForegroundResumedListeners.contains(listener)) {
      _appForegroundResumedListeners.add(listener);
    }
  }

  static void unregisterAppForegroundResumedListener(VoidCallback listener) {
    _appForegroundResumedListeners.remove(listener);
  }

  static void _notifyAppForegroundResumed() {
    for (final listener in _appForegroundResumedListeners.toList()) {
      try {
        listener();
      } catch (e) {
        debugPrint('IsrVideoReelConfig._notifyAppForegroundResumed: $e');
      }
    }
  }

  /// [PostItemWidget] registers so the visible reel can resume after lifecycle.
  static void registerSectionForegroundResume(
    PostSectionType section,
    VoidCallback handler,
  ) {
    _sectionForegroundResumeHandlers[section] = handler;
  }

  static void unregisterSectionForegroundResume(PostSectionType section) {
    _sectionForegroundResumeHandlers.remove(section);
  }

  static void _invokeSectionForegroundResume(PostSectionType? section) {
    if (section != null) {
      try {
        _sectionForegroundResumeHandlers[section]?.call();
      } catch (e) {
        debugPrint('IsrVideoReelConfig._invokeSectionForegroundResume: $e');
      }
      return;
    }
    for (final handler in _sectionForegroundResumeHandlers.values.toList()) {
      try {
        handler();
      } catch (e) {
        debugPrint('IsrVideoReelConfig._invokeSectionForegroundResume: $e');
      }
    }
  }

  /// Host-only: user left the reels bottom-nav tab (profile, explore, etc.).
  static void pauseFeedPlayback() {
    isHostFeedTabVisible = false;
    _emitPlayPause(play: false);
  }

  /// Host-only: user returned to the reels bottom-nav tab.
  static void resumeFeedPlayback() {
    isHostFeedTabVisible = true;
    _emitPlaybackResume(
      notifyHostTabResumed: true,
      scopedPostSection: getActiveHostPostSection?.call(),
    );
  }

  /// SDK overlays (sound sheet, capture) — pause without clearing host visibility.
  static void suppressPlayback() {
    _playbackSuppressionCount++;
    _emitPlayPause(play: false);
  }

  /// Pair with [suppressPlayback]; resumes only if the host tab is still reels.
  static void releasePlaybackSuppression() {
    if (_playbackSuppressionCount > 0) {
      _playbackSuppressionCount--;
    }
    _emitPlaybackResume();
  }

  /// Resume after an in-app flow without flipping [isHostFeedTabVisible].
  static void resumePlaybackIfAllowed() {
    _emitPlaybackResume();
  }

  /// Hard-stops video widgets and image-post [AudioPlayer] instances.
  static Future<void> hardStopAllReelsMedia() async {
    _emitPlayPause(play: false);
    IsrActiveVideoPlayerRegistry.pauseAll();
    await IsrImageSoundRegistry.stopAll();
  }

  /// Pauses all reels media when the app moves to background.
  ///
  /// Does not clear [isHostFeedTabVisible] — pair with [resumeFromAppForeground].
  static void pauseForAppBackground() {
    _appInBackground = true;
    _lifecyclePlaybackSuspended = true;
    unawaited(hardStopAllReelsMedia());
  }

  /// Restores playback after foreground return when policy allows.
  ///
  /// Pass [hostReelsTabVisible] true when the shell is still on the reels tab so
  /// the main feed can resume; overlay-only playback resumes when an overlay
  /// player is active regardless.
  static void resumeFromAppForeground({required bool hostReelsTabVisible}) {
    final shouldResume = _appInBackground || _lifecyclePlaybackSuspended;
    _appInBackground = false;
    _lifecyclePlaybackSuspended = false;
    if (!shouldResume) return;

    if (!hostReelsTabVisible && _overlayReelsPlayerCount == 0) return;

    PostSectionType? resumeSection;
    if (hostReelsTabVisible) {
      isHostFeedTabVisible = true;
      resumeSection = getActiveHostPostSection?.call();
      onHostFeedTabResumed?.call();
    } else if (_overlayReelsPlayerCount > 0) {
      resumeSection = _activeOverlaySection;
    }

    _notifyAppForegroundResumed();
    _resumeOnlyCurrentReelAfterForeground(resumeSection);
  }

  /// Silence everything, then nudge only the active section's current reel once.
  static void _resumeOnlyCurrentReelAfterForeground(
    PostSectionType? section,
  ) {
    if (_appInBackground || !allowsPlayback) return;

    IsrActiveVideoPlayerRegistry.pauseAll();
    _emitPlayPause(play: false);
    unawaited(IsrImageSoundRegistry.stopAll());

    if (section == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_appInBackground || !allowsPlayback) return;
      _invokeSectionForegroundResume(section);
    });
  }

  /// Host wiring for [WidgetsBindingObserver.didChangeAppLifecycleState].
  static void handleAppLifecycleState(
    AppLifecycleState state, {
    required bool hostReelsTabVisible,
  }) {
    switch (state) {
      case AppLifecycleState.inactive:
        if (_ignoreInactiveUntil != null &&
            DateTime.now().isBefore(_ignoreInactiveUntil!)) {
          break;
        }
        // Set the background flag before pausing so players cannot immediately
        // resume via visibility / stuck-video recovery (iOS stays inactive in
        // the app switcher while AVPlayer keeps audio going).
        pauseForAppBackground();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        pauseForAppBackground();
        break;
      case AppLifecycleState.resumed:
        resumeFromAppForeground(hostReelsTabVisible: hostReelsTabVisible);
        _ignoreInactiveUntil =
            DateTime.now().add(const Duration(milliseconds: 800));
        break;
    }
    _lastLifecycleState = state;
  }

  static void _emitPlaybackResume({
    bool notifyHostTabResumed = false,
    PostSectionType? scopedPostSection,
  }) {
    if (_appInBackground || !allowsPlayback) return;

    void emitResume() {
      if (_appInBackground || !allowsPlayback) return;
      try {
        final bloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
        bloc.add(
          PlayPauseVideoEvent(
            play: true,
            scopedPostSection: scopedPostSection,
          ),
        );
      } catch (e) {
        debugPrint('IsrVideoReelConfig._emitPlaybackResume: $e');
      }
      VisibilityDetectorController.instance.notifyNow();
    }

    if (notifyHostTabResumed) {
      onHostFeedTabResumed?.call();
    }

    emitResume();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notifyHostTabResumed) {
        onHostFeedTabResumed?.call();
      }
      emitResume();
    });
  }

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
  /// - [appName]: App name or identifier used by the SDK.
  /// - [getCurrentBuildContext]: Callback to resolve the current [BuildContext].
  ///
  /// Optional parameters:
  /// - [userInfoClass]: Initial user context persisted by the SDK.
  /// - [additionalHeader]: Extra HTTP headers merged with defaults.
  /// - [locale]: UI / API language (e.g. `Locale('en')`). Same pattern as
  ///   `IsmLiveApp.initialize(..., locale: ...)`. When omitted, `lan` from
  ///   [defaultHeaders] is used if present.
  ///
  /// **Module configuration (deprecated on this method):** Passing
  /// [socialConfig], [postConfig], [tabConfig], [commentConfig],
  /// [createEditPostConfig], [tagDetailsConfig], or [searchScreenConfig] here
  /// is deprecated. Prefer [setUpConfig] so feature flags and UI tuning stay
  /// separate from bootstrap (URL, analytics, headers, user).
  ///
  /// If called again after initialization, the SDK will update stored headers
  /// and user info, and notify internal state to refresh.
  static Future<void> initializeSdk({
    required String baseUrl,
    required String rudderStackWriteKey,
    required String rudderStackDataPlaneUrl,
    required UserInfoClass? userInfoClass,
    required Map<String, dynamic> defaultHeaders,
    required String appName,
    Map<String, String>? additionalHeader,
    required BuildContext? Function()? getCurrentBuildContext,
    Locale? locale,
  }) async {
    IsrVideoReelConfig.baseUrl = baseUrl;
    IsrVideoReelConfig.tenantId = defaultHeaders.stringOrNull('x-tenant-id');
    IsrVideoReelConfig.projectId = defaultHeaders.stringOrNull('x-project-id');
    IsrVideoReelConfig.appName = appName;
    if (!isSdkInitialize) {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      isrConfigureInjection();
      // ✅ Initialize SDK router
      await _initializeHive();
      Bloc.observer = IsrAppBlocObserver();
      await _initializeRudderStack(
        rudderStackWriteKey: rudderStackWriteKey,
        rudderStackDataPlaneUrl: rudderStackDataPlaneUrl,
      );
      isSdkInitialize = true;
    }
    IsrVideoReelConfig.additionalHeader = additionalHeader;
    await _storeHeaderValues(defaultHeaders);
    final resolvedLocale = locale ??
        _localeFromLanguageCode(defaultHeaders['lan'] as String?) ??
        IsrVideoReelConfig.locale;
    if (resolvedLocale != null) {
      await setLocale(resolvedLocale);
    }
    await _saveUserInformation(userInfoClass: userInfoClass);
    buildContext = getCurrentBuildContext?.call();
    debugPrint('IsrVideoReelConfig: initializeSdk: ${userInfoClass?.userId}');
    socialActionCubit.onSdkReinitializeChanged(
      userId: userInfoClass?.userId,
      userInfoClass: userInfoClass,
    );
    if (IsrVideoReelConfig.feedCacheConfig != null) {
      unawaited(
        IsrFeedCacheRepository.instance.reopenForOwner(
          userInfoClass?.userId ?? '',
        ),
      );
    }
    getBuildContext = getCurrentBuildContext;
    _triggerEventLog();
    unawaited(_updateHeaderAddressFromIp());
  }

  /// Applies or updates SDK module configuration (social, posts, tabs, comments,
  /// create/edit post, tag details, search).
  ///
  /// Call this when you need to change feature-specific settings without
  /// re-running full [initializeSdk] (for example after remote config loads, or
  /// when switching themes/locales that affect SDK UI). Any argument omitted
  /// keeps the current value; pass a new instance only for the pieces you want
  /// to replace.
  ///
  /// **Relationship to [initializeSdk]:** Prefer this method for all module
  /// configs. The corresponding parameters on [initializeSdk] are deprecated
  /// but still applied if passed, for backward compatibility.
  ///
  /// Parameters:
  /// - [socialConfig]: Social graph, profiles, and related behavior.
  /// - [postConfig]: Feed/post list and post UI behavior.
  /// - [tabConfig]: Tab bar and navigation within SDK surfaces.
  /// - [commentConfig]: Comments sheet, threading, and input behavior.
  /// - [createEditPostConfig]: Create and edit post flows and validation.
  /// - [tagDetailsConfig]: Tagging people and tag UI.
  /// - [searchScreenConfig]: In-SDK search screen layout and options.
  /// - [blockedUsersConfig]: Blocked users screen layout and options.
  static void setUpConfig({
    SocialConfig? socialConfig,
    NetworkConfig? networkConfig,
    PostConfig? postConfig,
    TabConfig? tabConfig,
    CommentConfig? commentConfig,
    CreateEditPostConfig? createEditPostConfig,
    TagDetailsConfig? tagDetailsConfig,
    SearchScreenConfig? searchScreenConfig,
    BlockedUsersConfig? blockedUsersConfig,
    StoryConfig? storyConfig,
    IsrFeedCacheConfig? feedCacheConfig,
  }) {
    IsrVideoReelConfig.socialConfig =
        socialConfig ?? IsrVideoReelConfig.socialConfig;
    IsrVideoReelConfig.networkConfig =
        networkConfig ?? IsrVideoReelConfig.networkConfig;
    final resolvedPostConfig = postConfig ?? IsrVideoReelConfig.postConfig;
    IsrVideoReelConfig.postConfig = resolvedPostConfig;
    VideoMuteController.applyDefaultMuted(
      resolvedPostConfig.resolvedPostFeedUIConfig.defaultVideoMuted,
    );
    IsrVideoReelConfig.tabConfig = tabConfig ?? IsrVideoReelConfig.tabConfig;
    IsrVideoReelConfig.commentConfig =
        commentConfig ?? IsrVideoReelConfig.commentConfig;
    IsrVideoReelConfig.createEditPostConfig =
        createEditPostConfig ?? IsrVideoReelConfig.createEditPostConfig;
    IsrVideoReelConfig.tagDetailsConfig =
        tagDetailsConfig ?? IsrVideoReelConfig.tagDetailsConfig;
    IsrVideoReelConfig.searchScreenConfig =
        searchScreenConfig ?? IsrVideoReelConfig.searchScreenConfig;
    IsrVideoReelConfig.blockedUsersConfig =
        blockedUsersConfig ?? IsrVideoReelConfig.blockedUsersConfig;
    IsrVideoReelConfig.storyConfig = storyConfig;
    IsrVideoReelConfig.feedCacheConfig = feedCacheConfig;
    unawaited(_applyFeedCacheConfig(feedCacheConfig));
  }

  static Future<void> _applyFeedCacheConfig(
    IsrFeedCacheConfig? feedCacheConfig,
  ) async {
    if (feedCacheConfig == null) {
      IsrFeedCacheSync.instance.detach();
      return;
    }
    var owner = 'guest';
    try {
      owner =
          await IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>().getUserId();
    } catch (_) {}
    await IsrFeedCacheRepository.instance.init(
      config: feedCacheConfig,
      ownerKey: owner,
    );
    IsrFeedCacheSync.instance.attach();
  }

  static Future<void> _updateHeaderAddressFromIp() async {
    try {
      await IsmInjectionUtils.getOtherClass<LocationManager>()
          .updateHeaderLocationFromIP();
    } catch (e) {
      debugPrint('Error getting location from IP: $e');
    }
  }

  static void _triggerEventLog() {
    Future.delayed(const Duration(seconds: 5), () {
      // to send any pending event to backend
      EventQueueProvider.instance.sendPendingEventsToBackend();
    });
  }

  static void registerTalker(Talker talker) {
    IsmInjectionUtils.unRegister<Talker>();
    IsmInjectionUtils.registerOtherClass<Talker>(() => talker);
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
    await localStorageManager.saveValue(
        LocalStorageKeys.isLoggedIn,
        userInfoClass?.userId?.trim().isNotEmpty == true,
        SavedValueDataType.bool);
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

  /// Updates SDK [locale] and persists `lan` for API headers.
  ///
  /// Prefer letting the host [EasyLocalization] drive UI strings via
  /// `context.setLocale`. Call this when you also want API `lan` kept in sync,
  /// or pass `locale:` to [initializeSdk].
  ///
  /// ```dart
  /// await IsrVideoReelConfig.setLocale(const Locale('ar'));
  /// ```
  static Future<void> setLocale(Locale locale) async {
    IsrVideoReelConfig.locale = locale;
    final languageCode = locale.languageCode;
    if (!isSdkInitialize) return;
    try {
      final localStorageManager =
          IsmInjectionUtils.getOtherClass<LocalStorageManager>();
      await localStorageManager.saveValue(
        LocalStorageKeys.language,
        languageCode,
        SavedValueDataType.string,
      );
    } catch (e) {
      debugPrint('IsrVideoReelConfig.setLocale: failed to persist: $e');
    }
  }

  static Locale? _localeFromLanguageCode(String? languageCode) {
    final code = languageCode?.trim();
    if (code == null || code.isEmpty) return null;
    final parts = code.replaceAll('-', '_').split('_');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return Locale(parts[0].toLowerCase(), parts[1].toUpperCase());
    }
    return Locale(parts.first.toLowerCase());
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
    IsrVideoReelConfig.currencySymbol = currencySymbol.trim();
    IsrVideoReelConfig.currencyCode = currencyCode.trim();
    final platform = defaultHeaders['platform'] as String? ?? '';
    final latitude = defaultHeaders['latitude'] as double? ?? 0;
    final longitude = defaultHeaders['longitude'] as double? ?? 0;
    final xTenantId = defaultHeaders['x-tenant-id'] as String? ?? '';
    final xProjectId = defaultHeaders['x-project-id'] as String? ?? '';
    await localStorageManager.saveValueSecurely(
        LocalStorageKeys.accessToken, accessToken);
    final resolvedLanguage = language.trim().isNotEmpty
        ? language.trim()
        : (IsrVideoReelConfig.locale?.languageCode ?? '');
    await localStorageManager.saveValue(
        LocalStorageKeys.language, resolvedLanguage, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.city,
        city.toHttpHeaderValue(), SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.state,
        state.toHttpHeaderValue(), SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.country,
        country.toHttpHeaderValue(), SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.ipAddress, ipAddress, SavedValueDataType.string);
    await localStorageManager.saveValue(
        LocalStorageKeys.version, version, SavedValueDataType.string);
    await localStorageManager.saveValue(LocalStorageKeys.currencySymbol,
        currencySymbol.toHttpHeaderValue(), SavedValueDataType.string);
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

  /// Display label for paid-post unlock amount using host currency when available.
  ///
  /// Prefers [currencySymbol] from host headers (e.g. `100 FCFA`). Falls back to
  /// post [priceCurrency], then amount-only for legacy coin posts.
  static String formatPaidUnlockPrice({
    required dynamic priceAmount,
    String? priceCurrency,
  }) {
    if (priceAmount == null) return '';
    final amount =
        priceAmount is num ? priceAmount.toString() : priceAmount.toString().trim();
    if (amount.isEmpty) return '';

    final hostSymbol = currencySymbol.trim();
    if (hostSymbol.isNotEmpty) return '$amount $hostSymbol';

    final hostCode = currencyCode.trim();
    if (hostCode.isNotEmpty &&
        hostCode.toLowerCase() != 'coin' &&
        hostCode.toLowerCase() != 'coins') {
      return '$amount $hostCode';
    }

    final c = (priceCurrency ?? '').trim().toLowerCase();
    if (c.isEmpty || c == '-') return amount;
    if (c == 'coin' || c == 'coins') return amount;
    if (c == 'usd') return '\$$amount';
    return '$amount ${priceCurrency!.trim()}';
  }

  /// Whether unlock UI should show the legacy coin icon.
  ///
  /// Returns false when the host supplied a real currency (e.g. XAF/FCFA).
  static bool isPaidUnlockCoinCurrency(String? priceCurrency) {
    final hostCode = currencyCode.trim().toLowerCase();
    final hostSymbol = currencySymbol.trim();
    if (hostSymbol.isNotEmpty ||
        (hostCode.isNotEmpty && hostCode != 'coin' && hostCode != 'coins')) {
      return false;
    }
    final c = (priceCurrency ?? '').trim().toLowerCase();
    return c == 'coin' || c == 'coins';
  }

  /// Returns SDK-wide singleton [BlocProvider] instances required by the SDK.
  static List<BlocProvider> getIsmSingletonBlocProviders() => [
        BlocProvider(
            create: (_) => IsmInjectionUtils.getBloc<IsmSocialActionCubit>()),
      ];
}
