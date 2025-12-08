import 'package:geolocator/geolocator.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class LocationManager with AppMixin {
  LocationManager(this._localStorageManager);

  final LocalStorageManager _localStorageManager;

  ///checks whether current location is fetched or not
  Future<bool> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await isLocationServiceEnable();
    if (!serviceEnabled) {
      return !serviceEnabled;
    }

    /// Check if location permissions are granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        printLog(
          this,
          'Location permissions are denied.',
        );
        return false;
      }
    }

    /// Get the current position
    final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium));
    await _localStorageManager.saveValue(LocalStorageKeys.latitude,
        position.latitude, SavedValueDataType.double);
    await _localStorageManager.saveValue(LocalStorageKeys.longitude,
        position.longitude, SavedValueDataType.double);

    printLog(
      this,
      'Latitude: ${position.latitude}, Longitude: ${position.longitude}',
    );
    return true;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnable() async {
    final iServiceEnabled = await Geolocator.isLocationServiceEnabled();
    return iServiceEnabled;
  }
}
