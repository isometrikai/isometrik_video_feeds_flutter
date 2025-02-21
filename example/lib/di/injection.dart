import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player_example/di/di.dart';

final kGetIt = GetIt.instance;

@InjectableInit()
void configureInjection() {
  kGetIt.init();
  injectAllModule();
}

void injectAllModule() {
  AppModuleInjection.inject();
  ApiServiceInjection.inject();
  RepositoryInjection.inject();
  UseCaseInjection.inject();
  BlocInjection.inject();
}
