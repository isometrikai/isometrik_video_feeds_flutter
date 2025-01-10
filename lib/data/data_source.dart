import 'package:ism_video_reel_player/export.dart';

abstract class DataSource {
  Services getNetworkManager();

  Future<Header> getHeader();

  LocalStorageManager getStorageManager();
}
