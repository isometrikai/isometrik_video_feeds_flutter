import 'package:ism_video_reel_player/domain/base_repository.dart';

abstract class IsrLocalStorageRepository extends BaseRepository {
  Future<String> getUserId();

  Future<String> getEmail();

  Future<bool> isLoggedIn();

  Future<String> getCurrencySymbol();

  Future<String> getCurrencyCode();

  void deleteSecuredValue(String key);

  void deleteValue(String key);

  void deleteAllSecuredValues();

  void clearLocalData();

  void clearSession();

  Future<String> getLanguage();

  Future<String> getAccessToken();

  Future<String> getRefreshToken();

  Future<String> getPhoneNumber();

  Future<String> getFirstName();

  Future<String> getLastName();

  Future<String> getProfilePic();

  Future<String> getUserInfo();

  void saveLanguage(String value);

  void saveIsLoggedIn(bool value);

  void saveAccessToken(String value);

  void saveRefreshToken(String value);

  void savePhoneNumber(String value);

  void saveEmail(String value);

  void saveFirstName(String value);

  void saveLastName(String value);

  void saveProfilePic(String value);
}
