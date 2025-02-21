// lib/utils/navigator/navigation_service.dart
abstract class NavigationService {
  Future<T?> pushNamed<T>(String routeName, {Object? arguments});
  void pushReplacementNamed<T>(String routeName, {Object? arguments});
  void goNamed(String routeName, {Object? arguments});
  void go(String routeName, {Object? arguments});
  void pop([Object? result]);
  void popUntil(String routeName, {Object? arguments});
}
