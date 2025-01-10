import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

final kGetIt = GetIt.instance;

@InjectableInit()
void configureInjection() => kGetIt.init();
