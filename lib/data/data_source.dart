import 'package:ism_video_reel_player/data/data.dart';

/// Data source abstraction used by the SDK to build request metadata and access
/// local persistence.
abstract class DataSource {
  /// Returns the current request [Header], built from persisted values.
  Future<Header> getHeader();

  /// Returns the underlying local storage manager used by the SDK.
  LocalStorageManager getStorageManager();
}
