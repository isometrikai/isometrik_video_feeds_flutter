import 'package:ism_video_reel_player/integration/integration.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:rudder_sdk_flutter/RudderController.dart';
import 'package:rudder_sdk_flutter_platform_interface/platform.dart';

class RudderStackAnalyticsService implements AnalyticsService {
  final RudderController _rudderClient = RudderController.instance;

  @override
  void initializeService(String writeKey, String dataPlaneUrl) {
    if (writeKey.isEmptyOrNull || dataPlaneUrl.isEmptyOrNull) {
      return;
    }
    final builder = RudderConfigBuilder();
    RudderLogger.init(RudderLogger.VERBOSE);
    builder.withDataPlaneUrl(dataPlaneUrl);
    builder.withFlushQueueSize(10);
    builder.withLogLevel(RudderLogger.VERBOSE);
    final mobileConfig = MobileConfig(
      trackDeepLinks: true,
      trackLifecycleEvents: true,
    );
    builder.withMobileConfig(mobileConfig);
    _rudderClient.initialize(writeKey, config: builder.build());
  }

  @override
  void onLogin(String userId, {Map<String, dynamic>? traits}) {
    // Convert Map to RudderTraits if necessary, or use the identify call directly
    if (traits != null) {
      final rudderTraits = RudderTraits();
      rudderTraits.putValue(traits);
      _rudderClient.identify(userId, traits: rudderTraits);
    }
  }

  @override
  void trackEvent(String eventName, {List<Map<String, dynamic>>? properties}) {
    if (properties.isEmptyOrNull == false) {
      final rudderProperties = RudderProperty();
      for (final mapItem in properties!) {
        rudderProperties.putValue(map: mapItem);
      }
      _rudderClient.track(eventName, properties: rudderProperties);
    } else {
      _rudderClient.track(eventName);
    }
  }

  @override
  void trackScreen(String screenName, {List<Map<String, dynamic>>? properties}) {
    if (properties.isEmptyOrNull == false) {
      final rudderProperties = RudderProperty();
      for (final mapItem in properties!) {
        rudderProperties.putValue(map: mapItem);
      }
      _rudderClient.screen(screenName, properties: rudderProperties);
    }
  }

  @override
  void onLogout() {
    _rudderClient.reset();
  }
}
