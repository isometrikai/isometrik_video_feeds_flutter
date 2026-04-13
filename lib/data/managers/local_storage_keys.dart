import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class LocalStorageKeys {
  LocalStorageKeys._();

  static String get _prefix => '${IsrVideoReelConfig.appName}_key_';

  static String _k(String suffix) => '$_prefix$suffix';

  static String get language => _k('language');
  static String get accessToken => _k('authorizedToken');
  static String get refreshToken => _k('authorizedRefreshToken');
  static String get userInfo => _k('userInfo');
  static String get tokenType => _k('tokenType');
  static String get isLoggedIn => _k('isLoggedIn');
  static String get userId => _k('userId');
  static String get userName => _k('userName');
  static String get currencySymbol => _k('currencySymbol');
  static String get currencyCode => _k('currencyCode');
  static String get latitude => _k('latitude');
  static String get longitude => _k('longitude');
  static String get countryId => _k('countryId');
  static String get email => _k('email');
  static String get firstName => _k('firstName');
  static String get lastName => _k('lastName');
  static String get profilePic => _k('profilePic');
  static String get dialCode => _k('dialCode');
  static String get phoneNumber => _k('phoneNumber');
  static String get city => _k('city');
  static String get state => _k('state');
  static String get country => _k('country');
  static String get ipAddress => _k('ipAddress');
  static String get version => _k('version');
  static String get platform => _k('platform');
  static String get xTenantId => _k('xTenantId');
  static String get xProjectId => _k('xProjectId');
}
