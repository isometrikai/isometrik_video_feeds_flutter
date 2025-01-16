import 'package:ism_video_reel_player/export.dart';

abstract class BaseRepository with IsrAppMixin {
  Future<String> getSecuredValue(String key);

  void saveValueSecurely(String key, String value);

  void deleteSecuredValue(String key);

  void deleteAllSecuredValues();

  void saveValue(String key, dynamic value, SavedValueDataType savedValueDataType);

  dynamic getValue(String key, SavedValueDataType savedValueDataType);

  void clearData();
}
