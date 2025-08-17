import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/di/di.dart';

final isrGetIt = GetIt.instance;
final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

@InjectableInit()
void isrConfigureInjection() {
  isrGetIt.init();
  injectAllModule();
}

void injectAllModule() {
  AppModuleInjection.inject();
  ApiServiceInjection.inject();
  RepositoryInjection.inject();
  UseCaseInjection.inject();
  BlocInjection.inject();
}
