import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Helper responsible for obtaining and persisting device location.
///
/// This class:
/// - checks location service availability
/// - requests permissions when needed
/// - saves the latest latitude/longitude into [LocalStorageManager]
class LocationManager with AppMixin {
  /// Creates a [LocationManager] using the provided [_localStorageManager].
  LocationManager(this._localStorageManager);

  final LocalStorageManager _localStorageManager;

  /// Fetches the current location and persists it locally.
  ///
  /// Returns `true` when:
  /// - location services are enabled,
  /// - permissions are granted, and
  /// - the SDK successfully reads + stores coordinates.
  ///
  /// Returns `false` otherwise.
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    await _localStorageManager.saveValue(
      LocalStorageKeys.latitude,
      position.latitude,
      SavedValueDataType.double,
    );
    await _localStorageManager.saveValue(
      LocalStorageKeys.longitude,
      position.longitude,
      SavedValueDataType.double,
    );

    printLog(
      this,
      'Latitude: ${position.latitude}, Longitude: ${position.longitude}',
    );
    return true;
  }

  Future<Map<String, dynamic>?> updateHeaderLocationFromIP() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        debugPrint("LocationManager:- fromIp:- City: ${data['city']}");
        debugPrint("LocationManager:- fromIp:- State: ${data['regionName']}");
        debugPrint("LocationManager:- fromIp:- Country: ${data['country']}");
        debugPrint("LocationManager:- fromIp:- lat: ${data['lat']}");
        debugPrint("LocationManager:- fromIp:- lon: ${data['lon']}");
        debugPrint('LocationManager:- fromIp:- data: $data');

        final city = data['city'] as String?;
        final state = data['regionName'] as String?;
        final country = data['country'] as String?;
        final latitude = data['lat'] as double?;
        final longitude = data['lon'] as double?;
        final ip = data['query'] as String? ?? data['ip'] as String? ;

        if (city?.trim().isNotEmpty == true &&
            state?.trim().isNotEmpty == true &&
            country?.trim().isNotEmpty == true &&
            latitude != null &&
            longitude != null) {
          await _localStorageManager.saveValue(
              LocalStorageKeys.city, city, SavedValueDataType.string);
          await _localStorageManager.saveValue(
              LocalStorageKeys.state, state, SavedValueDataType.string);
          await _localStorageManager.saveValue(
              LocalStorageKeys.country, country, SavedValueDataType.string);
          await _localStorageManager.saveValue(
              LocalStorageKeys.latitude, latitude, SavedValueDataType.double);
          await _localStorageManager.saveValue(
              LocalStorageKeys.longitude, longitude, SavedValueDataType.double);
        }

        if (ip?.trim().isNotEmpty == true) {
          await _localStorageManager.saveValue(
              LocalStorageKeys.ipAddress, ip, SavedValueDataType.string);
        }
        return data;
      } else {
        debugPrint('Failed to get location');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting location from IP: $e');
      return null;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnable() async {
    final iServiceEnabled = await Geolocator.isLocationServiceEnabled();
    return iServiceEnabled;
  }
}
