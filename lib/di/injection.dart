import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/di/di.dart';

final isrGetIt = GetIt.instance;

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
