abstract class AnalyticsService {
  void initializeService(String writeKey, String dataPlaneUrl);

  void onLogin(String userId, {Map<String, dynamic>? traits});

  void trackEvent(String eventName, {List<Map<String, dynamic>>? properties});

  void trackScreen(String screenName, {List<Map<String, dynamic>>? properties});

  void onLogout(); // For user logout
}
