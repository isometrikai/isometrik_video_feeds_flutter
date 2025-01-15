import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

final ismGetIt = GetIt.instance;

@InjectableInit()
void configureInjection() => ismGetIt.init();
