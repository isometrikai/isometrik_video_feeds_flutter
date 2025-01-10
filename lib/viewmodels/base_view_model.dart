import 'package:ism_video_reel_player/export.dart';

abstract class BaseViewModel with AppMixin {
  BaseRepository getRepository();
}
