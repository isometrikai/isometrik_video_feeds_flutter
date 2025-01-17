import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'ex_app_router.dart';

final GlobalKey<NavigatorState> exNavigatorKey = GlobalKey<NavigatorState>();

class ExRouteManagement {
  ExRouteManagement._();

  static void goToPostView() {
    exNavigatorKey.currentContext?.go(ExAppRoutes.postView);
  }
}
