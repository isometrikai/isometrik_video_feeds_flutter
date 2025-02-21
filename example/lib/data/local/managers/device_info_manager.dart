import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoManager {
  /// Device info plugin initialization
  final deviceInfo = DeviceInfoPlugin();

  /// To get android device info
  AndroidDeviceInfo? androidDeviceInfo;

  /// To get iOS device info
  IosDeviceInfo? iosDeviceInfo;

  /// initialize the android device information
  Future<void> init() async {
    if (Platform.isAndroid) {
      androidDeviceInfo = await deviceInfo.androidInfo;
    } else {
      iosDeviceInfo = await deviceInfo.iosInfo;
    }
  }

  /// Device id
  String? get deviceId => Platform.isAndroid ? androidDeviceInfo?.id : iosDeviceInfo?.identifierForVendor;

  /// Device make brand
  String? get deviceMake => Platform.isAndroid ? androidDeviceInfo?.brand : 'Apple';

  /// Device Model
  String? get deviceModel => Platform.isAndroid ? androidDeviceInfo?.model : iosDeviceInfo?.model;

  /// Device is a type of 1 for Android and 2 for iOS
  String get deviceTypeCode => Platform.isAndroid ? '1' : '2';

  //app store type 1 for PLAY_STORE and 2 for APP_STORE
  int get appStoreType => Platform.isAndroid ? 1 : 2;

  /// Device OS
  String get deviceOs => Platform.isAndroid ? 'ANDROID' : 'IOS';

  String get appVersion => androidDeviceInfo?.version.release ?? '';
}
