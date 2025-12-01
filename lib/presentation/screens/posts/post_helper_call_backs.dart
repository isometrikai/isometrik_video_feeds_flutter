// The Interface (Contract)
abstract class PostHelperCallBacks {
  // Method signature that must be implemented
  void sendAnalyticsEvent(String eventName, Map<String, dynamic> analyticsData);
}
