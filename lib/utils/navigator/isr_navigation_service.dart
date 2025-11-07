import 'package:flutter/cupertino.dart';

abstract class IsrNavigationService {
  Future<T?> pushNamed<T>(String routeName, {Object? arguments});
  void pushReplacementNamed<T>(BuildContext context, String routeName, {Object? arguments});
  void goNamed(BuildContext context, String routeName, {Object? arguments});
  void go(BuildContext context, String routeName, {Object? arguments});
  void pop(BuildContext context, [Object? result]);
  void popUntil(BuildContext context, String routeName, {Object? arguments});
}
