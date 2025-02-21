import 'package:ism_video_reel_player_example/data/data.dart';

abstract class DataSource {
  Future<Header> getHeader();
  LocalStorageManager getStorageManager();
}
